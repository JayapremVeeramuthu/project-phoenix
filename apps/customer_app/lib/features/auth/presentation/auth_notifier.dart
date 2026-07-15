import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/features/auth/data/firebase_service.dart';

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
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      provider: provider ?? this.provider,
      error: error,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final FirebaseService _firebaseService;

  String? _verificationId;
  int? _resendToken;

  AuthNotifier(
    this._apiClient, {
    FirebaseService? firebaseService,
  })  : _firebaseService = firebaseService ?? FirebaseService(),
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

      _logPostLogin(accessToken, (await _storage.read(key: 'firebase_uid')) ?? '', {
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
    } else {
      final currentUser = _firebaseService.currentUser;
      if (currentUser != null) {
        try {
          final idToken = await currentUser.getIdToken();
          if (idToken != null) {
            final response = await _apiClient.post('/auth/login', data: {
              'idToken': idToken,
            });

            final userMap = response.data['user'];
            final aToken = response.data['access_token'] as String;
            final rToken = response.data['refresh_token'] as String;

            await _saveSession(
              accessToken: aToken,
              refreshToken: rToken,
              firebaseUid: currentUser.uid,
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
            _logPostLogin(aToken, currentUser.uid, userMap);
            _fetchLatestProfile();
          }
        } catch (_) {
          await logout();
        }
      }
    }
  }

  Future<void> _saveSession({
    required String accessToken,
    required String refreshToken,
    required String firebaseUid,
    required Map<String, dynamic> userMap,
  }) async {
    await _storage.write(key: 'access_token', value: accessToken);
    await _storage.write(key: 'refresh_token', value: refreshToken);
    await _storage.write(key: 'firebase_uid', value: firebaseUid);
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
    await _storage.write(key: 'user_provider', value: userMap['provider'] as String? ?? '');
  }

  Future<void> _clearSession() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'firebase_uid');
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
    final userId = state.userId;
    if (userId == null) return;
    try {
      final response = await _apiClient.get('/auth/profile?userId=$userId');
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
      await _storage.write(key: 'user_provider', value: userMap['provider'] as String? ?? '');

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
    }
  }

  Future<void> fetchLatestProfile() => _fetchLatestProfile();

  void _logPostLogin(String accessToken, String firebaseUid, Map<String, dynamic> userMap) {
    debugPrint("=== SUCCESSFUL AUTHENTICATION LOGS ===");
    debugPrint("isAuthenticated: ${state.isAuthenticated}");
    debugPrint("accessToken: $accessToken");
    debugPrint("firebaseUid: $firebaseUid");
    debugPrint("user object: $userMap");
    debugPrint("name: ${userMap['name']}");
    debugPrint("email: ${userMap['email']}");
    debugPrint("phone: ${userMap['phoneNumber']}");
    debugPrint("role: ${userMap['role']}");
    debugPrint("======================================");
  }

  Future<void> logProfileScreenOpening() async {
    final currentUser = _firebaseService.currentUser;
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

    debugPrint("Current Firebase User:");
    if (currentUser != null) {
      debugPrint("  uid: ${currentUser.uid}");
      debugPrint("  email: ${currentUser.email}");
      debugPrint("  displayName: ${currentUser.displayName}");
    } else {
      debugPrint("  No active Firebase User session.");
    }

    debugPrint("Secure Storage Values:");
    final allKeys = [
      'access_token',
      'refresh_token',
      'firebase_uid',
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
        'userId': userId,
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
        firebaseUid: (await _storage.read(key: 'firebase_uid')) ?? '',
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
      final response = await _apiClient.put('/auth/profile', data: {
        'userId': userId,
        'avatarUrl': imageUrl,
      });

      final userMap = response.data;
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

  Future<bool> loginWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCredential = await _firebaseService.signInWithEmailAndPassword(
        email,
        password,
      );

      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Failed to obtain Firebase ID Token.');

      final response = await _apiClient.post('/auth/login', data: {
        'idToken': idToken,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;

      final userMap = response.data['user'];
      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        firebaseUid: userCredential.user?.uid ?? '',
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
      );
      _logPostLogin(accessToken, userCredential.user?.uid ?? '', userMap);
      _fetchLatestProfile();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
      return false;
    } catch (e) {
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
      final userCredential = await _firebaseService.createUserWithEmailAndPassword(
        email,
        password,
      );

      await userCredential.user?.sendEmailVerification();
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Failed to obtain Firebase ID Token.');

      final response = await _apiClient.post('/auth/register', data: {
        'idToken': idToken,
      });

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;

      final userMap = response.data['user'];
      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        firebaseUid: userCredential.user?.uid ?? '',
        userMap: userMap,
      );

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: name,
        userEmail: email,
        userPhone: phoneNumber,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
      );
      _logPostLogin(accessToken, userCredential.user?.uid ?? '', userMap);
      _fetchLatestProfile();
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> sendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    try {
      await _firebaseService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 30),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          debugPrint("verificationCompleted");
          final userCredential = await _firebaseService.signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            await _syncPhoneLogin(idToken, formattedPhone);
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          debugPrint("verificationFailed");
          debugPrint(e.code);
          debugPrint(e.message);
          state = state.copyWith(
            isLoading: false,
            error: "${e.code}\n${e.message}",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("codeSent");
          _verificationId = verificationId;
          _resendToken = resendToken;
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("codeAutoRetrievalTimeout");
          _verificationId = verificationId;
        },
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  Future<void> resendOtp(String phoneNumber) async {
    state = state.copyWith(isLoading: true, error: null);
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    try {
      await _firebaseService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 30),
        forceResendingToken: _resendToken,
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          debugPrint("verificationCompleted");
          final userCredential = await _firebaseService.signInWithCredential(credential);
          final idToken = await userCredential.user?.getIdToken();
          if (idToken != null) {
            await _syncPhoneLogin(idToken, formattedPhone);
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          debugPrint("verificationFailed");
          debugPrint(e.code);
          debugPrint(e.message);
          state = state.copyWith(
            isLoading: false,
            error: "${e.code}\n${e.message}",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("codeSent");
          _verificationId = verificationId;
          _resendToken = resendToken;
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("codeAutoRetrievalTimeout");
          _verificationId = verificationId;
        },
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to resend OTP: ${e.toString()}',
      );
    }
  }

  Future<bool> verifyOtp(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    try {
      if (_verificationId == null) {
        throw Exception('Verification code has not been sent yet.');
      }

      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final userCredential = await _firebaseService.signInWithCredential(credential);
      final idToken = await userCredential.user?.getIdToken();
      if (idToken == null) throw Exception('Failed to obtain Firebase ID Token.');

      return await _syncPhoneLogin(idToken, formattedPhone);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
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
    state = state.copyWith(isLoading: true, error: null);
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    try {
      await _firebaseService.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        timeout: const Duration(seconds: 30),
        verificationCompleted: (fb.PhoneAuthCredential credential) async {
          debugPrint("verificationCompleted for linking");
          final currentUser = fb.FirebaseAuth.instance.currentUser;
          if (currentUser != null) {
            await currentUser.linkWithCredential(credential);
            await _syncLinkedPhone(formattedPhone);
          }
        },
        verificationFailed: (fb.FirebaseAuthException e) {
          debugPrint("verificationFailed for linking");
          debugPrint(e.code);
          debugPrint(e.message);
          state = state.copyWith(
            isLoading: false,
            error: "${e.code}\n${e.message}",
          );
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint("codeSent for linking");
          _verificationId = verificationId;
          _resendToken = resendToken;
          state = state.copyWith(isLoading: false);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("codeAutoRetrievalTimeout for linking");
          _verificationId = verificationId;
        },
      );
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send OTP: ${e.toString()}',
      );
    }
  }

  Future<bool> verifyOtpForLinking(String phoneNumber, String otp) async {
    state = state.copyWith(isLoading: true, error: null);
    final formattedPhone = phoneNumber.startsWith('+') ? phoneNumber : '+91$phoneNumber';

    try {
      if (_verificationId == null) {
        throw Exception('Verification code has not been sent yet.');
      }

      final credential = fb.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      final currentUser = fb.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('No user currently logged in to link phone to.');
      }

      await currentUser.linkWithCredential(credential);
      debugPrint("Phone linking with Firebase SUCCESS");

      return await _syncLinkedPhone(formattedPhone);
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
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

  Future<bool> _syncLinkedPhone(String formattedPhone) async {
    final userId = state.userId;
    if (userId == null) return false;

    try {
      final response = await _apiClient.put('/auth/profile', data: {
        'userId': userId,
        'phoneNumber': formattedPhone,
      });

      final userMap = response.data;
      await _storage.write(key: 'user_phone', value: formattedPhone);

      state = state.copyWith(
        isLoading: false,
        userPhone: formattedPhone,
      );
      
      await _fetchLatestProfile();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update phone in database: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> _syncPhoneLogin(String idToken, String formattedPhone) async {
    final response = await _apiClient.post('/auth/otp-verify', data: {
      'idToken': idToken,
    });

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String;

    final userMap = response.data['user'];
    await _saveSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      firebaseUid: _firebaseService.currentUser?.uid ?? '',
      userMap: userMap,
    );

    state = AuthState(
      isAuthenticated: true,
      isGuest: false,
      userId: userMap['id'] as String,
      userName: userMap['name'] as String?,
      userEmail: userMap['email'] as String?,
      userPhone: formattedPhone,
      userRole: userMap['role'] as String?,
      userAvatar: userMap['avatarUrl'] as String?,
    );
    _logPostLogin(accessToken, _firebaseService.currentUser?.uid ?? '', userMap);
    _fetchLatestProfile();
    return true;
  }

  Future<bool> loginWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      debugPrint("STEP 1\nGoogle popup opened");

      // Use Firebase Auth's native signInWithPopup with GoogleAuthProvider.
      // This completely bypasses the google_sign_in package which internally
      // calls the Google People API (content-people.googleapis.com/v1/people/me)
      // causing a 403 SERVICE_DISABLED error.
      final googleProvider = fb.GoogleAuthProvider();
      googleProvider.addScope('email');

      final userCredential = await fb.FirebaseAuth.instance.signInWithPopup(googleProvider);

      debugPrint("STEP 2\nGoogle account selected");
      debugPrint("STEP 3\nGoogle accessToken received (via Firebase native)");
      debugPrint("STEP 4\nGoogle idToken received (via Firebase native)");
      debugPrint("STEP 5\nGoogleAuthProvider credential created (via Firebase native)");

      debugPrint("STEP 6\nFirebaseAuth.signInWithPopup SUCCESS");
      debugPrint("Firebase UID: ${userCredential.user?.uid}");
      debugPrint("Email: ${userCredential.user?.email}");
      debugPrint("DisplayName: ${userCredential.user?.displayName}");
      debugPrint("PhotoURL: ${userCredential.user?.photoURL}");

      if (userCredential.user == null) {
        debugPrint("Google login failed: Firebase user is null after signInWithPopup.");
        state = state.copyWith(isLoading: false);
        return false;
      }

      final idToken = await userCredential.user!.getIdToken();
      if (idToken == null) throw Exception('Failed to obtain Firebase ID Token.');
      debugPrint("Firebase ID Token length: ${idToken.length}");

      debugPrint("STEP 7\nBackend POST /auth/google called");
      final response = await _apiClient.post('/auth/google', data: {
        'idToken': idToken,
      });

      debugPrint("Backend response status: ${response.statusCode}");
      debugPrint("Backend response body: ${response.data}");

      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String;
      debugPrint("STEP 8\nBackend returns accessToken refreshToken");

      final userMap = response.data['user'];
      await _saveSession(
        accessToken: accessToken,
        refreshToken: refreshToken,
        firebaseUid: userCredential.user!.uid,
        userMap: userMap,
      );
      debugPrint("STEP 9\nSecureStorage write SUCCESS");
      debugPrint("Saved keys:");
      debugPrint("  access_token: $accessToken");
      debugPrint("  refresh_token: $refreshToken");
      debugPrint("  firebase_uid: ${userCredential.user!.uid}");
      debugPrint("  user_id: ${userMap['id']}");
      debugPrint("  user_name: ${userMap['name']}");
      debugPrint("  user_email: ${userMap['email']}");
      debugPrint("  user_phone: ${userMap['phoneNumber']}");
      debugPrint("  user_role: ${userMap['role']}");
      debugPrint("  user_avatar: ${userMap['avatarUrl']}");
      debugPrint("  user_provider: ${userMap['provider']}");

      // Read-back verification: confirm values were actually persisted
      debugPrint("--- SecureStorage READ-BACK VERIFICATION ---");
      for (final key in ['access_token', 'refresh_token', 'firebase_uid', 'user_id', 'user_name', 'user_email', 'user_phone', 'user_role', 'user_avatar', 'user_provider']) {
        final val = await _storage.read(key: key);
        debugPrint("  READ $key: $val");
      }
      debugPrint("--- END READ-BACK ---");

      // Verify FirebaseAuth.currentUser is set
      debugPrint("FirebaseAuth.instance.currentUser after signInWithPopup: ${fb.FirebaseAuth.instance.currentUser?.uid}");

      state = AuthState(
        isAuthenticated: true,
        isGuest: false,
        userId: userMap['id'] as String,
        userName: userMap['name'] as String?,
        userEmail: userMap['email'] as String?,
        userPhone: userMap['phoneNumber'] as String?,
        userRole: userMap['role'] as String?,
        userAvatar: userMap['avatarUrl'] as String?,
      );
      debugPrint("STEP 10\nRiverpod AuthState updated");
      debugPrint("isAuthenticated=true");
      debugPrint("userName: ${state.userName}");
      debugPrint("email: ${state.userEmail}");
      debugPrint("uid: ${state.userId}");
      debugPrint("role: ${state.userRole}");

      _logPostLogin(accessToken, userCredential.user!.uid, userMap);
      _fetchLatestProfile();

      debugPrint("STEP 11\nNavigate Home");
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(
        isLoading: false,
        error: "${e.code}\n${e.message}",
      );
      return false;
    } catch (e) {
      debugPrint("Exception during Google Login: $e");
      state = state.copyWith(
        isLoading: false,
        error: 'Google login failed: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firebaseService.sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(isLoading: false, error: "${e.code}\n${e.message}");
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _firebaseService.confirmPasswordReset(
        token,
        newPassword,
      );
      state = state.copyWith(isLoading: false);
      return true;
    } on fb.FirebaseAuthException catch (e) {
      debugPrint("FirebaseAuthException code: ${e.code}");
      debugPrint("FirebaseAuthException message: ${e.message}");
      debugPrint(e.toString());
      state = state.copyWith(isLoading: false, error: "${e.code}\n${e.message}");
      return false;
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
    final currentUserId = state.userId;
    if (currentUserId != null) {
      try {
        await _apiClient.post('/auth/logout?userId=$currentUserId');
      } catch (_) {}
    }
    // _firebaseService.signOut() already calls both
    // FirebaseAuth.signOut() and GoogleSignIn.signOut()
    await _firebaseService.signOut();
    await _clearSession();
    state = AuthState();
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(apiClient);
});
