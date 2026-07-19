import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';

class ReportsState {
  final bool isLoading;
  final String? errorMessage;
  final String? reportData;

  ReportsState({
    required this.isLoading,
    this.errorMessage,
    this.reportData,
  });

  factory ReportsState.initial() => ReportsState(
        isLoading: false,
      );

  ReportsState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? reportData,
  }) {
    return ReportsState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      reportData: reportData,
    );
  }
}

class ReportsNotifier extends StateNotifier<ReportsState> {
  final ApiClient _apiClient;

  ReportsNotifier(this._apiClient) : super(ReportsState.initial());

  Future<String?> generateReport({
    required String type,
    required String format,
    String? startDate,
    String? endDate,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null, reportData: null);
    try {
      final queryParams = <String, String>{
        'type': type,
        'format': format,
      };
      if (startDate != null && startDate.isNotEmpty) {
        queryParams['startDate'] = startDate;
      }
      if (endDate != null && endDate.isNotEmpty) {
        queryParams['endDate'] = endDate;
      }

      final uri = Uri(path: '/admin/reports/generate', queryParameters: queryParams).toString();
      final response = await _apiClient.get(uri);

      if (response.statusCode == 200) {
        final data = response.data.toString();
        state = state.copyWith(isLoading: false, reportData: data);
        return data;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to generate report.');
        return null;
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
      return null;
    }
  }
}

final reportsProvider = StateNotifierProvider<ReportsNotifier, ReportsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ReportsNotifier(apiClient);
});
