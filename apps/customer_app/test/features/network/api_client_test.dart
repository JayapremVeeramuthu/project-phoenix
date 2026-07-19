import 'package:flutter_test/flutter_test.dart';
import 'package:shared_api/shared_api.dart';
import 'package:dio/dio.dart';

void main() {
  group('ApiClient and ApiException Tests', () {
    test('ApiClient initialization with correct baseUrl', () {
      final client = ApiClient(baseUrl: 'https://test-api.phoenix.in/api/v1');
      expect(client.dio.options.baseUrl, 'https://test-api.phoenix.in/api/v1');
    });

    test('ApiException mapping for BadRequest', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 400,
          data: {'message': 'Bad Request Parameters'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.badRequest);
      expect(apiException.message, 'Bad Request Parameters');
      expect(apiException.statusCode, 400);
    });

    test('ApiException mapping for Unauthorized', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        response: Response(
          requestOptions: RequestOptions(path: '/test'),
          statusCode: 401,
          data: {'message': 'Unauthorized request'},
        ),
        type: DioExceptionType.badResponse,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.unauthorized);
      expect(apiException.statusCode, 401);
    });

    test('ApiException mapping for connection timeout', () {
      final dioException = DioException(
        requestOptions: RequestOptions(path: '/test'),
        type: DioExceptionType.connectionTimeout,
      );

      final apiException = ApiException.fromDioException(dioException);
      expect(apiException.type, ApiExceptionType.timeout);
    });
  });
}
