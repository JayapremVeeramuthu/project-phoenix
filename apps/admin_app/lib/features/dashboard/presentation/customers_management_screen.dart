import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'customers_notifier.dart';

class CustomersManagementScreen extends ConsumerStatefulWidget {
  const CustomersManagementScreen({super.key});

  @override
  ConsumerState<CustomersManagementScreen> createState() => _CustomersManagementScreenState();
}

class _CustomersManagementScreenState extends ConsumerState<CustomersManagementScreen> {
  final _searchController = TextEditingController();
  String _selectedActive = 'all';
  String _selectedVip = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _triggerSearch() {
    ref.read(customersProvider.notifier).updateSearch(_searchController.text);
  }

  void _showCustomerDetails(CustomerDto customer) {
    ref.read(customersProvider.notifier).getCustomerDetails(customer.id);
    showDialog(
      context: context,
      builder: (context) => _CustomerDetailsDialog(customerId: customer.id),
    );
  }

  void _showEditCustomerDialog(CustomerDto customer) {
    showDialog(
      context: context,
      builder: (context) => _EditCustomerDialog(customer: customer),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(customersProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Customers Directory',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.primaryTealDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage customer profiles, assign VIP status, toggle access, and check billing history.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 20),

            // Search bar & filters
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
                          hintText: 'Search by Customer Name, Email, or Phone...',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: InputBorder.none,
                        ),
                        onSubmitted: (_) => _triggerSearch(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedActive,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.toggle_on_rounded, size: 20),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Status')),
                        DropdownMenuItem(value: 'true', child: Text('Active Only')),
                        DropdownMenuItem(value: 'false', child: Text('Blocked Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedActive = val);
                          ref.read(customersProvider.notifier).updateFilters(active: val);
                        }
                      },
                    ),
                    const SizedBox(width: 16),
                    DropdownButton<String>(
                      value: _selectedVip,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.star_rate_rounded, size: 20),
                      items: const [
                        DropdownMenuItem(value: 'all', child: Text('All Customers')),
                        DropdownMenuItem(value: 'true', child: Text('VIPs Only')),
                        DropdownMenuItem(value: 'false', child: Text('Non-VIPs Only')),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedVip = val);
                          ref.read(customersProvider.notifier).updateFilters(vip: val);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Customer list
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
                            DataColumn(label: Text('Customer', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Bookings Count', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Total Spend', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('VIP Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: state.customers.map((cust) {
                            return DataRow(
                              cells: [
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: cust.isVip ? Colors.amber.shade100 : Colors.teal.shade50,
                                        child: Text(cust.name[0].toUpperCase(), style: TextStyle(color: cust.isVip ? Colors.amber.shade900 : AppTheme.primaryTeal, fontWeight: FontWeight.bold)),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                DataCell(Text(cust.phoneNumber)),
                                DataCell(Text(cust.email)),
                                DataCell(Text(cust.bookingsCount.toString())),
                                DataCell(Text('₹${cust.totalSpend.toStringAsFixed(0)}')),
                                DataCell(
                                  Switch(
                                    value: cust.isVip,
                                    activeColor: Colors.amber,
                                    onChanged: (val) => ref.read(customersProvider.notifier).toggleVIP(cust.id, val),
                                  ),
                                ),
                                DataCell(
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: cust.isActive ? Colors.green.shade50 : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      cust.isActive ? 'ACTIVE' : 'BLOCKED',
                                      style: TextStyle(
                                        color: cust.isActive ? Colors.green.shade800 : Colors.red.shade800,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.info_outline_rounded, color: Colors.blueAccent, size: 18),
                                        onPressed: () => _showCustomerDetails(cust),
                                        tooltip: 'Profile Details',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
                                        onPressed: () => _showEditCustomerDialog(cust),
                                        tooltip: 'Edit Profile',
                                      ),
                                      IconButton(
                                        icon: Icon(cust.isActive ? Icons.block_flipped : Icons.check_circle_outline_rounded,
                                            color: cust.isActive ? Colors.redAccent : Colors.green, size: 18),
                                        onPressed: () => ref.read(customersProvider.notifier).toggleCustomerStatus(cust.id, !cust.isActive),
                                        tooltip: cust.isActive ? 'Block Customer' : 'Unblock Customer',
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
                  'Total Customers: ${state.total}',
                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: state.page > 1
                          ? () => ref.read(customersProvider.notifier).fetchCustomers(page: state.page - 1)
                          : null,
                    ),
                    Text('Page ${state.page} of ${state.totalPages}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded),
                      onPressed: state.page < state.totalPages
                          ? () => ref.read(customersProvider.notifier).fetchCustomers(page: state.page + 1)
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

class _CustomerDetailsDialog extends ConsumerWidget {
  final String customerId;
  const _CustomerDetailsDialog({required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(customersProvider);
    final customer = state.selectedCustomer;

    return AlertDialog(
      title: const Text('Customer Profile details'),
      content: customer == null
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    leading: CircleAvatar(child: Text(customer.name[0])),
                    title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(customer.isVip ? 'VIP Customer' : 'Standard Customer'),
                  ),
                  const Divider(),
                  _buildDetailRow('Phone Number', customer.phoneNumber),
                  _buildDetailRow('Email Address', customer.email),
                  _buildDetailRow('Base Address', customer.address ?? 'Chennai, Tamil Nadu'),
                  _buildDetailRow('Total Spent', '₹${customer.totalSpend.toStringAsFixed(2)}'),
                  _buildDetailRow('Average Rating Given', '${customer.rating} ★'),
                  const SizedBox(height: 16),
                  const Text('Booking History:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  customer.bookings == null || customer.bookings!.isEmpty
                      ? const Text('No booking history available.')
                      : SizedBox(
                          height: 150,
                          child: ListView.builder(
                            itemCount: customer.bookings!.length,
                            itemBuilder: (context, index) {
                              final booking = customer.bookings![index];
                              return ListTile(
                                dense: true,
                                title: Text(booking.serviceIds.join(", ")),
                                subtitle: Text(booking.scheduledAt),
                                trailing: Text(booking.status),
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

class _EditCustomerDialog extends ConsumerStatefulWidget {
  final CustomerDto customer;
  const _EditCustomerDialog({required this.customer});

  @override
  ConsumerState<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends ConsumerState<_EditCustomerDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late bool _isVip;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer.name);
    _emailController = TextEditingController(text: widget.customer.email);
    _phoneController = TextEditingController(text: widget.customer.phoneNumber);
    _addressController = TextEditingController(text: widget.customer.address ?? '');
    _isVip = widget.customer.isVip;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Customer Profile'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 12),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 12),
            TextField(controller: _addressController, decoration: const InputDecoration(labelText: 'Address')),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Mark as VIP Customer'),
                Switch(
                  value: _isVip,
                  onChanged: (val) => setState(() => _isVip = val),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryTeal),
          onPressed: () async {
            Navigator.pop(context);
            final success = await ref.read(customersProvider.notifier).updateCustomer(
                  widget.customer.id,
                  name: _nameController.text,
                  email: _emailController.text,
                  phoneNumber: _phoneController.text,
                  address: _addressController.text,
                  isVip: _isVip,
                );
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Customer details updated.')),
              );
            }
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
