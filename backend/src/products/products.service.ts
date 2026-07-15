import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { ValkeyService } from '../common/services/valkey.service';

@Injectable()
export class ProductsService {
  constructor(
    private prisma: PrismaService,
    private valkey: ValkeyService,
  ) {}

  async getProducts(page = 1, limit = 10, category?: string) {
    const cacheKey = `products:list:page=${page}:limit=${limit}:cat=${category || 'all'}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const skip = (page - 1) * limit;
    const where: any = {};
    if (category) {
      where.category = { equals: category, mode: 'insensitive' };
    }
    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take: limit,
      }),
      this.prisma.product.count({ where }),
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

    await this.valkey.set(cacheKey, JSON.stringify(result), 60); // cache for 60s
    return result;
  }

  async getProductById(id: string) {
    const cacheKey = `products:item:${id}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    const product = await this.prisma.product.findUnique({
      where: { id },
    });
    if (!product) {
      throw new NotFoundException('Product not found');
    }

    await this.valkey.set(cacheKey, JSON.stringify(product), 300); // cache for 5m
    return product;
  }
}
