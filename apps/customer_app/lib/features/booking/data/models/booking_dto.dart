class BookingDto {
  final String? localId;
  final String customerId;
  final String propertyId;
  final String address;
  final List<String> serviceIds;
  final String scheduledAt;
  final String timeSlot;
  final bool isEmergency;
  final String description;
  final List<String> imagePaths;
  final String? voiceNotePath;
  final String? voiceTranscript;
  final double estimatedPrice;
  final double? latitude;
  final double? longitude;
  final String status;
  final String createdAt;

  BookingDto({
    this.localId,
    required this.customerId,
    required this.propertyId,
    required this.address,
    required this.serviceIds,
    required this.scheduledAt,
    required this.timeSlot,
    required this.isEmergency,
    required this.description,
    required this.imagePaths,
    this.voiceNotePath,
    this.voiceTranscript,
    required this.estimatedPrice,
    this.latitude,
    this.longitude,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'localId': localId,
      'customerId': customerId,
      'propertyId': propertyId,
      'address': address,
      'serviceId': serviceIds.join(','),
      'scheduledAt': scheduledAt,
      'timeSlot': timeSlot,
      'isEmergency': isEmergency,
      'description': description,
      'imageUrls': imagePaths,
      'voiceNoteUrl': voiceNotePath,
      'voiceTranscript': voiceTranscript,
      'estimatedPrice': estimatedPrice,
      'latitude': latitude,
      'longitude': longitude,
      'status': status,
      'createdAt': createdAt,
    };
  }

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    final rawServiceId = json['serviceId'] as String? ?? '';
    return BookingDto(
      localId: json['localId'] as String?,
      customerId: json['customerId'] as String? ?? '',
      propertyId: json['propertyId'] as String? ?? '',
      address: json['address'] as String? ?? '',
      serviceIds: rawServiceId.isNotEmpty
          ? rawServiceId.split(',').where((s) => s.isNotEmpty).toList()
          : [],
      scheduledAt: json['scheduledAt'] as String? ?? '',
      timeSlot: json['timeSlot'] as String? ?? '',
      isEmergency: json['isEmergency'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      imagePaths: (json['imageUrls'] as List?)
              ?.map((item) => item as String)
              .toList() ??
          [],
      voiceNotePath: json['voiceNoteUrl'] as String?,
      voiceTranscript: json['voiceTranscript'] as String?,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}
