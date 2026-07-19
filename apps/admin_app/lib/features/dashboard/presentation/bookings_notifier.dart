import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class BookingsState {
  final List<BookingDto> bookings;
  final bool isLoading;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String searchQuery;
  final String? statusFilter;
  final String? priorityFilter;

  BookingsState({
    required this.bookings,
    required this.isLoading,
    this.errorMessage,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.searchQuery,
    this.statusFilter,
    this.priorityFilter,
  });

  factory BookingsState.initial() => BookingsState(
        bookings: [],
        isLoading: false,
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0,
        searchQuery: '',
        statusFilter: null,
        priorityFilter: null,
      );

  BookingsState copyWith({
    List<BookingDto>? bookings,
    bool? isLoading,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    String? searchQuery,
    String? statusFilter,
    String? priorityFilter,
  }) {
    return BookingsState(
      bookings: bookings ?? this.bookings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter == 'ALL' ? null : (statusFilter ?? this.statusFilter),
      priorityFilter: priorityFilter == 'ALL' ? null : (priorityFilter ?? this.priorityFilter),
    );
  }
}

class BookingsNotifier extends StateNotifier<BookingsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingAcceptedSub;
  StreamSubscription? _statusUpdatedSub;

  BookingsNotifier(this._apiClient, this._ref) : super(BookingsState.initial()) {
    fetchBookings();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = _ref.read(socketServiceProvider);
    socket.connect();

    _bookingCreatedSub = socket.bookingCreatedStream.listen((_) => fetchBookings());
    _bookingAcceptedSub = socket.bookingAcceptedStream.listen((_) => fetchBookings());
    _statusUpdatedSub = socket.bookingStatusUpdatedStream.listen((_) => fetchBookings());
  }

  Future<void> fetchBookings({int? page}) async {
    final targetPage = page ?? state.page;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.get('/bookings', queryParameters: {
        'page': targetPage,
        'limit': state.limit,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'] as List? ?? [];
        final meta = response.data['meta'] ?? {};
        
        List<BookingDto> fetched = data.map((item) => BookingDto.fromJson(item as Map<String, dynamic>)).toList();

        // Perform client-side filter for advanced properties (since backend filter is lightweight)
        if (state.searchQuery.isNotEmpty) {
          final query = state.searchQuery.toLowerCase();
          fetched = fetched.where((b) {
            return (b.localId ?? '').toLowerCase().contains(query) ||
                (b.customerName ?? '').toLowerCase().contains(query) ||
                (b.description).toLowerCase().contains(query) ||
                (b.address).toLowerCase().contains(query) ||
                (b.technicianName ?? '').toLowerCase().contains(query);
          }).toList();
        }

        if (state.statusFilter != null) {
          fetched = fetched.where((b) => b.status == state.statusFilter).toList();
        }

        if (state.priorityFilter != null) {
          final isEmergency = state.priorityFilter == 'EMERGENCY';
          fetched = fetched.where((b) => b.isEmergency == isEmergency).toList();
        }

        state = state.copyWith(
          isLoading: false,
          bookings: fetched,
          page: targetPage,
          total: meta['total'] as int? ?? fetched.length,
          totalPages: meta['totalPages'] as int? ?? 1,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to fetch bookings.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query, page: 1);
    fetchBookings();
  }

  void updateStatusFilter(String? status) {
    state = state.copyWith(statusFilter: status, page: 1);
    fetchBookings();
  }

  void updatePriorityFilter(String? priority) {
    state = state.copyWith(priorityFilter: priority, page: 1);
    fetchBookings();
  }

  Future<bool> assignTechnician(String bookingId, String technicianId) async {
    try {
      final response = await _apiClient.post('/bookings/$bookingId/accept', data: {
        'technicianId': technicianId,
      });
      if (response.statusCode == 200) {
        fetchBookings();
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingAcceptedSub?.cancel();
    _statusUpdatedSub?.cancel();
    super.dispose();
  }
}

final bookingsProvider = StateNotifierProvider<BookingsNotifier, BookingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingsNotifier(apiClient, ref);
});
