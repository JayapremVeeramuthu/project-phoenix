import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/app_theme.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    debugPrint('Splash started');
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    Timer? timeoutTimer;
    bool isCompleted = false;

    debugPrint('Initialization started');
    try {
      // Create a safety timeout timer of 5 seconds
      timeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!isCompleted && mounted) {
          debugPrint('Navigating to Login (Timeout Fallback)');
          context.go(AppRouter.authSelection);
        }
      });

      // Simulate core system loading (2.5 seconds)
      await Future.delayed(const Duration(milliseconds: 2500));
      isCompleted = true;
      timeoutTimer.cancel(); // Cancel the safety timeout timer

      debugPrint('Initialization completed');

      if (!mounted) return;

      // Check if the user is authenticated
      final authState = ref.read(authNotifierProvider);
      const storage = FlutterSecureStorage();
      final accessToken = await storage.read(key: 'access_token');
      final refreshToken = await storage.read(key: 'refresh_token');

      if (authState.isAuthenticated || (accessToken != null && refreshToken != null)) {
        debugPrint('Navigating to Home');
        context.go(AppRouter.home);
      } else {
        debugPrint('Navigating to Login');
        context.go(AppRouter.authSelection);
      }
    } catch (e) {
      isCompleted = true;
      timeoutTimer?.cancel();
      if (mounted) {
        debugPrint('Navigating to Login (Error Fallback)');
        context.go(AppRouter.authSelection);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryTeal,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Premium Emblem logo made from Material Icons
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2), width: 2),
                ),
                child: const Icon(
                  Icons
                      .local_fire_department_rounded, // Represents the Phoenix bird
                  size: 72,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'PROJECT PHOENIX',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Enterprise Field Service Platform',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
