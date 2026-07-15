import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'App Settings',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSeniorMode ? 24 : 20,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Theme Options
          _buildSectionHeader('Appearance', theme),
          Card(
            child: Column(
              children: [
                RadioListTile<AppThemeMode>(
                  title: Text('Light Theme',
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15)),
                  subtitle: const Text('Clean white background'),
                  secondary: const Icon(Icons.light_mode_rounded),
                  value: AppThemeMode.light,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).toggleTheme(val);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<AppThemeMode>(
                  title: Text('Dark Theme',
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15)),
                  subtitle: const Text('Reduced eye strain in low light'),
                  secondary: const Icon(Icons.dark_mode_rounded),
                  value: AppThemeMode.dark,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).toggleTheme(val);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<AppThemeMode>(
                  title: Text('High Contrast',
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15)),
                  subtitle: const Text('Maximum visibility for impaired vision'),
                  secondary: const Icon(Icons.contrast_rounded),
                  value: AppThemeMode.highContrast,
                  groupValue: settings.themeMode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).toggleTheme(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Language Options
          _buildSectionHeader('Language / மொழி', theme),
          Card(
            child: Column(
              children: [
                RadioListTile<String>(
                  title: Text('English',
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15)),
                  secondary: const Text('EN',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  value: 'en',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).toggleLanguage(val);
                    }
                  },
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                RadioListTile<String>(
                  title: Text('தமிழ் (Tamil)',
                      style: TextStyle(fontSize: isSeniorMode ? 18 : 15)),
                  secondary: const Text('த',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  value: 'ta',
                  groupValue: settings.locale.languageCode,
                  onChanged: (val) {
                    if (val != null) {
                      ref.read(settingsProvider.notifier).toggleLanguage(val);
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Accessibility options
          _buildSectionHeader('Accessibility', theme),
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.elderly_rounded,
                color: isSeniorMode
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                size: 28,
              ),
              title: Text(
                'Senior Citizen Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSeniorMode ? 18 : 15,
                ),
              ),
              subtitle: const Text(
                  'Larger text, bigger buttons, simplified navigation'),
              value: settings.isSeniorMode,
              onChanged: (val) {
                ref.read(settingsProvider.notifier).toggleSeniorMode(val);
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.text_fields_rounded,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Text(
                        'Text Size Preview',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 18 : 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This text demonstrates how text will appear with the current settings. '
                    'Senior Citizen Mode enlarges all text throughout the app for better readability.',
                    style: TextStyle(
                      fontSize: isSeniorMode ? 16 : 14,
                      height: 1.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                Text(
                  'Project Phoenix Enterprise',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Version 2.0.0 • Build 2026.07',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}
