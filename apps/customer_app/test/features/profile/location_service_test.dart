import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/core/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('LocationService Unit Tests', () {
    late ApiClient apiClient;
    late LocationService locationService;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      apiClient = ApiClient(baseUrl: 'https://api.phoenix-fieldservice.in/api/v1');
      apiClient.dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.contains('/geo/reverse-geocode')) {
              return handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'latitude': 13.0827,
                  'longitude': 80.2707,
                  'building': 'No. 10',
                  'street': 'Raja Muthiah Road',
                  'area': 'Periamet',
                  'city': 'Chennai',
                  'state': 'Tamil Nadu',
                  'pincode': '600001',
                  'country': 'India',
                  'displayName': 'No. 10, Raja Muthiah Road, Periamet, Chennai, Tamil Nadu - 600001',
                  'formattedAddress': 'No. 10, Raja Muthiah Road, Periamet, Chennai, Tamil Nadu - 600001',
                },
              ));
            }
            return handler.next(options);
          },
        ),
      );

      locationService = LocationService(apiClient: apiClient);
    });

    test('LocationService can be initialized', () {
      expect(locationService, isNotNull);
    });

    test('reverseGeocode parses real coordinates and address components accurately', () async {
      final result = await locationService.reverseGeocode(13.0827, 80.2707);

      expect(result['houseNumber'], 'No. 10');
      expect(result['street'], 'Raja Muthiah Road');
      expect(result['area'], 'Periamet');
      expect(result['city'], 'Chennai');
      expect(result['state'], 'Tamil Nadu');
      expect(result['pincode'], '600001');
      expect(result['country'], 'India');
      expect(result['formattedAddress'], contains('Raja Muthiah Road'));
    });
  });
}
