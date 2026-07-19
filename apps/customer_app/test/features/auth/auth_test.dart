import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/auth/data/firebase_service.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class MockUser implements fb.User {
  @override
  Future<String?> getIdToken([bool forceRefresh = false]) async => 'mock_firebase_id_token';

  @override
  String get uid => 'mock_firebase_uid';

  @override
  String? get email => 'test@phoenix.in';

  @override
  String? get phoneNumber => '+919876543210';

  @override
  String? get displayName => 'Rajesh Kumar';

  @override
  Future<void> sendEmailVerification([fb.ActionCodeSettings? actionCodeSettings]) async {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockUserCredential implements fb.UserCredential {
  @override
  fb.User get user => MockUser();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFirebaseService implements FirebaseService {
  @override
  fb.User? get currentUser => null;

  @override
  Future<fb.UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return MockUserCredential();
  }

  @override
  Future<fb.UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return MockUserCredential();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> confirmPasswordReset(String code, String newPassword) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<GoogleSignInAccount?> signInWithGoogle() async => null;

  @override
  Future<fb.UserCredential> signInWithCredential(fb.AuthCredential credential) async {
    return MockUserCredential();
  }

  @override
  Future<void> verifyPhoneNumber({
    required String phoneNumber,
    required Duration timeout,
    required fb.PhoneVerificationCompleted verificationCompleted,
    required fb.PhoneVerificationFailed verificationFailed,
    required fb.PhoneCodeSent codeSent,
    required fb.PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) async {
    codeSent('mock_verification_id', 12345);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthNotifier Tests', () {
    late ApiClient apiClient;
    late AuthNotifier authNotifier;
    bool shouldSucceed = true;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      apiClient = ApiClient(baseUrl: 'http://localhost:3000/api/v1');
      apiClient.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/login') || options.path.contains('/auth/email-login')) {
            if (shouldSucceed) {
              handler.resolve(Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'access_token': 'mock_access_token',
                  'refresh_token': 'mock_refresh_token',
                  'user': {
                    'id': 'cust-uuid-112233',
                    'name': 'Rajesh Kumar',
                    'email': 'test@phoenix.in',
                    'phoneNumber': '+919876543210',
                  }
                },
              ));
            } else {
              handler.reject(DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 400,
                  data: {'message': 'Invalid credentials'},
                ),
                type: DioExceptionType.badResponse,
              ));
            }
          } else if (options.path.contains('/auth/logout')) {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {'message': 'Logout success'},
            ));
          } else {
            handler.next(options);
          }
        },
      ));
      authNotifier = AuthNotifier(apiClient, firebaseService: FakeFirebaseService());
    });

    test('Initial state is unauthenticated and guest false', () {
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.isGuest, false);
      expect(authNotifier.state.isLoading, false);
    });

    test('loginAsGuest updates state to guest mode', () {
      authNotifier.loginAsGuest();
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.isGuest, true);
    });

    test('loginWithEmail validation success updates state', () async {
      shouldSucceed = true;
      final success =
          await authNotifier.loginWithEmail('test@phoenix.in', 'password123');
      expect(success, true);
      expect(authNotifier.state.isAuthenticated, true);
      expect(authNotifier.state.isGuest, false);
      expect(authNotifier.state.userEmail, 'test@phoenix.in');
    });

    test('loginWithEmail validation failure returns false', () async {
      shouldSucceed = false;
      final success = await authNotifier.loginWithEmail('invalid-email', '123');
      expect(success, false);
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.error != null, true);
    });

    test('logout resets auth state to default', () async {
      shouldSucceed = true;
      await authNotifier.loginWithEmail('test@phoenix.in', 'password123');
      expect(authNotifier.state.isAuthenticated, true);

      await authNotifier.logout();
      expect(authNotifier.state.isAuthenticated, false);
      expect(authNotifier.state.userEmail, null);
    });
  });
}
