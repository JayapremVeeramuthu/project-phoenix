import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/localization/app_localizations.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class EmailLoginScreen extends ConsumerStatefulWidget {
  const EmailLoginScreen({super.key});

  @override
  ConsumerState<EmailLoginScreen> createState() => _EmailLoginScreenState();
}

class _EmailLoginScreenState extends ConsumerState<EmailLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isRegisterMode = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      bool success = false;
      if (_isRegisterMode) {
        success = await ref.read(authNotifierProvider.notifier).registerWithEmail(
              email: _emailController.text.trim(),
              phoneNumber: _phoneController.text.trim(),
              name: _nameController.text.trim(),
              password: _passwordController.text,
            );
      } else {
        success = await ref.read(authNotifierProvider.notifier).loginWithEmail(
              _emailController.text.trim(),
              _passwordController.text,
            );
      }

      if (success && mounted) {
        context.go(AppRouter.home);
      }
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
        title: Text(_isRegisterMode ? 'Create Account' : localizations.translate('btn_login')),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 10),
                Text(
                  _isRegisterMode ? 'Join Project Phoenix' : localizations.translate('login_title'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 26 : 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRegisterMode 
                      ? 'Create an account to track warranties and request smart dispatches.'
                      : localizations.translate('login_subtitle'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 16 : 14,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),

                // Mode Selector Toggle
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isRegisterMode = false),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isRegisterMode ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Login',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isRegisterMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => setState(() => _isRegisterMode = true),
                          child: Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isRegisterMode ? Theme.of(context).colorScheme.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isRegisterMode ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                if (_isRegisterMode) ...[
                  // Name Field
                  Text(
                    'Full Name',
                    style: TextStyle(
                      fontSize: isSeniorMode ? 18 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                    decoration: const InputDecoration(
                      hintText: 'Enter your full name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Name is required' : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone Number Field
                  Text(
                    'Phone Number',
                    style: TextStyle(
                      fontSize: isSeniorMode ? 18 : 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                    decoration: const InputDecoration(
                      hintText: '+91 99999 99999',
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                    validator: (val) => val == null || val.trim().isEmpty ? 'Phone number is required' : null,
                  ),
                  const SizedBox(height: 16),
                ],

                // Email Field
                Text(
                  localizations.translate('email_label'),
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
                  decoration: InputDecoration(
                    hintText: localizations.translate('email_hint'),
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return localizations.translate('error_required');
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                      return localizations.translate('error_email');
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Password Field
                Text(
                  localizations.translate('password_label'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 18 : 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                  decoration: InputDecoration(
                    hintText: localizations.translate('password_hint'),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.translate('error_required');
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    if (_isRegisterMode) {
                      // Strong validation check: requires number and special character
                      if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[!@#\$&*~]).{8,}$').hasMatch(value)) {
                        return 'Must include upper case, number & special char';
                      }
                    }
                    return null;
                  },
                ),

                if (!_isRegisterMode) ...[
                  const SizedBox(height: 8),
                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRouter.forgotPassword),
                      child: Text(
                        localizations.translate('forgot_pwd'),
                        style: TextStyle(
                          fontSize: isSeniorMode ? 16 : 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Display Error State
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

                // Submit Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isRegisterMode ? 'Sign Up' : localizations.translate('btn_login'),
                          style: TextStyle(fontSize: isSeniorMode ? 18 : 16),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
