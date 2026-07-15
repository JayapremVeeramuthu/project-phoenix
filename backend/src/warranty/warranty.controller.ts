import { Controller, Get } from '@nestjs/common';
import { ApiTags, ApiOperation } from '@nestjs/swagger';
import { WarrantyService } from './warranty.service';

@ApiTags('Warranties & AMC Contracts')
@Controller()
export class WarrantyController {
  constructor(private warrantyService: WarrantyService) {}

  @Get('warranties')
  @ApiOperation({ summary: 'List all active manufacturer product warranties' })
  async getWarranties() {
    return this.warrantyService.getWarranties();
  }

  @Get('amc')
  @ApiOperation({ summary: 'List all active Annual Maintenance Contracts (AMC)' })
  async getAmcContracts() {
    return this.warrantyService.getAmcContracts();
  }
}
