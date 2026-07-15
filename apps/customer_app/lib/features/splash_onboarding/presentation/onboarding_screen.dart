import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/localization/app_localizations.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<OnboardingData> _slides = [
    OnboardingData(
      icon: Icons.home_repair_service_rounded,
      titleKey: 'onboarding_1_title',
      subtitleKey: 'onboarding_1_subtitle',
    ),
    OnboardingData(
      icon: Icons.electric_bolt_rounded,
      titleKey: 'onboarding_2_title',
      subtitleKey: 'onboarding_2_subtitle',
    ),
    OnboardingData(
      icon: Icons.wifi_off_rounded,
      titleKey: 'onboarding_3_title',
      subtitleKey: 'onboarding_3_subtitle',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (_currentIndex < _slides.length - 1)
            TextButton(
              onPressed: () => context.go(AppRouter.authSelection),
              child: Text(
                'Skip',
                style: TextStyle(
                  fontSize: isSeniorMode ? 18 : 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color:
                                Theme.of(context).colorScheme.primaryContainer,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slide.icon,
                            size: isSeniorMode ? 96 : 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 40),
                        Text(
                          localizations.translate(slide.titleKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSeniorMode ? 28 : 24,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          localizations.translate(slide.subtitleKey),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: isSeniorMode ? 18 : 16,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.7),
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Indicators & Navigation Row
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Page Indicators
                  Row(
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.only(right: 6),
                        height: 8,
                        width: _currentIndex == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  // Button
                  ElevatedButton(
                    onPressed: () {
                      if (_currentIndex < _slides.length - 1) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        context.go(AppRouter.authSelection);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(
                          isSeniorMode ? 140 : 120, isSeniorMode ? 60 : 48),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    child: Text(
                      _currentIndex == _slides.length - 1
                          ? 'Get Started'
                          : 'Next',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;

  OnboardingData({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
  });
}
