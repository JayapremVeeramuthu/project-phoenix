import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_api/shared_api.dart';

class LocationPermissionResult {
  final bool granted;
  final bool permanentlyDenied;
  final String? message;

  LocationPermissionResult({
    required this.granted,
    this.permanentlyDenied = false,
    this.message,
  });
}

class LocationService {
  final ApiClient? _apiClient;
  final Dio _fallbackDio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 8),
  ));

  LocationService({ApiClient? apiClient}) : _apiClient = apiClient;

  /// Check and request location permission from the device/browser
  Future<LocationPermissionResult> requestPermission() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return LocationPermissionResult(
          granted: false,
          permanentlyDenied: false,
          message: 'Location services (GPS) are turned off. Please enable GPS on your device.',
        );
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return LocationPermissionResult(
            granted: false,
            permanentlyDenied: false,
            message: 'Location permissions were denied. Please grant location access to auto-fill your address.',
          );
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return LocationPermissionResult(
          granted: false,
          permanentlyDenied: true,
          message: 'Location permissions are permanently denied. Please enable them in your device or browser settings.',
        );
      }

      return LocationPermissionResult(granted: true);
    } catch (e) {
      debugPrint('Error requesting location permission: $e');
      return LocationPermissionResult(
        granted: false,
        message: 'Failed to request location permission: $e',
      );
    }
  }

  /// Obtains the real current GPS location from hardware
  Future<Map<String, dynamic>> getCurrentLocation({int attempt = 1}) async {
    final permissionResult = await requestPermission();
    if (!permissionResult.granted) {
      throw Exception(permissionResult.message ?? 'Location permission not granted.');
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );

      return {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy': position.accuracy,
        'attempts': attempt,
      };
    } catch (e) {
      debugPrint('Error getting GPS location: $e');
      // On fallback attempt if high accuracy timed out, try medium accuracy
      if (attempt < 2) {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 10),
        );
        return {
          'latitude': position.latitude,
          'longitude': position.longitude,
          'accuracy': position.accuracy,
          'attempts': attempt + 1,
        };
      }
      rethrow;
    }
  }

  /// Reverse geocodes the real GPS coordinates to a physical address
  Future<Map<String, String>> reverseGeocode(double latitude, double longitude) async {
    // 1. Try resolving via Project Phoenix Backend Reverse Geocode API
    final client = _apiClient;
    if (client != null) {
      try {
        final response = await client.get(
          '/geo/reverse-geocode',
          queryParameters: {
            'lat': latitude,
            'lng': longitude,
          },
        );

        if (response.statusCode == 200 && response.data != null) {
          final data = response.data as Map<String, dynamic>;
          return {
            'houseNumber': (data['building'] as String? ?? '').trim(),
            'street': (data['street'] as String? ?? '').trim(),
            'area': (data['area'] as String? ?? '').trim(),
            'city': (data['city'] as String? ?? '').trim(),
            'state': (data['state'] as String? ?? '').trim(),
            'pincode': (data['pincode'] as String? ?? '').trim(),
            'country': (data['country'] as String? ?? 'India').trim(),
            'formattedAddress': (data['formattedAddress'] as String? ?? '').trim(),
          };
        }
      } catch (e) {
        debugPrint('Backend reverse geocode failed, falling back to direct OSM: $e');
      }
    }

    // 2. Direct fallback to OpenStreetMap Nominatim
    try {
      final url = 'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&addressdetails=1';
      final response = await _fallbackDio.get(
        url,
        options: Options(
          headers: {
            'User-Agent': 'ProjectPhoenixCustomerApp/1.0',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        final addr = data['address'] as Map<String, dynamic>? ?? {};

        final houseNumber = (addr['house_number'] ?? addr['building'] ?? addr['commercial'] ?? '').toString();
        final street = (addr['road'] ?? addr['pedestrian'] ?? addr['street'] ?? addr['residential'] ?? '').toString();
        final area = (addr['neighbourhood'] ?? addr['suburb'] ?? addr['quarter'] ?? addr['village'] ?? '').toString();
        final city = (addr['city'] ?? addr['town'] ?? addr['municipality'] ?? addr['city_district'] ?? '').toString();
        final state = (addr['state'] ?? addr['province'] ?? '').toString();
        final pincode = (addr['postcode'] ?? '').toString();
        final country = (addr['country'] ?? 'India').toString();
        final displayName = (data['display_name'] ?? '').toString();

        final parts = [
          houseNumber,
          street,
          area,
          city,
          state.isNotEmpty ? (pincode.isNotEmpty ? '$state - $pincode' : state) : pincode,
        ].where((p) => p.trim().isNotEmpty).toList();

        final formattedAddress = parts.isNotEmpty ? parts.join(', ') : displayName;

        return {
          'houseNumber': houseNumber.trim(),
          'street': street.trim(),
          'area': area.trim(),
          'city': city.trim(),
          'state': state.trim(),
          'pincode': pincode.trim(),
          'country': country.trim(),
          'formattedAddress': formattedAddress.trim(),
        };
      }
    } catch (e) {
      debugPrint('Direct OSM reverse geocode failed: $e');
    }

    // Default if both fail
    return {
      'houseNumber': '',
      'street': '',
      'area': '',
      'city': '',
      'state': '',
      'pincode': '',
      'country': 'India',
      'formattedAddress': 'Lat: ${latitude.toStringAsFixed(4)}, Lng: ${longitude.toStringAsFixed(4)}',
    };
  }
}

final locationServiceProvider = Provider<LocationService>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return LocationService(apiClient: apiClient);
});
