import { Injectable, Logger, HttpException, HttpStatus } from '@nestjs/common';
import axios from 'axios';

export interface ReverseGeocodeResult {
  latitude: number;
  longitude: number;
  building: string;
  street: string;
  area: string;
  city: string;
  state: string;
  pincode: string;
  country: string;
  displayName: string;
  formattedAddress: string;
}

@Injectable()
export class GeoService {
  private readonly logger = new Logger(GeoService.name);

  async reverseGeocode(lat: number, lng: number): Promise<ReverseGeocodeResult> {
    if (isNaN(lat) || isNaN(lng)) {
      throw new HttpException('Invalid coordinates provided.', HttpStatus.BAD_REQUEST);
    }

    try {
      const url = `https://nominatim.openstreetmap.org/reverse?lat=${lat}&lon=${lng}&format=json&addressdetails=1`;
      this.logger.log(`Fetching reverse geocode for lat=${lat}, lng=${lng}`);

      const response = await axios.get(url, {
        headers: {
          'User-Agent': 'ProjectPhoenixApp/1.0 (contact: admin@projectphoenix.com)',
          'Accept': 'application/json',
        },
        timeout: 8000,
      });

      const data = response.data;
      if (!data || data.error) {
        throw new HttpException(data?.error || 'Address not found for coordinates.', HttpStatus.NOT_FOUND);
      }

      const addr = data.address || {};

      const building = addr.house_number || addr.building || addr.commercial || addr.office || '';
      const street = addr.road || addr.pedestrian || addr.street || addr.residential || addr.footway || '';
      const area = addr.neighbourhood || addr.suburb || addr.quarter || addr.village || addr.city_district || '';
      const city = addr.city || addr.town || addr.municipality || addr.county || addr.state_district || '';
      const state = addr.state || addr.province || '';
      const pincode = addr.postcode || '';
      const country = addr.country || 'India';
      const displayName = data.display_name || '';

      const parts = [
        building,
        street,
        area,
        city,
        state ? (pincode ? `${state} - ${pincode}` : state) : pincode,
      ].filter((p) => Boolean(p && p.trim().length > 0));

      const formattedAddress = parts.length > 0 ? parts.join(', ') : displayName;

      return {
        latitude: lat,
        longitude: lng,
        building,
        street,
        area,
        city,
        state,
        pincode,
        country,
        displayName,
        formattedAddress,
      };
    } catch (error: any) {
      this.logger.error(`Failed to reverse geocode lat=${lat}, lng=${lng}: ${error.message}`);
      if (error instanceof HttpException) {
        throw error;
      }
      throw new HttpException(
        `Reverse geocoding failed: ${error.message}`,
        HttpStatus.INTERNAL_SERVER_ERROR,
      );
    }
  }
}
