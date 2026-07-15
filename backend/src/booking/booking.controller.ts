import { Controller, Post, Get, Body, Query, ParseIntPipe, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';

@ApiTags('Bookings')
@Controller('bookings')
export class BookingController {
  constructor(private bookingService: BookingService) {}

  @Post()
  @ApiOperation({ summary: 'Create a new service booking' })
  @ApiResponse({ status: 201, description: 'Booking successfully created' })
  async createBooking(@Body() dto: CreateBookingDto) {
    return this.bookingService.createBooking(dto);
  }

  @Get()
  @ApiOperation({ summary: 'List all bookings with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  async getBookings(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 10,
  ) {
    return this.bookingService.getBookings(page, limit);
  }

  @Get(':id/tracking')
  @ApiOperation({ summary: 'Get live tracking timeline updates for a booking' })
  async getBookingTimeline(@Param('id') id: string) {
    return this.bookingService.getBookingTimeline(id);
  }
}
