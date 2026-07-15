import { Controller, Get, Query, ParseIntPipe, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { ServicesService } from './services.service';

@ApiTags('Services Catalog')
@Controller('services')
export class ServicesController {
  constructor(private servicesService: ServicesService) {}

  @Get('categories')
  @ApiOperation({ summary: 'List all service categories with pagination' })
  @ApiQuery({ name: 'page', required: false, type: Number })
  @ApiQuery({ name: 'limit', required: false, type: Number })
  @ApiResponse({ status: 200, description: 'Paginated category array returned successfully' })
  async getCategories(
    @Query('page', new ParseIntPipe({ optional: true })) page = 1,
    @Query('limit', new ParseIntPipe({ optional: true })) limit = 10,
  ) {
    return this.servicesService.getCategories(page, limit);
  }

  @Get(':id')
  @ApiOperation({ summary: 'Get details of a specific service item' })
  async getServiceById(@Param('id') id: string) {
    return this.servicesService.getServiceById(id);
  }
}
