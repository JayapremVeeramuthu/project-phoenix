import { IsString, IsNotEmpty } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class FirebaseTokenDto {
  @ApiProperty({ example: 'firebase-id-token-string-xyz' })
  @IsString()
  @IsNotEmpty()
  idToken: string;
}
