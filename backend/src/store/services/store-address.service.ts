import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../../prisma/prisma.service';
import { CreateCustomerAddressDto, UpdateCustomerAddressDto, AddressTypeDto } from '../dto/store-dtos';
import { AddressType } from '@prisma/client';

@Injectable()
export class StoreAddressService {
  constructor(private prisma: PrismaService) {}

  private async resolveCustomerId(customerId: string): Promise<string> {
    const isUuid = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(customerId);
    if (!isUuid) {
      throw new BadRequestException('Customer not found');
    }
    const user = await this.prisma.user.findUnique({
      where: { id: customerId },
    });
    if (!user) {
      throw new BadRequestException('Customer not found');
    }
    return user.id;
  }

  async getAddresses(customerId: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    return this.prisma.customerAddress.findMany({
      where: {
        customerId: resolvedId,
        deletedAt: null,
      },
      orderBy: [{ isDefault: 'desc' }, { createdAt: 'desc' }],
    });
  }

  async getAddressById(id: string, customerId: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const address = await this.prisma.customerAddress.findFirst({
      where: { id, customerId: resolvedId, deletedAt: null },
    });
    if (!address) {
      throw new NotFoundException('Delivery address not found');
    }
    return address;
  }

  async createAddress(dto: CreateCustomerAddressDto) {
    const resolvedId = await this.resolveCustomerId(dto.customerId);

    // If first address, mark as default automatically
    const count = await this.prisma.customerAddress.count({
      where: { customerId: resolvedId, deletedAt: null },
    });
    const isDefault = dto.isDefault || count === 0;

    if (isDefault) {
      await this.prisma.customerAddress.updateMany({
        where: { customerId: resolvedId },
        data: { isDefault: false },
      });
    }

    return this.prisma.customerAddress.create({
      data: {
        customerId: resolvedId,
        fullName: dto.fullName,
        phoneNumber: dto.phoneNumber,
        buildingNo: dto.buildingNo,
        street: dto.street,
        area: dto.area,
        city: dto.city,
        state: dto.state,
        pincode: dto.pincode,
        landmark: dto.landmark,
        addressType: (dto.addressType as AddressType) || AddressType.HOME,
        isDefault,
      },
    });
  }

  async updateAddress(id: string, customerId: string, dto: UpdateCustomerAddressDto) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const existing = await this.prisma.customerAddress.findFirst({
      where: { id, customerId: resolvedId, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException('Delivery address not found');
    }

    if (dto.isDefault) {
      await this.prisma.customerAddress.updateMany({
        where: { customerId: resolvedId },
        data: { isDefault: false },
      });
    }

    return this.prisma.customerAddress.update({
      where: { id },
      data: {
        ...dto,
        addressType: dto.addressType ? (dto.addressType as AddressType) : undefined,
      },
    });
  }

  async deleteAddress(id: string, customerId: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const existing = await this.prisma.customerAddress.findFirst({
      where: { id, customerId: resolvedId, deletedAt: null },
    });
    if (!existing) {
      throw new NotFoundException('Delivery address not found');
    }

    await this.prisma.customerAddress.update({
      where: { id },
      data: { deletedAt: new Date() },
    });

    // If deleted address was default, set another address as default
    if (existing.isDefault) {
      const another = await this.prisma.customerAddress.findFirst({
        where: { customerId: resolvedId, deletedAt: null },
        orderBy: { createdAt: 'desc' },
      });
      if (another) {
        await this.prisma.customerAddress.update({
          where: { id: another.id },
          data: { isDefault: true },
        });
      }
    }

    return { message: 'Address deleted successfully' };
  }

  async setDefaultAddress(id: string, customerId: string) {
    const resolvedId = await this.resolveCustomerId(customerId);
    const address = await this.prisma.customerAddress.findFirst({
      where: { id, customerId: resolvedId, deletedAt: null },
    });
    if (!address) {
      throw new NotFoundException('Delivery address not found');
    }

    await this.prisma.customerAddress.updateMany({
      where: { customerId: resolvedId },
      data: { isDefault: false },
    });

    return this.prisma.customerAddress.update({
      where: { id },
      data: { isDefault: true },
    });
  }
}
