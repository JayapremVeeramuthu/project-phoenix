import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_success_screen.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';

class FakeSocketService extends SocketService {
  bool connectCalled = false;
  final List<String> joinedRooms = [];
  final List<String> leftRooms = [];
  final StreamController<Map<String, dynamic>> _statusController =
      StreamController<Map<String, dynamic>>.broadcast();

  FakeSocketService() : super(url: 'http://localhost:3000');

  @override
  Stream<Map<String, dynamic>> get bookingStatusUpdatedStream => _statusController.stream;

  @override
  void connect() {
    connectCalled = true;
  }

  @override
  void joinRoom(String room) {
    joinedRooms.add(room);
  }

  @override
  void leaveRoom(String room) {
    leftRooms.add(room);
  }

  void emitStatus(Map<String, dynamic> status) {
    _statusController.add(status);
  }

  void close() {
    _statusController.close();
  }
}

class FakeBookingRepository extends BookingRepository {
  FakeBookingRepository() : super(ApiClient(baseUrl: 'http://localhost:3000/api/v1'));

  @override
  Future<Map<String, dynamic>> getBookingTracking(String bookingId) async {
    return {
      'currentStatus': 'WAITING_FOR_TECHNICIAN',
      'technicianName': null,
      'technicianPhone': null,
      'technicianBranch': null,
      'technicianId': null,
    };
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('BookingSuccessScreen Lifecycle and Disposal Tests', () {
    late FakeSocketService fakeSocket;
    late FakeBookingRepository fakeRepo;

    setUp(() {
      fakeSocket = FakeSocketService();
      fakeRepo = FakeBookingRepository();
    });

    tearDown(() {
      fakeSocket.close();
    });

    testWidgets('Renders properly, joins room, updates on socket event, and disposes without Cannot use ref error',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socketServiceProvider.overrideWithValue(fakeSocket),
            bookingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BookingSuccessScreen(
              bookingId: 'test-booking-101',
              isOffline: false,
            ),
          ),
        ),
      );

      // Trigger post frame callbacks and initial fetch
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 1. Initial screen state verification
      expect(find.text('Booking Confirmed!'), findsOneWidget);
      expect(find.text('test-booking-101'), findsOneWidget);
      expect(find.text('WAITING FOR TECHNICIAN'), findsWidgets);

      // 2. Socket connection and joinRoom verification
      expect(fakeSocket.connectCalled, isTrue);
      expect(fakeSocket.joinedRooms, contains('booking_test-booking-101'));

      // 3. Socket event / status update verification
      fakeSocket.emitStatus({
        'bookingId': 'test-booking-101',
        'status': 'TECHNICIAN_ASSIGNED',
        'technicianName': 'Murugan S',
        'technicianPhone': '+919876543210',
        'technicianBranch': 'Chennai Central',
        'technicianId': 'TECH-007',
      });
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('TECHNICIAN ASSIGNED'), findsWidgets);
      expect(find.text('Murugan S'), findsOneWidget);
      expect(find.text('ID: TECH-007'), findsOneWidget);

      // 4. Navigation / unmount disposal test
      // Replace widget tree with an empty container to trigger dispose()
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Text('Navigated Away')),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify that leaveRoom was called on the socket service
      expect(fakeSocket.leftRooms, contains('booking_test-booking-101'));

      // Verify no "Cannot use ref after the widget was disposed" exception was thrown!
      expect(tester.takeException(), isNull);
    });

    testWidgets('Offline mode renders Saved Offline correctly and disposes safely',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            socketServiceProvider.overrideWithValue(fakeSocket),
            bookingRepositoryProvider.overrideWithValue(fakeRepo),
          ],
          child: const MaterialApp(
            home: BookingSuccessScreen(
              bookingId: 'offline-booking-202',
              isOffline: true,
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Saved Offline'), findsOneWidget);
      expect(find.text('offline-booking-202'), findsOneWidget);

      // Unmount
      await tester.pumpWidget(
        const MaterialApp(
          home: SizedBox(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });
  });
}
