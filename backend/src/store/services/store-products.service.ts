import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { ValkeyService } from '../../common/services/valkey.service';

@Injectable()
export class StoreProductsService {
  constructor(
    private prisma: PrismaService,
    private valkey: ValkeyService,
  ) {}

  async getProducts(
    page = 1,
    limit = 12,
    category?: string,
    search?: string,
    sortBy?: 'price_asc' | 'price_desc' | 'rating' | 'popular' | 'newest',
  ) {
    const cacheKey = `store:products:page=${page}:limit=${limit}:cat=${category || 'all'}:q=${search || 'none'}:sort=${sortBy || 'default'}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      try {
        return JSON.parse(cached);
      } catch (_) {}
    }

    const skip = (page - 1) * limit;
    const where: any = { deletedAt: null };

    if (category && category.toLowerCase() !== 'all') {
      where.category = { equals: category, mode: 'insensitive' };
    }

    if (search && search.trim().length > 0) {
      where.OR = [
        { name: { contains: search.trim(), mode: 'insensitive' } },
        { brand: { contains: search.trim(), mode: 'insensitive' } },
        { description: { contains: search.trim(), mode: 'insensitive' } },
        { category: { contains: search.trim(), mode: 'insensitive' } },
      ];
    }

    let orderBy: any = { createdAt: 'desc' };
    if (sortBy === 'price_asc') {
      orderBy = { price: 'asc' };
    } else if (sortBy === 'price_desc') {
      orderBy = { price: 'desc' };
    } else if (sortBy === 'rating') {
      orderBy = { rating: 'desc' };
    } else if (sortBy === 'popular') {
      orderBy = { reviewCount: 'desc' };
    }

    const [data, total] = await Promise.all([
      this.prisma.product.findMany({
        where,
        skip,
        take: limit,
        orderBy,
      }),
      this.prisma.product.count({ where }),
    ]);

    // Categories list for tabs
    const categoriesRaw = await this.prisma.product.groupBy({
      by: ['category'],
      where: { deletedAt: null },
      _count: { id: true },
    });

    const categories = categoriesRaw.map((c) => ({
      name: c.category,
      count: c._count.id,
    }));

    const result = {
      data,
      categories,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };

    await this.valkey.set(cacheKey, JSON.stringify(result), 60); // 1 minute cache
    return result;
  }

  async getProductById(id: string) {
    const cacheKey = `store:product:${id}`;
    const cached = await this.valkey.get(cacheKey);
    if (cached) {
      try {
        return JSON.parse(cached);
      } catch (_) {}
    }

    const product = await this.prisma.product.findFirst({
      where: { id, deletedAt: null },
    });
    if (!product) {
      throw new NotFoundException('Product not found in catalog');
    }

    await this.valkey.set(cacheKey, JSON.stringify(product), 180); // 3 minutes cache
    return product;
  }

  async checkPincodeDelivery(pincode: string, subtotal = 0) {
    const cleanPin = (pincode || '').trim();
    if (!/^\d{6}$/.test(cleanPin)) {
      throw new BadRequestException('Please enter a valid 6-digit PIN code.');
    }

    const now = new Date();
    // Standard: 3 business days
    const standardDate = new Date(now.getTime() + 3 * 24 * 60 * 60 * 1000);
    // Express: 1 business day
    const expressDate = new Date(now.getTime() + 1 * 24 * 60 * 60 * 1000);

    const standardFee = subtotal >= 499 ? 0 : 40;
    const expressFee = 99;

    return {
      pincode: cleanPin,
      isServiceable: true,
      codAvailable: true,
      options: [
        {
          id: 'standard',
          name: 'Standard Delivery',
          price: standardFee,
          isFree: standardFee === 0,
          estimatedDate: standardDate.toISOString(),
          formattedDate: standardDate.toLocaleDateString('en-IN', {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
          }),
          description: standardFee === 0 ? 'FREE on orders above ₹499' : 'Standard ground shipping',
        },
        {
          id: 'express',
          name: 'Express Delivery (Next Day)',
          price: expressFee,
          isFree: false,
          estimatedDate: expressDate.toISOString(),
          formattedDate: expressDate.toLocaleDateString('en-IN', {
            weekday: 'short',
            day: 'numeric',
            month: 'short',
          }),
          description: 'Priority courier with fast-track dispatch',
        },
      ],
    };
  }
}
