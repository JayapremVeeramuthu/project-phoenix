import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:shared_api/shared_api.dart';

import 'package:project_phoenix_technician/features/dashboard/presentation/jobs_notifier.dart';
import 'package:project_phoenix_technician/features/auth/presentation/auth_notifier.dart';

class MockSocketService extends SocketService {
  final _createdController = StreamController<Map<String, dynamic>>.broadcast();
  final _acceptedController = StreamController<Map<String, dynamic>>.broadcast();

  MockSocketService() : super(url: '');

  @override
  Stream<Map<String, dynamic>> get bookingCreatedStream => _createdController.stream;

  @override
  Stream<Map<String, dynamic>> get bookingAcceptedStream => _acceptedController.stream;

  void emitBookingCreated(Map<String, dynamic> event) {
    _createdController.add(event);
  }
}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(super.apiClient, super.socketService) {
    state = AuthState(
      isLoading: false,
      isAuthenticated: true,
      userId: 'test-tech-uuid-12345',
      technicianId: 'TECH001',
      technicianName: 'Test Tech',
      isOnline: true,
    );
  }

  @override
  Future<void> checkSession() async {
    // No-op to avoid FlutterSecureStorage crash in unit tests
  }
}

class FakeApiClient extends ApiClient {
  FakeApiClient() : super(baseUrl: '');

  @override
  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    return Response(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: [],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('JobsNotifier Unit Tests', () {
    test('booking_created event is parsed and added to availableJobs', () async {
      final mockSocket = MockSocketService();
      final fakeApi = FakeApiClient();
      final container = ProviderContainer(
        overrides: [
          socketServiceProvider.overrideWithValue(mockSocket),
          apiClientProvider.overrideWithValue(fakeApi),
          authProvider.overrideWith((ref) {
            final api = ref.watch(apiClientProvider);
            final socket = ref.watch(socketServiceProvider);
            return FakeAuthNotifier(api, socket);
          }),
        ],
      );

      container.read(jobsProvider.notifier);

      // Wait for async fetchJobs() in the constructor to complete
      while (container.read(jobsProvider).isLoading) {
        await Future.delayed(Duration.zero);
      }

      final mockBookingEvent = {
        'id': 'test-booking-uuid-12345',
        'localId': 'PHX-12345678',
        'customerId': 'customer-uuid-1',
        'propertyId': 'property-uuid-1',
        'serviceId': 'plumbing-repair',
        'address': '123 Main St, Area, 600096',
        'scheduledAt': '2026-07-16T18:19:15.000Z',
        'timeSlot': 'ANYTIME',
        'isEmergency': true,
        'description': 'Leaking sink in master kitchen',
        'imageUrls': ['http://minio/image.jpg'],
        'voiceNoteUrl': null,
        'voiceTranscript': null,
        'estimatedPrice': 450.0,
        'status': 'WAITING_FOR_TECHNICIAN',
        'createdAt': '2026-07-16T18:19:15.000Z',
        'customer': {
          'name': 'Rajesh Kumar',
          'phoneNumber': '+919876543210',
        }
      };

      mockSocket.emitBookingCreated(mockBookingEvent);

      // Wait a microtask for the stream listener to process the event
      await Future.delayed(Duration.zero);

      final state = container.read(jobsProvider);
      expect(state.availableJobs.length, 1);
      expect(state.availableJobs.first.localId, 'test-booking-uuid-12345');
      expect(state.availableJobs.first.customerName, 'Rajesh Kumar');
      expect(state.availableJobs.first.customerPhone, '+919876543210');
    });
  });
}
