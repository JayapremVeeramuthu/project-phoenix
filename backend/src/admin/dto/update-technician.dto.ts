import { IsString, IsOptional, IsEmail, IsArray } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateTechnicianDto {
  @ApiProperty({ example: 'Rajesh Kumar', required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: '+919999999999', required: false })
  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @ApiProperty({ example: 'tech.rajesh@phoenix.in', required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: 'Chennai OMR', required: false })
  @IsString()
  @IsOptional()
  branch?: string;

  @ApiProperty({ example: ['AC Service', 'Electrical'], required: false })
  @IsArray()
  @IsOptional()
  skills?: string[];

  @ApiProperty({ example: ['Adyar', 'Velachery'], required: false })
  @IsArray()
  @IsOptional()
  serviceAreas?: string[];

  @ApiProperty({ example: '5 Years', required: false })
  @IsString()
  @IsOptional()
  experience?: string;
}
