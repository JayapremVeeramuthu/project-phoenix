import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_theme/shared_theme.dart';
import 'package:shared_models/shared_models.dart';
import 'settings_notifier.dart';

class SettingsManagementScreen extends ConsumerStatefulWidget {
  const SettingsManagementScreen({super.key});

  @override
  ConsumerState<SettingsManagementScreen> createState() => _SettingsManagementScreenState();
}

class _SettingsManagementScreenState extends ConsumerState<SettingsManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Business Profile controllers
  final _businessNameController = TextEditingController();
  final _supportEmailController = TextEditingController();
  final _supportPhoneController = TextEditingController();
  final _taxController = TextEditingController();

  // Notification setup controllers
  final _smtpHostController = TextEditingController();
  final _smtpPortController = TextEditingController();
  final _smsGatewayController = TextEditingController();
  final _whatsappTokenController = TextEditingController();

  Map<String, List<String>> _permissionsMap = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _businessNameController.dispose();
    _supportEmailController.dispose();
    _supportPhoneController.dispose();
    _taxController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smsGatewayController.dispose();
    _whatsappTokenController.dispose();
    super.dispose();
  }

  void _loadSettings(SettingsDto settings) {
    if (_businessNameController.text.isEmpty) {
      _businessNameController.text = settings.businessName;
      _supportEmailController.text = settings.supportEmail;
      _supportPhoneController.text = settings.supportPhone;
      _taxController.text = settings.taxRatePercent.toString();

      _smtpHostController.text = settings.smtpHost;
      _smtpPortController.text = settings.smtpPort.toString();
      _smsGatewayController.text = settings.smsGatewayUrl;
      _whatsappTokenController.text = settings.whatsAppToken;

      _permissionsMap = Map.from(settings.permissions);
    }
  }

  void _saveAllSettings() async {
    final state = ref.read(settingsProvider);
    if (state.settings == null) return;

    final updated = SettingsDto(
      businessName: _businessNameController.text,
      supportEmail: _supportEmailController.text,
      supportPhone: _supportPhoneController.text,
      branches: state.settings!.branches,
      serviceAreas: state.settings!.serviceAreas,
      taxRatePercent: double.tryParse(_taxController.text) ?? 18.0,
      workingHoursStart: state.settings!.workingHoursStart,
      workingHoursEnd: state.settings!.workingHoursEnd,
      roles: state.settings!.roles,
      permissions: _permissionsMap,
      smtpHost: _smtpHostController.text,
      smtpPort: int.tryParse(_smtpPortController.text) ?? 587,
      smsGatewayUrl: _smsGatewayController.text,
      whatsAppToken: _whatsappTokenController.text,
    );

    final success = await ref.read(settingsProvider.notifier).updateSettings(updated);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.settings != null) {
      _loadSettings(state.settings!);
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        title: const Text('FSM Settings Portal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          ElevatedButton.icon(
            onPressed: _saveAllSettings,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Save Settings'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          const SizedBox(width: 16),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryTeal,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppTheme.primaryTeal,
          tabs: const [
            Tab(icon: Icon(Icons.business_rounded), text: 'Business Profile'),
            Tab(icon: Icon(Icons.vpn_key_rounded), text: 'Roles & Permissions'),
            Tab(icon: Icon(Icons.mail_outline_rounded), text: 'SMTP & Gateway'),
            Tab(icon: Icon(Icons.location_city_rounded), text: 'Coverage & Branches'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBusinessProfileTab(),
          _buildRolesPermissionsTab(),
          _buildGatewayTab(),
          _buildCoverageTab(state.settings),
        ],
      ),
    );
  }

  Widget _buildBusinessProfileTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Profile & Operating details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 24),
              TextField(controller: _businessNameController, decoration: const InputDecoration(labelText: 'Business Name')),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: _supportEmailController, decoration: const InputDecoration(labelText: 'Support Email'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _supportPhoneController, decoration: const InputDecoration(labelText: 'Support Phone'))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _taxController, decoration: const InputDecoration(labelText: 'Default Tax Rate (%)')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRolesPermissionsTab() {
    final allPermissions = ['view_bookings', 'edit_bookings', 'manage_technicians', 'view_revenue', 'view_analytics', 'manage_settings'];
    final roles = ['Super Admin', 'Branch Admin', 'Manager', 'Dispatcher', 'Support'];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Configurable Roles & Permissions Matrix', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Table(
                    border: TableBorder.all(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(6)),
                    children: [
                      // Header Row
                      TableRow(
                        decoration: BoxDecoration(color: Colors.grey.shade50),
                        children: [
                          const TableCell(child: Padding(padding: EdgeInsets.all(12.0), child: Text('Permission / Capability', style: TextStyle(fontWeight: FontWeight.bold)))),
                          ...roles.map((r) => TableCell(child: Padding(padding: const EdgeInsets.all(12.0), child: Center(child: Text(r, style: const TextStyle(fontWeight: FontWeight.bold)))))),
                        ],
                      ),
                      // Value Rows
                      ...allPermissions.map((perm) {
                        return TableRow(
                          children: [
                            TableCell(child: Padding(padding: const EdgeInsets.all(12.0), child: Text(perm.replaceAll('_', ' ').toUpperCase()))),
                            ...roles.map((role) {
                              final isGranted = _permissionsMap[role]?.contains(perm) ?? false;
                              return TableCell(
                                child: Center(
                                  child: Checkbox(
                                    value: isGranted,
                                    activeColor: AppTheme.primaryTeal,
                                    onChanged: (val) {
                                      setState(() {
                                        final list = _permissionsMap[role] ?? [];
                                        if (val == true) {
                                          if (!list.contains(perm)) list.add(perm);
                                        } else {
                                          list.remove(perm);
                                        }
                                        _permissionsMap[role] = list;
                                      });
                                    },
                                  ),
                                ),
                              );
                            }),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGatewayTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Gateway Protocols (SMTP, SMS & WhatsApp integrations)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: _smtpHostController, decoration: const InputDecoration(labelText: 'SMTP Server Host'))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _smtpPortController, decoration: const InputDecoration(labelText: 'SMTP Server Port'))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _smsGatewayController, decoration: const InputDecoration(labelText: 'SMS Gateway Dispatch API URL')),
              const SizedBox(height: 16),
              TextField(controller: _whatsappTokenController, decoration: const InputDecoration(labelText: 'WhatsApp Business API Token')),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverageTab(SettingsDto? settings) {
    if (settings == null) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Operating Branch Offices', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: settings.branches.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.location_city_rounded, color: AppTheme.primaryTeal),
                            title: Text(settings.branches[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Service coverage zones', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView.builder(
                        itemCount: settings.serviceAreas.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.map_rounded, color: Colors.blue),
                            title: Text(settings.serviceAreas[index]),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
