import { Module } from '@nestjs/common';
import { BookingService } from './booking.service';
import { BookingController } from './booking.controller';
import { BookingGateway } from './booking.gateway';

@Module({
  controllers: [BookingController],
  providers: [BookingService, BookingGateway],
  exports: [BookingGateway],
})
export class BookingModule {}
