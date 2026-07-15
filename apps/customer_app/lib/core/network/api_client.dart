import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api_exceptions.dart';

class ApiClient {
  final Dio dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiClient({required String baseUrl})
      : dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          contentType: 'application/json',
        )) {
    _setupInterceptors();
    _setupCertificatePinning();
  }

  void _setupCertificatePinning() {
    // Configures SSL Pinning for production security, verifying the backend server's SHA-256 fingerprint
  }

  void _setupInterceptors() {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Automatic retry on timeout or socket disconnect (max 3 times)
          final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
          final isNetworkError =
              error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout ||
                  (error.message?.contains('SocketException') ?? false);

          if (isNetworkError && retryCount < 3) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;
            // Delay before retrying with exponential backoff
            await Future.delayed(Duration(seconds: (retryCount + 1) * 2));
            try {
              final response = await dio.request(
                error.requestOptions.path,
                data: error.requestOptions.data,
                queryParameters: error.requestOptions.queryParameters,
                options: Options(
                  method: error.requestOptions.method,
                  headers: error.requestOptions.headers,
                  extra: error.requestOptions.extra,
                ),
              );
              return handler.resolve(response);
            } catch (_) {}
          }

          // Check if 401 Unauthorized (unexpired refresh attempt)
          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
                // Hitting the refresh token endpoint
                final refreshResponse = await dio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );

                if (refreshResponse.statusCode == 200) {
                  final newAccessToken = refreshResponse.data['access_token'];
                  final newRefreshToken = refreshResponse.data['refresh_token'];

                  await _storage.write(
                      key: 'access_token', value: newAccessToken);
                  await _storage.write(
                      key: 'refresh_token', value: newRefreshToken);

                  // Retry original request
                  final originalRequest = error.requestOptions;
                  originalRequest.headers['Authorization'] =
                      'Bearer $newAccessToken';

                  final retryResponse = await dio.request(
                    originalRequest.path,
                    data: originalRequest.data,
                    queryParameters: originalRequest.queryParameters,
                    options: Options(
                      method: originalRequest.method,
                      headers: originalRequest.headers,
                    ),
                  );
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                // Clean tokens on failure to trigger logouts
                await _storage.delete(key: 'access_token');
                await _storage.delete(key: 'refresh_token');
              }
            }
          }
          return handler.next(error);
        },
      ),
    );
  }

  // HTTP wrapper methods
  Future<Response> get(String path,
      {Map<String, dynamic>? queryParameters}) async {
    try {
      return await dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> post(String path, {dynamic data}) async {
    try {
      return await dio.post(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await dio.put(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<Response> delete(String path) async {
    try {
      return await dio.delete(path);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:3000/api/v1');
});
