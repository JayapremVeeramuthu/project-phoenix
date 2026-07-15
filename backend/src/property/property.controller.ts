import { Controller, Get, Post, Delete, Body, Param } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse } from '@nestjs/swagger';
import { PropertyService } from './property.service';
import { CreatePropertyDto } from './dto/create-property.dto';

@ApiTags('Properties')
@Controller('properties')
export class PropertyController {
  constructor(private propertyService: PropertyService) {}

  @Get()
  @ApiOperation({ summary: 'List all properties saved by customers' })
  async getProperties() {
    return this.propertyService.getProperties();
  }

  @Post()
  @ApiOperation({ summary: 'Add a new property premises entry' })
  async addProperty(@Body() dto: CreatePropertyDto) {
    return this.propertyService.addProperty(dto);
  }

  @Delete(':id')
  @ApiOperation({ summary: 'Soft delete a property entry' })
  async deleteProperty(@Param('id') id: string) {
    return this.propertyService.deleteProperty(id);
  }
}
