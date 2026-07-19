import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'payments_notifier.dart';

class RevenueDashboardScreen extends ConsumerStatefulWidget {
  const RevenueDashboardScreen({super.key});

  @override
  ConsumerState<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends ConsumerState<RevenueDashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(paymentsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Control Center',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track client payments, compare COD vs online transactions, and audit transaction records.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            // Revenue KPI row
            Row(
              children: [
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Online Revenues',
                    value: '₹${state.stats?.onlineRevenue.toStringAsFixed(0) ?? "0"}',
                    subtitle: '${state.stats?.paidCount ?? 0} invoices paid',
                    icon: Icons.payments_rounded,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Cash On Delivery (COD)',
                    value: '₹${state.stats?.codRevenue.toStringAsFixed(0) ?? "0"}',
                    subtitle: 'Settled by technicians',
                    icon: Icons.monetization_on_rounded,
                    color: Colors.teal,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Pending Invoices',
                    value: '₹${state.stats?.totalUnpaid.toStringAsFixed(0) ?? "0"}',
                    subtitle: '${state.stats?.unpaidCount ?? 0} unpaid bookings',
                    icon: Icons.hourglass_empty_rounded,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildFinancialCard(
                    title: 'Gross Paid Earnings',
                    value: '₹${state.stats?.totalPaid.toStringAsFixed(0) ?? "0"}',
                    subtitle: 'Deposited successfully',
                    icon: Icons.savings_rounded,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Latest Invoice Transactions Ledger',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 12),

            // Invoices Ledger list
            Expanded(
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      clipBehavior: Clip.antiAlias,
                      elevation: 1,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(Colors.grey.shade100),
                          columns: const [
                            DataColumn(label: Text('Invoice ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Technician', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Gateway / Method', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Razorpay ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Date issued', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Invoice Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.invoices.map((inv) {
                            return DataRow(
                              cells: [
                                DataCell(Text(inv.id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(Text(inv.localBookingId.substring(0, 8))),
                                DataCell(Text(inv.customerName)),
                                DataCell(Text(inv.technicianName)),
                                DataCell(Text(inv.paymentMethod)),
                                DataCell(Text(inv.paymentId)),
                                DataCell(Text(inv.createdAt.split('T')[0])),
                                DataCell(_buildStatusBadge(inv.status)),
                                DataCell(Text('₹${inv.totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
            ),

            // Pagination footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Invoices: ${state.total}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: state.page > 1
                          ? () => ref.read(paymentsProvider.notifier).fetchHistory(page: state.page - 1)
                          : null,
                    ),
                    Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: state.page < state.totalPages
                          ? () => ref.read(paymentsProvider.notifier).fetchHistory(page: state.page + 1)
                          : null,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const Icon(Icons.trending_up_rounded, color: Colors.green, size: 18),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status) {
      case 'PAID':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
        break;
      case 'UNPAID':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case 'CANCELLED':
        bg = Colors.red.shade50;
        fg = Colors.red.shade800;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(
        status,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
