import 'package:flutter_test/flutter_test.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/profile/data/repositories/property_repository.dart';
import 'package:project_phoenix_customer/features/profile/domain/entities/property_model.dart';

void main() {
  group('PropertyRepository Unit Tests', () {
    late ApiClient apiClient;
    late PropertyRepository repository;

    setUp(() {
      apiClient =
          ApiClient(baseUrl: 'https://api.phoenix-fieldservice.in/api/v1');
      repository = PropertyRepository(apiClient);
    });

    test('PropertyRepository can be initialized', () {
      expect(repository, isNotNull);
    });

    test('Property object serialization and parsing', () {
      final prop = Property(
        id: 'prop-11',
        name: 'My Chennai Flat',
        address: 'OMR Road, Chennai',
        installedAppliances: ['Daikin AC', 'Havells Geyser'],
        warranties: ['W-100', 'W-101'],
        amcStatus: 'Active',
        serviceHistory: ['Checkup Dec 2025'],
        notes: 'Security code is 4455',
      );

      final map = prop.toMap();
      expect(map['id'], 'prop-11');
      expect(map['name'], 'My Chennai Flat');

      final parsed = Property.fromMap(map);
      expect(parsed.id, 'prop-11');
      expect(parsed.name, 'My Chennai Flat');
      expect(parsed.installedAppliances.length, 2);
    });
  });
}
