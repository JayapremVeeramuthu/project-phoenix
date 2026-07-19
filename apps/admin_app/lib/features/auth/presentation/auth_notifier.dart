import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_api/shared_api.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final String? adminName;
  final String? email;
  final String? userId;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.errorMessage,
    this.adminName,
    this.email,
    this.userId,
  });

  factory AuthState.initial() => AuthState(isLoading: false, isAuthenticated: false);

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    String? adminName,
    String? email,
    String? userId,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
      adminName: adminName ?? this.adminName,
      email: email ?? this.email,
      userId: userId ?? this.userId,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient) : super(AuthState.initial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    final token = await _storage.read(key: 'admin_access_token');
    if (token != null) {
      final name = await _storage.read(key: 'admin_name');
      final email = await _storage.read(key: 'admin_email');
      final userId = await _storage.read(key: 'admin_user_id');

      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        adminName: name,
        email: email,
        userId: userId,
      );
    }
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post('/auth/admin/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];

        await _storage.write(key: 'admin_access_token', value: accessToken);
        await _storage.write(key: 'admin_refresh_token', value: refreshToken);
        await _storage.write(key: 'admin_name', value: user['name'] ?? '');
        await _storage.write(key: 'admin_email', value: user['email'] ?? '');
        await _storage.write(key: 'admin_user_id', value: user['id'] ?? '');

        // Inject bearer token into apiClient headers
        _apiClient.dio.options.headers['Authorization'] = 'Bearer $accessToken';

        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          adminName: user['name'],
          email: user['email'],
          userId: user['id'],
        );

        return true;
      } else {
        state = AuthState.initial().copyWith(errorMessage: 'Authentication failed.');
        return false;
      }
    } on ApiException catch (e) {
      state = AuthState.initial().copyWith(errorMessage: e.message);
      return false;
    } catch (_) {
      state = AuthState.initial().copyWith(errorMessage: 'Invalid admin credentials or server offline.');
      return false;
    }
  }

  Future<void> logout() async {
    _apiClient.dio.options.headers.remove('Authorization');
    await _storage.deleteAll();
    state = AuthState.initial();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
