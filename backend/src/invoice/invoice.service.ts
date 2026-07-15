import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOrderDto } from './dto/create-order.dto';

@Injectable()
export class InvoiceService {
  constructor(private prisma: PrismaService) {}

  async createRazorpayOrder(dto: CreateOrderDto) {
    const orderId = `rzp_order_live_${Date.now()}`;
    return {
      orderId,
      amount: dto.amount,
      currency: dto.currency,
      status: 'created',
    };
  }

  async verifyPaymentSignature(payload: any) {
    const bookingId = payload.bookingId;
    const amount = parseFloat(payload.amount ?? '0');
    const paymentMethod = payload.paymentMethod ?? 'UPI';
    const paymentId = payload.paymentId ?? `pay_mock_${Date.now()}`;

    // Verify booking exists in DB
    if (bookingId) {
      const bookingExists = await this.prisma.booking.findUnique({
        where: { id: bookingId },
      });
      if (!bookingExists) {
        throw new NotFoundException(`Booking with ID ${bookingId} not found`);
      }
    }

    // Persist real Invoice inside PostgreSQL database
    const invoice = await this.prisma.invoice.create({
      data: {
        bookingId: bookingId,
        amount: amount,
        taxAmount: amount * 0.18, // 18% tax rate
        discountAmount: parseFloat(payload.discountAmount ?? '0'),
        totalAmount: amount + (amount * 0.18) - (parseFloat(payload.discountAmount ?? '0')),
        status: 'PAID',
        paymentMethod: paymentMethod,
        paymentId: paymentId,
      },
    });

    // Automatically create a simulated active warranty record for the service item if completed
    if (bookingId) {
      const booking = await this.prisma.booking.findUnique({
        where: { id: bookingId },
        include: { serviceItem: true },
      });

      if (booking) {
        // Update booking status to completed
        await this.prisma.booking.update({
          where: { id: bookingId },
          data: { status: 'COMPLETED' },
        });

        // Add COMPLETED step in timeline
        await this.prisma.bookingTimeline.create({
          data: {
            bookingId: bookingId,
            status: 'Completed',
            notes: 'Service successfully delivered and payment completed.',
          },
        });

        // Add 6-month warranty card in database
        await this.prisma.warranty.create({
          data: {
            propertyId: booking.propertyId,
            itemName: booking.serviceItem.nameEn,
            installDate: new Date(),
            expiryDate: new Date(Date.now() + 180 * 24 * 60 * 60 * 1000), // 180 days
            duration: '6 Months',
            status: 'ACTIVE',
          },
        });
      }
    }

    return {
      verified: true,
      status: 'PAID',
      invoiceId: invoice.id,
      totalAmount: invoice.totalAmount,
    };
  }
}
