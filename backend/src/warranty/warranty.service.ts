import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class WarrantyService {
  constructor(private prisma: PrismaService) {}

  async getWarranties() {
    return this.prisma.warranty.findMany({
      orderBy: { expiryDate: 'asc' },
    });
  }

  async getAmcContracts() {
    return this.prisma.amcContract.findMany({
      orderBy: { nextServiceDate: 'asc' },
    });
  }
}
