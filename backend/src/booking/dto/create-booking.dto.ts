import { IsString, IsNotEmpty, IsOptional, IsBoolean, IsNumber, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateBookingDto {
  @ApiProperty({ example: 'local-uuid-key-here', required: false })
  @IsString()
  @IsOptional()
  localId?: string;

  @ApiProperty({ example: 'customer-uuid-here', required: false })
  @IsString()
  @IsOptional()
  customerId?: string;

  @ApiProperty({ example: 'property-uuid-here', required: false })
  @IsString()
  @IsOptional()
  propertyId?: string;

  @ApiProperty({ example: 'elec-wiring' })
  @IsString()
  @IsNotEmpty()
  serviceId: string;

  @ApiProperty({ example: 'Flat 405, Chennai' })
  @IsString()
  @IsNotEmpty()
  address: string;

  @ApiProperty({ example: '2026-07-12T10:00:00Z' })
  @IsString()
  @IsNotEmpty()
  scheduledAt: string;

  @ApiProperty({ example: '10:00 AM' })
  @IsString()
  @IsNotEmpty()
  timeSlot: string;

  @ApiProperty({ example: false, required: false })
  @IsBoolean()
  @IsOptional()
  isEmergency?: boolean;

  @ApiProperty({ example: 'AC compressor makes a heavy rattling sound.' })
  @IsString()
  @IsNotEmpty()
  description: string;

  @ApiProperty({ type: [String], example: ['http://minio/bucket/file.jpg'] })
  @IsArray()
  @IsString({ each: true })
  @IsOptional()
  imageUrls?: string[];

  @ApiProperty({ example: 'http://minio/bucket/audio.m4a', required: false })
  @IsString()
  @IsOptional()
  voiceNoteUrl?: string;

  @ApiProperty({ example: 'Compressor noise rattle', required: false })
  @IsString()
  @IsOptional()
  voiceTranscript?: string;

  @ApiProperty({ example: 499.00 })
  @IsNumber()
  @IsNotEmpty()
  estimatedPrice: number;

  @ApiProperty({ example: 12.9716, required: false })
  @IsNumber()
  @IsOptional()
  latitude?: number;

  @ApiProperty({ example: 80.2462, required: false })
  @IsNumber()
  @IsOptional()
  longitude?: number;
}
