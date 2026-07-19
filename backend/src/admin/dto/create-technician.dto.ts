import { IsString, IsNotEmpty, IsEmail, IsArray, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CreateTechnicianDto {
  @ApiProperty({ example: 'Rajesh Kumar' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'PX@123456' })
  @IsString()
  @IsNotEmpty()
  password: string;

  @ApiProperty({ example: '+919999999999' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @ApiProperty({ example: 'tech.rajesh@phoenix.in' })
  @IsEmail()
  @IsNotEmpty()
  email: string;

  @ApiProperty({ example: 'Chennai OMR' })
  @IsString()
  @IsNotEmpty()
  branch: string;

  @ApiProperty({ example: ['AC Service', 'Electrical'] })
  @IsArray()
  @IsOptional()
  skills?: string[];

  @ApiProperty({ example: ['Adyar', 'Velachery'] })
  @IsArray()
  @IsOptional()
  serviceAreas?: string[];

  @ApiProperty({ example: '5 Years' })
  @IsString()
  @IsOptional()
  experience?: string;
}
