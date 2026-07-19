import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';

class DashboardStats {
  final int totalCustomers;
  final int activeCustomers;
  final int totalTechnicians;
  final int activeTechnicians;
  final int onlineTechnicians;
  final int offlineTechnicians;
  final int todayBookings;
  final int pendingJobs;
  final int assignedBookings;
  final int completedJobs;
  final int cancelledBookings;
  final double todayRevenue;
  final double revenueThisMonth;
  final double revenueThisYear;
  final double revenue;
  final double averageRating;
  final double averageResponseTime;
  final double averageCompletionTime;

  DashboardStats({
    required this.totalCustomers,
    required this.activeCustomers,
    required this.totalTechnicians,
    required this.activeTechnicians,
    required this.onlineTechnicians,
    required this.offlineTechnicians,
    required this.todayBookings,
    required this.pendingJobs,
    required this.assignedBookings,
    required this.completedJobs,
    required this.cancelledBookings,
    required this.todayRevenue,
    required this.revenueThisMonth,
    required this.revenueThisYear,
    required this.revenue,
    required this.averageRating,
    required this.averageResponseTime,
    required this.averageCompletionTime,
  });

  factory DashboardStats.initial() => DashboardStats(
        totalCustomers: 0,
        activeCustomers: 0,
        totalTechnicians: 0,
        activeTechnicians: 0,
        onlineTechnicians: 0,
        offlineTechnicians: 0,
        todayBookings: 0,
        pendingJobs: 0,
        assignedBookings: 0,
        completedJobs: 0,
        cancelledBookings: 0,
        todayRevenue: 0.0,
        revenueThisMonth: 0.0,
        revenueThisYear: 0.0,
        revenue: 0.0,
        averageRating: 0.0,
        averageResponseTime: 0.0,
        averageCompletionTime: 0.0,
      );

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalCustomers: json['totalCustomers'] as int? ?? 0,
      activeCustomers: json['activeCustomers'] as int? ?? 0,
      totalTechnicians: json['totalTechnicians'] as int? ?? 0,
      activeTechnicians: json['activeTechnicians'] as int? ?? 0,
      onlineTechnicians: json['onlineTechnicians'] as int? ?? 0,
      offlineTechnicians: json['offlineTechnicians'] as int? ?? 0,
      todayBookings: json['todayBookings'] as int? ?? 0,
      pendingJobs: json['pendingJobs'] as int? ?? 0,
      assignedBookings: json['assignedBookings'] as int? ?? 0,
      completedJobs: json['completedJobs'] as int? ?? 0,
      cancelledBookings: json['cancelledBookings'] as int? ?? 0,
      todayRevenue: (json['todayRevenue'] as num? ?? 0.0).toDouble(),
      revenueThisMonth: (json['revenueThisMonth'] as num? ?? 0.0).toDouble(),
      revenueThisYear: (json['revenueThisYear'] as num? ?? 0.0).toDouble(),
      revenue: (json['revenue'] as num? ?? 0.0).toDouble(),
      averageRating: (json['averageRating'] as num? ?? 0.0).toDouble(),
      averageResponseTime: (json['averageResponseTime'] as num? ?? 0.0).toDouble(),
      averageCompletionTime: (json['averageCompletionTime'] as num? ?? 0.0).toDouble(),
    );
  }
}

class DashboardStatsState {
  final bool isLoading;
  final DashboardStats stats;
  final String? errorMessage;

  DashboardStatsState({
    required this.isLoading,
    required this.stats,
    this.errorMessage,
  });

  factory DashboardStatsState.initial() => DashboardStatsState(
        isLoading: false,
        stats: DashboardStats.initial(),
      );

  DashboardStatsState copyWith({
    bool? isLoading,
    DashboardStats? stats,
    String? errorMessage,
  }) {
    return DashboardStatsState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      errorMessage: errorMessage,
    );
  }
}

class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  StreamSubscription? _bookingCreatedSub;
  StreamSubscription? _bookingAcceptedSub;
  StreamSubscription? _statusUpdatedSub;

  DashboardStatsNotifier(this._apiClient, this._ref) : super(DashboardStatsState.initial()) {
    fetchStats();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = _ref.read(socketServiceProvider);
    socket.connect();

    _bookingCreatedSub = socket.bookingCreatedStream.listen((_) => fetchStats());
    _bookingAcceptedSub = socket.bookingAcceptedStream.listen((_) => fetchStats());
    _statusUpdatedSub = socket.bookingStatusUpdatedStream.listen((_) => fetchStats());
  }

  Future<void> fetchStats() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/admin/dashboard/stats');
      if (response.statusCode == 200) {
        final stats = DashboardStats.fromJson(response.data);
        state = state.copyWith(isLoading: false, stats: stats);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve stats.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to connect to backend.');
    }
  }

  @override
  void dispose() {
    _bookingCreatedSub?.cancel();
    _bookingAcceptedSub?.cancel();
    _statusUpdatedSub?.cancel();
    super.dispose();
  }
}

final dashboardStatsProvider = StateNotifierProvider<DashboardStatsNotifier, DashboardStatsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardStatsNotifier(apiClient, ref);
});
