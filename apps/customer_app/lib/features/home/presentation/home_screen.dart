import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:project_phoenix_customer/core/routing/app_router.dart';
import 'package:project_phoenix_customer/core/theme/app_theme.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';
import 'package:project_phoenix_customer/features/auth/presentation/auth_notifier.dart';
import 'package:project_phoenix_customer/features/booking/presentation/booking_notifier.dart';
import 'package:project_phoenix_customer/features/services/data/repositories/services_repository.dart';
import 'package:project_phoenix_customer/core/database/sqlite_helper.dart';
import 'package:project_phoenix_customer/core/widgets/offline_banner.dart';
import 'package:project_phoenix_customer/core/widgets/shimmer_loader.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _pendingSyncCount = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _checkOfflineQueue();
  }

  Future<void> _checkOfflineQueue() async {
    final list = await SqliteHelper().getQueuedBookings();
    if (mounted) {
      setState(() {
        _pendingSyncCount = list.length;
      });
    }
  }

  void _syncQueue() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Checking network connectivity and synchronizing offline bookings...')),
    );
    await ref.read(bookingNotifierProvider.notifier).syncOfflineQueue();
    await _checkOfflineQueue();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Offline bookings synchronized successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final locale = ref.watch(settingsProvider.select((s) => s.locale));
    final categories = ref.watch(servicesRepositoryProvider).getCategories();
    final searchResults = ref
        .watch(servicesRepositoryProvider)
        .searchServices(_searchQuery, locale);

    return OfflineBanner(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROJECT PHOENIX',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0),
              ),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 12, color: Colors.teal),
                  const SizedBox(width: 4),
                  Text(
                    'OMR Road, Chennai',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.shopping_bag_outlined),
              onPressed: () => context.push(AppRouter.store),
            ),
            IconButton(
              icon: const Icon(Icons.psychology_outlined),
              onPressed: () => context.push(AppRouter.aiAssistant),
            ),
            IconButton(
              icon: const Icon(Icons.account_circle_outlined),
              onPressed: () => context.push(AppRouter.profile),
            ),
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: () {
                ref.read(authNotifierProvider.notifier).logout();
              },
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            await _checkOfflineQueue();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_pendingSyncCount > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      border: Border.all(color: Colors.orange.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cloud_off_rounded,
                            color: Colors.orange),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '$_pendingSyncCount offline bookings pending sync.',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: _syncQueue,
                          child: const Text('Sync Now'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _buildEmergencyCard(isSeniorMode, context),
                const SizedBox(height: 16),

                // Search Bar
                TextField(
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search services...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 20),

                if (_searchQuery.isNotEmpty) ...[
                  Text(
                    'Search Results',
                    style: TextStyle(
                        fontSize: isSeniorMode ? 22 : 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (searchResults.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Text('No matching services found.'),
                      ),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final item = searchResults[index];
                        return Card(
                          child: ListTile(
                            title: Text(
                              item.getName(locale),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: isSeniorMode ? 18 : 15),
                            ),
                            subtitle: Text(
                                'Base Price: ₹${item.basePrice.toStringAsFixed(0)}'),
                            trailing:
                                const Icon(Icons.arrow_forward_ios, size: 14),
                            onTap: () {
                              context.push('${AppRouter.booking}/${item.id}');
                            },
                          ),
                        );
                      },
                    ),
                ] else ...[
                  Text(
                    'Explore Service Categories',
                    style: TextStyle(
                        fontSize: isSeniorMode ? 22 : 18,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  if (categories.isEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSeniorMode ? 1 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSeniorMode ? 4 : 1.3,
                      ),
                      itemCount: 4,
                      itemBuilder: (context, index) => const ShimmerLoader(
                          width: double.infinity, height: 80),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: isSeniorMode ? 1 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: isSeniorMode ? 4 : 1.3,
                      ),
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final cat = categories[index];
                        return Card(
                          child: InkWell(
                            onTap: () {
                              context.push('${AppRouter.services}/${cat.id}');
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primaryContainer,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      cat.icon,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      size: isSeniorMode ? 32 : 24,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      cat.getName(locale),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: isSeniorMode ? 18 : 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 24),

                  // Quick links for Help Center
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.support_agent_outlined,
                          color: Colors.teal),
                      title: const Text('Help Center & Customer Hotline',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: const Text(
                          'Access FAQs and direct call/whatsapp triggers'),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => context.push(AppRouter.helpCenter),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyCard(bool isSeniorMode, BuildContext context) {
    final theme = Theme.of(context);
    final isHighContrast = theme.colorScheme.primary.value == AppTheme.hcYellow.value;
    final isDarkMode = theme.brightness == Brightness.dark;

    Color cardBgColor = Colors.red.shade50;
    Color borderColor = Colors.red.shade200;
    Color iconBgColor = Colors.red.shade100;
    Color textColor = Colors.red.shade900;
    Color subTextColor = Colors.red.shade700;
    Color btnColor = Colors.red.shade700;
    Color btnTextColor = Colors.white;

    if (isHighContrast) {
      cardBgColor = Colors.black;
      borderColor = Colors.white;
      iconBgColor = Colors.black;
      textColor = Colors.white;
      subTextColor = Colors.white;
      btnColor = AppTheme.hcYellow;
      btnTextColor = Colors.black;
    } else if (isDarkMode) {
      cardBgColor = Colors.red.shade900.withValues(alpha: 0.4);
      borderColor = Colors.red.shade800;
      iconBgColor = Colors.red.shade900.withValues(alpha: 0.3);
      textColor = Colors.red.shade200;
      subTextColor = Colors.red.shade300;
      btnColor = Colors.red.shade600;
      btnTextColor = Colors.white;
    }

    return Card(
      color: cardBgColor,
      elevation: isHighContrast ? 0 : 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: borderColor, width: isHighContrast ? 3 : 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
                border: isHighContrast ? Border.all(color: Colors.white, width: 2) : null,
              ),
              child: Icon(
                Icons.flash_on_rounded,
                color: isHighContrast ? AppTheme.hcYellow : (isDarkMode ? Colors.red.shade300 : Colors.red.shade800),
                size: isSeniorMode ? 32 : 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SOS: Emergency Breakdown?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      fontSize: isSeniorMode ? 18 : 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Dispatches technician within 45 mins.',
                    style: TextStyle(
                      color: subTextColor,
                      fontSize: isSeniorMode ? 14 : 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: isSeniorMode ? 100 : 88,
              height: isSeniorMode ? 54 : 44,
              child: ElevatedButton(
                onPressed: () {
                  context.push('${AppRouter.booking}/elec-wiring');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: btnTextColor,
                  elevation: 2,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: isHighContrast ? const BorderSide(color: Colors.black, width: 2) : BorderSide.none,
                  ),
                ),
                child: Text(
                  'SOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSeniorMode ? 18 : 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
