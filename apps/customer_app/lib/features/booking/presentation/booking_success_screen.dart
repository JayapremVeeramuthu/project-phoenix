import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/core/theme/app_theme.dart';

class BookingSuccessScreen extends ConsumerWidget {
  final String bookingId;
  final bool isOffline;

  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    required this.isOffline,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;
    final theme = Theme.of(context);
    final isHighContrast = theme.colorScheme.primary.value == AppTheme.hcYellow.value;
    final isDarkMode = theme.brightness == Brightness.dark;

    // Design tokens based on contrast settings
    final Color successColor = isHighContrast ? AppTheme.hcYellow : Colors.green.shade600;
    final Color successBg = isHighContrast ? Colors.black : (isDarkMode ? Colors.green.shade900.withValues(alpha: 0.3) : Colors.green.shade50);
    final Color cardBg = isHighContrast ? Colors.black : (isDarkMode ? const Color(0xFF1F2937) : Colors.white);
    final Color textMuted = isHighContrast ? Colors.white : Colors.grey.shade600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirmation'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Success Mark
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isOffline
                        ? (isHighContrast ? Colors.black : Colors.orange.shade50)
                        : successBg,
                    shape: BoxShape.circle,
                    border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: Icon(
                    isOffline ? Icons.cloud_off_rounded : Icons.check_circle_outline,
                    size: isSeniorMode ? 80 : 64,
                    color: isOffline ? Colors.orange : successColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                isOffline ? 'Saved Offline' : 'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSeniorMode ? 30 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                isOffline
                    ? 'No internet connection detected. The booking has been queued locally in SQLite and will sync once network is online.'
                    : 'Your request has been successfully transmitted. Allocations will follow shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textMuted,
                  fontSize: isSeniorMode ? 17 : 14,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 28),

              // Booking details card
              Card(
                color: cardBg,
                elevation: isHighContrast ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Booking ID', style: TextStyle(color: textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        bookingId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 22 : 18,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('ETA Response'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '45 Mins',
                              style: TextStyle(
                                color: Colors.teal.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Warranty Status'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '1-Year Active',
                              style: TextStyle(
                                color: Colors.blue.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Assigned Technician Profile
              Card(
                color: cardBg,
                elevation: isHighContrast ? 0 : 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Assigned Technician',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 18 : 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: isSeniorMode ? 28 : 24,
                            backgroundColor: theme.colorScheme.primaryContainer,
                            child: Icon(Icons.person, size: isSeniorMode ? 28 : 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Karthik Raja',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSeniorMode ? 18 : 15,
                                  ),
                                ),
                                const Text('Branch #04 - Anna Nagar'),
                                const Row(
                                  children: [
                                    Icon(Icons.star, color: Colors.amber, size: 14),
                                    SizedBox(width: 4),
                                    Text('4.9 (142 reviews)', style: TextStyle(fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Calling Support...')),
                                );
                              },
                              icon: const Icon(Icons.phone),
                              label: const Text('Call'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, isSeniorMode ? 52 : 44),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening WhatsApp support helper...')),
                                );
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('WhatsApp'),
                              style: OutlinedButton.styleFrom(
                                minimumSize: Size(double.infinity, isSeniorMode ? 52 : 44),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Detailed Next Steps Timeline
              Text(
                'Next Steps',
                style: TextStyle(
                  fontSize: isSeniorMode ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStepItem('1', 'Technician Dispatch', 'Technician mapping initialized and route maps drawn.', isSeniorMode, theme),
              _buildStepItem('2', 'Pre-service Diagnosis', 'Technician inspects structural links and inputs.', isSeniorMode, theme),
              _buildStepItem('3', 'Standard Job Execution', 'Fixing and testing complete with standard checklist.', isSeniorMode, theme),
              _buildStepItem('4', 'Parts Warranty Active', 'Digital invoice and warranty files locked for active service.', isSeniorMode, theme),

              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton(
                onPressed: () {
                  context.go('${AppRouter.tracking}/$bookingId');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSeniorMode ? 60 : 52),
                ),
                child: const Text('Track Request Timeline'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  context.go(AppRouter.home);
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: Size(double.infinity, isSeniorMode ? 60 : 52),
                ),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(String num, String title, String subtitle, bool isSeniorMode, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                num,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSeniorMode ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
