import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';
import '../../auth/presentation/auth_notifier.dart';

class JobsState {
  final bool isLoading;
  final List<BookingDto> jobs;
  final List<BookingDto> availableJobs;
  final String? errorMessage;

  JobsState({
    required this.isLoading,
    required this.jobs,
    required this.availableJobs,
    this.errorMessage,
  });

  factory JobsState.initial() => JobsState(isLoading: false, jobs: [], availableJobs: []);

  JobsState copyWith({
    bool? isLoading,
    List<BookingDto>? jobs,
    List<BookingDto>? availableJobs,
    String? errorMessage,
  }) {
    return JobsState(
      isLoading: isLoading ?? this.isLoading,
      jobs: jobs ?? this.jobs,
      availableJobs: availableJobs ?? this.availableJobs,
      errorMessage: errorMessage,
    );
  }
}

class JobsNotifier extends StateNotifier<JobsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingAcceptedSub;

  JobsNotifier(this._apiClient, this._ref) : super(JobsState.initial()) {
    fetchJobs();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = _ref.read(socketServiceProvider);

    _bookingCreatedSub = socket.bookingCreatedStream.listen((event) {
      print('[JobsNotifier] ===== booking_created EVENT RECEIVED =====');
      print('[JobsNotifier] Raw event keys: ${event.keys.toList()}');
      print('[JobsNotifier] Raw event: $event');
      try {
        final newJob = BookingDto.fromJson(event);
        print('[JobsNotifier] Parsed BookingDto: localId=${newJob.localId}, status=${newJob.status}, customer=${newJob.customerName}, address=${newJob.address}');
        if (newJob.status == 'WAITING_FOR_TECHNICIAN' || newJob.status == 'PENDING') {
          // Avoid duplicate additions
          final exists = state.availableJobs.any((job) => job.localId == newJob.localId);
          print('[JobsNotifier] Status eligible. Duplicate check: exists=$exists, current availableJobs count=${state.availableJobs.length}');
          if (!exists) {
            print('[JobsNotifier] availableJobs count BEFORE update: ${state.availableJobs.length}');
            state = state.copyWith(
              availableJobs: [...state.availableJobs, newJob],
            );
            print('[JobsNotifier] availableJobs count AFTER update: ${state.availableJobs.length}');
            print('[JobsNotifier] ✅ Job ADDED to availableJobs. New count=${state.availableJobs.length}');
          } else {
            print('[JobsNotifier] ⏭️ Job SKIPPED (duplicate localId=${newJob.localId})');
          }
        } else {
          print('[JobsNotifier] ⏭️ Job SKIPPED (status=${newJob.status} not eligible)');
        }
      } catch (e, stack) {
        // ignore: avoid_print
        print('[JobsNotifier] ❌ Error parsing booking_created event: $e');
        // ignore: avoid_print
        print(stack);
      }
    });

    _bookingAcceptedSub = socket.bookingAcceptedStream.listen((event) {
      try {
        final acceptedId = event['bookingId'];
        state = state.copyWith(
          availableJobs: state.availableJobs.where((job) => job.localId != acceptedId).toList(),
        );
      } catch (e, stack) {
        // ignore: avoid_print
        print('[JobsNotifier] Error parsing booking_accepted event: $e');
        // ignore: avoid_print
        print(stack);
      }
    });
  }


  Future<void> fetchJobs() async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final assignedResponse = await _apiClient.get('/bookings/technician/$userId');
      List<BookingDto> assignedJobs = [];
      if (assignedResponse.statusCode == 200) {
        final list = assignedResponse.data as List;
        assignedJobs = list.map((json) => BookingDto.fromJson(json)).toList();
      }

      final availableResponse = await _apiClient.get('/bookings/available?technicianId=$userId');
      List<BookingDto> availableJobs = [];
      if (availableResponse.statusCode == 200) {
        final list = availableResponse.data as List;
        availableJobs = list.map((json) => BookingDto.fromJson(json)).toList();
      }

      state = state.copyWith(
        isLoading: false,
        jobs: assignedJobs,
        availableJobs: availableJobs,
      );
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'An unexpected error occurred.');
    }
  }

  Future<String?> acceptBooking(String bookingId) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return 'Session expired. Please log in again.';

    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.post(
        '/bookings/$bookingId/accept',
        data: {'technicianId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Accept succeeded, fetch fresh jobs and clear from live feed
        await fetchJobs();
        state = state.copyWith(
          availableJobs: state.availableJobs.where((job) => job.localId != bookingId).toList(),
        );
        return null; // Return null if success
      }
      state = state.copyWith(isLoading: false);
      return 'Failed to accept booking.';
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return 'This job has already been accepted by another technician.';
    }
  }

  Future<String?> updateBookingStatus(String bookingId, String status) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.patch(
        '/bookings/$bookingId/status',
        data: {'status': status},
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchJobs();
        return null;
      }
      state = state.copyWith(isLoading: false);
      return 'Failed to update status.';
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }

  void dismissAvailableJob(String bookingId) {
    state = state.copyWith(
      availableJobs: state.availableJobs.where((job) => job.localId != bookingId).toList(),
    );
  }

  Future<String?> rejectBooking(String bookingId) async {
    final userId = _ref.read(authProvider).userId;
    if (userId == null) return 'Session expired. Please log in again.';

    state = state.copyWith(isLoading: true);

    try {
      final response = await _apiClient.post(
        '/bookings/$bookingId/reject',
        data: {'technicianId': userId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        state = state.copyWith(
          isLoading: false,
          availableJobs: state.availableJobs.where((job) => job.localId != bookingId).toList(),
        );
        return null;
      }
      state = state.copyWith(isLoading: false);
      return 'Failed to reject booking.';
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }

  @override
  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingAcceptedSub?.cancel();
    super.dispose();
  }
}

final jobsProvider = StateNotifierProvider<JobsNotifier, JobsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  // Watch authProvider so jobsState is reset/recreated when authentication status changes
  ref.watch(authProvider);
  return JobsNotifier(apiClient, ref);
});
