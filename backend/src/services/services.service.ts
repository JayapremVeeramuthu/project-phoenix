import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ValkeyService } from '../common/services/valkey.service';

@Injectable()
export class ServicesService {
  constructor(
    private prisma: PrismaService,
    private valkey: ValkeyService,
  ) {}

  async getCategories(page = 1, limit = 10) {
    const cacheKey = `services:categories:page=${page}:limit=${limit}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const skip = (page - 1) * limit;
    const [data, total] = await Promise.all([
      this.prisma.serviceCategory.findMany({
        where: { deletedAt: null },
        include: { items: true },
        skip,
        take: limit,
      }),
      this.prisma.serviceCategory.count({
        where: { deletedAt: null },
      }),
    ]);

    const result = {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };

    await this.valkey.set(cacheKey, JSON.stringify(result), 300); // cache for 5m
    return result;
  }

  async getServiceById(id: string) {
    const cacheKey = `services:item:${id}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const service = await this.prisma.serviceItem.findUnique({
      where: { id },
      include: { category: true },
    });
    if (!service) {
      throw new NotFoundException('Service not found');
    }

    await this.valkey.set(cacheKey, JSON.stringify(service), 600); // cache for 10m
    return service;
  }
}
