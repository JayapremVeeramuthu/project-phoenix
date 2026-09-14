import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';

class BookingSuccessScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final bool isOffline;

  const BookingSuccessScreen({
    super.key,
    required this.bookingId,
    required this.isOffline,
  });

  @override
  ConsumerState<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends ConsumerState<BookingSuccessScreen>
    with SingleTickerProviderStateMixin {
  // Technician data – null until a technician accepts
  String? _technicianName;
  String? _technicianPhone;
  String? _technicianBranch;
  String? _technicianDisplayId;
  String _bookingStatus = 'WAITING_FOR_TECHNICIAN';

  StreamSubscription? _statusSubscription;
  late AnimationController _pulseController;
  SocketService? _socketService;
  BookingRepository? _bookingRepository;

  Future<void> _fetchInitialTracking() async {
    if (!mounted) return;
    try {
      final repo = _bookingRepository;
      if (repo == null) return;
      final data = await repo.getBookingTracking(widget.bookingId);
      if (mounted) {
        setState(() {
          if (data['currentStatus'] != null) {
            _bookingStatus = data['currentStatus'];
          }
          _technicianName = data['technicianName'];
          _technicianPhone = data['technicianPhone'];
          _technicianBranch = data['technicianBranch'];
          _technicianDisplayId = data['technicianId'];
        });
      }
    } catch (_) {
      // ignore
    }
  }

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _socketService = ref.read(socketServiceProvider);
    _bookingRepository = ref.read(bookingRepositoryProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchInitialTracking();
      _connectSocket();
    });
  }

  void _connectSocket() {
    if (!mounted) return;
    final socket = _socketService;
    if (socket == null) return;
    socket.connect();
    socket.joinRoom('booking_${widget.bookingId}');

    _statusSubscription = socket.bookingStatusUpdatedStream.listen((event) {
      if (!mounted) return;
      if (event['bookingId'] != widget.bookingId) return;

      final status = event['status'] as String?;
      final techName = event['technicianName'] as String?;
      final techPhone = event['technicianPhone'] as String?;
      final techBranch = event['technicianBranch'] as String?;
      final techId = event['technicianId'] as String?;

      setState(() {
        if (status != null) _bookingStatus = status;
        if (techName != null) _technicianName = techName;
        if (techPhone != null) _technicianPhone = techPhone;
        if (techBranch != null) _technicianBranch = techBranch;
        if (techId != null) _technicianDisplayId = techId;
      });
    });
  }

  bool get _isTechnicianAssigned =>
      _technicianName != null &&
      (_bookingStatus == 'TECHNICIAN_ASSIGNED' ||
       _bookingStatus == 'ASSIGNED' ||
       _bookingStatus == 'TRAVELLING' ||
       _bookingStatus == 'REACHED' ||
       _bookingStatus == 'IN_PROGRESS' ||
       _bookingStatus == 'PAYMENT_PENDING' ||
       _bookingStatus == 'COMPLETED');

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _pulseController.dispose();
    _socketService?.leaveRoom('booking_${widget.bookingId}');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    color: widget.isOffline
                        ? (isHighContrast ? Colors.black : Colors.orange.shade50)
                        : successBg,
                    shape: BoxShape.circle,
                    border: isHighContrast ? Border.all(color: Colors.white, width: 3) : null,
                  ),
                  child: Icon(
                    widget.isOffline ? Icons.cloud_off_rounded : Icons.check_circle_outline,
                    size: isSeniorMode ? 80 : 64,
                    color: widget.isOffline ? Colors.orange : successColor,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                widget.isOffline ? 'Saved Offline' : 'Booking Confirmed!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSeniorMode ? 30 : 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isOffline
                    ? 'No internet connection detected. The booking has been queued locally in SQLite and will sync once network is online.'
                    : 'Your request has been successfully transmitted. A technician will be assigned shortly.',
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
                        widget.bookingId,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 22 : 18,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Booking Status'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _isTechnicianAssigned
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _isTechnicianAssigned
                                  ? 'TECHNICIAN ASSIGNED'
                                  : 'WAITING FOR TECHNICIAN',
                              style: TextStyle(
                                color: _isTechnicianAssigned
                                    ? Colors.green.shade800
                                    : Colors.orange.shade800,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

              // Technician Card – searching state or assigned state
              _isTechnicianAssigned
                  ? _buildAssignedTechnicianCard(isSeniorMode, theme, cardBg, textMuted)
                  : _buildSearchingCard(isSeniorMode, theme, cardBg),

              const SizedBox(height: 24),

              // Next Steps Timeline
              Text(
                'Next Steps',
                style: TextStyle(
                  fontSize: isSeniorMode ? 20 : 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildStepItem('1', 'Technician Dispatch', 'An available technician will be assigned to your request.', isSeniorMode, theme),
              _buildStepItem('2', 'Pre-service Diagnosis', 'Technician inspects the issue and provides assessment.', isSeniorMode, theme),
              _buildStepItem('3', 'Service Execution', 'Fixing and testing complete with standard checklist.', isSeniorMode, theme),
              _buildStepItem('4', 'Completion & Invoice', 'Digital invoice generated after service completion.', isSeniorMode, theme),

              const SizedBox(height: 32),

              // Action buttons
              ElevatedButton(
                onPressed: () {
                  context.go('${AppRouter.tracking}/${widget.bookingId}');
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

  /// Pulsing "Searching for technician..." placeholder card
  Widget _buildSearchingCard(bool isSeniorMode, ThemeData theme, Color cardBg) {
    return Card(
      color: cardBg,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
        child: Column(
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Opacity(
                  opacity: 0.4 + (_pulseController.value * 0.6),
                  child: Icon(
                    Icons.person_search_rounded,
                    size: isSeniorMode ? 56 : 48,
                    color: theme.colorScheme.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Text(
              'Searching for an available technician...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isSeniorMode ? 18 : 15,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'You will be notified once a technician accepts your request.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }

  /// Real technician data card – only shown after acceptance
  Widget _buildAssignedTechnicianCard(bool isSeniorMode, ThemeData theme, Color cardBg, Color textMuted) {
    return Card(
      color: cardBg,
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Technician Assigned',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSeniorMode ? 18 : 15,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
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
                        _technicianName ?? '',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: isSeniorMode ? 18 : 15,
                        ),
                      ),
                      if (_technicianDisplayId != null && _technicianDisplayId!.isNotEmpty)
                        Text(
                          'ID: $_technicianDisplayId',
                          style: TextStyle(fontSize: 12, color: textMuted),
                        ),
                      if (_technicianBranch != null && _technicianBranch!.isNotEmpty)
                        Text(
                          _technicianBranch!,
                          style: TextStyle(fontSize: 13, color: textMuted),
                        ),
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Calling $_technicianPhone...')),
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
                          const SnackBar(content: Text('Opening chat...')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text('Chat'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: Size(double.infinity, isSeniorMode ? 52 : 44),
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
