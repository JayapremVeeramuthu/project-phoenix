import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'system_logs_notifier.dart';

class SystemLogsScreen extends ConsumerStatefulWidget {
  const SystemLogsScreen({super.key});

  @override
  ConsumerState<SystemLogsScreen> createState() => _SystemLogsScreenState();
}

class _SystemLogsScreenState extends ConsumerState<SystemLogsScreen> {
  final _searchController = TextEditingController();
  String _selectedAction = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(systemLogsProvider.notifier).updateSearch(_searchController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(systemLogsProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Security & Audit System Logs',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Track admin operations, technician statuses, invoice creations, and account logs.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Search and filter console
            Card(
              elevation: 1,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Search details, actions, IP Address...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _triggerSearch(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedAction,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.category_rounded, size: 20),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Actions')),
                        DropdownMenuItem(value: 'BOOKING_CREATE', child: Text('Booking Created')),
                        DropdownMenuItem(value: 'BOOKING_ACCEPT', child: Text('Booking Accepted')),
                        DropdownMenuItem(value: 'BOOKING_STATUS_UPDATE', child: Text('Status Updated')),
                        DropdownMenuItem(value: 'TECHNICIAN_CREATE', child: Text('Technician Hired')),
                        DropdownMenuItem(value: 'TECHNICIAN_ENABLE', child: Text('Technician Enabled')),
                        DropdownMenuItem(value: 'TECHNICIAN_DISABLE', child: Text('Technician Disabled')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedAction = val);
                          ref.read(systemLogsProvider.notifier).updateActionFilter(val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Logs Table
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
                            DataColumn(label: Text('Log ID', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Action', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Details Description', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Performed By', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('IP Address', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Time Stamp', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.logs.map((log) {
                            return DataRow(
                              cells: [
                                DataCell(Text(log.id.substring(0, 8), style: const TextStyle(fontWeight: FontWeight.bold))),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.blueGrey.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      log.action,
                                      style: TextStyle(
                                        color: Colors.blueGrey.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(Text(log.details)),
                                DataCell(Text(log.userName)),
                                DataCell(Text(log.ipAddress)),
                                DataCell(Text(log.createdAt.replaceAll('T', ' ').substring(0, 19))),
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
                  'Total Activity Logs: ${state.total}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: state.page > 1
                          ? () => ref.read(systemLogsProvider.notifier).fetchLogs(page: state.page - 1)
                          : null,
                    ),
                    Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: state.page < state.totalPages
                          ? () => ref.read(systemLogsProvider.notifier).fetchLogs(page: state.page + 1)
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
}
