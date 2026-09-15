import { IsString, IsOptional, IsEmail } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class CustomerLoginDto {
  @ApiProperty({ example: 'john.doe@example.com', required: false })
  @IsEmail()
  @IsOptional()
  email?: string;

  @ApiProperty({ example: 'P@ssword12345!', required: false })
  @IsString()
  @IsOptional()
  password?: string;

  @ApiProperty({ example: 'legacy-firebase-id-token', required: false })
  @IsString()
  @IsOptional()
  idToken?: string;
}
