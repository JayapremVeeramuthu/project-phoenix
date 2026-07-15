import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class LoginDto {
  @ApiProperty({ example: '+919988776655' })
  @IsString()
  @IsNotEmpty()
  phoneNumber: string;
}
