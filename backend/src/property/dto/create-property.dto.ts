import { IsString, IsNotEmpty, IsOptional, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreatePropertyDto {
  @ApiProperty({ example: 'customer-uuid-here' })
  @IsString()
  @IsNotEmpty()
  customerId: string;

  @ApiProperty({ example: 'Home Flat' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'OMR Road, Chennai' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ type: [String], example: ['Daikin AC', 'Havells Geyser'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  installedAppliances?: string[];

  @ApiProperty({ example: 'Security code 1234', required: false })
  @IsString()
  @IsOptional()
  notes?: string;
}
