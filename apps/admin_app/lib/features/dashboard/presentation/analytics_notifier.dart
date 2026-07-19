import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class AnalyticsState {
  final AnalyticsDto? analytics;
  final bool isLoading;
  final String? errorMessage;

  AnalyticsState({
    this.analytics,
    required this.isLoading,
    this.errorMessage,
  });

  factory AnalyticsState.initial() => AnalyticsState(
        isLoading: false,
      );

  AnalyticsState copyWith({
    AnalyticsDto? analytics,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AnalyticsState(
      analytics: analytics ?? this.analytics,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AnalyticsNotifier extends StateNotifier<AnalyticsState> {
  final ApiClient _apiClient;

  AnalyticsNotifier(this._apiClient) : super(AnalyticsState.initial()) {
    fetchAnalytics();
  }

  Future<void> fetchAnalytics() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/admin/analytics');
      if (response.statusCode == 200) {
        final analytics = AnalyticsDto.fromJson(Map<String, dynamic>.from(response.data as Map));
        state = state.copyWith(isLoading: false, analytics: analytics);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve analytics data.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }
}

final analyticsProvider = StateNotifierProvider<AnalyticsNotifier, AnalyticsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AnalyticsNotifier(apiClient);
});
