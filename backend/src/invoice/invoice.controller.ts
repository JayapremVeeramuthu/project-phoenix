import { Controller, Post, Body } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { InvoiceService } from './invoice.service';
import { CreateOrderDto } from './dto/create-order.dto';

@ApiTags('Payments & Invoices')
@Controller('payments')
export class InvoiceController {
  constructor(private invoiceService: InvoiceService) {}

  @Post('create-order')
  @ApiOperation({ summary: 'Create a Razorpay payment order token' })
  @ApiResponse({ status: 201, description: 'Order token generated successfully' })
  async createOrder(@Body() dto: CreateOrderDto) {
    return this.invoiceService.createRazorpayOrder(dto);
  }

  @Post('verify')
  @ApiOperation({ summary: 'Verify signature of completed Razorpay payment' })
  async verifyPayment(@Body() payload: any) {
    return this.invoiceService.verifyPaymentSignature(payload);
  }
}
