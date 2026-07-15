import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class InvoiceItem {
  final String id;
  final String date;
  final String serviceName;
  final double amount;
  final String status;
  final String paymentMode;

  InvoiceItem({
    required this.id,
    required this.date,
    required this.serviceName,
    required this.amount,
    required this.status,
    required this.paymentMode,
  });
}

class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final theme = Theme.of(context);

    final List<InvoiceItem> invoices = [
      InvoiceItem(
        id: 'INV-2026-081',
        date: '14 May 2026',
        serviceName: 'Ceiling Fan Installation',
        amount: 249.00,
        status: 'PAID',
        paymentMode: 'UPI (GPay)',
      ),
      InvoiceItem(
        id: 'INV-2026-042',
        date: '02 Apr 2026',
        serviceName: 'Water Motor Diagnostic',
        amount: 1149.00,
        status: 'PAID',
        paymentMode: 'Debit Card',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Digital Invoices',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSeniorMode ? 24 : 20,
          ),
        ),
      ),
      body: invoices.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No invoices yet',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invoices from your bookings will appear here.',
                    style: TextStyle(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: invoices.length,
              itemBuilder: (context, index) {
                final inv = invoices[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.receipt_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  inv.id,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: isSeniorMode ? 16 : 14,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: Colors.green.shade200),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_rounded,
                                      size: 12, color: Colors.green.shade700),
                                  const SizedBox(width: 4),
                                  Text(
                                    inv.status,
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Service info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    inv.serviceName,
                                    style: TextStyle(
                                      fontSize: isSeniorMode ? 18 : 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.calendar_today_rounded,
                                          size: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        inv.date,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Icon(Icons.payment_rounded,
                                          size: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.5)),
                                      const SizedBox(width: 4),
                                      Text(
                                        inv.paymentMode,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: theme.colorScheme.onSurface
                                              .withValues(alpha: 0.6),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₹${inv.amount.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: isSeniorMode ? 22 : 20,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        // Action buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Sharing invoice ${inv.id}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.share_rounded, size: 18),
                              label: const Text('Share'),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        'Downloading invoice ${inv.id}'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              icon: const Icon(Icons.download_rounded,
                                  size: 18),
                              label: const Text('Download'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
