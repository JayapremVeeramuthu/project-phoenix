import 'dart:async';

class FcmService {
  Future<void> configurePushNotifications() async {
    // Simulate push listeners (foreground, background, and clicked messaging handlers)
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Future<String> fetchFcmToken() async {
    // Return mock FCM push token for testing
    return 'fcm_token_device_mock_99221100aa';
  }
}
