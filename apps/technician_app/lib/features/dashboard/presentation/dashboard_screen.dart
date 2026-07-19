import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import '../../auth/presentation/auth_notifier.dart';
import 'jobs_notifier.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  bool _isToday(String scheduledDateStr) {
    try {
      final scheduledDate = DateTime.parse(scheduledDateStr);
      final now = DateTime.now();
      return scheduledDate.year == now.year &&
          scheduledDate.month == now.month &&
          scheduledDate.day == now.day;
    } catch (_) {
      return false;
    }
  }

  String _formatDate(String scheduledDateStr) {
    try {
      final scheduledDate = DateTime.parse(scheduledDateStr);
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${scheduledDate.day} ${months[scheduledDate.month - 1]} ${scheduledDate.year}';
    } catch (_) {
      return scheduledDateStr;
    }
  }

  Widget _buildSectionHeader(String title, int count, {Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 4.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badgeColor ?? Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
                boxShadow: badgeColor == Colors.red
                    ? [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.3),
                          blurRadius: 6,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: badgeColor == Colors.red ? Colors.white : Colors.black87,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final jobsState = ref.watch(jobsProvider);
    print('[DashboardScreen] Rebuilding. availableJobs count: ${jobsState.availableJobs.length}, isOnline: ${authState.isOnline}, isLoading: ${jobsState.isLoading}');

    // Listen to changes in availableJobs and auto-scroll to Available Jobs section (top, 0.0) if a new job arrives
    ref.listen<List<BookingDto>>(
      jobsProvider.select((state) => state.availableJobs),
      (previous, next) {
        if (next.isNotEmpty && (previous == null || next.length > previous.length)) {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOut,
            );
          }
        }
      },
    );

    // Redirect to login if unauthenticated
    if (!authState.isAuthenticated && !authState.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Redirect to mandatory change password screen if flag is set
    if (authState.mustChangePassword) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/change-password');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // Calculations based on fetched jobs
    final allJobs = jobsState.jobs;
    final todayJobs = allJobs.where((job) => _isToday(job.scheduledAt) && job.status != 'COMPLETED' && job.status != 'CANCELLED').toList();
    final completedJobs = allJobs.where((job) => job.status == 'COMPLETED').toList();
    final pendingJobs = allJobs.where((job) => job.status != 'COMPLETED' && job.status != 'CANCELLED' && !_isToday(job.scheduledAt)).toList();

    final double totalEarnings = completedJobs.fold(0.0, (sum, job) => sum + job.estimatedPrice);
    final double completionRate = allJobs.isEmpty ? 0.0 : (completedJobs.length / allJobs.length) * 100;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              authState.technicianName ?? 'Technician Workspace',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Branch: ${authState.branch ?? 'Unknown'} • ID: ${authState.technicianId ?? ''}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11),
            ),
          ],
        ),
        actions: [
          Row(
            children: [
              Text(
                authState.isOnline ? 'ONLINE' : 'OFFLINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: authState.isOnline ? Colors.greenAccent : Colors.white70,
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                value: authState.isOnline,
                activeThumbColor: Colors.greenAccent,
                activeTrackColor: AppTheme.primaryTealDark,
                inactiveThumbColor: Colors.grey.shade400,
                inactiveTrackColor: Colors.grey.shade700,
                onChanged: (val) {
                  ref.read(authProvider.notifier).toggleOnlineStatus(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(jobsProvider.notifier).fetchJobs(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              final router = GoRouter.of(context);
              await ref.read(authProvider.notifier).logout();
              router.go('/login');
            },
          ),
        ],
      ),
      body: jobsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(jobsProvider.notifier).fetchJobs(),
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // Quick Actions Bar
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
                      child: Card(
                        elevation: 1,
                        color: Colors.grey.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Quick Actions',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildQuickActionBtn(context, Icons.qr_code_scanner_rounded, 'Scan QR'),
                                  _buildQuickActionBtn(context, Icons.notifications_active_rounded, 'Alerts'),
                                  _buildQuickActionBtn(context, Icons.support_agent_rounded, 'Support'),
                                  _buildQuickActionBtn(context, Icons.add_circle_outline_rounded, 'New Request'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 1. Available Jobs (Highest Priority)
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Available Jobs",
                      jobsState.availableJobs.length,
                      badgeColor: Colors.red,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildAvailableJobsList(context, jobsState.availableJobs, authState.isOnline),
                  ),

                  // 2. Today's Jobs
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Today's Jobs",
                      todayJobs.length,
                      badgeColor: AppTheme.primaryTeal,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildJobsList(todayJobs, "No assigned jobs scheduled for today."),
                  ),

                  // 3. Pending
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Pending",
                      pendingJobs.length,
                      badgeColor: AppTheme.accentGold,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildJobsList(pendingJobs, "No upcoming pending jobs."),
                  ),

                  // 4. Completed
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(
                      "Completed",
                      completedJobs.length,
                      badgeColor: Colors.green.shade700,
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: _buildJobsList(completedJobs, "No completed job history found."),
                  ),

                  // 5. Performance Cards (KPI Statistics Grid)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                      child: const Text(
                        'Performance & Stats',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 32.0),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 180,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 96,
                      ),
                      delegate: SliverChildListDelegate([
                        _buildKpiCard(
                          context,
                          title: "Today's Jobs",
                          value: '${todayJobs.length}',
                          icon: Icons.calendar_today_rounded,
                          color: AppTheme.primaryTeal,
                        ),
                        _buildKpiCard(
                          context,
                          title: "Pending Jobs",
                          value: '${pendingJobs.length}',
                          icon: Icons.pending_actions_rounded,
                          color: AppTheme.accentGold,
                        ),
                        _buildKpiCard(
                          context,
                          title: "Completed",
                          value: '${completedJobs.length}',
                          icon: Icons.check_circle_outline_rounded,
                          color: Colors.green.shade700,
                        ),
                        _buildKpiCard(
                          context,
                          title: "Earnings",
                          value: '₹${totalEarnings.toStringAsFixed(0)}',
                          icon: Icons.currency_rupee_rounded,
                          color: Colors.blue.shade700,
                        ),
                        _buildKpiCard(
                          context,
                          title: "Rating",
                          value: '4.9 ★',
                          icon: Icons.star_border_rounded,
                          color: Colors.amber.shade800,
                        ),
                        _buildKpiCard(
                          context,
                          title: "Performance",
                          value: '${completionRate.toStringAsFixed(0)}%',
                          icon: Icons.trending_up_rounded,
                          color: Colors.purple.shade700,
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildKpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8), // Provide minimum spacing
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                  )
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                title,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionBtn(BuildContext context, IconData icon, String label) {
    return Expanded(
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Action "$label" triggered.')),
          );
        },
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(icon, color: AppTheme.primaryTeal, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailableJobsList(BuildContext context, List<BookingDto> jobs, bool isOnline) {
    if (!isOnline) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off_rounded, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'You are currently OFFLINE',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Toggle ONLINE in the header to subscribe and receive live job booking feeds in real-time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.explore_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No available jobs nearby',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                'Waiting for new requests... Booking alerts will appear here instantly.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];

        return HighlightCardWrapper(
          isEmergency: job.isEmergency,
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: job.isEmergency ? Colors.red.shade50.withValues(alpha: 0.5) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: job.isEmergency ? Colors.red.shade200 : Colors.grey.shade200,
              width: job.isEmergency ? 1.5 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: job.isEmergency ? Colors.red.shade100 : AppTheme.primaryLightTeal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        job.isEmergency ? 'EMERGENCY' : 'STANDARD',
                        style: TextStyle(
                          color: job.isEmergency ? Colors.red.shade800 : AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(job.scheduledAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.person_outline_rounded, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Client: ${job.customerName ?? "Valued Customer"}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.phone_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Phone: ${job.customerPhone ?? "Not Provided"}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.build_outlined, size: 16, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Services: ${job.serviceIds.isNotEmpty ? job.serviceIds.join(", ") : "General Service"}',
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Address: ${job.address}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  'Issue: ${job.description}',
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${_formatDate(job.scheduledAt)} • ${job.timeSlot}',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est: ₹${job.estimatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Reject'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          minimumSize: const Size(100, 38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final errorMsg = await ref.read(jobsProvider.notifier).rejectBooking(job.localId!);
                          if (errorMsg != null && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(errorMsg)),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job request rejected/dismissed.')),
                            );
                          }
                        },
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check_rounded, size: 16),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(100, 38),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () async {
                          final errorMsg = await ref.read(jobsProvider.notifier).acceptBooking(job.localId!);
                          if (errorMsg != null && context.mounted) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Booking Unavailable'),
                                content: Text(errorMsg),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          } else if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Job accepted successfully! Assigned to you.')),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
    );
  }

  Widget _buildJobsList(List<BookingDto> jobs, String emptyMsg) {
    if (jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              Text(
                emptyMsg,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: jobs.length,
      itemBuilder: (context, index) {
        final job = jobs[index];
        final isCompleted = job.status == 'COMPLETED';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: job.isEmergency ? Colors.red.shade50 : AppTheme.primaryLightTeal,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        job.isEmergency ? 'EMERGENCY' : 'STANDARD',
                        style: TextStyle(
                          color: job.isEmergency ? Colors.red.shade700 : AppTheme.primaryTeal,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                    Text(
                      _formatDate(job.scheduledAt),
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  job.address,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  job.description,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        job.timeSlot,
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Est: ₹${job.estimatedPrice.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTeal),
                    ),
                  ],
                ),
                if (!isCompleted && job.status != 'CANCELLED') ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.end,
                      children: [
                        if (job.localId != null) ...[
                          if (job.status == 'ASSIGNED' || job.status == 'TECHNICIAN_ASSIGNED') ...[
                            OutlinedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Navigating to job location...')),
                                );
                              },
                              child: const Text('Navigate'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final err = await ref.read(jobsProvider.notifier).updateBookingStatus(job.localId!, 'TRAVELLING');
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              child: const Text('Start Journey'),
                            ),
                          ] else if (job.status == 'TRAVELLING') ...[
                            ElevatedButton(
                              onPressed: () async {
                                final err = await ref.read(jobsProvider.notifier).updateBookingStatus(job.localId!, 'REACHED');
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              child: const Text('Arrived'),
                            ),
                          ] else if (job.status == 'REACHED') ...[
                            ElevatedButton(
                              onPressed: () async {
                                final err = await ref.read(jobsProvider.notifier).updateBookingStatus(job.localId!, 'IN_PROGRESS');
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              child: const Text('Start Work'),
                            ),
                          ] else if (job.status == 'IN_PROGRESS') ...[
                            ElevatedButton(
                              onPressed: () async {
                                final err = await ref.read(jobsProvider.notifier).updateBookingStatus(job.localId!, 'PAYMENT_PENDING');
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              child: const Text('Complete Work'),
                            ),
                          ] else if (job.status == 'PAYMENT_PENDING') ...[
                            ElevatedButton(
                              onPressed: () async {
                                final err = await ref.read(jobsProvider.notifier).updateBookingStatus(job.localId!, 'COMPLETED');
                                if (err != null && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
                                }
                              },
                              child: const Text('Collect Payment'),
                            ),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class HighlightCardWrapper extends StatefulWidget {
  final Widget child;
  final bool isEmergency;
  const HighlightCardWrapper({super.key, required this.child, required this.isEmergency});

  @override
  State<HighlightCardWrapper> createState() => _HighlightCardWrapperState();
}

class _HighlightCardWrapperState extends State<HighlightCardWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final val = _animation.value;
        final highlightColor = (widget.isEmergency ? Colors.red : AppTheme.primaryTeal)
            .withValues(alpha: 0.20 * (1.0 - val));
        return Container(
          decoration: BoxDecoration(
            color: highlightColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: widget.child,
        );
      },
    );
  }
}
