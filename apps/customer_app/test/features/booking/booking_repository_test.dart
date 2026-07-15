import 'package:flutter_test/flutter_test.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';
import 'package:project_phoenix_customer/features/booking/data/models/booking_dto.dart';

void main() {
  group('BookingRepository Unit Tests', () {
    late ApiClient apiClient;
    late BookingRepository repository;

    setUp(() {
      apiClient =
          ApiClient(baseUrl: 'https://api.phoenix-fieldservice.in/api/v1');
      repository = BookingRepository(apiClient);
    });

    test('BookingRepository can be initialized', () {
      expect(repository, isNotNull);
    });

    test('BookingDto serialization & deserialization matches perfectly', () {
      final dto = BookingDto(
        localId: 'local-123',
        customerId: 'cust-99',
        propertyId: 'prop-55',
        address: 'Chennai OMR',
        serviceIds: ['elec-fan'],
        scheduledAt: '2026-07-12',
        timeSlot: '10:00 AM',
        isEmergency: true,
        description: 'Noisy fan blades',
        imagePaths: ['/tmp/fan1.jpg', '/tmp/fan2.jpg'],
        voiceNotePath: '/tmp/note.m4a',
        voiceTranscript: 'Squeaking sound',
        estimatedPrice: 350.00,
        status: 'PENDING',
        createdAt: '2026-07-12T00:00:00Z',
      );

      final json = dto.toJson();
      expect(json['localId'], 'local-123');
      expect(json['customerId'], 'cust-99');
      expect(json['isEmergency'], true);
      expect(json['estimatedPrice'], 350.00);

      final decoded = BookingDto.fromJson(json);
      expect(decoded.localId, 'local-123');
      expect(decoded.customerId, 'cust-99');
      expect(decoded.isEmergency, true);
      expect(decoded.estimatedPrice, 350.00);
      expect(decoded.imagePaths.length, 2);
    });
  });
}
