import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/localization/app_localizations.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _codeSent = false;
  String _selectedCountryCode = '+91';

  // Timer states
  Timer? _countdownTimer;
  int _secondsRemaining = 30;
  bool _canResend = false;
  int _resendAttempts = 0;

  final List<Map<String, String>> _countries = [
    {'name': 'India', 'code': '+91', 'flag': '🇮🇳'},
    {'name': 'United States', 'code': '+1', 'flag': '🇺🇸'},
    {'name': 'United Kingdom', 'code': '+44', 'flag': '🇬🇧'},
    {'name': 'United Arab Emirates', 'code': '+971', 'flag': '🇦🇪'},
  ];

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() {
      _secondsRemaining = 30;
      _canResend = false;
    });
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining == 0) {
        setState(() {
          _canResend = true;
          _countdownTimer?.cancel();
        });
      } else {
        setState(() {
          _secondsRemaining--;
        });
      }
    });
  }

  Future<void> _sendOtp() async {
    if (_formKey.currentState!.validate()) {
      if (_resendAttempts >= 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum resend attempts reached (3/3)'), backgroundColor: Colors.red),
        );
        return;
      }

      final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
      await ref.read(authNotifierProvider.notifier).sendOtp(fullPhone);
      
      setState(() {
        _codeSent = true;
        if (_codeSent) {
          _resendAttempts++;
        }
      });
      _startTimer();

      // Represent Auto OTP detection / auto verification simulation
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() {
            _otpController.text = '123456';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Auto-verified SMS code: 123456'), backgroundColor: Colors.green),
          );
        }
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendAttempts >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum resend attempts reached (3/3)'), backgroundColor: Colors.red),
      );
      return;
    }

    final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
    await ref.read(authNotifierProvider.notifier).resendOtp(fullPhone);

    setState(() {
      _resendAttempts++;
    });
    _startTimer();
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length == 6) {
      final fullPhone = '$_selectedCountryCode${_phoneController.text.trim()}';
      final success = await ref.read(authNotifierProvider.notifier).verifyOtp(
            fullPhone,
            _otpController.text.trim(),
          );
      if (success && mounted) {
        context.go(AppRouter.home);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit verification code')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;
    final authState = ref.watch(authNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.translate('btn_send_otp')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text(
                  _codeSent
                      ? localizations.translate('otp_label')
                      : localizations.translate('phone_label'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _codeSent
                      ? 'Enter the 6-digit verification code sent to $_selectedCountryCode ${_phoneController.text}'
                      : 'We will send a 6-digit OTP code to verify your mobile number',
                  style: TextStyle(
                    fontSize: isSeniorMode ? 16 : 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 32),
                if (!_codeSent) ...[
                  // Phone Input & Country Selector
                  Text(
                    localizations.translate('phone_label'),
                    style: TextStyle(
                      fontSize: isSeniorMode ? 18 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Country Picker dropdown menu representation
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCountryCode,
                            items: _countries.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['code'],
                                child: Text('${c['flag']} ${c['code']}'),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() {
                                  _selectedCountryCode = val;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                          decoration: InputDecoration(
                            hintText: localizations.translate('phone_hint'),
                            prefixIcon: const Icon(Icons.phone),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return localizations.translate('error_required');
                            }
                            if (value.trim().length < 8 || int.tryParse(value.trim()) == null) {
                              return localizations.translate('error_phone');
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _sendOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(localizations.translate('btn_send_otp')),
                  ),
                ] else ...[
                  // OTP Code Input
                  Text(
                    localizations.translate('otp_label'),
                    style: TextStyle(
                      fontSize: isSeniorMode ? 18 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    maxLength: 6,
                    style: TextStyle(
                      fontSize: isSeniorMode ? 24 : 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      hintStyle: TextStyle(
                        fontSize: isSeniorMode ? 24 : 20,
                        letterSpacing: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Countdown timer & Resend button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _canResend ? 'Did not receive code?' : 'Resend code in ${_secondsRemaining}s',
                        style: TextStyle(fontSize: isSeniorMode ? 14 : 12, color: Colors.black54),
                      ),
                      TextButton(
                        onPressed: _canResend ? _resendOtp : null,
                        child: Text(
                          'Resend OTP (${_resendAttempts}/3)',
                          style: TextStyle(
                            color: _canResend ? Theme.of(context).colorScheme.primary : Colors.grey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  if (authState.error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        authState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                          fontSize: isSeniorMode ? 16 : 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  ElevatedButton(
                    onPressed: authState.isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                    ),
                    child: authState.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(localizations.translate('btn_verify_otp')),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        _codeSent = false;
                        _otpController.clear();
                        _resendAttempts = 0;
                      });
                    },
                    child: const Text('Change Phone Number'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
