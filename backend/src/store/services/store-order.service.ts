import {
  Injectable,
  NotFoundException,
  BadRequestException,
  ForbiddenException,
  Logger,
} from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { StoreCouponService } from './store-coupon.service';
import { StorePaymentService } from './store-payment.service';
import { StoreAddressService } from './store-address.service';
import {
  CreateOrderDto,
  VerifyPaymentDto,
  ReturnRequestDto,
  OrderItemInputDto,
  PaymentMethodDto,
} from '../dto/store-dtos';
import { EcomOrderStatus, EcomPaymentStatus, PaymentMethodType } from '@prisma/client';

@Injectable()
export class StoreOrderService {
  private readonly logger = new Logger(StoreOrderService.name);

  constructor(
    private prisma: PrismaService,
    private couponService: StoreCouponService,
    private paymentService: StorePaymentService,
    private addressService: StoreAddressService,
  ) {}

  private async resolveCustomerId(customerId: string): Promise<string> {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(customerId);
    if (!isUuid) {
      throw new BadRequestException('Customer record not found');
    }
    const user = await this.prisma.user.findUnique({
      where: { id: customerId },
    });
    if (!user) {
      throw new BadRequestException('Customer record not found');
    }
    return user.id;
  }

  // Server-side calculation engine
  async previewOrder(dto: {
    items: OrderItemInputDto[];
    deliveryOption: string;
    couponCode?: string;
  }) {
    if (!dto.items || dto.items.length === 0) {
      throw new BadRequestException('Order items list cannot be empty.');
    }

    const productIds = dto.items.map((i) => i.productId);
    const products = await this.prisma.product.findMany({
      where: { id: { in: productIds }, deletedAt: null },
    });

    const productMap = new Map(products.map((p) => [p.id, p]));

    let subtotal = 0;
    let mrpTotal = 0;
    const validatedItems = [];

    for (const item of dto.items) {
      const product = productMap.get(item.productId);
      if (!product) {
        throw new BadRequestException(`Product with ID ${item.productId} was not found.`);
      }

      if (product.stock < item.quantity) {
        throw new BadRequestException(
          `Insufficient stock for "${product.name}". Available: ${product.stock}, requested: ${item.quantity}.`,
        );
      }

      const itemPrice = product.price;
      const itemMrp = product.mrp > 0 ? product.mrp : product.price;

      subtotal += itemPrice * item.quantity;
      mrpTotal += itemMrp * item.quantity;

      validatedItems.push({
        productId: product.id,
        productName: product.name,
        productImage: product.imageUrl,
        brand: product.brand,
        price: itemPrice,
        mrp: itemMrp,
        quantity: item.quantity,
        selectedVariant: item.selectedVariant || null,
        itemTotal: itemPrice * item.quantity,
      });
    }

    // Delivery fee
    let deliveryFee = 0;
    const isExpress = (dto.deliveryOption || '').toLowerCase() === 'express';
    if (isExpress) {
      deliveryFee = 99;
    } else {
      deliveryFee = subtotal >= 499 ? 0 : 40;
    }

    // Coupon discount calculation
    let couponDiscount = 0;
    let appliedCoupon = null;
    if (dto.couponCode && dto.couponCode.trim() !== '') {
      try {
        const couponResult = await this.couponService.validateCoupon(dto.couponCode, subtotal);
        couponDiscount = couponResult.discountAmount;
        appliedCoupon = {
          code: couponResult.code,
          description: couponResult.description,
          discountAmount: couponDiscount,
        };
      } catch (err: any) {
        this.logger.warn(`Coupon validation failed during preview: ${err.message}`);
        throw new BadRequestException(err.message || 'Invalid coupon code');
      }
    }

    const catalogDiscount = Math.max(0, mrpTotal - subtotal);
    const taxAmount = Math.round((subtotal * 0.18) * 100) / 100; // 18% GST (already inclusive or breakdown)
    const finalTotal = Math.max(0, Math.round((subtotal - couponDiscount + deliveryFee) * 100) / 100);
    const totalSavings = Math.round((catalogDiscount + couponDiscount + (deliveryFee === 0 && !isExpress ? 40 : 0)) * 100) / 100;

    return {
      items: validatedItems,
      subtotal: Math.round(subtotal * 100) / 100,
      mrpTotal: Math.round(mrpTotal * 100) / 100,
      catalogDiscount: Math.round(catalogDiscount * 100) / 100,
      deliveryFee,
      couponDiscount,
      taxAmount,
      totalAmount: finalTotal,
      totalSavings,
      deliveryOption: isExpress ? 'express' : 'standard',
      appliedCoupon,
    };
  }

  async createOrder(dto: CreateOrderDto) {
    const customerId = await this.resolveCustomerId(dto.customerId);

    // 1. Fetch and snapshot delivery address
    const address = await this.addressService.getAddressById(dto.addressId, customerId);
    const addressSnapshot = {
      addressId: address.id,
      fullName: address.fullName,
      phoneNumber: address.phoneNumber,
      buildingNo: address.buildingNo,
      street: address.street,
      area: address.area,
      city: address.city,
      state: address.state,
      pincode: address.pincode,
      landmark: address.landmark,
      addressType: address.addressType,
    };

    // 2. Compute server-verified pricing
    const pricing = await this.previewOrder({
      items: dto.items,
      deliveryOption: dto.deliveryOption,
      couponCode: dto.couponCode,
    });

    // 3. Calculate estimated delivery date
    const now = new Date();
    const isExpress = (dto.deliveryOption || '').toLowerCase() === 'express';
    const estimatedDelivery = new Date(
      now.getTime() + (isExpress ? 1 : 3) * 24 * 60 * 60 * 1000,
    );

    const orderNumber = `PHX-${Date.now().toString().slice(-6)}-${Math.floor(1000 + Math.random() * 9000)}`;

    const deliveryOptionSnapshot = {
      id: isExpress ? 'express' : 'standard',
      name: isExpress ? 'Express Delivery' : 'Standard Delivery',
      fee: pricing.deliveryFee,
      estimatedDelivery: estimatedDelivery.toISOString(),
    };

    const initialTimeline = [
      {
        status: 'PLACED',
        title: 'Order Placed',
        description: 'We have received your order.',
        timestamp: now.toISOString(),
      },
    ];

    const isCod = dto.paymentMethod === PaymentMethodDto.CASH_ON_DELIVERY;

    // 4. Atomic transaction: create order, create order items, decrement stock
    const order = await this.prisma.$transaction(async (tx) => {
      // Decrement stock
      for (const item of pricing.items) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { decrement: item.quantity } },
        });
      }

      const created = await tx.ecomOrder.create({
        data: {
          orderNumber,
          customerId,
          status: isCod ? EcomOrderStatus.CONFIRMED : EcomOrderStatus.PLACED,
          deliveryAddress: addressSnapshot,
          deliveryOption: deliveryOptionSnapshot,
          paymentMethod: dto.paymentMethod as PaymentMethodType,
          paymentStatus: isCod ? EcomPaymentStatus.PENDING : EcomPaymentStatus.PENDING,
          subtotal: pricing.subtotal,
          discountAmount: pricing.catalogDiscount,
          deliveryFee: pricing.deliveryFee,
          couponDiscount: pricing.couponDiscount,
          taxAmount: pricing.taxAmount,
          totalAmount: pricing.totalAmount,
          couponCode: pricing.appliedCoupon?.code || null,
          estimatedDelivery,
          timeline: initialTimeline,
        },
      });

      // Create items
      for (const item of pricing.items) {
        await tx.ecomOrderItem.create({
          data: {
            orderId: created.id,
            productId: item.productId,
            productName: item.productName,
            productImage: item.productImage,
            price: item.price,
            mrp: item.mrp,
            quantity: item.quantity,
            selectedVariant: item.selectedVariant,
          },
        });
      }

      return created;
    });

    // 5. Payment Session Creation
    let paymentSession = null;
    if (!isCod) {
      paymentSession = await this.paymentService.createPaymentSession(
        order.id,
        order.totalAmount,
        'INR',
        dto.paymentMethod,
      );
      // Save payment ID
      await this.prisma.ecomOrder.update({
        where: { id: order.id },
        data: { paymentId: paymentSession.paymentId },
      });
    }

    const fullOrder = await this.getOrderById(order.id, customerId);

    return {
      order: fullOrder,
      paymentSession,
      isCod,
    };
  }

  async verifyPayment(orderId: string, dto: VerifyPaymentDto) {
    const order = await this.prisma.ecomOrder.findUnique({
      where: { id: orderId },
    });
    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.paymentStatus === EcomPaymentStatus.PAID) {
      return { verified: true, order };
    }

    const verifyResult = await this.paymentService.verifyPayment(
      dto.paymentId,
      dto.signature,
      dto.status,
    );

    if (!verifyResult.verified) {
      await this.prisma.ecomOrder.update({
        where: { id: orderId },
        data: { paymentStatus: EcomPaymentStatus.FAILED },
      });
      throw new BadRequestException(verifyResult.message || 'Payment verification failed');
    }

    // Add CONFIRMED step in timeline
    const timeline = (order.timeline as any[]) || [];
    timeline.push({
      status: 'CONFIRMED',
      title: 'Order Confirmed & Paid',
      description: `Payment confirmed via ${order.paymentMethod} (Ref: ${dto.paymentId}).`,
      timestamp: new Date().toISOString(),
    });

    const updated = await this.prisma.ecomOrder.update({
      where: { id: orderId },
      data: {
        paymentStatus: EcomPaymentStatus.PAID,
        status: EcomOrderStatus.CONFIRMED,
        paymentId: dto.paymentId,
        timeline,
      },
      include: {
        items: true,
      },
    });

    return {
      verified: true,
      order: updated,
    };
  }

  async getCustomerOrders(customerId: string, statusFilter?: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const where: any = { customerId: resolvedId, deletedAt: null };

    if (statusFilter && statusFilter.toUpperCase() !== 'ALL') {
      where.status = statusFilter.toUpperCase();
    }

    return this.prisma.ecomOrder.findMany({
      where,
      include: {
        items: true,
        returns: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getOrderById(orderId: string, customerId?: string) {
    const where: any = { id: orderId };
    if (customerId) {
      const resolvedId = await this.resolveCustomerId(customerId);
      where.customerId = resolvedId;
    }

    const order = await this.prisma.ecomOrder.findFirst({
      where,
      include: {
        items: true,
        returns: true,
      },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }
    return order;
  }

  async cancelOrder(orderId: string, customerId: string, reason?: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const order = await this.prisma.ecomOrder.findFirst({
      where: { id: orderId, customerId: resolvedId },
      include: { items: true },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    const cancellableStatuses: EcomOrderStatus[] = [
      EcomOrderStatus.PLACED,
      EcomOrderStatus.CONFIRMED,
      EcomOrderStatus.PROCESSING,
    ];

    if (!cancellableStatuses.includes(order.status)) {
      throw new BadRequestException(
        `Order cannot be cancelled in status "${order.status}". Items are already dispatched.`,
      );
    }

    const timeline = (order.timeline as any[]) || [];
    timeline.push({
      status: 'CANCELLED',
      title: 'Order Cancelled',
      description: reason || 'Cancelled by customer.',
      timestamp: new Date().toISOString(),
    });

    // Revert inventory stock
    await this.prisma.$transaction(async (tx) => {
      for (const item of order.items) {
        await tx.product.update({
          where: { id: item.productId },
          data: { stock: { increment: item.quantity } },
        });
      }

      await tx.ecomOrder.update({
        where: { id: orderId },
        data: {
          status: EcomOrderStatus.CANCELLED,
          timeline,
        },
      });
    });

    return this.getOrderById(orderId, customerId);
  }

  async submitReturnRequest(orderId: string, customerId: string, dto: ReturnRequestDto) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const order = await this.prisma.ecomOrder.findFirst({
      where: { id: orderId, customerId: resolvedId },
    });

    if (!order) {
      throw new NotFoundException('Order not found');
    }

    if (order.status !== EcomOrderStatus.DELIVERED) {
      throw new BadRequestException('Returns can only be requested for delivered orders.');
    }

    const returnRequest = await this.prisma.ecomReturnRequest.create({
      data: {
        orderId,
        customerId: resolvedId,
        type: dto.type === 'REPLACEMENT' ? 'REPLACEMENT' : 'RETURN',
        reason: dto.reason,
        comments: dto.comments,
      },
    });

    const timeline = (order.timeline as any[]) || [];
    timeline.push({
      status: 'RETURN_REQUESTED',
      title: `${dto.type === 'REPLACEMENT' ? 'Replacement' : 'Return'} Requested`,
      description: `Reason: ${dto.reason}. Under review by fulfillment team.`,
      timestamp: new Date().toISOString(),
    });

    await this.prisma.ecomOrder.update({
      where: { id: orderId },
      data: {
        status: EcomOrderStatus.RETURN_REQUESTED,
        timeline,
      },
    });

    return returnRequest;
  }
}
