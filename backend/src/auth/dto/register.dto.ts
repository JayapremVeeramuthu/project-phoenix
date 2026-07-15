import { IsString, IsNotEmpty, IsOptional, IsEnum } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';
import { Role } from '@prisma/client';

export class RegisterDto {
  @ApiProperty({ example: '+919988776655' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;

  @ApiProperty({ example: 'John Doe' })
  @IsString()
  @IsNotEmpty()
  name: string;

  @ApiProperty({ example: 'john.doe@example.com', required: false })
  @IsString()
  @IsOptional()
  email?: string;

  @ApiProperty({ enum: Role, default: Role.CUSTOMER })
  @IsEnum(Role)
  @IsOptional()
  role?: Role;
}
