import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_theme/shared_theme.dart';
import '../../auth/presentation/auth_notifier.dart';
import 'dashboard_stats_notifier.dart';
import 'technician_management_screen.dart';
import 'bookings_management_screen.dart';
import 'customers_management_screen.dart';
import 'services_management_screen.dart';
import 'revenue_dashboard_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'reports_generation_screen.dart';
import 'notifications_center_screen.dart';
import 'settings_management_screen.dart';
import 'system_logs_screen.dart';

// View selection provider
final adminViewProvider = StateProvider<String>((ref) => 'Dashboard');

class AdminShell extends ConsumerWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentView = ref.watch(adminViewProvider);
    final authState = ref.watch(authProvider);
    final statsState = ref.watch(dashboardStatsProvider);

    final isDesktop = MediaQuery.of(context).size.width > 950;

    // Sidebar items with icons
    final sidebarItems = [
      {'name': 'Dashboard', 'icon': Icons.dashboard_rounded},
      {'name': 'Bookings', 'icon': Icons.calendar_today_rounded},
      {'name': 'Customers', 'icon': Icons.people_outline_rounded},
      {'name': 'Technicians', 'icon': Icons.engineering_outlined},
      {'name': 'Services', 'icon': Icons.design_services_rounded},
      {'name': 'Revenue', 'icon': Icons.currency_rupee_rounded},
      {'name': 'Analytics', 'icon': Icons.analytics_rounded},
      {'name': 'Reports', 'icon': Icons.assessment_rounded},
      {'name': 'Notifications', 'icon': Icons.notifications_active_rounded},
      {'name': 'Settings', 'icon': Icons.settings_rounded},
      {'name': 'System Logs', 'icon': Icons.receipt_long_rounded},
    ];

    Widget buildSidebarContent() {
      return Container(
        color: const Color(0xFF0F172A),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Phoenix FSM',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: sidebarItems.length,
                itemBuilder: (context, index) {
                  final item = sidebarItems[index];
                  final name = item['name'] as String;
                  final icon = item['icon'] as IconData;
                  final isSelected = currentView == name;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: InkWell(
                      onTap: () {
                        ref.read(adminViewProvider.notifier).state = name;
                        if (!isDesktop) {
                          Navigator.pop(context); // Close drawer on mobile
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.15) : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryTeal.withValues(alpha: 0.3) : Colors.transparent,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade400,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              name,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.grey.shade300,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF020617),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppTheme.primaryTeal,
                    radius: 18,
                    child: Text(
                      (authState.adminName ?? 'A')[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          authState.adminName ?? 'Admin User',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text(
                          'Operations Manager',
                          style: TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
                    onPressed: () async {
                      final router = GoRouter.of(context);
                      await ref.read(authProvider.notifier).logout();
                      router.go('/login');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget buildMainContent() {
      switch (currentView) {
        case 'Dashboard':
          return _buildDashboardContent(context, ref, statsState);
        case 'Bookings':
          return const BookingsManagementScreen();
        case 'Customers':
          return const CustomersManagementScreen();
        case 'Technicians':
          return const TechnicianManagementScreen(isEmbedded: true);
        case 'Services':
          return const ServicesManagementScreen();
        case 'Revenue':
          return const RevenueDashboardScreen();
        case 'Analytics':
          return const AnalyticsDashboardScreen();
        case 'Reports':
          return const ReportsGenerationScreen();
        case 'Notifications':
          return const NotificationsCenterScreen();
        case 'Settings':
          return const SettingsManagementScreen();
        case 'System Logs':
          return const SystemLogsScreen();
        default:
          return _buildPlaceholderView(currentView);
      }
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: isDesktop ? null : Drawer(child: buildSidebarContent()),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
        title: Row(
          children: [
            if (isDesktop) ...[
              const Icon(Icons.admin_panel_settings_rounded, color: AppTheme.primaryTeal),
              const SizedBox(width: 8),
              const Text(
                'Enterprise Command Console',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
              ),
            ] else ...[
              Text(
                currentView,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ],
          ],
        ),
        actions: [
          // Global Search Bar in Header
          if (isDesktop)
            Container(
              width: 300,
              height: 38,
              margin: const EdgeInsets.only(right: 16),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Global Search...',
                  prefixIcon: const Icon(Icons.search_rounded, size: 18),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  fillColor: Colors.grey.shade100,
                  filled: true,
                ),
              ),
            ),
          // Refresh Icon
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(dashboardStatsProvider.notifier).fetchStats(),
          ),
          // Notification indicator
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () => ref.read(adminViewProvider.notifier).state = 'Notifications',
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            SizedBox(
              width: 250,
              child: buildSidebarContent(),
            ),
          Expanded(
            child: buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, DashboardStatsState statsState) {
    if (statsState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final stats = statsState.stats;

    return RefreshIndicator(
      onRefresh: () => ref.read(dashboardStatsProvider.notifier).fetchStats(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Live Status Indicator Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryTeal, AppTheme.primaryTealDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.sensors_rounded, color: Colors.white, size: 28),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Ops Sync Active',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          'Listening to real-time events. Metrics update automatically.',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'CONNECTED',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            if (statsState.errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  statsState.errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Section Header
            Text(
              'FSM Command Center Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Real-time operational summary & business indicators',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // 16 Grid KPI Cards
            GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 4
                  : MediaQuery.of(context).size.width > 800
                      ? 3
                      : MediaQuery.of(context).size.width > 550
                          ? 2
                          : 1,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMetricCard('Today\'s Revenue', '₹${stats.todayRevenue.toStringAsFixed(0)}', Icons.payments_rounded, Colors.green),
                _buildMetricCard('Revenue This Month', '₹${stats.revenueThisMonth.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, Colors.teal),
                _buildMetricCard('Revenue This Year', '₹${stats.revenueThisYear.toStringAsFixed(0)}', Icons.savings_rounded, Colors.indigo),
                _buildMetricCard('Total Revenue', '₹${stats.revenue.toStringAsFixed(0)}', Icons.currency_rupee_rounded, Colors.blue),

                _buildMetricCard('Today\'s Bookings', '${stats.todayBookings}', Icons.calendar_today_rounded, Colors.amber.shade700),
                _buildMetricCard('Pending Bookings', '${stats.pendingJobs}', Icons.hourglass_empty_rounded, Colors.orange),
                _buildMetricCard('Assigned Bookings', '${stats.assignedBookings}', Icons.assignment_turned_in_rounded, Colors.blue.shade700),
                _buildMetricCard('Completed Jobs', '${stats.completedJobs}', Icons.check_circle_rounded, Colors.green.shade700),
                _buildMetricCard('Cancelled Jobs', '${stats.cancelledBookings}', Icons.cancel_rounded, Colors.red.shade700),

                _buildMetricCard('Online Technicians', '${stats.onlineTechnicians}', Icons.wifi_rounded, AppTheme.primaryTeal),
                _buildMetricCard('Offline Technicians', '${stats.offlineTechnicians}', Icons.wifi_off_rounded, Colors.grey.shade600),
                _buildMetricCard('Active Technicians', '${stats.activeTechnicians}', Icons.engineering_rounded, Colors.blueGrey),

                _buildMetricCard('Total Customers', '${stats.totalCustomers}', Icons.people_outline_rounded, Colors.purple),
                _buildMetricCard('Active Customers', '${stats.activeCustomers}', Icons.person_search_rounded, Colors.pink),

                _buildMetricCard('Average Rating', '${stats.averageRating.toStringAsFixed(1)} ★', Icons.star_rate_rounded, Colors.amber.shade800),
                _buildMetricCard('Avg Response Time', '${stats.averageResponseTime.toStringAsFixed(0)} mins', Icons.speed_rounded, Colors.deepOrange),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Icon(Icons.more_vert_rounded, color: Colors.grey, size: 16),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderView(String viewName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            '$viewName Module Under Construction',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          const Text(
            'This view will be implemented in a subsequent FSM stage.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
