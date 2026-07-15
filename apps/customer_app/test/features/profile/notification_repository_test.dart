import 'package:flutter_test/flutter_test.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/features/profile/data/repositories/notification_repository.dart';

void main() {
  group('NotificationRepository Unit Tests', () {
    late ApiClient apiClient;
    late NotificationRepository repository;

    setUp(() {
      apiClient =
          ApiClient(baseUrl: 'https://api.phoenix-fieldservice.in/api/v1');
      repository = NotificationRepository(apiClient);
    });

    test('NotificationRepository can be initialized', () {
      expect(repository, isNotNull);
    });
  });
}
