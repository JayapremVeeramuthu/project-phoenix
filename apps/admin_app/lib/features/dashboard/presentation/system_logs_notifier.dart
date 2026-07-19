import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class SystemLogsState {
  final List<SystemLogDto> logs;
  final bool isLoading;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String searchQuery;
  final String? actionFilter;

  SystemLogsState({
    required this.logs,
    required this.isLoading,
    this.errorMessage,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.searchQuery,
    this.actionFilter,
  });

  factory SystemLogsState.initial() => SystemLogsState(
        logs: [],
        isLoading: false,
        page: 1,
        limit: 50,
        total: 0,
        totalPages: 0,
        searchQuery: '',
        actionFilter: 'all',
      );

  SystemLogsState copyWith({
    List<SystemLogDto>? logs,
    bool? isLoading,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    String? searchQuery,
    String? actionFilter,
  }) {
    return SystemLogsState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      actionFilter: actionFilter ?? this.actionFilter,
    );
  }
}

class SystemLogsNotifier extends StateNotifier<SystemLogsState> {
  final ApiClient _apiClient;

  SystemLogsNotifier(this._apiClient) : super(SystemLogsState.initial()) {
    fetchLogs();
  }

  Future<void> fetchLogs({int? page}) async {
    final targetPage = page ?? state.page;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final queryParams = <String, String>{
        'page': targetPage.toString(),
        'limit': state.limit.toString(),
      };
      if (state.searchQuery.trim().isNotEmpty) {
        queryParams['search'] = state.searchQuery;
      }
      if (state.actionFilter != null && state.actionFilter != 'all') {
        queryParams['action'] = state.actionFilter!;
      }

      final uri = Uri(path: '/admin/logs', queryParameters: queryParams).toString();
      final response = await _apiClient.get(uri);

      if (response.statusCode == 200) {
        final list = response.data['data'] as List? ?? [];
        final meta = response.data['meta'] ?? {};
        final fetched = list.map((json) => SystemLogDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();

        state = state.copyWith(
          isLoading: false,
          logs: fetched,
          page: targetPage,
          total: meta['total'] as int? ?? fetched.length,
          totalPages: meta['totalPages'] as int? ?? 1,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve logs.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query, page: 1);
    fetchLogs();
  }

  void updateActionFilter(String? action) {
    state = state.copyWith(actionFilter: action, page: 1);
    fetchLogs();
  }
}

final systemLogsProvider = StateNotifierProvider<SystemLogsNotifier, SystemLogsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SystemLogsNotifier(apiClient);
});
