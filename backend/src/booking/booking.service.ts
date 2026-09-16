import { Injectable, NotFoundException, ConflictException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { RabbitmqService } from '../common/services/rabbitmq.service';
import { BookingGateway } from './booking.gateway';

@Injectable()
export class BookingService {
  constructor(
    private prisma: PrismaService,
    private rabbitmq: RabbitmqService,
    private bookingGateway: BookingGateway,
  ) {}

  async createBooking(dto: CreateBookingDto, authenticatedUserId?: string) {
    const effectiveCustomerId = authenticatedUserId || dto.customerId;
    if (!effectiveCustomerId) {
      throw new BadRequestException('A valid customerId is required to create a booking.');
    }

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(effectiveCustomerId);
    if (!isUuid) {
      throw new BadRequestException(`Invalid customer identifier '${effectiveCustomerId}'. A valid UUID is required.`);
    }

    const customer = await this.prisma.user.findUnique({
      where: { id: effectiveCustomerId },
    });

    if (!customer) {
      throw new BadRequestException(
        `Customer with ID '${effectiveCustomerId}' does not exist in the database. Please log in with a valid account.`,
      );
    }

    let propertyId = dto.propertyId;
    const isPropUuid = propertyId && /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(propertyId);
    let property = isPropUuid
      ? await this.prisma.property.findFirst({
          where: { id: propertyId, customerId: customer.id, deletedAt: null },
        })
      : null;

    if (!property) {
      let customerProperty = await this.prisma.property.findFirst({
        where: { customerId: customer.id, deletedAt: null },
      });
      if (!customerProperty) {
        customerProperty = await this.prisma.property.create({
          data: {
            customerId: customer.id,
            name: 'Primary Residence',
            address: dto.address,
            installedAppliances: [],
          },
        });
      }
      propertyId = customerProperty.id;
    }

    // 1. Create booking in PostgreSQL
    const booking = await this.prisma.booking.create({
      data: {
        localId: dto.localId,
        customerId: customer.id,
        propertyId: propertyId,
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
        status: 'WAITING_FOR_TECHNICIAN',
      },
    });
    console.log('[BookingService] Created Booking in PostgreSQL. UUID:', booking.id, 'Customer UUID:', customer.id);

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

    const fullBooking = await this.prisma.booking.findUnique({
      where: { id: booking.id },
      include: {
        serviceItem: true,
        customer: true,
      },
    });
    if (fullBooking) {
      const technicians = await this.prisma.user.findMany({
        where: {
          role: 'TECHNICIAN',
          isOnline: true,
          isActive: true,
        },
      });

      const eligibleIds = technicians.map((t) => t.id);
      this.bookingGateway.broadcastNewBooking(fullBooking, eligibleIds);
    }

    return booking;
  }

  async getBookings(page = 1, limit = 10, customerId?: string) {
    const skip = (page - 1) * limit;
    const where: any = { deletedAt: null };
    if (customerId) {
      where.customerId = customerId;
    }
    const [data, total] = await Promise.all([
      this.prisma.booking.findMany({
        where,
        include: {
          serviceItem: true,
          technician: true,
          customer: true,
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.booking.count({
        where,
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

  async getAvailableBookings(technicianId: string) {
    const technician = await this.prisma.user.findUnique({
      where: { id: technicianId },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    return this.prisma.booking.findMany({
      where: {
        status: {
          in: ['WAITING_FOR_TECHNICIAN', 'PENDING'],
        },
        NOT: {
          rejectedBy: {
            has: technicianId,
          },
        },
        deletedAt: null,
      },
      include: {
        serviceItem: true,
        customer: true,
      },
    });
  }

  async getBookingTimeline(bookingId: string) {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);
    const booking = await this.prisma.booking.findFirst({
      where: isUuid ? { id: bookingId } : { localId: bookingId },
      include: {
        technician: true,
      },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }

    const steps = await this.prisma.bookingTimeline.findMany({
      where: { bookingId: booking.id },
      orderBy: { createdAt: 'asc' },
    });

    const completedSteps = steps.map((s, index) => ({
      index,
      title: s.status,
      description: s.notes,
      timestamp: s.createdAt,
    }));

    return {
      bookingId,
      currentStatus: booking.status,
      technicianName: booking.technician?.name || null,
      technicianPhone: booking.technician?.phoneNumber || null,
      technicianBranch: booking.technician?.branch || null,
      technicianId: booking.technician?.technicianId || null,
      timeline: completedSteps,
    };
  }

  async getTechnicianJobs(technicianId: string) {
    return this.prisma.booking.findMany({
      where: {
        technicianId,
        deletedAt: null,
      },
      include: {
        serviceItem: true,
        customer: true,
      },
      orderBy: {
        scheduledAt: 'asc',
      },
    });
  }

  async acceptBooking(bookingId: string, technicianId: string) {
    const technician = await this.prisma.user.findUnique({
      where: { id: technicianId },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);

    const updatedBooking = await this.prisma.$transaction(async (tx) => {
      const booking = await tx.booking.findFirst({
        where: isUuid ? { id: bookingId } : { localId: bookingId },
      });

      if (!booking) {
        throw new NotFoundException('Booking not found.');
      }

      if (booking.status !== 'PENDING' && booking.status !== 'WAITING_FOR_TECHNICIAN') {
        throw new ConflictException('This booking has already been accepted by another technician.');
      }

      const updated = await tx.booking.update({
        where: { id: booking.id },
        data: {
          status: 'TECHNICIAN_ASSIGNED',
          technicianId: technicianId,
        },
      });

      await tx.bookingTimeline.create({
        data: {
          bookingId: booking.id,
          status: 'Assigned',
          notes: `Job assigned to technician ${technician.name}.`,
        },
      });

      await tx.auditLog.create({
        data: {
          userId: technicianId,
          action: 'BOOKING_ACCEPT',
          details: `Technician ${technician.name} accepted booking: ${booking.id}`,
        },
      });

      return updated;
    });

    this.bookingGateway.broadcastBookingAccepted(
      updatedBooking.id,
      updatedBooking.localId,
      technician.name,
      technician.phoneNumber,
      technician.branch || '',
      technician.technicianId || '',
    );

    return updatedBooking;
  }

  async updateStatus(bookingId: string, status: any, notes?: string) {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);
    const booking = await this.prisma.booking.findFirst({
      where: isUuid ? { id: bookingId } : { localId: bookingId },
      include: {
        technician: true,
      },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found.');
    }

    const updated = await this.prisma.$transaction(async (tx) => {
      const upd = await tx.booking.update({
        where: { id: booking.id },
        data: { status },
      });

      await tx.bookingTimeline.create({
        data: {
          bookingId: booking.id,
          status: status,
          notes: notes || `Booking status updated to ${status}.`,
        },
      });

      await tx.auditLog.create({
        data: {
          userId: booking.technicianId || booking.customerId,
          action: 'BOOKING_STATUS_UPDATE',
          details: `Booking ${booking.id} status updated to ${status}`,
        },
      });

      return upd;
    });

    this.bookingGateway.broadcastBookingStatusUpdated(
      booking.id,
      booking.localId,
      status,
      booking.technician?.name,
      booking.technician?.phoneNumber,
      booking.technician?.branch || '',
      booking.technician?.technicianId || '',
    );

    return updated;
  }

  async rejectBooking(bookingId: string, technicianId: string) {
    const technician = await this.prisma.user.findUnique({
      where: { id: technicianId },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(bookingId);
    const booking = await this.prisma.booking.findFirst({
      where: isUuid ? { id: bookingId } : { localId: bookingId },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found.');
    }

    const rejectedBy = booking.rejectedBy || [];
    if (!rejectedBy.includes(technicianId)) {
      await this.prisma.booking.update({
        where: { id: booking.id },
        data: {
          rejectedBy: {
            set: [...rejectedBy, technicianId],
          },
        },
      });
    }

    return { success: true };
  }
}
