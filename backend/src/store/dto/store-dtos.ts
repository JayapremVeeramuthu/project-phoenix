import { IsString, IsNotEmpty, IsOptional, IsEnum, IsBoolean, IsNumber, IsArray, ValidateNested, Min } from 'class-validator';
import { Type } from 'class-transformer';
import { ApiProperty } from '@nestjs/swagger';

export enum AddressTypeDto {
  HOME = 'HOME',
  WORK = 'WORK',
  OTHER = 'OTHER',
}

export class CreateCustomerAddressDto {
  @ApiProperty({ example: 'b87fa109-178c-42b7-8977-628d08cb5f09' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiProperty({ example: 'Prem Kumar' })
  @IsString()
  @IsNotEmpty()
  fullName: string;

  @ApiProperty({ example: '+919003028001' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @ApiProperty({ example: 'Flat 405, Block B' })
  @IsString()
  @IsNotEmpty()
  buildingNo: string;

  @ApiProperty({ example: 'Phoenix Towers, OMR Express Highway' })
  @IsString()
  @IsNotEmpty()
  street: string;

  @ApiProperty({ example: 'Thoraipakkam' })
  @IsString()
  @IsNotEmpty()
  area: string;

  @ApiProperty({ example: 'Chennai' })
  @IsString()
  @IsNotEmpty()
  city: string;

  @ApiProperty({ example: 'Tamil Nadu' })
  @IsString()
  @IsNotEmpty()
  state: string;

  @ApiProperty({ example: '600096' })
  @IsString()
  @IsNotEmpty()
  pincode: string;

  @ApiProperty({ example: 'Near Cognizant Junction', required: false })
  @IsString()
  @IsOptional()
  landmark?: string;

  @ApiProperty({ enum: AddressTypeDto, default: AddressTypeDto.HOME })
  @IsEnum(AddressTypeDto)
  @IsOptional()
  addressType?: AddressTypeDto;

  @ApiProperty({ example: true, required: false })
  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class UpdateCustomerAddressDto {
  @IsString()
  @IsOptional()
  fullName?: string;

  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @IsString()
  @IsOptional()
  buildingNo?: string;

  @IsString()
  @IsOptional()
  street?: string;

  @IsString()
  @IsOptional()
  area?: string;

  @IsString()
  @IsOptional()
  city?: string;

  @IsString()
  @IsOptional()
  state?: string;

  @IsString()
  @IsOptional()
  pincode?: string;

  @IsString()
  @IsOptional()
  landmark?: string;

  @IsEnum(AddressTypeDto)
  @IsOptional()
  addressType?: AddressTypeDto;

  @IsBoolean()
  @IsOptional()
  isDefault?: boolean;
}

export class ValidateCouponDto {
  @ApiProperty({ example: 'PHOENIX100' })
  @IsString()
  @IsNotEmpty()
  code: string;

  @ApiProperty({ example: 1499.0 })
  @IsNumber()
  @Min(0)
  subtotal: number;
}

export class OrderItemInputDto {
  @ApiProperty({ example: 'b87fa109-178c-42b7-8977-628d08cb5f01' })
  @IsString()
  @IsNotEmpty()
  productId: string;

  @ApiProperty({ example: 2 })
  @IsNumber()
  @Min(1)
  quantity: number;

  @ApiProperty({ example: '6-Gang (White)', required: false })
  @IsString()
  @IsOptional()
  selectedVariant?: string;
}

export enum PaymentMethodDto {
  UPI = 'UPI',
  CREDIT_CARD = 'CREDIT_CARD',
  DEBIT_CARD = 'DEBIT_CARD',
  NET_BANKING = 'NET_BANKING',
  WALLET = 'WALLET',
  CASH_ON_DELIVERY = 'CASH_ON_DELIVERY',
}

export class CreateOrderDto {
  @ApiProperty({ example: 'b87fa109-178c-42b7-8977-628d08cb5f09' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiProperty({ type: [OrderItemInputDto] })
  @IsArray()
  @ValidateNested({ each: true })
  @Type(() => OrderItemInputDto)
  items: OrderItemInputDto[];

  @ApiProperty({ example: 'b87fa109-178c-42b7-8977-628d08cb5f99' })
  @IsString()
  @IsNotEmpty()
  addressId: string;

  @ApiProperty({ example: 'standard', enum: ['standard', 'express'] })
  @IsString()
  @IsNotEmpty()
  deliveryOption: string; // standard or express

  @ApiProperty({ enum: PaymentMethodDto })
  @IsEnum(PaymentMethodDto)
  paymentMethod: PaymentMethodDto;

  @ApiProperty({ example: 'PHOENIX100', required: false })
  @IsString()
  @IsOptional()
  couponCode?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  paymentDetails?: any;
}

export class VerifyPaymentDto {
  @ApiProperty({ example: 'pay_xyz_123' })
  @IsString()
  @IsNotEmpty()
  paymentId: string;

  @ApiProperty({ example: 'sig_mock_456', required: false })
  @IsString()
  @IsOptional()
  signature?: string;

  @ApiProperty({ example: 'SUCCESS', required: false })
  @IsString()
  @IsOptional()
  status?: string;
}

export class ReturnRequestDto {
  @ApiProperty({ example: 'RETURN', enum: ['RETURN', 'REPLACEMENT'] })
  @IsString()
  @IsNotEmpty()
  type: string;

  @ApiProperty({ example: 'Defective product' })
  @IsString()
  @IsNotEmpty()
  reason: string;

  @ApiProperty({ example: 'Button gets stuck intermittently', required: false })
  @IsString()
  @IsOptional()
  comments?: string;
}
