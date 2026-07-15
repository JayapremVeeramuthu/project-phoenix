import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';
import 'package:project_phoenix_customer/core/network/minio_upload_service.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_notifier.dart';
import 'package:project_phoenix_customer/features/services/domain/entities/service_item.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('BookingNotifier Unit Tests', () {
    late ApiClient apiClient;
    late BookingRepository bookingRepository;
    late MinioUploadService minioUploadService;
    late BookingNotifier bookingNotifier;
    late ServiceItem mockService;

    setUp(() {
      apiClient = ApiClient(baseUrl: 'http://localhost:3000/api/v1');
      bookingRepository = BookingRepository(apiClient);
      minioUploadService = MinioUploadService(apiClient);
      bookingNotifier = BookingNotifier(bookingRepository, minioUploadService);
      mockService = ServiceItem(
        id: 'test-elec-mcb',
        categoryId: 'electrical',
        nameEn: 'MCB Repair',
        nameTa: 'MCB பழுதுபார்த்தல்',
        descriptionEn: 'Repair MCB',
        descriptionTa: 'MCB பழுது',
        basePrice: 1000.00,
        durationMinutes: 45,
      );
    });

    test('Initializes state correctly with base price', () {
      bookingNotifier.initBookingWithService(mockService);
      expect(bookingNotifier.debugState.services.first.id, 'test-elec-mcb');
      expect(bookingNotifier.debugState.estimatedPrice, 1000.00);
      expect(bookingNotifier.debugState.totalAmount, 1000.00);
    });

    test('Emergency toggle adds 25% premium surcharge', () {
      bookingNotifier.initBookingWithService(mockService);
      bookingNotifier.toggleEmergency(true);

      expect(bookingNotifier.debugState.isEmergency, true);
      expect(bookingNotifier.debugState.estimatedPrice, 1250.00);
      expect(bookingNotifier.debugState.totalAmount, 1250.00);
    });

    test('Applying valid coupon PHOENIX15 deducts 15% discount', () {
      bookingNotifier.initBookingWithService(mockService);
      final success = bookingNotifier.applyCoupon('PHOENIX15');

      expect(success, true);
      expect(bookingNotifier.debugState.couponCode, 'PHOENIX15');
      expect(bookingNotifier.debugState.discountAmount, 150.00);
      expect(bookingNotifier.debugState.totalAmount, 850.00);
    });

    test('Emergency toggle combined with coupon calculates correctly', () {
      bookingNotifier.initBookingWithService(mockService);
      bookingNotifier.toggleEmergency(true); // Base becomes 1250
      final success =
          bookingNotifier.applyCoupon('PHOENIX15'); // 15% of 1250 is 187.5

      expect(success, true);
      expect(bookingNotifier.debugState.discountAmount, 187.50);
      expect(bookingNotifier.debugState.totalAmount, 1062.50);
    });

    test('Removing coupon resets pricing', () {
      bookingNotifier.initBookingWithService(mockService);
      bookingNotifier.applyCoupon('PHOENIX15');
      expect(bookingNotifier.debugState.totalAmount, 850.00);

      bookingNotifier.removeCoupon();
      expect(bookingNotifier.debugState.couponCode, null);
      expect(bookingNotifier.debugState.discountAmount, 0.00);
      expect(bookingNotifier.debugState.totalAmount, 1000.00);
    });

    test('Toggle additional service updates state prices', () {
      bookingNotifier.initBookingWithService(mockService);
      final additional = ServiceItem(
        id: 'test-elec-switch',
        categoryId: 'electrical',
        nameEn: 'Switch Change',
        nameTa: 'சுவிட்ச் மாற்றுதல்',
        descriptionEn: 'Change switches',
        descriptionTa: 'சுவிட்ச் மாற்றுதல்',
        basePrice: 500.00,
        durationMinutes: 20,
      );
      bookingNotifier.toggleService(additional);

      expect(bookingNotifier.debugState.services.length, 2);
      expect(bookingNotifier.debugState.estimatedPrice, 1500.00);
      expect(bookingNotifier.debugState.totalAmount, 1500.00);

      // Toggle off
      bookingNotifier.toggleService(additional);
      expect(bookingNotifier.debugState.services.length, 1);
      expect(bookingNotifier.debugState.estimatedPrice, 1000.00);
    });
  });
}

extension BookingNotifierTestExtension on BookingNotifier {
  BookingFormState get debugState => state;
}
