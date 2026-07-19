import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'bookings_notifier.dart';
import 'technicians_notifier.dart';

class BookingsManagementScreen extends ConsumerStatefulWidget {
  const BookingsManagementScreen({super.key});

  @override
  ConsumerState<BookingsManagementScreen> createState() => _BookingsManagementScreenState();
}

class _BookingsManagementScreenState extends ConsumerState<BookingsManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedStatus = 'ALL';
  String _selectedPriority = 'ALL';
  BookingDto? _activeDrawerBooking;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(bookingsProvider.notifier).updateSearch(_searchController.text);
  }

  void _openBookingDrawer(BookingDto booking) {
    setState(() {
      _activeDrawerBooking = booking;
    });
  }

  void _closeBookingDrawer() {
    setState(() {
      _activeDrawerBooking = null;
    });
  }

  void _showAssignTechnicianDialog(BookingDto booking) {
    final techState = ref.read(techniciansProvider);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign Technician'),
        content: techState.technicians.isEmpty
            ? const Text('No online or active technicians available.')
            : SizedBox(
                width: 320,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: techState.technicians.length,
                  itemBuilder: (context, index) {
                    final tech = techState.technicians[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: tech.isOnline ? Colors.green.shade100 : Colors.grey.shade200,
                        child: Icon(Icons.engineering_outlined, color: tech.isOnline ? Colors.green.shade800 : Colors.grey.shade600),
                      ),
                      title: Text(tech.name),
                      subtitle: Text('${tech.branch} • ${tech.skills.join(", ")}'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () async {
                        Navigator.pop(context);
                        final success = await ref.read(bookingsProvider.notifier).assignTechnician(booking.localId ?? '', tech.id);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Assigned ${tech.name} successfully!')),
                          );
                          // Refresh active drawer if open
                          if (_activeDrawerBooking?.localId == booking.localId) {
                            setState(() {
                              _activeDrawerBooking = ref.read(bookingsProvider).bookings.firstWhere((b) => b.localId == booking.localId);
                            });
                          }
                        }
                      },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bookingsProvider);
    final isDesktop = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Screen Title
                  const Text(
                    'Service Bookings Console',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Dispatch bookings, assign technicians, and monitor status real-time.',
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
                                hintText: 'Search Booking ID, Customer, Address, Description...',
                                prefixIcon: Icon(Icons.search_rounded),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _triggerSearch(),
                            ),
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedStatus,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.filter_list_rounded, size: 20),
                            hint: const Text('Status'),
                            items: ['ALL', 'PENDING', 'TECHNICIAN_ASSIGNED', 'TRAVELLING', 'REACHED', 'IN_PROGRESS', 'COMPLETED', 'CANCELLED']
                                .map((status) => DropdownMenuItem(value: status, child: Text(status)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedStatus = val);
                                ref.read(bookingsProvider.notifier).updateStatusFilter(val == 'ALL' ? null : val);
                              }
                            },
                          ),
                          const SizedBox(width: 16),
                          DropdownButton<String>(
                            value: _selectedPriority,
                            underline: const SizedBox(),
                            icon: const Icon(Icons.priority_high_rounded, size: 20),
                            items: ['ALL', 'STANDARD', 'EMERGENCY']
                                .map((priority) => DropdownMenuItem(value: priority, child: Text(priority)))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedPriority = val);
                                ref.read(bookingsProvider.notifier).updatePriorityFilter(val == 'ALL' ? null : val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Bookings Table
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
                                  DataColumn(label: Text('Booking ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Technician', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Service ID', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Priority', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Est. Price', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: state.bookings.map((booking) {
                                  final isEmergency = booking.isEmergency;
                                  return DataRow(
                                    cells: [
                                      DataCell(
                                        InkWell(
                                          onTap: () => _openBookingDrawer(booking),
                                          child: Text(
                                            booking.localId?.substring(0, 8) ?? 'Unk',
                                            style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(booking.customerName ?? 'Rajesh Kumar')),
                                      DataCell(Text(booking.technicianName ?? 'Unassigned')),
                                      DataCell(Text(booking.serviceIds.join(", "))),
                                      DataCell(_buildStatusBadge(booking.status)),
                                      DataCell(
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isEmergency ? Colors.red.shade50 : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            isEmergency ? 'EMERGENCY' : 'STANDARD',
                                            style: TextStyle(
                                              color: isEmergency ? Colors.red.shade800 : Colors.grey.shade700,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text('₹${booking.estimatedPrice.toStringAsFixed(0)}')),
                                      DataCell(
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (booking.technicianName == null)
                                              IconButton(
                                                icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.blueAccent, size: 18),
                                                onPressed: () => _showAssignTechnicianDialog(booking),
                                                tooltip: 'Assign Technician',
                                              ),
                                            IconButton(
                                              icon: const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 18),
                                              onPressed: () => _openBookingDrawer(booking),
                                              tooltip: 'Details',
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                  ),

                  // Pagination controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Bookings: ${state.total}',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: state.page > 1
                                ? () => ref.read(bookingsProvider.notifier).fetchBookings(page: state.page - 1)
                                : null,
                          ),
                          Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: state.page < state.totalPages
                                ? () => ref.read(bookingsProvider.notifier).fetchBookings(page: state.page + 1)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (_activeDrawerBooking != null) _buildDetailsDrawer(isDesktop),
        ],
      ),
    );
  }

  Widget _buildDetailsDrawer(bool isDesktop) {
    final booking = _activeDrawerBooking!;
    return Container(
      width: isDesktop ? 400 : double.infinity,
      color: Colors.white,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: Colors.black12)),
      ),
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Booking Details',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: _closeBookingDrawer),
            ],
          ),
          const Divider(),
          Expanded(
            child: ListView(
              children: [
                _buildInfoRow('Booking UUID', booking.localId ?? ''),
                _buildInfoRow('Customer Name', booking.customerName ?? 'Rajesh Kumar'),
                _buildInfoRow('Phone', booking.customerPhone ?? '+919876543210'),
                _buildInfoRow('Address', booking.address),
                _buildInfoRow('Description', booking.description),
                _buildInfoRow('Date Scheduled', booking.scheduledAt),
                _buildInfoRow('Time Slot', booking.timeSlot),
                _buildInfoRow('Technician', booking.technicianName ?? 'Not Assigned'),
                if (booking.technicianPhone != null) _buildInfoRow('Tech Phone', booking.technicianPhone!),
                _buildInfoRow('Est. Invoice', '₹${booking.estimatedPrice.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                const Text('Photos Attached:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                booking.imagePaths.isEmpty
                    ? Text('No job photos attached.', style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic))
                    : GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: booking.imagePaths.length,
                        itemBuilder: (context, index) {
                          return ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              booking.imagePaths[index],
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: Colors.grey.shade200, child: const Icon(Icons.broken_image)),
                            ),
                          );
                        },
                      ),
                const SizedBox(height: 20),
                const Text('Timeline History:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                _buildTimelinePoint('Booking Created', booking.createdAt),
                if (booking.technicianName != null)
                  _buildTimelinePoint('Technician Assigned', 'Job claimed by ${booking.technicianName}'),
                if (booking.status == 'COMPLETED')
                  _buildTimelinePoint('Job Completed', 'Completed successfully.'),
              ],
            ),
          ),
          if (booking.technicianName == null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _showAssignTechnicianDialog(booking),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Assign Dispatcher'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryTeal,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 14, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildTimelinePoint(String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: const BoxDecoration(color: AppTheme.primaryTeal, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 32, color: Colors.teal.shade100),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color fg = Colors.grey.shade800;

    switch (status) {
      case 'PENDING':
        bg = Colors.orange.shade50;
        fg = Colors.orange.shade800;
        break;
      case 'TECHNICIAN_ASSIGNED':
      case 'ASSIGNED':
        bg = Colors.blue.shade50;
        fg = Colors.blue.shade800;
        break;
      case 'TRAVELLING':
      case 'REACHED':
      case 'IN_PROGRESS':
        bg = Colors.teal.shade50;
        fg = Colors.teal.shade800;
        break;
      case 'COMPLETED':
        bg = Colors.green.shade50;
        fg = Colors.green.shade800;
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
        status.replaceAll('_', ' '),
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
