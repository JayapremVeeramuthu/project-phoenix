class Property {
  final String id;
  final String name;
  final String address;
  final List<String> installedAppliances;
  final List<String> warranties;
  final String amcStatus; // e.g. "Active - Expires Dec 2026", "None"
  final List<String> serviceHistory;
  final String notes;

  Property({
    required this.id,
    required this.name,
    required this.address,
    required this.installedAppliances,
    required this.warranties,
    required this.amcStatus,
    required this.serviceHistory,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'appliances': installedAppliances.join(','),
      'warranty_info': warranties.join(','),
      'amc_info': amcStatus,
      'service_history': serviceHistory.join(','),
      'notes': notes,
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'] as String,
      name: map['name'] as String,
      address: map['address'] as String,
      installedAppliances: (map['appliances'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      warranties: (map['warranty_info'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      amcStatus: map['amc_info'] as String? ?? 'None',
      serviceHistory: (map['service_history'] as String?)
              ?.split(',')
              .where((s) => s.isNotEmpty)
              .toList() ??
          [],
      notes: map['notes'] as String? ?? '',
    );
  }
}
