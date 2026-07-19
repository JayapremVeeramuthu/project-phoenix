import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_api/shared_api.dart';

class NotificationRepository {
  final ApiClient _apiClient;

  NotificationRepository(this._apiClient);

  Future<void> registerFcmToken(String customerId, String token) async {
    try {
      await _apiClient.post('/notifications/register-token', data: {
        'customerId': customerId,
        'fcmToken': token,
        'platform': 'flutter_mobile',
      });
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final response = await _apiClient.get('/notifications');
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((json) => json as Map<String, dynamic>).toList();
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
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationRepository(apiClient);
});
