import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_api/shared_api.dart';

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final String? errorMessage;
  final String? technicianId;
  final String? technicianName;
  final String? branch;
  final String? role;
  final String? userId;
  final bool isOnline;
  final bool mustChangePassword;

  AuthState({
    required this.isLoading,
    required this.isAuthenticated,
    this.errorMessage,
    this.technicianId,
    this.technicianName,
    this.branch,
    this.role,
    this.userId,
    this.isOnline = false,
    this.mustChangePassword = false,
  });

  factory AuthState.initial() => AuthState(
        isLoading: false,
        isAuthenticated: false,
        isOnline: false,
        mustChangePassword: false,
      );

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    String? errorMessage,
    String? technicianId,
    String? technicianName,
    String? branch,
    String? role,
    String? userId,
    bool? isOnline,
    bool? mustChangePassword,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      errorMessage: errorMessage,
      technicianId: technicianId ?? this.technicianId,
      technicianName: technicianName ?? this.technicianName,
      branch: branch ?? this.branch,
      role: role ?? this.role,
      userId: userId ?? this.userId,
      isOnline: isOnline ?? this.isOnline,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final SocketService _socketService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._apiClient, this._socketService) : super(AuthState.initial()) {
    checkSession();
  }

  Future<void> checkSession() async {
    final token = await _storage.read(key: 'access_token');
    if (token != null) {
      final techId = await _storage.read(key: 'technicianId');
      final techName = await _storage.read(key: 'technicianName');
      final branch = await _storage.read(key: 'branch');
      final role = await _storage.read(key: 'role');
      final userId = await _storage.read(key: 'user_id');
      final isOnlineStr = await _storage.read(key: 'is_online');
      final isOnline = isOnlineStr == 'true';
      final mustChangePassStr = await _storage.read(key: 'must_change_password');
      final mustChangePass = mustChangePassStr == 'true';

      state = AuthState(
        isLoading: false,
        isAuthenticated: true,
        technicianId: techId,
        technicianName: techName,
        branch: branch,
        role: role,
        userId: userId,
        isOnline: isOnline,
        mustChangePassword: mustChangePass,
      );

      if (isOnline) {
        _socketService.connect();
        _socketService.joinRoom('online_technicians');
        if (userId != null) {
          _socketService.joinRoom('technician_$userId');
        }
        if (techId != null && techId.isNotEmpty) {
          _socketService.joinRoom('technician_$techId');
        }
      }
    }
  }

  Future<bool> login(String technicianId, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final response = await _apiClient.post('/auth/technician/login', data: {
        'technicianId': technicianId,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];
        final isOnline = user['isOnline'] as bool? ?? false;
        final mustChangePassword = user['mustChangePassword'] as bool? ?? false;

        await _storage.write(key: 'access_token', value: accessToken);
        await _storage.write(key: 'refresh_token', value: refreshToken);
        await _storage.write(key: 'technicianId', value: user['technicianId'] ?? '');
        await _storage.write(key: 'technicianName', value: user['name'] ?? '');
        await _storage.write(key: 'branch', value: user['branch'] ?? '');
        await _storage.write(key: 'role', value: user['role'] ?? '');
        await _storage.write(key: 'user_id', value: user['id'] ?? '');
        await _storage.write(key: 'is_online', value: isOnline.toString());
        await _storage.write(key: 'must_change_password', value: mustChangePassword.toString());

        state = AuthState(
          isLoading: false,
          isAuthenticated: true,
          technicianId: user['technicianId'],
          technicianName: user['name'],
          branch: user['branch'],
          role: user['role'],
          userId: user['id'],
          isOnline: isOnline,
          mustChangePassword: mustChangePassword,
        );

        if (isOnline) {
          _socketService.connect();
          _socketService.joinRoom('online_technicians');
          if (user['id'] != null) {
            _socketService.joinRoom('technician_${user['id']}');
          }
          final String? techId = user['technicianId'];
          if (techId != null && techId.isNotEmpty) {
            _socketService.joinRoom('technician_$techId');
          }
        }

        return true;
      } else {
        state = AuthState.initial().copyWith(errorMessage: 'Authentication failed.');
        return false;
      }
    } on ApiException catch (e) {
      state = AuthState.initial().copyWith(errorMessage: e.message);
      return false;
    } catch (e) {
      state = AuthState.initial().copyWith(errorMessage: 'An unexpected error occurred.');
      return false;
    }
  }

  Future<bool> toggleOnlineStatus(bool online) async {
    final userId = state.userId;
    if (userId == null) return false;

    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.put('/auth/technician/availability', data: {
        'userId': userId,
        'isOnline': online,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final newOnline = data['isOnline'] as bool? ?? online;

        await _storage.write(key: 'is_online', value: newOnline.toString());
        state = state.copyWith(isLoading: false, isOnline: newOnline);

        // Sync Socket.IO rooms
        _socketService.connect();
        final techId = state.technicianId;
        if (newOnline) {
          _socketService.joinRoom('online_technicians');
          _socketService.joinRoom('technician_$userId');
          if (techId != null && techId.isNotEmpty) {
            _socketService.joinRoom('technician_$techId');
          }
        } else {
          _socketService.leaveRoom('online_technicians');
          _socketService.leaveRoom('technician_$userId');
          if (techId != null && techId.isNotEmpty) {
            _socketService.leaveRoom('technician_$techId');
          }
        }
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<void> logout() async {
    final userId = await _storage.read(key: 'user_id');
    if (userId != null) {
      try {
        await _apiClient.post('/auth/logout?userId=$userId');
      } catch (_) {}
    }

    if (userId != null) {
      _socketService.leaveRoom('technician_$userId');
    }
    _socketService.leaveRoom('online_technicians');
    _socketService.disconnect();

    await _storage.deleteAll();
    state = AuthState.initial();
  }

  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final userId = state.userId;
    if (userId == null) return 'Session expired. Please log in again.';

    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.post('/auth/technician/change-password', data: {
        'userId': userId,
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _storage.write(key: 'must_change_password', value: 'false');
        state = state.copyWith(
          isLoading: false,
          mustChangePassword: false,
        );
        return null;
      }
      state = state.copyWith(isLoading: false);
      return 'Failed to change password.';
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false);
      return e.message;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return 'An unexpected error occurred.';
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final socketService = ref.watch(socketServiceProvider);
  return AuthNotifier(apiClient, socketService);
});
