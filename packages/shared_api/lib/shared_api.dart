import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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
      final isNetwork = error.type == DioExceptionType.connectionError ||
          (error.message?.contains('SocketException') ?? false) ||
          (error.message?.contains('XMLHttpRequest') ?? false) ||
          error.response == null;
      if (isNetwork) {
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
      dynamic responseData = response.data;
      if (responseData is String) {
        try {
          responseData = jsonDecode(responseData);
        } catch (_) {}
      }
      final serverMessage =
          responseData is Map ? responseData['message'] : null;
      final String msg;
      if (serverMessage is List) {
        msg = serverMessage.join(', ');
      } else {
        msg = (serverMessage as String?) ?? 'Server error occurred.';
      }

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
          final retryCount = error.requestOptions.extra['retry_count'] ?? 0;
          final isNetworkError =
              error.type == DioExceptionType.connectionError ||
                  error.type == DioExceptionType.connectionTimeout ||
                  (error.message?.contains('SocketException') ?? false);

          if (isNetworkError && retryCount < 3) {
            error.requestOptions.extra['retry_count'] = retryCount + 1;
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

          if (error.response?.statusCode == 401 &&
              !error.requestOptions.path.contains('/auth/refresh')) {
            final refreshToken = await _storage.read(key: 'refresh_token');
            if (refreshToken != null) {
              try {
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

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await dio.patch(path, data: data);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(baseUrl: 'http://localhost:3000/api/v1');
});

class SocketService {
  final String _url;
  io.Socket? _socket;
  final Set<String> _rooms = {};
  final _connectionController = StreamController<bool>.broadcast();
  final _bookingCreatedController = StreamController<Map<String, dynamic>>.broadcast();
  final _bookingAcceptedController = StreamController<Map<String, dynamic>>.broadcast();
  final _bookingStatusUpdatedController = StreamController<Map<String, dynamic>>.broadcast();

  SocketService({required String url}) : _url = url;

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get bookingCreatedStream => _bookingCreatedController.stream;
  Stream<Map<String, dynamic>> get bookingAcceptedStream => _bookingAcceptedController.stream;
  Stream<Map<String, dynamic>> get bookingStatusUpdatedStream => _bookingStatusUpdatedController.stream;

  bool get isConnected => _socket?.connected ?? false;

  Map<String, dynamic>? _toMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    // Flutter web: JS interop objects may not pass `is Map` checks.
    // Try round-tripping through JSON to convert.
    try {
      final encoded = jsonEncode(data);
      final decoded = jsonDecode(encoded);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
    return null;
  }

  void connect() {
    if (_socket != null) {
      print('[SocketService] connect() called, but socket is already initialized. isConnected: $isConnected');
      return;
    }

    print('[SocketService] Initializing socket connection to $_url...');
    _socket = io.io(
      _url,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableReconnection()
          .build(),
    );

    _socket!.onConnect((_) {
      print('[SocketService] ===== SOCKET CONNECTED SUCCESSFULLY TO $_url =====');
      _connectionController.add(true);
      for (final room in _rooms) {
        _socket!.emit('join_room', {'room': room});
        print('[SocketService] Emitted join_room on connect for: $room');
      }
    });

    _socket!.onConnectError((err) {
      print('[SocketService] ❌ Socket Connection Error: $err');
    });

    _socket!.onDisconnect((_) {
      print('[SocketService] ⚠️ Socket Disconnected from $_url');
      _connectionController.add(false);
    });

    _socket!.onError((err) {
      print('[SocketService] ❌ General Socket Error: $err');
    });

    _socket!.on('booking_created', (data) {
      print('[SocketService] ===== booking_created RAW EVENT RECEIVED =====');
      print('[SocketService] Raw payload: $data');
      final map = _toMap(data);
      if (map != null) {
        print('[SocketService] parsed event Map: $map');
        _bookingCreatedController.add(map);
      } else {
        print('[SocketService] ❌ ERROR: booking_created could not be parsed to Map. data=$data');
      }
    });

    _socket!.on('booking_accepted', (data) {
      print('[SocketService] ===== booking_accepted RAW EVENT RECEIVED =====');
      print('[SocketService] Raw payload: $data');
      final map = _toMap(data);
      if (map != null) {
        _bookingAcceptedController.add(map);
      } else {
        print('[SocketService] ❌ ERROR: booking_accepted could not be parsed to Map.');
      }
    });

    _socket!.on('booking_status_updated', (data) {
      print('[SocketService] ===== booking_status_updated RAW EVENT RECEIVED =====');
      print('[SocketService] Raw payload: $data');
      final map = _toMap(data);
      if (map != null) {
        _bookingStatusUpdatedController.add(map);
      } else {
        print('[SocketService] ❌ ERROR: booking_status_updated could not be parsed to Map.');
      }
    });

    _socket!.connect();
  }

  void joinRoom(String room) {
    _rooms.add(room);
    print('[SocketService] joinRoom called for room: "$room". isConnected: $isConnected');
    if (_socket != null && isConnected) {
      _socket!.emit('join_room', {'room': room});
      print('[SocketService] Emitted join_room directly for room: "$room"');
    }
  }

  void leaveRoom(String room) {
    _rooms.remove(room);
    print('[SocketService] leaveRoom called for room: "$room". isConnected: $isConnected');
    if (_socket != null && isConnected) {
      _socket!.emit('leave_room', {'room': room});
      print('[SocketService] Emitted leave_room directly for room: "$room"');
    }
  }

  void disconnect() {
    print('[SocketService] disconnect called. Clearing rooms: $_rooms');
    _rooms.clear();
    _socket?.disconnect();
    _socket = null;
  }
}

final socketServiceProvider = Provider<SocketService>((ref) {
  return SocketService(url: 'http://localhost:3000');
});
