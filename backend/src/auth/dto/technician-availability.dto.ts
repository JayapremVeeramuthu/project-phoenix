import { IsBoolean, IsNotEmpty, IsString } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class TechnicianAvailabilityDto {
  @ApiProperty({ example: 'tech-uuid-123' })
  @IsString()
  @IsNotEmpty()
  userId: string;

  @ApiProperty({ example: true })
  @IsBoolean()
  @IsNotEmpty()
  isOnline: boolean;
}
