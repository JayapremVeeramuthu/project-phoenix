import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/auth/data/google_auth_service.dart';

class AuthState {
  final bool isAuthenticated;
  final bool isGuest;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? userRole;
  final String? userAvatar;
  final String? gender;
  final String? dateOfBirth;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? provider;
  final String? error;
  final bool isLoading;

  AuthState({
    this.isAuthenticated = false,
    this.isGuest = false,
    this.userId,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.userRole,
    this.userAvatar,
    this.gender,
    this.dateOfBirth,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.provider,
    this.error,
    this.isLoading = false,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isGuest,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? userRole,
    String? userAvatar,
    String? gender,
    String? dateOfBirth,
    String? address,
    String? city,
    String? state,
    String? pincode,
    String? provider,
    String? error,
    bool? isLoading,
    bool clearAddress = false,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      userRole: userRole ?? this.userRole,
      userAvatar: userAvatar ?? this.userAvatar,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      address: clearAddress ? null : (address ?? this.address),
      city: clearAddress ? null : (city ?? this.city),
      state: clearAddress ? null : (state ?? this.state),
      pincode: clearAddress ? null : (pincode ?? this.pincode),
      provider: provider ?? this.provider,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final GoogleAuthService _googleAuthService;

  AuthNotifier(
    this._apiClient, {
    GoogleAuthService? googleAuthService,
  })  : _googleAuthService = googleAuthService ?? GoogleAuthService(),
        super(AuthState()) {
    _checkAutoLogin();
  }

  Future<void> _checkAutoLogin() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    if (accessToken != null && refreshToken != null) {
      final userId = await _storage.read(key: 'user_id');
      final userName = await _storage.read(key: 'user_name');
      final userEmail = await _storage.read(key: 'user_email');
      final userPhone = await _storage.read(key: 'user_phone');
      final userRole = await _storage.read(key: 'user_role');
      final userAvatar = await _storage.read(key: 'user_avatar');
      final gender = await _storage.read(key: 'user_gender');
      final dateOfBirth = await _storage.read(key: 'user_dob');
      final address = await _storage.read(key: 'user_address');
      final city = await _storage.read(key: 'user_city');
      final stateName = await _storage.read(key: 'user_state');
      final pincode = await _storage.read(key: 'user_pincode');
      final provider = await _storage.read(key: 'user_provider');

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userId,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        userRole: userRole,
        userAvatar: userAvatar,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
        city: city,
        state: stateName,
        pincode: pincode,
        provider: provider,
      );

      _logPostLogin(accessToken, {
        'id': userId,
        'name': userName,
        'email': userEmail,
        'phoneNumber': userPhone,
        'role': userRole,
        'avatarUrl': userAvatar,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'city': city,
        'state': stateName,
        'pincode': pincode,
        'provider': provider,
      });

      _fetchLatestProfile();
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required Map<String, dynamic> userMap,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'user_id', value: userMap['id'] as String);
    await _storage.write(key: 'user_name', value: userMap['name'] as String? ?? '');
    await _storage.write(key: 'user_email', value: userMap['email'] as String? ?? '');
    await _storage.write(key: 'user_phone', value: userMap['phoneNumber'] as String? ?? '');
    await _storage.write(key: 'user_role', value: userMap['role'] as String? ?? 'CUSTOMER');
    await _storage.write(key: 'user_avatar', value: userMap['avatarUrl'] as String? ?? '');
    await _storage.write(key: 'user_gender', value: userMap['gender'] as String? ?? '');
    await _storage.write(key: 'user_dob', value: userMap['dateOfBirth'] as String? ?? '');
    await _storage.write(key: 'user_address', value: userMap['address'] as String? ?? '');
    await _storage.write(key: 'user_city', value: userMap['city'] as String? ?? '');
    await _storage.write(key: 'user_state', value: userMap['state'] as String? ?? '');
    await _storage.write(key: 'user_pincode', value: userMap['pincode'] as String? ?? '');
    await _storage.write(key: 'user_provider', value: userMap['provider'] as String? ?? 'email');
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
    await _storage.delete(key: 'user_phone');
    await _storage.delete(key: 'user_role');
    await _storage.delete(key: 'user_avatar');
    await _storage.delete(key: 'user_gender');
    await _storage.delete(key: 'user_dob');
    await _storage.delete(key: 'user_address');
    await _storage.delete(key: 'user_city');
    await _storage.delete(key: 'user_state');
    await _storage.delete(key: 'user_pincode');
    await _storage.delete(key: 'user_provider');
  }

  Future<void> _fetchLatestProfile() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;
    try {
      final response = await _apiClient.get('/auth/profile');
      final userMap = response.data;

      await _storage.write(key: 'user_name', value: userMap['name'] as String? ?? '');
      await _storage.write(key: 'user_email', value: userMap['email'] as String? ?? '');
      await _storage.write(key: 'user_phone', value: userMap['phoneNumber'] as String? ?? '');
      await _storage.write(key: 'user_role', value: userMap['role'] as String? ?? 'CUSTOMER');
      await _storage.write(key: 'user_avatar', value: userMap['avatarUrl'] as String? ?? '');
      await _storage.write(key: 'user_gender', value: userMap['gender'] as String? ?? '');
      await _storage.write(key: 'user_dob', value: userMap['dateOfBirth'] as String? ?? '');
      await _storage.write(key: 'user_address', value: userMap['address'] as String? ?? '');
      await _storage.write(key: 'user_city', value: userMap['city'] as String? ?? '');
      await _storage.write(key: 'user_state', value: userMap['state'] as String? ?? '');
      await _storage.write(key: 'user_pincode', value: userMap['pincode'] as String? ?? '');
      await _storage.write(key: 'user_provider', value: userMap['provider'] as String? ?? 'email');

      state = state.copyWith(
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
        gender: userMap['gender'] as String?,
        dateOfBirth: userMap['dateOfBirth'] as String?,
        address: userMap['address'] as String?,
        city: userMap['city'] as String?,
        state: userMap['state'] as String?,
        pincode: userMap['pincode'] as String?,
        provider: userMap['provider'] as String?,
      );
    } catch (e) {
      debugPrint('Failed to refresh profile cache: ${e.toString()}');
      if (e is ApiException && (e.statusCode == 401 || e.statusCode == 400 || e.statusCode == 404)) {
        await logout();
      }
    }
  }

  Future<void> fetchLatestProfile() => _fetchLatestProfile();

  void _logPostLogin(String accessToken, Map<String, dynamic> userMap) {
    debugPrint("=== SUCCESSFUL AUTHENTICATION LOGS ===");
    debugPrint("isAuthenticated: ${state.isAuthenticated}");
    debugPrint("accessToken: $accessToken");
    debugPrint("user object: $userMap");
    debugPrint("userId: ${userMap['id']}");
    debugPrint("name: ${userMap['name']}");
    debugPrint("email: ${userMap['email']}");
    debugPrint("phone: ${userMap['phoneNumber']}");
    debugPrint("role: ${userMap['role']}");
    debugPrint("======================================");
  }

  Future<void> logProfileScreenOpening() async {
    debugPrint("=== PROFILE SCREEN OPENING LOGS ===");
    debugPrint("Current AuthState:");
    debugPrint("  isAuthenticated: ${state.isAuthenticated}");
    debugPrint("  isGuest: ${state.isGuest}");
    debugPrint("  userId: ${state.userId}");
    debugPrint("  userName: ${state.userName}");
    debugPrint("  userEmail: ${state.userEmail}");
    debugPrint("  userPhone: ${state.userPhone}");
    debugPrint("  userRole: ${state.userRole}");
    debugPrint("  userAvatar: ${state.userAvatar}");
    debugPrint("  gender: ${state.gender}");
    debugPrint("  dateOfBirth: ${state.dateOfBirth}");
    debugPrint("  address: ${state.address}");
    debugPrint("  city: ${state.city}");
    debugPrint("  state: ${state.state}");
    debugPrint("  pincode: ${state.pincode}");
    debugPrint("  provider: ${state.provider}");

    debugPrint("Secure Storage Values:");
    final allKeys = [
      'access_token',
      'refresh_token',
      'user_id',
      'user_name',
      'user_email',
      'user_phone',
      'user_role',
      'user_avatar',
      'user_gender',
      'user_dob',
      'user_address',
      'user_city',
      'user_state',
      'user_pincode',
      'user_provider'
    ];
    for (var key in allKeys) {
      final val = await _storage.read(key: key);
      debugPrint("  $key: $val");
    }
    debugPrint("======================================");
  }

  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/login', data: {
        'email': email.trim(),
        'password': password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final userMap = response.data['user'] as Map<String, dynamic>;

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userMap: userMap,
      );

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
        gender: userMap['gender'] as String?,
        dateOfBirth: userMap['dateOfBirth'] as String?,
        address: userMap['address'] as String?,
        city: userMap['city'] as String?,
        state: userMap['state'] as String?,
        pincode: userMap['pincode'] as String?,
        provider: userMap['provider'] as String?,
      );

      _logPostLogin(accessToken, userMap);
      _fetchLatestProfile();
      return true;
    } on ApiException catch (e) {
      debugPrint("Login ApiException: ${e.statusCode} ${e.message}");
      state = state.copyWith(
        isLoading: false,
        error: e.message.isNotEmpty ? e.message : 'Invalid credentials',
      );
      return false;
    } catch (e) {
      debugPrint("Login error: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> registerWithEmail({
    required String email,
    required String phoneNumber,
    required String name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/register', data: {
        'name': name.trim(),
        'email': email.trim(),
        'phoneNumber': phoneNumber.trim(),
        'password': password,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final userMap = response.data['user'] as Map<String, dynamic>;

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userMap: userMap,
      );

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: userMap['name'] as String? ?? name,
        userEmail: userMap['email'] as String? ?? email,
        userPhone: userMap['phoneNumber'] as String? ?? phoneNumber,
        userRole: userMap['role'] as String? ?? 'CUSTOMER',
        userAvatar: userMap['avatarUrl'] as String?,
        gender: userMap['gender'] as String?,
        dateOfBirth: userMap['dateOfBirth'] as String?,
        address: userMap['address'] as String?,
        city: userMap['city'] as String?,
        state: userMap['state'] as String?,
        pincode: userMap['pincode'] as String?,
        provider: 'email',
      );

      _logPostLogin(accessToken, userMap);
      _fetchLatestProfile();
      return true;
    } on ApiException catch (e) {
      debugPrint("Registration ApiException: ${e.statusCode} ${e.message}");
      state = state.copyWith(
        isLoading: false,
        error: e.message.isNotEmpty ? e.message : 'Registration failed',
      );
      return false;
    } catch (e) {
      debugPrint("Registration error: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateProfile({
    required String name,
    required String email,
    required String phoneNumber,
    required String gender,
    required String dateOfBirth,
    required String address,
    required String city,
    required String stateName,
    required String pincode,
  }) async {
    final userId = state.userId;
    if (userId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _apiClient.put('/auth/profile', data: {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'gender': gender,
        'dateOfBirth': dateOfBirth,
        'address': address,
        'city': city,
        'state': stateName,
        'pincode': pincode,
      });

      final userMap = response.data;
      await _saveSession(
        accessToken: (await _storage.read(key: 'access_token')) ?? '',
        refreshToken: (await _storage.read(key: 'refresh_token')) ?? '',
        userMap: userMap,
      );

      state = state.copyWith(
        isLoading: false,
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
        gender: userMap['gender'] as String?,
        dateOfBirth: userMap['dateOfBirth'] as String?,
        address: userMap['address'] as String?,
        city: userMap['city'] as String?,
        state: userMap['state'] as String?,
        pincode: userMap['pincode'] as String?,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateAvatar(String imageUrl) async {
    final userId = state.userId;
    if (userId == null) return false;
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiClient.put('/auth/profile', data: {
        'avatarUrl': imageUrl,
      });

      await _storage.write(key: 'user_avatar', value: imageUrl);

      state = state.copyWith(
        isLoading: false,
        userAvatar: imageUrl,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update avatar: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> updateAddress({
    required String address,
    String? city,
    String? stateName,
    String? pincode,
  }) async {
    var userId = state.userId;
    if (userId == null || userId.isEmpty) {
      userId = await _storage.read(key: 'user_id');
    }

    final effectiveCity = city ?? '';
    final effectiveState = stateName ?? '';
    final effectivePincode = pincode ?? '';

    if (userId == null || userId.isEmpty) {
      debugPrint('[AUTH] updateAddress: Guest/Unauthenticated mode. Saving address locally.');
      await _storage.write(key: 'user_address', value: address);
      await _storage.write(key: 'user_city', value: effectiveCity);
      await _storage.write(key: 'user_state', value: effectiveState);
      await _storage.write(key: 'user_pincode', value: effectivePincode);

      state = state.copyWith(
        isLoading: false,
        error: null,
        address: address,
        city: effectiveCity,
        state: effectiveState,
        pincode: effectivePincode,
      );
      return true;
    }

    state = state.copyWith(isLoading: true, error: null);

    final payload = {
      'address': address,
      'city': effectiveCity,
      'state': effectiveState,
      'pincode': effectivePincode,
    };

    try {
      final response = await _apiClient.put('/auth/profile', data: payload);

      final userMap = response.data;
      final savedAddress = userMap['address'] as String? ?? address;
      final savedCity = userMap['city'] as String? ?? effectiveCity;
      final savedState = userMap['state'] as String? ?? effectiveState;
      final savedPincode = userMap['pincode'] as String? ?? effectivePincode;

      await _storage.write(key: 'user_address', value: savedAddress);
      await _storage.write(key: 'user_city', value: savedCity);
      await _storage.write(key: 'user_state', value: savedState);
      await _storage.write(key: 'user_pincode', value: savedPincode);

      state = state.copyWith(
        isLoading: false,
        userId: userMap['id'] as String? ?? userId,
        address: savedAddress,
        city: savedCity,
        state: savedState,
        pincode: savedPincode,
      );
      return true;
    } catch (e) {
      debugPrint('[AUTH] Error updating address: $e');
      final errorMsg = e is ApiException
          ? 'Failed to update address: [${e.statusCode}] ${e.message}'
          : 'Failed to update address: ${e.toString()}';
      state = state.copyWith(
        isLoading: false,
        error: errorMsg,
      );
      return false;
    }
  }

  Future<bool> deleteAddress() async {
    var userId = state.userId;
    if (userId == null || userId.isEmpty) {
      userId = await _storage.read(key: 'user_id');
    }

    if (userId == null || userId.isEmpty) {
      await _storage.delete(key: 'user_address');
      await _storage.delete(key: 'user_city');
      await _storage.delete(key: 'user_state');
      await _storage.delete(key: 'user_pincode');

      state = state.copyWith(
        isLoading: false,
        clearAddress: true,
      );
      return true;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _apiClient.delete('/auth/address');

      await _storage.delete(key: 'user_address');
      await _storage.delete(key: 'user_city');
      await _storage.delete(key: 'user_state');
      await _storage.delete(key: 'user_pincode');

      state = state.copyWith(
        isLoading: false,
        clearAddress: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete address: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final idToken = await _googleAuthService.signInAndGetIdToken();
      if (idToken == null || idToken.isEmpty) {
        state = state.copyWith(isLoading: false);
        return false;
      }

      final response = await _apiClient.post('/auth/google', data: {
        'idToken': idToken,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final userMap = response.data['user'] as Map<String, dynamic>;

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userMap: userMap,
      );

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
        gender: userMap['gender'] as String?,
        dateOfBirth: userMap['dateOfBirth'] as String?,
        address: userMap['address'] as String?,
        city: userMap['city'] as String?,
        state: userMap['state'] as String?,
        pincode: userMap['pincode'] as String?,
        provider: userMap['provider'] as String? ?? 'google',
      );

      _logPostLogin(accessToken, userMap);
      _fetchLatestProfile();
      return true;
    } on ApiException catch (e) {
      debugPrint("Google login ApiException: ${e.statusCode} ${e.message}");
      state = state.copyWith(
        isLoading: false,
        error: e.message.isNotEmpty ? e.message : 'Google authentication failed',
      );
      return false;
    } catch (e) {
      debugPrint("Google login error: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Google Sign-In failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: false,
      error: 'Phone OTP verification is disabled pending SMS gateway configuration. Please use email authentication.',
    );
  }

  Future<void> resendOtp(String phoneNumber) async {
    state = state.copyWith(
      isLoading: false,
      error: 'Phone OTP verification is disabled pending SMS gateway configuration.',
    );
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _apiClient.post('/auth/otp-verify', data: {
        'phoneNumber': phoneNumber.trim(),
        'otp': otp.trim(),
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      final userMap = response.data['user'] as Map<String, dynamic>;

      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        userMap: userMap,
      );

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String? ?? 'CUSTOMER',
        userAvatar: userMap['avatarUrl'] as String?,
        provider: 'phone',
      );

      _logPostLogin(accessToken, userMap);
      _fetchLatestProfile();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message.isNotEmpty ? e.message : 'OTP verification failed',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Verification failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> sendOtpForLinking(String phoneNumber) async {
    state = state.copyWith(
      isLoading: false,
      error: 'Phone OTP verification is disabled pending SMS gateway configuration.',
    );
  }

  Future<bool> verifyOtpForLinking(String phoneNumber, String otp) async {
    state = state.copyWith(
      isLoading: false,
      error: 'Phone OTP verification is disabled pending SMS gateway configuration.',
    );
    return false;
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post('/auth/forgot-password', data: {'email': email.trim()});
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.post('/auth/reset-password', data: {
        'token': token,
        'newPassword': newPassword,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  void loginAsGuest() {
    state = AuthState(
      isAuthenticated: false,
      isGuest: true,
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout');
    } catch (_) {}
    await _googleAuthService.signOut();
    await _clearSession();
    state = AuthState();
  }

  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _apiClient.delete('/auth/account');
      await _googleAuthService.signOut();
      await _clearSession();
      state = AuthState();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message.isNotEmpty ? e.message : 'Failed to delete account',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to delete account: ${e.toString()}',
      );
      return false;
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
