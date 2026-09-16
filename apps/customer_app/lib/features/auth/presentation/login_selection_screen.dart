import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/localization/app_localizations.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class LoginSelectionScreen extends ConsumerWidget {
  const LoginSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    debugPrint('Login screen built');
    final localizations = AppLocalizations.of(context);
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              // Brand Branding Header
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.local_fire_department_rounded,
                    size: isSeniorMode ? 72 : 60,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                localizations.translate('login_title'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSeniorMode ? 28 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                localizations.translate('login_subtitle'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSeniorMode ? 16 : 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const Spacer(),

              // Error notification if present
              if (ref.watch(authNotifierProvider).error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ref.watch(authNotifierProvider).error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                      fontSize: isSeniorMode ? 16 : 14,
                    ),
                  ),
                ),
              ],

              // Google Sign-In Action
              OutlinedButton.icon(
                onPressed: ref.watch(authNotifierProvider).isLoading
                    ? null
                    : () async {
                        final success = await ref
                            .read(authNotifierProvider.notifier)
                            .loginWithGoogle();
                        if (success && context.mounted) {
                          context.go(AppRouter.home);
                        }
                      },
                icon: const Icon(Icons.account_circle_outlined, size: 24),
                label: Text(
                  localizations.translate('btn_google'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 18 : 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Primary Action: Email Login & Register
              ElevatedButton.icon(
                onPressed: () => context.push(AppRouter.emailLogin),
                icon: const Icon(Icons.email_outlined),
                label: Text(localizations.translate('btn_login')),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSeniorMode ? 64 : 52),
                ),
              ),
              const SizedBox(height: 24),

              // Guest Browsing Toggle
              TextButton(
                onPressed: () {
                  ref.read(authNotifierProvider.notifier).loginAsGuest();
                  context.go(AppRouter.home);
                },
                child: Text(
                  localizations.translate('btn_guest'),
                  style: TextStyle(
                    fontSize: isSeniorMode ? 18 : 16,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
