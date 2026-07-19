import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class SettingsState {
  final SettingsDto? settings;
  final bool isLoading;
  final String? errorMessage;

  SettingsState({
    this.settings,
    required this.isLoading,
    this.errorMessage,
  });

  factory SettingsState.initial() => SettingsState(
        isLoading: false,
      );

  SettingsState copyWith({
    SettingsDto? settings,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SettingsState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  final ApiClient _apiClient;

  SettingsNotifier(this._apiClient) : super(SettingsState.initial()) {
    fetchSettings();
  }

  Future<void> fetchSettings() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/admin/settings');
      if (response.statusCode == 200) {
        final settings = SettingsDto.fromJson(Map<String, dynamic>.from(response.data as Map));
        state = state.copyWith(isLoading: false, settings: settings);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve settings.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  Future<bool> updateSettings(SettingsDto settings) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.put('/admin/settings', data: settings.toJson());
      if (response.statusCode == 200) {
        state = state.copyWith(isLoading: false, settings: settings);
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false, errorMessage: 'Failed to save settings.');
    return false;
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SettingsNotifier(apiClient);
});
