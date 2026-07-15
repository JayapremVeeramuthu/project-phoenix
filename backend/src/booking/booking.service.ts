import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { RabbitmqService } from '../common/services/rabbitmq.service';

@Injectable()
export class BookingService {
  constructor(
    private prisma: PrismaService,
    private rabbitmq: RabbitmqService,
  ) {}

  async createBooking(dto: CreateBookingDto) {
    // 1. Create booking in PostgreSQL
    const booking = await this.prisma.booking.create({
      data: {
        localId: dto.localId,
        customerId: dto.customerId,
        propertyId: dto.propertyId,
        serviceId: dto.serviceId,
        address: dto.address,
        scheduledAt: new Date(dto.scheduledAt),
        timeSlot: dto.timeSlot,
        isEmergency: dto.isEmergency ?? false,
        description: dto.description,
        imageUrls: dto.imageUrls ?? [],
        voiceNoteUrl: dto.voiceNoteUrl,
        voiceTranscript: dto.voiceTranscript,
        estimatedPrice: dto.estimatedPrice,
        latitude: dto.latitude,
        longitude: dto.longitude,
        status: 'PENDING',
      },
    });

    // 2. Initialize tracking timeline step
    await this.prisma.bookingTimeline.create({
      data: {
        bookingId: booking.id,
        status: 'Created',
        notes: 'Booking created successfully.',
      },
    });

    // Write Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId: booking.customerId,
        action: 'BOOKING_CREATE',
        details: `Booking created: ${booking.id} for service: ${booking.serviceId}`,
      },
    });

    // 3. Publish message to RabbitMQ event queue for background processing
    await this.rabbitmq.publish('booking_events', {
      eventId: 'booking.created',
      bookingId: booking.id,
      customerId: booking.customerId,
      timestamp: new Date().toISOString(),
    });

    return booking;
  }

  async getBookings(page = 1, limit = 10) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.booking.findMany({
        where: { deletedAt: null },
        include: { serviceItem: true },
        skip,
        take: limit,
      }),
      this.prisma.booking.count({
        where: { deletedAt: null },
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getBookingTimeline(bookingId: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const steps = await this.prisma.bookingTimeline.findMany({
      where: { bookingId },
      orderBy: { createdAt: 'asc' },
    });

    // Map stages: PENDING -> Created, etc.
    const completedSteps = steps.map((s, index) => ({
      index,
      title: s.status,
      description: s.notes,
      timestamp: s.createdAt,
    }));

    return {
      bookingId,
      currentStatus: booking.status,
      timeline: completedSteps,
    };
  }
}
