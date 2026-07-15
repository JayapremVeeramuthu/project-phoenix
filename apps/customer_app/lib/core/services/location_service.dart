import 'dart:async';
import 'dart:math';

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
  bool _permissionGranted = false;
  bool _permissionPermanentlyDenied = false;
  bool _gpsEnabled = true;

  Future<LocationPermissionResult> requestPermission() async {
    if (_permissionPermanentlyDenied) {
      return LocationPermissionResult(
        granted: false,
        permanentlyDenied: true,
        message: 'Location permission permanently denied. Enable it in app settings.',
      );
    }
    _permissionGranted = true;
    return LocationPermissionResult(granted: true);
  }

  Future<void> toggleGps(bool enabled) async {
    _gpsEnabled = enabled;
  }

  Future<void> setPermanentlyDenied(bool denied) async {
    _permissionPermanentlyDenied = denied;
    if (denied) _permissionGranted = false;
  }

  Future<Map<String, dynamic>> getCurrentLocation({int attempt = 1}) async {
    if (!_permissionGranted) {
      throw Exception('Location permission not granted');
    }
    if (!_gpsEnabled) {
      throw Exception('GPS is disabled on this device');
    }

    // Simulate real high-accuracy GPS receiver hardware polling
    await Future.delayed(Duration(milliseconds: 400 * attempt));
    
    // Simulate high-accuracy GPS with occasional jitter
    final random = Random();
    final accuracy = 5.0 + random.nextDouble() * 30.0; // accuracy in meters

    if (accuracy > 20.0 && attempt < 3) {
      // Retry automatically if GPS accuracy > 20m as per requirement
      return getCurrentLocation(attempt: attempt + 1);
    }

    return {
      'latitude': 12.9716 + (random.nextDouble() - 0.5) * 0.001,
      'longitude': 80.2462 + (random.nextDouble() - 0.5) * 0.001,
      'accuracy': accuracy,
      'attempts': attempt,
    };
  }

  Future<Map<String, String>> reverseGeocode(double latitude, double longitude) async {
    await Future.delayed(const Duration(milliseconds: 600));
    
    // Auto-fill parameters as requested: House Number, Street, Area, City, State, PIN Code
    return {
      'houseNumber': 'Flat 405, Phoenix Tower B',
      'street': 'OMR Road',
      'area': 'Thoraipakkam',
      'city': 'Chennai',
      'state': 'Tamil Nadu',
      'pincode': '600096',
    };
  }
}
