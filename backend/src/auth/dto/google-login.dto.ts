import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class GoogleLoginDto {
  @ApiProperty({ example: 'google-oauth2-id-token-xyz' })
  @IsString()
  @IsNotEmpty()
  idToken: string;
}
