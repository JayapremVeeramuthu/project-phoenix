import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/localization/app_localizations.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: ProjectPhoenixApp(),
    ),
  );
}

class ProjectPhoenixApp extends ConsumerWidget {
  const ProjectPhoenixApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Select theme mode configuration
    ThemeData appTheme;
    switch (settings.themeMode) {
      case AppThemeMode.light:
        appTheme = AppTheme.lightTheme;
        break;
      case AppThemeMode.dark:
        appTheme = AppTheme.darkTheme;
        break;
      case AppThemeMode.highContrast:
        appTheme = AppTheme.highContrastTheme;
        break;
    }

    return MaterialApp.router(
      title: 'Project Phoenix',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      routerConfig: AppRouter.router,
      locale: settings.locale,
      localizationsDelegates: const [
        AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ta'),
      ],
      // Apply custom accessibility scale factor mapping for Senior Mode
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(settings.textScaleFactor),
          ),
          child: child!,
        );
      },
    );
  }
}
