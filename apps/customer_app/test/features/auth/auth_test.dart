import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FlutterSecureStorage.setMockInitialValues({});

  group('AuthNotifier Tests', () {
    late ApiClient apiClient;
    late AuthNotifier authNotifier;
    bool shouldSucceed = true;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      apiClient = ApiClient(baseUrl: AppConfig.apiUrl);
      apiClient.dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          if (options.path.contains('/auth/login')) {
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
                    'role': 'CUSTOMER',
                  }
                },
              ));
            } else {
              handler.reject(DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 401,
                  data: {'message': 'Invalid credentials'},
                ),
                type: DioExceptionType.badResponse,
              ));
            }
          } else if (options.path.contains('/auth/register')) {
            if (shouldSucceed) {
              final data = options.data as Map<String, dynamic>;
              handler.resolve(Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'access_token': 'mock_register_access_token',
                  'refresh_token': 'mock_register_refresh_token',
                  'user': {
                    'id': 'cust-uuid-998877',
                    'name': data['name'] ?? 'New Customer',
                    'email': data['email'] ?? 'new@phoenix.in',
                    'phoneNumber': data['phoneNumber'] ?? '+919876500000',
                    'role': 'CUSTOMER',
                  }
                },
              ));
            } else {
              handler.reject(DioException(
                requestOptions: options,
                response: Response(
                  requestOptions: options,
                  statusCode: 409,
                  data: {'message': 'User already exists'},
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
          } else if (options.path.contains('/auth/profile') && options.method == 'PUT') {
            final data = options.data as Map<String, dynamic>;
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'cust-uuid-112233',
                'name': 'Rajesh Kumar',
                'email': 'test@phoenix.in',
                'phoneNumber': '+919876543210',
                'address': data['address'],
                'city': data['city'],
                'state': data['state'],
                'pincode': data['pincode'],
              },
            ));
          } else if (options.path.contains('/auth/address') && options.method == 'DELETE') {
            handler.resolve(Response(
              requestOptions: options,
              statusCode: 200,
              data: {
                'id': 'cust-uuid-112233',
                'name': 'Rajesh Kumar',
                'email': 'test@phoenix.in',
                'phoneNumber': '+919876543210',
                'address': null,
                'city': null,
                'state': null,
                'pincode': null,
              },
            ));
          } else {
            handler.next(options);
          }
        },
      ));
      authNotifier = AuthNotifier(apiClient);
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

    test('registerWithEmail success creates session with JWT and User.id', () async {
      shouldSucceed = true;
      final success = await authNotifier.registerWithEmail(
        name: 'New Customer',
        email: 'new@phoenix.in',
        phoneNumber: '+919876500000',
        password: 'Password123!',
      );
      expect(success, true);
      expect(authNotifier.state.isAuthenticated, true);
      expect(authNotifier.state.userId, 'cust-uuid-998877');
      expect(authNotifier.state.userEmail, 'new@phoenix.in');
      expect(authNotifier.state.userName, 'New Customer');
    });

    test('loginWithEmail validation success updates state', () async {
      shouldSucceed = true;
      final success =
          await authNotifier.loginWithEmail('test@phoenix.in', 'password123');
      expect(success, true);
      expect(authNotifier.state.isAuthenticated, true);
      expect(authNotifier.state.isGuest, false);
      expect(authNotifier.state.userId, 'cust-uuid-112233');
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
      expect(authNotifier.state.userId, null);
    });

    test('updateAddress saves new address to state and database', () async {
      shouldSucceed = true;
      await authNotifier.loginWithEmail('test@phoenix.in', 'password123');

      final success = await authNotifier.updateAddress(
        address: 'No. 42 Gandhi Mandapam Road',
        city: 'Chennai',
        stateName: 'Tamil Nadu',
        pincode: '600025',
      );

      expect(success, true);
      expect(authNotifier.state.address, 'No. 42 Gandhi Mandapam Road');
      expect(authNotifier.state.city, 'Chennai');
      expect(authNotifier.state.state, 'Tamil Nadu');
      expect(authNotifier.state.pincode, '600025');
    });

    test('deleteAddress removes address from state and resets fields to null', () async {
      shouldSucceed = true;
      await authNotifier.loginWithEmail('test@phoenix.in', 'password123');

      await authNotifier.updateAddress(
        address: 'No. 42 Gandhi Mandapam Road',
        city: 'Chennai',
        stateName: 'Tamil Nadu',
        pincode: '600025',
      );
      expect(authNotifier.state.address, 'No. 42 Gandhi Mandapam Road');

      final deleteSuccess = await authNotifier.deleteAddress();
      expect(deleteSuccess, true);
      expect(authNotifier.state.address, null);
      expect(authNotifier.state.city, null);
      expect(authNotifier.state.state, null);
      expect(authNotifier.state.pincode, null);
    });
  });
}
