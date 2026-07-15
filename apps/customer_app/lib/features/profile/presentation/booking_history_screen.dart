import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class HistoricBooking {
  final String id;
  final String serviceName;
  final String date;
  final String status;
  final String complaintNotes;
  final String technicianNotes;
  final String branchNotes;
  final double amount;

  HistoricBooking({
    required this.id,
    required this.serviceName,
    required this.date,
    required this.status,
    required this.complaintNotes,
    required this.technicianNotes,
    required this.branchNotes,
    required this.amount,
  });
}

class BookingHistoryScreen extends ConsumerWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));
    final theme = Theme.of(context);

    final List<HistoricBooking> history = [
      HistoricBooking(
        id: 'PHX-77A23B',
        serviceName: 'Ceiling Fan Installation',
        date: '14 May 2026',
        status: 'COMPLETED',
        amount: 249.00,
        complaintNotes:
            'Installed high-speed BLDC fan in main hall. Customer requested extra long rod check.',
        technicianNotes:
            'Rigid anchor bolt checked. Connected successfully. Fan speed regulator replaced.',
        branchNotes: 'No follow up needed. Standard billing completed.',
      ),
      HistoricBooking(
        id: 'PHX-88F41D',
        serviceName: 'Water Motor Diagnostic',
        date: '02 Apr 2026',
        status: 'COMPLETED',
        amount: 1149.00,
        complaintNotes: 'Motor humming sound, no water suction.',
        technicianNotes:
            'Capacitor 36 MFD was burnt. Replaced with genuine Havells parts. Tested successfully.',
        branchNotes: 'Warranty active for parts replaced up to October 2026.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Booking History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isSeniorMode ? 24 : 20,
          ),
        ),
      ),
      body: history.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_rounded,
                      size: 64,
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  const Text(
                    'No booking history yet',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed bookings will appear here.',
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
              itemCount: history.length,
              itemBuilder: (context, index) {
                final booking = history[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  clipBehavior: Clip.antiAlias,
                  child: ExpansionTile(
                    tilePadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 4),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: Colors.green.shade700,
                        size: isSeniorMode ? 24 : 20,
                      ),
                    ),
                    title: Text(
                      booking.serviceName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 17 : 15,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          Text(
                            booking.id,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking.date,
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${booking.amount.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSeniorMode ? 16 : 14,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            booking.status,
                            style: TextStyle(
                              color: Colors.green.shade700,
                              fontWeight: FontWeight.bold,
                              fontSize: 9,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            _buildNotesSection(
                              title: 'Your Complaint',
                              notes: booking.complaintNotes,
                              icon: Icons.speaker_notes_rounded,
                              color: Colors.blue,
                            ),
                            const SizedBox(height: 16),
                            _buildNotesSection(
                              title: 'Technician Notes',
                              notes: booking.technicianNotes,
                              icon: Icons.build_circle_rounded,
                              color: Colors.orange,
                            ),
                            const SizedBox(height: 16),
                            _buildNotesSection(
                              title: 'Resolution',
                              notes: booking.branchNotes,
                              icon: Icons.corporate_fare_rounded,
                              color: Colors.teal,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildNotesSection({
    required String title,
    required String notes,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: color),
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
                  fontSize: 12,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notes,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
