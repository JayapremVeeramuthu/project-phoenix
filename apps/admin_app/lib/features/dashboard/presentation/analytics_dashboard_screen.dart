import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'analytics_notifier.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Business Intelligence & Analytics',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Detailed view of bookings frequency, monthly revenues, repeat customers, and peaks.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.analytics == null
                      ? const Center(child: Text('Failed to load analytics data.'))
                      : ListView(
                          children: [
                            // Main charts layout
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: _buildChartCard(
                                    title: 'Weekly Revenues Trend',
                                    subtitle: 'Calculated over last 4 operational weeks',
                                    child: _buildRevenueBarChart(state.analytics!.weeklyRevenue),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _buildChartCard(
                                    title: 'Booking Status Distributions',
                                    subtitle: 'Overall fulfillment indicators',
                                    child: _buildRatesPanel(state.analytics!),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: _buildChartCard(
                                    title: 'Service Popularity Groupings',
                                    subtitle: 'Category-wise bookings density',
                                    child: _buildPopularityList(state.analytics!.servicePopularity),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildChartCard(
                                    title: 'Daily Bookings (Last 7 Days)',
                                    subtitle: 'Overall activity fluctuations',
                                    child: _buildWeeklyVolumeChart(state.analytics!.dailyBookings),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required String subtitle, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTealDark)),
            const SizedBox(height: 2),
            Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            const SizedBox(height: 20),
            SizedBox(height: 200, child: child),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueBarChart(List<ChartItemDto> items) {
    if (items.isEmpty) return const Center(child: Text('No revenue history.'));
    final maxAmount = items.map((i) => i.count).reduce(max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items.map((item) {
        final percentage = maxAmount > 0 ? item.count / maxAmount : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text('₹${item.count.toStringAsFixed(0)}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal)),
            const SizedBox(height: 6),
            Container(
              width: 44,
              height: max(140 * percentage, 10.0),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.teal, AppTheme.primaryTeal],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyVolumeChart(List<ChartItemDto> items) {
    if (items.isEmpty) return const Center(child: Text('No daily bookings.'));
    final maxVal = items.map((i) => i.count).reduce(max);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: items.map((item) {
        final percentage = maxVal > 0 ? item.count / maxVal : 0.0;
        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(item.count.toStringAsFixed(0), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue)),
            const SizedBox(height: 6),
            Container(
              width: 32,
              height: max(140 * percentage, 6.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade600, Colors.blue.shade300],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Text(item.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildPopularityList(List<ChartItemDto> items) {
    if (items.isEmpty) return const Center(child: Text('No catalog bookings statistics.'));
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                  Text('${item.count.toStringAsFixed(0)} jobs', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.teal)),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: item.count / 100.0, // scale relative to hypothetical max
                  color: AppTheme.primaryTeal,
                  backgroundColor: Colors.teal.shade50,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRatesPanel(AnalyticsDto analytics) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildRateProgressCard('Completed Fulfilments Rate', analytics.completionRate, Colors.green),
        _buildRateProgressCard('Cancellation & Reject Rate', analytics.cancellationRate, Colors.redAccent),
        _buildRateProgressCard('Repeat Customer Density', analytics.repeatCustomerRate, Colors.amber.shade800),
      ],
    );
  }

  Widget _buildRateProgressCard(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
            Text('${value.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value / 100.0,
            color: color,
            backgroundColor: color.withValues(alpha: 0.1),
            minHeight: 10,
          ),
        ),
      ],
    );
  }
}
