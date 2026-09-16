import { Controller, Post, Get, Patch, Body, Query, ParseIntPipe, Param, HttpCode, HttpStatus, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { BookingService } from './booking.service';
import { CreateBookingDto } from './dto/create-booking.dto';
import { JwtAuthGuard, OptionalJwtAuthGuard } from '../common/guards/jwt-auth.guard';

@ApiTags('Bookings')
@Controller('bookings')
export class BookingController {
  constructor(private bookingService: BookingService) {}

  @Post()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'Create a new service booking' })
  @ApiResponse({ status: 201, description: 'Booking successfully created' })
  async createBooking(@Body() dto: CreateBookingDto, @Req() req: any) {
    const customerId = req.user?.id || req.user?.sub;
    return this.bookingService.createBooking(dto, customerId);
  }

  @Get()
  @UseGuards(JwtAuthGuard)
  @ApiOperation({ summary: 'List all bookings with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiQuery({ name: 'customerId', required: false, type: String })
  async getBookings(
    @Req() req: any,
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 10,
    @Query('customerId') customerId?: string,
  ) {
    const effectiveCustomerId = req.user?.role === 'CUSTOMER' ? (req.user.id || req.user.sub) : customerId;
    return this.bookingService.getBookings(page, limit, effectiveCustomerId);
  }

  @Get(':id/tracking')
  @ApiOperation({ summary: 'Get live tracking timeline updates for a booking' })
  async getBookingTimeline(@Param('id') id: string) {
    return this.bookingService.getBookingTimeline(id);
  }

  @Get('available')
  @ApiOperation({ summary: 'Get available bookings eligible for a technician' })
  async getAvailableBookings(@Query('technicianId') technicianId: string) {
    return this.bookingService.getAvailableBookings(technicianId);
  }

  @Get('technician/:id')
  @ApiOperation({ summary: "Get bookings assigned to a technician" })
  async getTechnicianJobs(@Param('id') id: string) {
    return this.bookingService.getTechnicianJobs(id);
  }

  @Post(':id/accept')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Accept a pending booking' })
  @ApiResponse({ status: 200, description: 'Booking accepted successfully' })
  async acceptBooking(
    @Param('id') id: string,
    @Body('technicianId') technicianId: string,
  ) {
    return this.bookingService.acceptBooking(id, technicianId);
  }

  @Post(':id/reject')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Reject a pending booking' })
  @ApiResponse({ status: 200, description: 'Booking rejected successfully' })
  async rejectBooking(
    @Param('id') id: string,
    @Body('technicianId') technicianId: string,
  ) {
    return this.bookingService.rejectBooking(id, technicianId);
  }

  @Patch(':id/status')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ summary: 'Update status of a booking' })
  @ApiResponse({ status: 200, description: 'Booking status updated successfully' })
  async updateStatus(
    @Param('id') id: string,
    @Body('status') status: string,
    @Body('notes') notes?: string,
  ) {
    return this.bookingService.updateStatus(id, status, notes);
  }
}
