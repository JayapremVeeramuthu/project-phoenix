import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';

@Injectable()
export class StoreCouponService {
  constructor(private prisma: PrismaService) {}

  async getActiveCoupons() {
    return this.prisma.coupon.findMany({
      where: {
        isActive: true,
        OR: [
          { expiryDate: null },
          { expiryDate: { gte: new Date() } },
        ],
      },
      orderBy: { discountValue: 'desc' },
    });
  }

  async validateCoupon(code: string, subtotal: number): Promise<{
    valid: boolean;
    code: string;
    description: string;
    discountAmount: number;
    message: string;
  }> {
    if (!code || code.trim() === '') {
      throw new BadRequestException('Coupon code is required');
    }

    const coupon = await this.prisma.coupon.findUnique({
      where: { code: code.trim().toUpperCase() },
    });

    if (!coupon || !coupon.isActive) {
      throw new BadRequestException(`Coupon code "${code}" is invalid or expired.`);
    }

    if (coupon.expiryDate && coupon.expiryDate < new Date()) {
      throw new BadRequestException(`Coupon code "${code}" has expired.`);
    }

    if (subtotal < coupon.minOrderAmount) {
      throw new BadRequestException(
        `Coupon "${coupon.code}" requires a minimum order value of ₹${coupon.minOrderAmount.toFixed(0)}. Add ₹${(coupon.minOrderAmount - subtotal).toFixed(0)} more to apply.`,
      );
    }

    let discount = 0;
    if (coupon.discountType === 'PERCENT') {
      discount = (subtotal * coupon.discountValue) / 100;
      if (coupon.maxDiscount && discount > coupon.maxDiscount) {
        discount = coupon.maxDiscount;
      }
    } else {
      // FLAT
      discount = Math.min(coupon.discountValue, subtotal);
    }

    // Round to 2 decimals
    discount = Math.round(discount * 100) / 100;

    return {
      valid: true,
      code: coupon.code,
      description: coupon.description,
      discountAmount: discount,
      message: `Coupon applied successfully! Saved ₹${discount.toFixed(0)}.`,
    };
  }
}
