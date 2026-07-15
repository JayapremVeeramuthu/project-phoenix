import { IsString, IsNotEmpty, IsOptional } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiProperty({ example: 'b87fa109-178c-42b7-8977-628d08cb5f09' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ example: 'Prem Kumar', required: false })
  @IsString()
  @IsOptional()
  name?: string;

  @ApiProperty({ example: 'prem@gmail.com', required: false })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: '+919003028001', required: false })
  @IsString()
  @IsOptional()
  phoneNumber?: string;

  @ApiProperty({ example: 'Male', required: false })
  @IsString()
  @IsOptional()
  gender?: string;

  @ApiProperty({ example: '1995-08-15', required: false })
  @IsString()
  @IsOptional()
  dateOfBirth?: string;

  @ApiProperty({ example: 'Flat 405, Phoenix Tower B', required: false })
  @IsString()
  @IsOptional()
  address?: string;

  @ApiProperty({ example: 'Chennai', required: false })
  @IsString()
  @IsOptional()
  city?: string;

  @ApiProperty({ example: 'Tamil Nadu', required: false })
  @IsString()
  @IsOptional()
  state?: string;

  @ApiProperty({ example: '600096', required: false })
  @IsString()
  @IsOptional()
  pincode?: string;

  @ApiProperty({ example: 'http://localhost:3000/media/1234_avatar.png', required: false })
  @IsString()
  @IsOptional()
  avatarUrl?: string;
}
