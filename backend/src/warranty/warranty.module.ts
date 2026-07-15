import { Module } from '@nestjs/common';
import { WarrantyService } from './warranty.service';
import { WarrantyController } from './warranty.controller';

@Module({
  controllers: [WarrantyController],
  providers: [WarrantyService],
})
export class WarrantyModule {}
