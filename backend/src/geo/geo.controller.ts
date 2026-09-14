import { Controller, Get, Query, ParseFloatPipe, BadRequestException } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiQuery, ApiResponse } from '@nestjs/swagger';
import { GeoService, ReverseGeocodeResult } from './geo.service';

@ApiTags('Geolocation')
@Controller('geo')
export class GeoController {
  constructor(private readonly geoService: GeoService) {}

  @Get('reverse-geocode')
  @ApiOperation({ summary: 'Reverse geocode GPS coordinates to real street address' })
  @ApiQuery({ name: 'lat', required: true, type: Number, description: 'Latitude coordinate' })
  @ApiQuery({ name: 'lng', required: true, type: Number, description: 'Longitude coordinate' })
  @ApiResponse({ status: 200, description: 'Address successfully resolved' })
  async reverseGeocode(
    @Query('lat') latStr: string,
    @Query('lng') lngStr: string,
  ): Promise<ReverseGeocodeResult> {
    const lat = parseFloat(latStr);
    const lng = parseFloat(lngStr);

    if (isNaN(lat) || isNaN(lng)) {
      throw new BadRequestException('Query parameters "lat" and "lng" must be valid numbers.');
    }

    return this.geoService.reverseGeocode(lat, lng);
  }
}
