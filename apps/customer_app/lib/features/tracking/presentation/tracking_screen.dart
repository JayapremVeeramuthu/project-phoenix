import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:shared_api/shared_api.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String bookingId;

  const TrackingScreen({
    super.key,
    required this.bookingId,
  });

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen>
    with SingleTickerProviderStateMixin {
  int _currentTimelineStep = 0;
  StreamSubscription? _statusSubscription;

  // Technician data – null until assigned
  String? _technicianName;
  String? _technicianPhone;
  String? _technicianBranch;
  String? _technicianDisplayId;

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchBookingDetails();
      final socket = ref.read(socketServiceProvider);
      socket.connect();
      socket.joinRoom('booking_${widget.bookingId}');
      _statusSubscription = socket.bookingStatusUpdatedStream.listen((event) {
        if (mounted && event['bookingId'] == widget.bookingId) {
          final status = event['status'] as String?;
          final techName = event['technicianName'] as String?;
          final techPhone = event['technicianPhone'] as String?;
          final techBranch = event['technicianBranch'] as String?;
          final techId = event['technicianId'] as String?;

          setState(() {
            if (techName != null) _technicianName = techName;
            if (techPhone != null) _technicianPhone = techPhone;
            if (techBranch != null) _technicianBranch = techBranch;
            if (techId != null) _technicianDisplayId = techId;

            _updateTimelineStep(status);
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Status update: ${_statusLabels[_currentTimelineStep]}')),
          );
        }
      });
    });
  }

  void _updateTimelineStep(String? status) {
    if (status == null) return;
    if (status == 'PENDING' || status == 'WAITING_FOR_TECHNICIAN') {
      _currentTimelineStep = 0;
    } else if (status == 'ASSIGNED' || status == 'TECHNICIAN_ASSIGNED') {
      _currentTimelineStep = 1;
    } else if (status == 'TRAVELLING') {
      _currentTimelineStep = 2;
    } else if (status == 'REACHED') {
      _currentTimelineStep = 3;
    } else if (status == 'IN_PROGRESS') {
      _currentTimelineStep = 4;
    } else if (status == 'PAYMENT_PENDING') {
      _currentTimelineStep = 5;
    } else if (status == 'COMPLETED') {
      _currentTimelineStep = 5;
    }
  }

  Future<void> fetchBookingDetails() async {
    try {
      final response = await ref.read(apiClientProvider).get('/bookings/${widget.bookingId}/tracking');
      if (response.statusCode == 200 && mounted) {
        final data = response.data;
        final String status = data['currentStatus'];
        final String? techName = data['technicianName'];
        final String? techPhone = data['technicianPhone'];
        final String? techBranch = data['technicianBranch'];
        final String? techId = data['technicianId'];

        setState(() {
          _technicianName = techName;
          _technicianPhone = techPhone;
          _technicianBranch = techBranch;
          _technicianDisplayId = techId;
          _updateTimelineStep(status);
        });
      }
    } catch (_) {}
  }

  bool get _isTechnicianAssigned => _technicianName != null && _currentTimelineStep >= 1;

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _pulseController.dispose();
    ref.read(socketServiceProvider).leaveRoom('booking_${widget.bookingId}');
    super.dispose();
  }

  final List<String> _statusLabels = [
    'Waiting for Technician',
    'Technician Assigned',
    'Technician Travelling',
    'Technician Reached',
    'Work In Progress',
    'Completed',
  ];

  IconData _getStepIcon(int index) {
    switch (index) {
      case 0: return Icons.person_search_rounded;
      case 1: return Icons.person_pin_rounded;
      case 2: return Icons.directions_car_rounded;
      case 3: return Icons.home_work_rounded;
      case 4: return Icons.play_circle_fill_rounded;
      case 5: return Icons.task_alt_rounded;
      default: return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final isSeniorMode = settings.isSeniorMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Track Request',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: isSeniorMode ? 22 : 18),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Map Placeholder
            Container(
              height: 200,
              color: Colors.blueGrey.shade100,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map_rounded,
                        size: 48, color: Colors.blueGrey.shade700),
                    const SizedBox(height: 8),
                    const Text(
                      'Live Tracking',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      _isTechnicianAssigned
                          ? 'Tracking ${_technicianName ?? "technician"}'
                          : 'Awaiting technician assignment...',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Technician Info Card – conditional rendering
                  _isTechnicianAssigned
                      ? _buildAssignedTechnicianCard(isSeniorMode, context)
                      : _buildSearchingCard(isSeniorMode, context),
                  const SizedBox(height: 16),

                  // Status Banner
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isTechnicianAssigned
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isTechnicianAssigned
                              ? Icons.timelapse
                              : Icons.hourglass_top_rounded,
                          color: _isTechnicianAssigned
                              ? Colors.teal
                              : Colors.orange.shade700,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isTechnicianAssigned
                                    ? 'Current Status'
                                    : 'Booking Status',
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                _statusLabels[_currentTimelineStep],
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
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

                  if (_currentTimelineStep >= 5) ...[
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

  /// Pulsing searching card while waiting for a technician
  Widget _buildSearchingCard(bool isSeniorMode, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 16.0),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.4 + (_pulseController.value * 0.6),
                  child: Icon(
                    Icons.person_search_rounded,
                    size: isSeniorMode ? 48 : 40,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            Text(
              'Searching for an available technician...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSeniorMode ? 17 : 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be notified once a technician accepts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// Real technician info card – only shown after acceptance
  Widget _buildAssignedTechnicianCard(bool isSeniorMode, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: isSeniorMode ? 32 : 24,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(Icons.person, size: isSeniorMode ? 32 : 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _technicianName ?? '',
                        style: TextStyle(
                          fontSize: isSeniorMode ? 20 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_technicianDisplayId != null && _technicianDisplayId!.isNotEmpty)
                        Text(
                          'ID: $_technicianDisplayId',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      if (_technicianBranch != null && _technicianBranch!.isNotEmpty)
                        Text(_technicianBranch!),
                    ],
                  ),
                ),
              ],
            ),
            if (_technicianPhone != null && _technicianPhone!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling $_technicianPhone...')),
                        );
                      },
                      icon: const Icon(Icons.phone),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, isSeniorMode ? 56 : 44),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Opening chat...')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, isSeniorMode ? 56 : 44),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
