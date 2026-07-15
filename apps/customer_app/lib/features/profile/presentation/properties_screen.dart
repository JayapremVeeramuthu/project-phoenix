import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:project_phoenix_customer/core/theme/settings_provider.dart';

class PropertyItem {
  final String name;
  final String address;
  final String propertyType; // Home, Office, Rental, Apartment, Farm
  final List<String> appliances;
  final List<String> warranties;
  final String amcDetails;
  final String notes;

  PropertyItem({
    required this.name,
    required this.address,
    required this.propertyType,
    this.appliances = const [],
    this.warranties = const [],
    this.amcDetails = 'None',
    this.notes = '',
  });
}

class PropertiesScreen extends ConsumerStatefulWidget {
  const PropertiesScreen({super.key});

  @override
  ConsumerState<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends ConsumerState<PropertiesScreen> {
  final List<PropertyItem> _properties = [
    PropertyItem(
      name: 'Main Home',
      propertyType: 'Home',
      address: 'Phoenix Tower B, Flat 405, OMR Road, Chennai - 600096',
      appliances: [
        'Daikin 1.5 Ton AC',
        'Havells 25L Geyser',
        'Crompton 1HP Water Pump'
      ],
      warranties: ['Havells Geyser - Expiry 20 Dec 2027'],
      amcDetails: 'Active - Annual AC Maintenance (#AMC-8930)',
      notes: 'Main residence. Best to contact in the afternoon.',
    ),
    PropertyItem(
      name: 'Commercial Shop',
      propertyType: 'Office',
      address: 'No. 12, T-Nagar Shopping Plaza, Chennai - 600017',
      appliances: ['CCTV Camera System', 'BlueStar Cassette AC'],
      warranties: ['CCTV System - Expiry 12 Jan 2028'],
      amcDetails: 'None',
      notes: 'Office hours only (9 AM - 6 PM).',
    ),
  ];

  final _nameController = TextEditingController();
  final _addrController = TextEditingController();
  final _notesController = TextEditingController();
  String _selectedType = 'Home';

  @override
  void dispose() {
    _nameController.dispose();
    _addrController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _showPropertyDetails(PropertyItem prop, bool isSeniorMode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.85,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prop.name,
                        style: TextStyle(
                            fontSize: isSeniorMode ? 24 : 20,
                            fontWeight: FontWeight.bold),
                      ),
                      Chip(label: Text(prop.propertyType)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    prop.address,
                    style: TextStyle(
                        color: Colors.black54,
                        fontSize: isSeniorMode ? 16 : 14),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Installed Appliances',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 18 : 15),
                  ),
                  const SizedBox(height: 8),
                  if (prop.appliances.isEmpty)
                    const Text('No appliances listed')
                  else
                    ...prop.appliances.map((app) => ListTile(
                          leading: const Icon(Icons.settings_suggest_outlined),
                          title: Text(app,
                              style:
                                  TextStyle(fontSize: isSeniorMode ? 16 : 14)),
                          dense: true,
                        )),
                  const Divider(height: 32),
                  Text(
                    'Active Warranties',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 18 : 15),
                  ),
                  const SizedBox(height: 8),
                  if (prop.warranties.isEmpty)
                    const Text('No active product warranties')
                  else
                    ...prop.warranties.map((warr) => ListTile(
                          leading: const Icon(Icons.workspace_premium_outlined,
                              color: Colors.amber),
                          title: Text(warr,
                              style:
                                  TextStyle(fontSize: isSeniorMode ? 16 : 14)),
                          dense: true,
                        )),
                  const Divider(height: 32),
                  Text(
                    'AMC Contracts',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 18 : 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prop.amcDetails,
                    style: TextStyle(
                        color: Colors.teal.shade800,
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 16 : 14),
                  ),
                  const Divider(height: 32),
                  Text(
                    'Property Notes',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: isSeniorMode ? 18 : 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    prop.notes.isEmpty
                        ? 'No custom property notes recorded.'
                        : prop.notes,
                    style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: isSeniorMode ? 16 : 14),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _addProperty() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add Property'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                        labelText: 'Property Name (e.g. Office)'),
                  ),
                  const SizedBox(height: 12),
                  // Dropdown for type
                  DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration:
                        const InputDecoration(labelText: 'Property Type'),
                    items: ['Home', 'Office', 'Rental', 'Apartment', 'Farm']
                        .map((type) {
                      return DropdownMenuItem(value: type, child: Text(type));
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _selectedType = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addrController,
                    decoration: const InputDecoration(labelText: 'Address'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    decoration:
                        const InputDecoration(labelText: 'Notes (Optional)'),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (_nameController.text.isNotEmpty &&
                      _addrController.text.isNotEmpty) {
                    setState(() {
                      _properties.add(PropertyItem(
                        name: _nameController.text.trim(),
                        propertyType: _selectedType,
                        address: _addrController.text.trim(),
                        notes: _notesController.text.trim(),
                      ));
                    });
                    _nameController.clear();
                    _addrController.clear();
                    _notesController.clear();
                    Navigator.pop(context);
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSeniorMode =
        ref.watch(settingsProvider.select((s) => s.isSeniorMode));

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Properties'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _addProperty,
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _properties.length,
        itemBuilder: (context, index) {
          final prop = _properties[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ListTile(
              leading: Icon(
                Icons.business_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: isSeniorMode ? 28 : 24,
              ),
              title: Text(
                prop.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isSeniorMode ? 18 : 16,
                ),
              ),
              subtitle: Text(
                prop.address,
                style: TextStyle(fontSize: isSeniorMode ? 14 : 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.chevron_right),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      setState(() {
                        _properties.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
              onTap: () => _showPropertyDetails(prop, isSeniorMode),
            ),
          );
        },
      ),
    );
  }
}
