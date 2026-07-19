import 'dart:async';
import 'package:shared_api/shared_api.dart';

class PaymentService {
  final ApiClient _apiClient;

  PaymentService(this._apiClient);

  Future<Map<String, dynamic>> initiateRazorpayPayment({
    required double amount,
    required String currency,
    required String email,
    required String phone,
  }) async {
    try {
      // 1. Generate Order ID from backend
      final response = await _apiClient.post('/payments/create-order', data: {
        'amount': amount * 100, // Convert to paise for Razorpay
        'currency': currency,
      });

      final orderId = response.statusCode == 201 || response.statusCode == 200
          ? response.data['orderId'] as String
          : 'rzp_order_mock_${DateTime.now().millisecondsSinceEpoch}';

      // 2. Simulate Razorpay checkout platform modal overlay
      await Future.delayed(const Duration(seconds: 2));

      return {
        'success': true,
        'paymentId': 'pay_mock_${DateTime.now().millisecondsSinceEpoch}',
        'orderId': orderId,
        'signature': 'sig_mock_verification_hash_129031203',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }
}
