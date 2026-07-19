import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class PaymentsState {
  final List<InvoiceDto> invoices;
  final PaymentStatsDto? stats;
  final bool isLoading;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaymentsState({
    required this.invoices,
    this.stats,
    required this.isLoading,
    this.errorMessage,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaymentsState.initial() => PaymentsState(
        invoices: [],
        isLoading: false,
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0,
      );

  PaymentsState copyWith({
    List<InvoiceDto>? invoices,
    PaymentStatsDto? stats,
    bool? isLoading,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
  }) {
    return PaymentsState(
      invoices: invoices ?? this.invoices,
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

class PaymentsNotifier extends StateNotifier<PaymentsState> {
  final ApiClient _apiClient;

  PaymentsNotifier(this._apiClient) : super(PaymentsState.initial()) {
    fetchStats();
    fetchHistory();
  }

  Future<void> fetchStats() async {
    try {
      final response = await _apiClient.get('/admin/payments/stats');
      if (response.statusCode == 200) {
        final stats = PaymentStatsDto.fromJson(Map<String, dynamic>.from(response.data as Map));
        state = state.copyWith(stats: stats);
      }
    } catch (_) {}
  }

  Future<void> fetchHistory({int? page}) async {
    final targetPage = page ?? state.page;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.get(
        '/admin/payments/history',
        queryParameters: {
          'page': targetPage.toString(),
          'limit': state.limit.toString(),
        },
      );

      if (response.statusCode == 200) {
        final list = response.data['data'] as List? ?? [];
        final meta = response.data['meta'] ?? {};
        final fetched = list.map((json) => InvoiceDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();

        state = state.copyWith(
          isLoading: false,
          invoices: fetched,
          page: targetPage,
          total: meta['total'] as int? ?? fetched.length,
          totalPages: meta['totalPages'] as int? ?? 1,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve payments history.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }
}

final paymentsProvider = StateNotifierProvider<PaymentsNotifier, PaymentsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PaymentsNotifier(apiClient);
});
