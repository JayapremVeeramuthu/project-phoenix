import 'dart:async';

class FirebaseAuthService {
  Future<void> sendOtpCode(String phoneNumber) async {
    // Simulate sending an SMS verification OTP code to user phone
    await Future.delayed(const Duration(seconds: 1));
  }

  Future<bool> verifyOtpCode(String phoneNumber, String smsCode) async {
    // Simulate verifying code against Firebase Auth servers
    await Future.delayed(const Duration(milliseconds: 800));
    return smsCode == '123456';
  }

  Future<Map<String, String>> loginWithGoogle() async {
    // Simulate Google account selection and ID token exchange
    await Future.delayed(const Duration(seconds: 2));
    return {
      'email': 'google.user@phoenix.in',
      'name': 'Google User',
      'idToken': 'google_id_token_mock_1902381203',
    };
  }
}
