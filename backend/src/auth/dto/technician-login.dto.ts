import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class TechnicianLoginDto {
  @ApiProperty({ example: 'TECH000123' })
  @IsString()
  @IsNotEmpty()
  technicianId: string;

  @ApiProperty({ example: 'Password' })
  @IsString()
  @IsNotEmpty()
  password: string;
}
