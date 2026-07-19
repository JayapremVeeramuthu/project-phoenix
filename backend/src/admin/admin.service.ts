import { Injectable, BadRequestException, NotFoundException, ForbiddenException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateTechnicianDto } from './dto/create-technician.dto';
import { UpdateTechnicianDto } from './dto/update-technician.dto';
import * as bcrypt from 'bcryptjs';
import * as fs from 'fs';
import * as path from 'path';

@Injectable()
export class AdminService {
  constructor(private prisma: PrismaService) {}

  async createTechnician(dto: CreateTechnicianDto) {
    // Check if phone or email already exists
    const existing = await this.prisma.user.findFirst({
      where: {
        OR: [
          { phoneNumber: dto.phoneNumber },
          { email: dto.email },
        ],
      },
    });

    if (existing) {
      throw new BadRequestException('User with this email or phone number already exists.');
    }

    // Auto-generate Technician ID sequentially (TECH000001)
    const latestTech = await this.prisma.user.findFirst({
      where: {
        technicianId: { startsWith: 'TECH' },
      },
      orderBy: {
        technicianId: 'desc',
      },
    });

    let nextNum = 1;
    if (latestTech && latestTech.technicianId) {
      const match = latestTech.technicianId.match(/\d+/);
      if (match) {
        nextNum = parseInt(match[0], 10) + 1;
      }
    }
    const technicianId = `TECH${nextNum.toString().padStart(6, '0')}`;

    // Use temporary password provided in dto
    const tempPassword = dto.password;
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    const newTechnician = await this.prisma.user.create({
      data: {
        name: dto.name,
        phoneNumber: dto.phoneNumber,
        email: dto.email,
        branch: dto.branch,
        role: 'TECHNICIAN',
        technicianId,
        password: hashedPassword,
        mustChangePassword: true,
        skills: dto.skills ?? [],
        serviceAreas: dto.serviceAreas ?? [],
        experience: dto.experience,
        isActive: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: newTechnician.id,
        action: 'TECHNICIAN_CREATE',
        details: `Created technician: ${newTechnician.technicianId} with temporary password: ${tempPassword}`,
      },
    });

    return {
      technician: {
        id: newTechnician.id,
        technicianId: newTechnician.technicianId,
        name: newTechnician.name,
        phoneNumber: newTechnician.phoneNumber,
        email: newTechnician.email,
        branch: newTechnician.branch,
        role: newTechnician.role,
        skills: newTechnician.skills,
        serviceAreas: newTechnician.serviceAreas,
        experience: newTechnician.experience,
        isActive: newTechnician.isActive,
      },
      temporaryPassword: tempPassword,
    };
  }

  async updateTechnician(id: string, dto: UpdateTechnicianDto) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (targetUser && targetUser.isFounder) {
      throw new ForbiddenException('Cannot modify Founder Admin account.');
    }

    const technician = await this.prisma.user.findFirst({
      where: { id, role: 'TECHNICIAN', deletedAt: null },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    // Email or phone validation
    if (dto.email || dto.phoneNumber) {
      const existing = await this.prisma.user.findFirst({
        where: {
          id: { not: id },
          OR: [
            dto.phoneNumber ? { phoneNumber: dto.phoneNumber } : undefined,
            dto.email ? { email: dto.email } : undefined,
          ].filter(Boolean) as any,
        },
      });
      if (existing) {
        throw new BadRequestException('User with this email or phone number already exists.');
      }
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        name: dto.name,
        phoneNumber: dto.phoneNumber,
        email: dto.email,
        branch: dto.branch,
        skills: dto.skills,
        serviceAreas: dto.serviceAreas,
        experience: dto.experience,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: id,
        action: 'TECHNICIAN_UPDATE',
        details: `Updated details for technician: ${updated.technicianId}`,
      },
    });

    return updated;
  }

  async toggleStatus(id: string, isActive: boolean) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (targetUser && targetUser.isFounder) {
      throw new ForbiddenException('Cannot modify Founder Admin account.');
    }

    const technician = await this.prisma.user.findFirst({
      where: { id, role: 'TECHNICIAN', deletedAt: null },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    const updated = await this.prisma.user.update({
      where: { id },
      data: {
        isActive,
        isOnline: isActive ? undefined : false, // Force offline if disabled
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: id,
        action: isActive ? 'TECHNICIAN_ENABLE' : 'TECHNICIAN_DISABLE',
        details: `Availability status updated for: ${updated.technicianId}`,
      },
    });

    return updated;
  }

  async resetPassword(id: string) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (targetUser && targetUser.isFounder) {
      throw new ForbiddenException('Cannot modify Founder Admin account.');
    }

    const technician = await this.prisma.user.findFirst({
      where: { id, role: 'TECHNICIAN', deletedAt: null },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    const randomDigits = Math.floor(1000 + Math.random() * 9000);
    const tempPassword = `PX@${randomDigits}`;
    const hashedPassword = await bcrypt.hash(tempPassword, 10);

    await this.prisma.user.update({
      where: { id },
      data: {
        password: hashedPassword,
        mustChangePassword: true,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: id,
        action: 'TECHNICIAN_PASSWORD_RESET',
        details: `Reset password for technician: ${technician.technicianId}`,
      },
    });

    return {
      message: 'Password reset successfully.',
      temporaryPassword: tempPassword,
    };
  }

  async softDelete(id: string) {
    const targetUser = await this.prisma.user.findUnique({ where: { id } });
    if (targetUser && targetUser.isFounder) {
      throw new ForbiddenException('Cannot modify Founder Admin account.');
    }

    const technician = await this.prisma.user.findFirst({
      where: { id, role: 'TECHNICIAN', deletedAt: null },
    });
    if (!technician) {
      throw new NotFoundException('Technician not found.');
    }

    const deleted = await this.prisma.user.update({
      where: { id },
      data: {
        deletedAt: new Date(),
        isActive: false,
        isOnline: false,
      },
    });

    await this.prisma.auditLog.create({
      data: {
        userId: id,
        action: 'TECHNICIAN_DELETE',
        details: `Soft deleted technician: ${technician.technicianId}`,
      },
    });

    return deleted;
  }

  async listTechnicians(search?: string, branch?: string, isActiveStr?: string) {
    const filters: any = {
      role: 'TECHNICIAN',
      deletedAt: null,
    };

    if (branch && branch.trim().length > 0) {
      filters.branch = { contains: branch, mode: 'insensitive' };
    }

    if (isActiveStr) {
      filters.isActive = isActiveStr === 'true';
    }

    if (search && search.trim().length > 0) {
      filters.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { phoneNumber: { contains: search, mode: 'insensitive' } },
        { technicianId: { contains: search, mode: 'insensitive' } },
      ];
    }

    const technicians = await this.prisma.user.findMany({
      where: filters,
      include: {
        jobs: {
          where: { deletedAt: null },
        },
      },
      orderBy: {
        createdAt: 'desc',
      },
    });

    // Map stats dynamically: Completed Jobs, Earnings, Current Booking
    return technicians.map((tech) => {
      const completedJobs = tech.jobs.filter((j) => j.status === 'COMPLETED');
      const earnings = completedJobs.reduce((sum, j) => sum + (j.estimatedPrice || 0), 0);
      const activeJob = tech.jobs.find(
        (j) => !['COMPLETED', 'CANCELLED', 'PENDING'].includes(j.status),
      );

      return {
        id: tech.id,
        technicianId: tech.technicianId,
        name: tech.name,
        phoneNumber: tech.phoneNumber,
        email: tech.email,
        branch: tech.branch,
        role: tech.role,
        skills: tech.skills,
        serviceAreas: tech.serviceAreas,
        experience: tech.experience,
        isActive: tech.isActive,
        isOnline: tech.isOnline,
        rating: 4.9, // Static/Mock average rating representation
        completedJobsCount: completedJobs.length,
        earnings,
        currentJobId: activeJob?.id || null,
        currentJobAddress: activeJob?.address || null,
        acceptanceRate: 96,
        completionRate: 98,
      };
    });
  }

  async getDashboardStats() {
    const now = new Date();
    const todayStart = new Date(now.getFullYear(), now.getMonth(), now.getDate());
    const todayEnd = new Date(now.getFullYear(), now.getMonth(), now.getDate() + 1);
    
    const monthStart = new Date(now.getFullYear(), now.getMonth(), 1);
    const yearStart = new Date(now.getFullYear(), 0, 1);

    const [
      customersCount,
      activeCustomersCount,
      techniciansCount,
      activeTechCount,
      onlineTechCount,
      todayBookingsCount,
      revenueBookingsToday,
      revenueBookingsMonth,
      revenueBookingsYear,
      pendingCount,
      assignedCount,
      completedCount,
      cancelledCount,
    ] = await Promise.all([
      this.prisma.user.count({ where: { role: 'CUSTOMER', deletedAt: null } }),
      this.prisma.user.count({ where: { role: 'CUSTOMER', isActive: true, deletedAt: null } }),
      this.prisma.user.count({ where: { role: 'TECHNICIAN', deletedAt: null } }),
      this.prisma.user.count({ where: { role: 'TECHNICIAN', isActive: true, deletedAt: null } }),
      this.prisma.user.count({ where: { role: 'TECHNICIAN', isOnline: true, deletedAt: null } }),
      this.prisma.booking.count({
        where: {
          scheduledAt: {
            gte: todayStart,
            lt: todayEnd,
          },
          deletedAt: null,
        },
      }),
      this.prisma.booking.findMany({
        where: {
          status: 'COMPLETED',
          scheduledAt: {
            gte: todayStart,
            lt: todayEnd,
          },
          deletedAt: null,
        },
        select: { estimatedPrice: true },
      }),
      this.prisma.booking.findMany({
        where: {
          status: 'COMPLETED',
          scheduledAt: {
            gte: monthStart,
          },
          deletedAt: null,
        },
        select: { estimatedPrice: true },
      }),
      this.prisma.booking.findMany({
        where: {
          status: 'COMPLETED',
          scheduledAt: {
            gte: yearStart,
          },
          deletedAt: null,
        },
        select: { estimatedPrice: true },
      }),
      this.prisma.booking.count({ where: { status: 'PENDING', deletedAt: null } }),
      this.prisma.booking.count({
        where: {
          status: { in: ['ASSIGNED', 'TECHNICIAN_ASSIGNED', 'TRAVELLING', 'REACHED', 'IN_PROGRESS'] },
          deletedAt: null,
        },
      }),
      this.prisma.booking.count({ where: { status: 'COMPLETED', deletedAt: null } }),
      this.prisma.booking.count({ where: { status: 'CANCELLED', deletedAt: null } }),
    ]);

    const todayRevenue = revenueBookingsToday.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);
    const monthRevenue = revenueBookingsMonth.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);
    const yearRevenue = revenueBookingsYear.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);
    const totalRevenue = revenueBookingsYear.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);

    return {
      totalCustomers: customersCount,
      activeCustomers: activeCustomersCount,
      totalTechnicians: techniciansCount,
      activeTechnicians: activeTechCount,
      onlineTechnicians: onlineTechCount,
      offlineTechnicians: techniciansCount - onlineTechCount,
      todayBookings: todayBookingsCount,
      pendingJobs: pendingCount,
      assignedBookings: assignedCount,
      completedJobs: completedCount,
      cancelledBookings: cancelledCount,
      todayRevenue,
      revenueThisMonth: monthRevenue,
      revenueThisYear: yearRevenue,
      revenue: totalRevenue,
      averageRating: 4.8,
      averageResponseTime: 12, // in minutes
      averageCompletionTime: 42, // in minutes
    };
  }

  private getSettingsFilePath() {
    return path.join(process.cwd(), 'settings.json');
  }

  async getSettings() {
    const filePath = this.getSettingsFilePath();
    if (fs.existsSync(filePath)) {
      try {
        return JSON.parse(fs.readFileSync(filePath, 'utf8'));
      } catch (_) {}
    }
    return {
      businessName: 'Phoenix Field Services',
      supportEmail: 'support@phoenix.fsm',
      supportPhone: '+919999999999',
      branches: ['Chennai OMR', 'Chennai T-Nagar', 'Coimbatore North', 'Madurai Central'],
      serviceAreas: ['Thoraipakkam', 'Adyar', 'Velachery', 'Nungambakkam', 'Gandhipuram', 'Peelamedu'],
      taxRatePercent: 18.0,
      workingHoursStart: '08:00',
      workingHoursEnd: '20:00',
      roles: ['Super Admin', 'Branch Admin', 'Manager', 'Dispatcher', 'Support'],
      permissions: {
        'Super Admin': ['view_bookings', 'edit_bookings', 'manage_technicians', 'view_revenue', 'view_analytics', 'manage_settings'],
        'Branch Admin': ['view_bookings', 'edit_bookings', 'manage_technicians', 'view_analytics'],
        'Manager': ['view_bookings', 'edit_bookings', 'manage_technicians', 'view_revenue'],
        'Dispatcher': ['view_bookings', 'edit_bookings'],
        'Support': ['view_bookings'],
      },
      smtpHost: 'smtp.gmail.com',
      smtpPort: 587,
      smsGatewayUrl: 'https://api.sms.local/send',
      whatsAppToken: 'mock_whatsapp_token_123',
    };
  }

  async updateSettings(dto: any) {
    const filePath = this.getSettingsFilePath();
    fs.writeFileSync(filePath, JSON.stringify(dto, null, 2), 'utf8');
    return dto;
  }

  async getNotifications() {
    return this.prisma.notification.findMany({
      orderBy: { createdAt: 'desc' },
      take: 50,
    });
  }

  async markNotificationRead(id: string) {
    return this.prisma.notification.update({
      where: { id },
      data: { isRead: true },
    });
  }

  async deleteNotification(id: string) {
    return this.prisma.notification.delete({
      where: { id },
    });
  }

  async getLogs(search?: string, action?: string, page = 1, limit = 50) {
    const skip = (page - 1) * limit;
    const where: any = {};
    if (action && action !== 'all' && action !== 'ALL') {
      where.action = action;
    }
    if (search && search.trim().length > 0) {
      where.OR = [
        { details: { contains: search, mode: 'insensitive' } },
        { action: { contains: search, mode: 'insensitive' } },
      ];
    }
    const [data, total] = await Promise.all([
      this.prisma.auditLog.findMany({
        where,
        include: { user: true },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.auditLog.count({ where }),
    ]);
    return {
      data: data.map(log => ({
        id: log.id,
        action: log.action,
        details: log.details,
        ipAddress: log.ipAddress || '127.0.0.1',
        createdAt: log.createdAt,
        userName: log.user?.name || 'System',
        userId: log.userId,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getAnalytics() {
    const now = new Date();
    const dailyBookings = [];
    for (let i = 6; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth(), now.getDate() - i);
      const start = new Date(d.getFullYear(), d.getMonth(), d.getDate());
      const end = new Date(d.getFullYear(), d.getMonth(), d.getDate() + 1);
      const count = await this.prisma.booking.count({
        where: {
          scheduledAt: { gte: start, lt: end },
          deletedAt: null,
        },
      });
      const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
      dailyBookings.push({
        label: days[d.getDay()],
        count,
      });
    }

    const weeklyRevenue = [];
    for (let i = 3; i >= 0; i--) {
      const start = new Date(now.getTime() - (i + 1) * 7 * 24 * 60 * 60 * 1000);
      const end = new Date(now.getTime() - i * 7 * 24 * 60 * 60 * 1000);
      const bookings = await this.prisma.booking.findMany({
        where: {
          status: 'COMPLETED',
          scheduledAt: { gte: start, lt: end },
          deletedAt: null,
        },
        select: { estimatedPrice: true },
      });
      const amount = bookings.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);
      weeklyRevenue.push({
        label: `Wk -${i}`,
        amount,
      });
    }

    const monthlyRevenue = [];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const start = new Date(d.getFullYear(), d.getMonth(), 1);
      const end = new Date(d.getFullYear(), d.getMonth() + 1, 1);
      const bookings = await this.prisma.booking.findMany({
        where: {
          status: 'COMPLETED',
          scheduledAt: { gte: start, lt: end },
          deletedAt: null,
        },
        select: { estimatedPrice: true },
      });
      const amount = bookings.reduce((sum, b) => sum + (b.estimatedPrice || 0), 0);
      monthlyRevenue.push({
        label: months[d.getMonth()],
        amount,
      });
    }

    const customerGrowth = [];
    let cumulative = await this.prisma.user.count({
      where: {
        role: 'CUSTOMER',
        createdAt: { lt: new Date(now.getFullYear(), now.getMonth() - 5, 1) },
        deletedAt: null,
      },
    });
    for (let i = 5; i >= 0; i--) {
      const d = new Date(now.getFullYear(), now.getMonth() - i, 1);
      const start = new Date(d.getFullYear(), d.getMonth(), 1);
      const end = new Date(d.getFullYear(), d.getMonth() + 1, 1);
      const count = await this.prisma.user.count({
        where: {
          role: 'CUSTOMER',
          createdAt: { gte: start, lt: end },
          deletedAt: null,
        },
      });
      cumulative += count;
      customerGrowth.push({
        label: months[d.getMonth()],
        count: cumulative,
      });
    }

    const bookingsForServices = await this.prisma.booking.findMany({
      where: { deletedAt: null },
      include: { serviceItem: true },
    });
    const serviceCounts: Record<string, number> = {};
    for (const b of bookingsForServices) {
      const name = b.serviceItem?.nameEn || b.serviceId;
      serviceCounts[name] = (serviceCounts[name] || 0) + 1;
    }
    const servicePopularity = Object.entries(serviceCounts).map(([name, count]) => ({
      name,
      count,
    })).sort((a, b) => b.count - a.count).slice(0, 5);

    const bookingsForSlots = await this.prisma.booking.findMany({
      where: { deletedAt: null },
      select: { timeSlot: true },
    });
    const slotCounts: Record<string, number> = {};
    for (const b of bookingsForSlots) {
      if (b.timeSlot) {
        slotCounts[b.timeSlot] = (slotCounts[b.timeSlot] || 0) + 1;
      }
    }
    const peakHours = Object.entries(slotCounts).map(([slot, count]) => ({
      slot,
      count,
    })).sort((a, b) => b.count - a.count);

    const totalBookings = await this.prisma.booking.count({ where: { deletedAt: null } });
    const completedJobs = await this.prisma.booking.count({ where: { status: 'COMPLETED', deletedAt: null } });
    const cancelledJobs = await this.prisma.booking.count({ where: { status: 'CANCELLED', deletedAt: null } });

    const completionRate = totalBookings > 0 ? (completedJobs / totalBookings) * 100 : 0.0;
    const cancellationRate = totalBookings > 0 ? (cancelledJobs / totalBookings) * 100 : 0.0;

    const bookingsByCustomer = await this.prisma.booking.groupBy({
      by: ['customerId'],
      where: { deletedAt: null },
      _count: { id: true },
    });
    const repeatCount = bookingsByCustomer.filter(g => g._count.id > 1).length;
    const totalUniqueCustomers = bookingsByCustomer.length;
    const repeatCustomerRate = totalUniqueCustomers > 0 ? (repeatCount / totalUniqueCustomers) * 100 : 0.0;

    return {
      dailyBookings,
      weeklyRevenue,
      monthlyRevenue,
      customerGrowth,
      servicePopularity,
      peakHours,
      completionRate,
      cancellationRate,
      repeatCustomerRate,
      averageServiceTime: 42.0,
    };
  }

  async generateReport(type: string, format: string, startDate?: string, endDate?: string) {
    const filter: any = { deletedAt: null };
    if (startDate || endDate) {
      filter.createdAt = {};
      if (startDate) filter.createdAt.gte = new Date(startDate);
      if (endDate) filter.createdAt.lte = new Date(endDate);
    }

    if (type === 'bookings') {
      const list = await this.prisma.booking.findMany({
        where: filter,
        include: { customer: true, technician: true, serviceItem: true },
      });
      if (format === 'csv') {
        let csv = 'Booking ID,Customer,Technician,Service,Status,Price,Date\n';
        for (const b of list) {
          csv += `"${b.localId || b.id}","${b.customer?.name}","${b.technician?.name || 'N/A'}","${b.serviceItem?.nameEn}","${b.status}",${b.estimatedPrice},"${b.scheduledAt.toISOString()}"\n`;
        }
        return csv;
      }
      return list;
    } else if (type === 'revenue') {
      const list = await this.prisma.invoice.findMany({
        include: { booking: { include: { customer: true } } },
      });
      if (format === 'csv') {
        let csv = 'Invoice ID,Booking ID,Customer,Total,Status,Date\n';
        for (const inv of list) {
          csv += `"${inv.id}","${inv.bookingId}","${inv.booking.customer.name}",${inv.totalAmount},"${inv.status}","${inv.createdAt.toISOString()}"\n`;
        }
        return csv;
      }
      return list;
    } else if (type === 'technicians') {
      const list = await this.prisma.user.findMany({
        where: { role: 'TECHNICIAN', deletedAt: null },
        include: { jobs: true },
      });
      if (format === 'csv') {
        let csv = 'Technician ID,Name,Phone,Email,Branch,Completed Jobs,Online\n';
        for (const t of list) {
          const completed = t.jobs.filter(j => j.status === 'COMPLETED').length;
          csv += `"${t.technicianId}","${t.name}","${t.phoneNumber}","${t.email}","${t.branch}",${completed},${t.isOnline}\n`;
        }
        return csv;
      }
      return list;
    } else {
      return 'No report type found.';
    }
  }

  async getPaymentStats() {
    const list = await this.prisma.invoice.findMany();
    const paid = list.filter(i => i.status === 'PAID');
    const unpaid = list.filter(i => i.status === 'UNPAID');

    const totalPaid = paid.reduce((sum, i) => sum + i.totalAmount, 0);
    const totalUnpaid = unpaid.reduce((sum, i) => sum + i.totalAmount, 0);

    const online = paid.filter(i => i.paymentMethod !== 'COD');
    const cod = paid.filter(i => i.paymentMethod === 'COD');

    const onlineRevenue = online.reduce((sum, i) => sum + i.totalAmount, 0);
    const codRevenue = cod.reduce((sum, i) => sum + i.totalAmount, 0);

    return {
      totalPaid,
      totalUnpaid,
      onlineRevenue,
      codRevenue,
      paidCount: paid.length,
      unpaidCount: unpaid.length,
      refundCount: 0,
      refundAmount: 0.0,
    };
  }

  async getPaymentHistory(page = 1, limit = 10) {
    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.invoice.findMany({
        include: { booking: { include: { customer: true, technician: true } } },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.invoice.count(),
    ]);

    return {
      data: data.map(inv => ({
        id: inv.id,
        bookingId: inv.bookingId,
        localBookingId: inv.booking.localId || inv.bookingId,
        customerName: inv.booking.customer.name,
        technicianName: inv.booking.technician?.name || 'Unassigned',
        amount: inv.amount,
        taxAmount: inv.taxAmount,
        discountAmount: inv.discountAmount,
        totalAmount: inv.totalAmount,
        status: inv.status,
        paymentMethod: inv.paymentMethod || 'COD',
        paymentId: inv.paymentId || 'N/A',
        createdAt: inv.createdAt,
      })),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async createCategory(dto: any) {
    return this.prisma.serviceCategory.create({
      data: {
        id: dto.id,
        nameEn: dto.nameEn,
        nameTa: dto.nameTa,
        icon: dto.icon || 'home_repair_service',
      },
    });
  }

  async updateCategory(id: string, dto: any) {
    return this.prisma.serviceCategory.update({
      where: { id },
      data: {
        nameEn: dto.nameEn,
        nameTa: dto.nameTa,
        icon: dto.icon,
      },
    });
  }

  async deleteCategory(id: string) {
    return this.prisma.serviceCategory.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async createServiceItem(dto: any) {
    return this.prisma.serviceItem.create({
      data: {
        id: dto.id,
        categoryId: dto.categoryId,
        nameEn: dto.nameEn,
        nameTa: dto.nameTa,
        descriptionEn: dto.descriptionEn,
        descriptionTa: dto.descriptionTa,
        basePrice: dto.basePrice,
        durationMinutes: dto.durationMinutes,
      },
    });
  }

  async updateServiceItem(id: string, dto: any) {
    return this.prisma.serviceItem.update({
      where: { id },
      data: {
        categoryId: dto.categoryId,
        nameEn: dto.nameEn,
        nameTa: dto.nameTa,
        descriptionEn: dto.descriptionEn,
        descriptionTa: dto.descriptionTa,
        basePrice: dto.basePrice,
        durationMinutes: dto.durationMinutes,
      },
    });
  }

  async deleteServiceItem(id: string) {
    return this.prisma.serviceItem.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async listCustomers(search?: string, isActiveStr?: string, isVipStr?: string, sortBy = 'createdAt', sortOrder = 'desc', page = 1, limit = 10) {
    const skip = (page - 1) * limit;
    const filters: any = {
      role: 'CUSTOMER',
      deletedAt: null,
    };

    if (isActiveStr) {
      filters.isActive = isActiveStr === 'true';
    }

    if (isVipStr) {
      filters.isFounder = isVipStr === 'true';
    }

    if (search && search.trim().length > 0) {
      filters.OR = [
        { name: { contains: search, mode: 'insensitive' } },
        { email: { contains: search, mode: 'insensitive' } },
        { phoneNumber: { contains: search, mode: 'insensitive' } },
      ];
    }

    const order: any = {};
    order[sortBy] = sortOrder;

    const [data, total] = await Promise.all([
      this.prisma.user.findMany({
        where: filters,
        include: {
          bookings: {
            where: { deletedAt: null },
            include: { invoices: true },
          },
        },
        orderBy: order,
        skip,
        take: limit,
      }),
      this.prisma.user.count({ where: filters }),
    ]);

    return {
      data: data.map(cust => {
        const bookings = cust.bookings;
        const totalSpend = bookings.reduce((sum, b) => {
          const paidInvoices = b.invoices.filter(i => i.status === 'PAID');
          return sum + paidInvoices.reduce((s, i) => s + i.totalAmount, 0);
        }, 0);

        const rating = 4.8;
        const lastBooking = bookings.length > 0 ? bookings[0].createdAt : null;

        return {
          id: cust.id,
          name: cust.name,
          phoneNumber: cust.phoneNumber,
          email: cust.email,
          avatarUrl: cust.avatarUrl,
          isActive: cust.isActive,
          isVip: cust.isFounder,
          createdAt: cust.createdAt,
          totalSpend,
          rating,
          bookingsCount: bookings.length,
          lastBookingDate: lastBooking,
        };
      }),
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  async getCustomerDetails(id: string) {
    const cust = await this.prisma.user.findFirst({
      where: { id, role: 'CUSTOMER', deletedAt: null },
      include: {
        bookings: {
          where: { deletedAt: null },
          include: { serviceItem: true, invoices: true },
          orderBy: { createdAt: 'desc' },
        },
      },
    });

    if (!cust) {
      throw new NotFoundException('Customer not found');
    }

    const bookings = cust.bookings;
    const totalSpend = bookings.reduce((sum, b) => {
      const paidInvoices = b.invoices.filter(i => i.status === 'PAID');
      return sum + paidInvoices.reduce((s, i) => s + i.totalAmount, 0);
    }, 0);

    return {
      id: cust.id,
      name: cust.name,
      phoneNumber: cust.phoneNumber,
      email: cust.email,
      avatarUrl: cust.avatarUrl,
      isActive: cust.isActive,
      isVip: cust.isFounder,
      address: cust.address || 'Chennai, India',
      createdAt: cust.createdAt,
      totalSpend,
      rating: 4.8,
      bookingsCount: bookings.length,
      bookings: bookings.map(b => ({
        id: b.id,
        localId: b.localId,
        serviceName: b.serviceItem?.nameEn || b.serviceId,
        status: b.status,
        price: b.estimatedPrice,
        scheduledAt: b.scheduledAt,
      })),
    };
  }

  async updateCustomer(id: string, dto: any) {
    return this.prisma.user.update({
      where: { id },
      data: {
        name: dto.name,
        email: dto.email,
        phoneNumber: dto.phoneNumber,
        address: dto.address,
        isFounder: dto.isVip,
      },
    });
  }

  async toggleCustomerStatus(id: string, isActive: boolean) {
    return this.prisma.user.update({
      where: { id },
      data: { isActive },
    });
  }

  async softDeleteCustomer(id: string) {
    return this.prisma.user.update({
      where: { id },
      data: { deletedAt: new Date() },
    });
  }

  async listBookingsAdmin(search?: string, status?: string, priority?: string, customerId?: string, technicianId?: string, startDate?: string, endDate?: string, sortBy = 'createdAt', sortOrder = 'desc', page = 1, limit = 10) {
    const skip = (page - 1) * limit;
    const filters: any = { deletedAt: null };

    if (status && status !== 'all' && status !== 'ALL') {
      filters.status = status;
    }
    if (priority && priority !== 'all' && priority !== 'ALL') {
      filters.isEmergency = priority === 'EMERGENCY';
    }
    if (customerId) {
      filters.customerId = customerId;
    }
    if (technicianId) {
      filters.technicianId = technicianId;
    }
    if (startDate || endDate) {
      filters.scheduledAt = {};
      if (startDate) filters.scheduledAt.gte = new Date(startDate);
      if (endDate) filters.scheduledAt.lte = new Date(endDate);
    }
    if (search && search.trim().length > 0) {
      filters.OR = [
        { localId: { contains: search, mode: 'insensitive' } },
        { address: { contains: search, mode: 'insensitive' } },
        { description: { contains: search, mode: 'insensitive' } },
        { customer: { name: { contains: search, mode: 'insensitive' } } },
        { technician: { name: { contains: search, mode: 'insensitive' } } },
      ];
    }

    const order: any = {};
    order[sortBy] = sortOrder;

    const [data, total] = await Promise.all([
      this.prisma.booking.findMany({
        where: filters,
        include: { customer: true, technician: true, serviceItem: true },
        orderBy: order,
        skip,
        take: limit,
      }),
      this.prisma.booking.count({ where: filters }),
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

  async getBookingDetailsAdmin(id: string) {
    const booking = await this.prisma.booking.findUnique({
      where: { id },
      include: {
        customer: true,
        technician: true,
        serviceItem: true,
        timeline: true,
        invoices: true,
      },
    });
    if (!booking) {
      throw new NotFoundException('Booking not found');
    }
    return booking;
  }

  async updateBookingAdmin(id: string, dto: any) {
    return this.prisma.booking.update({
      where: { id },
      data: {
        status: dto.status,
        description: dto.description,
        address: dto.address,
        scheduledAt: dto.scheduledAt ? new Date(dto.scheduledAt) : undefined,
        timeSlot: dto.timeSlot,
        technicianId: dto.technicianId,
        estimatedPrice: dto.estimatedPrice,
      },
    });
  }
}
