import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreatePropertyDto } from './dto/create-property.dto';

@Injectable()
export class PropertyService {
  constructor(private prisma: PrismaService) {}

  async getProperties() {
    return this.prisma.property.findMany({
      where: { deletedAt: null },
    });
  }

  async addProperty(dto: CreatePropertyDto) {
    const property = await this.prisma.property.create({
      data: {
        customerId: dto.customerId,
        name: dto.name,
        address: dto.address,
        installedAppliances: dto.installedAppliances ?? [],
        notes: dto.notes,
      },
    });

    // Write Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId: property.customerId,
        action: 'PROPERTY_ADD',
        details: `Property added: ${property.name} at address: ${property.address}`,
      },
    });

    return property;
  }

  async deleteProperty(id: string) {
    const property = await this.prisma.property.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    // Write Audit Log
    await this.prisma.auditLog.create({
      data: {
        userId: property.customerId,
        action: 'PROPERTY_DELETE',
        details: `Property soft-deleted: ${property.id} (${property.name})`,
      },
    });

    return property;
  }
}
