import 'package:flutter_test/flutter_test.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/features/profile/data/repositories/warranty_repository.dart';

void main() {
  group('WarrantyRepository Unit Tests', () {
    late ApiClient apiClient;
    late WarrantyRepository repository;

    setUp(() {
      apiClient =
          ApiClient(baseUrl: 'https://api.phoenix-fieldservice.in/api/v1');
      repository = WarrantyRepository(apiClient);
    });

    test('WarrantyRepository can be initialized', () {
      expect(repository, isNotNull);
    });
  });
}
