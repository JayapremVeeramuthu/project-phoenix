import 'package:dio/dio.dart';

enum ApiExceptionType {
  network,
  timeout,
  badRequest,
  unauthorized,
  forbidden,
  notFound,
  serverError,
  unknown,
}

class ApiException implements Exception {
  final ApiExceptionType type;
  final String message;
  final int? statusCode;

  ApiException({
    required this.type,
    required this.message,
    this.statusCode,
  });

  @override
  String toString() => 'ApiException [$type] ($statusCode): $message';

  factory ApiException.fromDioException(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return ApiException(
        type: ApiExceptionType.timeout,
        message: 'Connection timed out. Please try again.',
      );
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.unknown) {
      if (error.message?.contains('SocketException') ?? false) {
        return ApiException(
          type: ApiExceptionType.network,
          message:
              'No internet connection detected. Please verify your network.',
        );
      }
    }

    final response = error.response;
    if (response != null) {
      final code = response.statusCode;
      final serverMessage =
          response.data is Map ? response.data['message'] : null;
      final msg = serverMessage ?? 'Server error occurred.';

      switch (code) {
        case 400:
          return ApiException(
              type: ApiExceptionType.badRequest,
              message: msg,
              statusCode: code);
        case 401:
          return ApiException(
              type: ApiExceptionType.unauthorized,
              message: msg,
              statusCode: code);
        case 403:
          return ApiException(
              type: ApiExceptionType.forbidden, message: msg, statusCode: code);
        case 404:
          return ApiException(
              type: ApiExceptionType.notFound, message: msg, statusCode: code);
        default:
          if (code != null && code >= 500) {
            return ApiException(
                type: ApiExceptionType.serverError,
                message: msg,
                statusCode: code);
          }
          return ApiException(
              type: ApiExceptionType.unknown, message: msg, statusCode: code);
      }
    }

    return ApiException(
      type: ApiExceptionType.unknown,
      message: error.message ?? 'An unexpected network error occurred.',
    );
  }
}
