import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class BookingRepository {
  final ApiClient _apiClient;

  BookingRepository(this._apiClient);

  Future<BookingDto> createBooking(BookingDto booking) async {
    try {
      final payload = booking.toJson();
      print('[DEBUG] POST /bookings payload: $payload');
      final response =
          await _apiClient.post('/bookings', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return BookingDto.fromJson(response.data);
      }
      throw Exception('Unexpected status code: ${response.statusCode}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<List<BookingDto>> getBookings({int page = 1, int limit = 10, String? customerId}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (customerId != null) {
        queryParams['customerId'] = customerId;
      }
      final response = await _apiClient.get('/bookings', queryParameters: queryParams);
      if (response.statusCode == 200) {
        final list = response.data['data'] as List;
        return list.map((json) => BookingDto.fromJson(json)).toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<Map<String, dynamic>> getBookingTracking(String bookingId) async {
    try {
      final response = await _apiClient.get('/bookings/$bookingId/tracking');
      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      return {'step': 0, 'status': 'Created'};
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }
}

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return BookingRepository(apiClient);
});
