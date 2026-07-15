import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  int _currentTimelineStep =
      2; // Default starting at Tech Assigned for visual preview

  final List<String> _statusLabels = [
    'Booking Created',
    'Branch Assigned',
    'Technician Assigned',
    'Technician Travelling',
    'Reached',
    'Work Started',
    'Completed',
    'Invoice Generated',
    'Feedback Pending',
  ];

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0: return Icons.receipt_long_rounded;
      case 1: return Icons.corporate_fare_rounded;
      case 2: return Icons.person_pin_rounded;
      case 3: return Icons.directions_car_rounded;
      case 4: return Icons.home_work_rounded;
      case 5: return Icons.play_circle_fill_rounded;
      case 6: return Icons.task_alt_rounded;
      case 7: return Icons.receipt_rounded;
      case 8: return Icons.rate_review_rounded;
      default: return Icons.circle;
    }
  }

  String _getMockTimestamp(int index) {
    switch (index) {
      case 0: return '10:15 AM';
      case 1: return '10:22 AM';
      case 2: return '10:30 AM';
      case 3: return '10:45 AM';
      case 4: return '11:00 AM';
      case 5: return '11:05 AM';
      case 6: return '11:30 AM';
      case 7: return '11:35 AM';
      case 8: return '11:40 AM';
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Request: ${widget.bookingId}',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: isSeniorMode ? 22 : 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                if (_currentTimelineStep < 8) {
                  _currentTimelineStep++;
                } else {
                  _currentTimelineStep = 0;
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Mock Layout
            Container(
              height: 250,
              color: Colors.blueGrey.shade100,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded,
                            size: 48, color: Colors.blueGrey.shade700),
                        const SizedBox(height: 8),
                        const Text(
                          'Google Maps Live Tracking API Ready',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Displaying routes from Branch #04 to Client site',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                  // Map Pin simulation
                  const Positioned(
                    top: 80,
                    left: 120,
                    child:
                        Icon(Icons.location_city, color: Colors.teal, size: 36),
                  ),
                  const Positioned(
                    bottom: 70,
                    right: 140,
                    child: Icon(Icons.directions_car,
                        color: Colors.orange, size: 32),
                  ),
                  const Positioned(
                    bottom: 30,
                    right: 80,
                    child: Icon(Icons.home, color: Colors.teal, size: 36),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Technician Info Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: isSeniorMode ? 32 : 24,
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .primaryContainer,
                                child: Icon(Icons.person,
                                    size: isSeniorMode ? 32 : 24),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Karthik Raja',
                                      style: TextStyle(
                                        fontSize: isSeniorMode ? 20 : 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const Text('Branch #04 - Anna Nagar'),
                                    const Row(
                                      children: [
                                        Icon(Icons.star,
                                            color: Colors.amber, size: 16),
                                        SizedBox(width: 4),
                                        Text('4.9 (142 reviews)',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
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
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Calling +91 94440 12345 (Simulated)')),
                                    );
                                  },
                                  icon: const Icon(Icons.phone),
                                  label: const Text('Call'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: Size(double.infinity,
                                        isSeniorMode ? 56 : 44),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Opening Chat (Simulated)')),
                                    );
                                  },
                                  icon: const Icon(Icons.chat_bubble_outline),
                                  label: const Text('Chat'),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: Size(double.infinity,
                                        isSeniorMode ? 56 : 44),
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

                  // ETA Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timelapse, color: Colors.teal),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Estimated Time of Arrival',
                                style: TextStyle(fontSize: 12)),
                            Text(
                              _currentTimelineStep >= 6
                                  ? 'Arrived / Completed'
                                  : '15 Minutes (1.8 km away)',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Timeline Tracker
                  Text(
                    'Service Progress Timeline',
                    style: TextStyle(
                      fontSize: isSeniorMode ? 20 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: List.generate(_statusLabels.length, (index) {
                      final isActive = index <= _currentTimelineStep;
                      final isCurrent = index == _currentTimelineStep;
                      final theme = Theme.of(context);
                      final isDarkMode = theme.brightness == Brightness.dark;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: isSeniorMode ? 40 : 32,
                                  height: isSeniorMode ? 40 : 32,
                                  decoration: BoxDecoration(
                                    color: isCurrent
                                        ? theme.colorScheme.primary
                                        : (isActive
                                            ? theme.colorScheme.primaryContainer
                                            : Colors.grey.shade200),
                                    shape: BoxShape.circle,
                                    border: isCurrent
                                        ? Border.all(
                                            color: theme.colorScheme.onPrimary,
                                            width: 2)
                                        : null,
                                    boxShadow: isCurrent
                                        ? [
                                            BoxShadow(
                                              color: theme.colorScheme.primary
                                                  .withValues(alpha: 0.4),
                                              blurRadius: 8,
                                              spreadRadius: 2,
                                            )
                                          ]
                                        : null,
                                  ),
                                  child: Icon(
                                    _getStepIcon(index),
                                    size: isSeniorMode ? 20 : 16,
                                    color: isCurrent
                                        ? theme.colorScheme.onPrimary
                                        : (isActive
                                            ? theme.colorScheme.primary
                                            : Colors.grey),
                                  ),
                                ),
                                if (index < _statusLabels.length - 1)
                                  Container(
                                    width: 2,
                                    height: 36,
                                    color: index < _currentTimelineStep
                                        ? theme.colorScheme.primary
                                        : Colors.grey.shade300,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        _statusLabels[index],
                                        style: TextStyle(
                                          fontWeight: isActive
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: isCurrent
                                              ? theme.colorScheme.primary
                                              : (isActive
                                                  ? (isDarkMode
                                                      ? Colors.white
                                                      : Colors.black87)
                                                  : Colors.grey),
                                          fontSize: isSeniorMode ? 18 : 15,
                                        ),
                                      ),
                                      if (isActive)
                                        Text(
                                          _getMockTimestamp(index),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: isCurrent
                                                ? theme.colorScheme.primary
                                                : Colors.grey.shade600,
                                            fontWeight: isCurrent
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    isCurrent
                                        ? 'Active stage in progress...'
                                        : (isActive
                                            ? 'Completed successfully.'
                                            : 'Pending previous steps.'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCurrent
                                          ? theme.colorScheme.primary
                                          : Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),

                  if (_currentTimelineStep >= 6) ...[
                    const SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: () {
                        context.go(AppRouter.home);
                      },
                      child: const Text('Return to Home'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
