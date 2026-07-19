import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'reports_notifier.dart';

class ReportsGenerationScreen extends ConsumerStatefulWidget {
  const ReportsGenerationScreen({super.key});

  @override
  ConsumerState<ReportsGenerationScreen> createState() => _ReportsGenerationScreenState();
}

class _ReportsGenerationScreenState extends ConsumerState<ReportsGenerationScreen> {
  String _selectedReportType = 'bookings';
  String _selectedFormat = 'csv';
  final _startDateController = TextEditingController(text: '2026-07-01');
  final _endDateController = TextEditingController(text: '2026-07-30');
  bool _exportSuccess = false;

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  void _triggerExport() async {
    final notifier = ref.read(reportsProvider.notifier);
    final data = await notifier.generateReport(
      type: _selectedReportType,
      format: _selectedFormat,
      startDate: _startDateController.text,
      endDate: _endDateController.text,
    );

    if (data != null && mounted) {
      setState(() {
        _exportSuccess = true;
      });
      // Copy to clipboard to mock saving the exported CSV file
      await Clipboard.setData(ClipboardData(text: data));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Report generated! Copied ${formatUppercase(_selectedFormat)} payload to clipboard.')),
      );
    }
  }

  String formatUppercase(String s) => s.toUpperCase();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'FSM Data Exporter & Reports',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select custom metrics categories, date filters, and download report assets.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 24),

            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left side: Selection form
                  Expanded(
                    flex: 2,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Report Parameters Configuration', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Divider(height: 24),
                            DropdownButtonFormField<String>(
                              value: _selectedReportType,
                              decoration: const InputDecoration(labelText: 'Report Database category'),
                              items: const [
                                DropdownMenuItem(value: 'bookings', child: Text('Bookings Log Report')),
                                DropdownMenuItem(value: 'revenue', child: Text('Revenue & Payments Ledger')),
                                DropdownMenuItem(value: 'technicians', child: Text('Technicians Performance Audits')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedReportType = val);
                              },
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _startDateController,
                                    decoration: const InputDecoration(
                                      labelText: 'Start Date (YYYY-MM-DD)',
                                      prefixIcon: Icon(Icons.date_range_rounded),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextField(
                                    controller: _endDateController,
                                    decoration: const InputDecoration(
                                      labelText: 'End Date (YYYY-MM-DD)',
                                      prefixIcon: Icon(Icons.date_range_rounded),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _selectedFormat,
                              decoration: const InputDecoration(labelText: 'Download Asset Format'),
                              items: const [
                                DropdownMenuItem(value: 'csv', child: Text('CSV Spreadsheet File (*.csv)')),
                                DropdownMenuItem(value: 'pdf', child: Text('PDF Portable Document (*.pdf)')),
                                DropdownMenuItem(value: 'excel', child: Text('Excel Spreadsheet Book (*.xlsx)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedFormat = val);
                              },
                            ),
                            const SizedBox(height: 32),
                            ElevatedButton.icon(
                              onPressed: state.isLoading ? null : _triggerExport,
                              icon: state.isLoading
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download_rounded),
                              label: Text(state.isLoading ? 'Processing Export...' : 'Generate & Download Report'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryTeal,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Right side: Status and generated view
                  Expanded(
                    flex: 3,
                    child: Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 1,
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Export Terminal Output Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const Divider(height: 24),
                            Expanded(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade900,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: state.isLoading
                                    ? const Center(child: Text('Compiling records from PostgreSQL. Caching analytics queries in Valkey...', style: TextStyle(color: Colors.green, fontFamily: 'monospace', fontSize: 12)))
                                    : _exportSuccess && state.reportData != null
                                        ? SingleChildScrollView(
                                            child: Text(
                                              state.reportData!,
                                              style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace', fontSize: 11),
                                            ),
                                          )
                                        : Center(
                                            child: Text(
                                              'No active generated logs. Click generate to start exporting.',
                                              style: TextStyle(color: Colors.grey.shade500),
                                            ),
                                          ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
