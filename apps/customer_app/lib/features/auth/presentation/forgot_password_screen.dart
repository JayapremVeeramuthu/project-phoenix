import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _submittedEmail = false;
  bool _resetComplete = false;
  String? _dispatchedToken;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _requestLink() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .forgotPassword(_emailController.text.trim());
      if (success) {
        setState(() {
          _submittedEmail = true;
          // Set target mock token locally for testing reset flows directly
          _dispatchedToken = 'phoenix_reset_token';
          _tokenController.text = _dispatchedToken!;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to request reset link. Email not found.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      final success = await ref
          .read(authNotifierProvider.notifier)
          .resetPassword(_tokenController.text.trim(), _passwordController.text);
      if (success) {
        setState(() {
          _resetComplete = true;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reset failed. Invalid or expired token.'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorMode = ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final authState = ref.watch(authNotifierProvider);

    if (_resetComplete) {
      return Scaffold(
        appBar: AppBar(title: const Text('Reset Complete')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, size: 64, color: Colors.white),
                ),
                const SizedBox(height: 24),
                Text(
                  'Password Updated',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isSeniorMode ? 24 : 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  'Your password has been successfully reset. You can now login using your new credentials.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: isSeniorMode ? 16 : 14, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => context.pop(),
                  child: const Text('Back to Login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: _submittedEmail
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Enter Reset Token',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 26 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'We sent a reset token code to your email. Enter it below along with your new password.',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 16 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Reset Token Input
                      Text(
                        'Reset Token Code',
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _tokenController,
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                        decoration: const InputDecoration(
                          hintText: 'Enter reset code',
                          prefixIcon: Icon(Icons.vpn_key_outlined),
                        ),
                        validator: (value) => value == null || value.trim().isEmpty ? 'Token code is required' : null,
                      ),
                      const SizedBox(height: 20),

                      // New Password Input
                      Text(
                        'New Password',
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                        decoration: const InputDecoration(
                          hintText: 'Enter new password',
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          if (value.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),

                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _resetPassword,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                        ),
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Update Password'),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 20),
                      Text(
                        'Forgot Password',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 26 : 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter your registered email address and we will send a secure link to reset your account password.',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 16 : 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      Text(
                        'Email Address',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 18 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                        decoration: const InputDecoration(
                          hintText: 'Enter your email address',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email address is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: authState.isLoading ? null : _requestLink,
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                        ),
                        child: authState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Send Reset Link'),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
