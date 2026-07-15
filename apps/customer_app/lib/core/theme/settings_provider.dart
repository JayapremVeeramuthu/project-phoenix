import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppThemeMode {
  light,
  dark,
  highContrast,
}

class AppSettings {
  final AppThemeMode themeMode;
  final bool isSeniorMode;
  final Locale locale;
  final double textScaleFactor;

  AppSettings({
    required this.themeMode,
    required this.isSeniorMode,
    required this.locale,
    required this.textScaleFactor,
  });

  AppSettings copyWith({
    AppThemeMode? themeMode,
    bool? isSeniorMode,
    Locale? locale,
    double? textScaleFactor,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      isSeniorMode: isSeniorMode ?? this.isSeniorMode,
      locale: locale ?? this.locale,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
    );
  }
}

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier()
      : super(AppSettings(
          themeMode: AppThemeMode.light,
          isSeniorMode: false,
          locale: const Locale('en'),
          textScaleFactor: 1.0,
        ));

  void toggleTheme(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void toggleSeniorMode(bool enable) {
    state = state.copyWith(
      isSeniorMode: enable,
      textScaleFactor: enable ? 1.4 : 1.0,
    );
  }

  void toggleLanguage(String languageCode) {
    state = state.copyWith(locale: Locale(languageCode));
  }

  void updateTextScale(double scale) {
    state = state.copyWith(textScaleFactor: scale);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
