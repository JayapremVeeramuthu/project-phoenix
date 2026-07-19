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
  final String? customerName;
  final String? customerPhone;
  final String? technicianName;
  final String? technicianPhone;
  final String? technicianId;

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
    this.customerName,
    this.customerPhone,
    this.technicianName,
    this.technicianPhone,
    this.technicianId,
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
      'customerName': customerName,
      'customerPhone': customerPhone,
      'technicianName': technicianName,
      'technicianPhone': technicianPhone,
      'technicianId': technicianId,
    };
  }

  factory BookingDto.fromJson(Map<String, dynamic> json) {
    final rawServiceId = json['serviceId'] as String? ?? '';
    final customerData = json['customer'] is Map
        ? Map<String, dynamic>.from(json['customer'] as Map)
        : null;
    final technicianData = json['technician'] is Map
        ? Map<String, dynamic>.from(json['technician'] as Map)
        : null;
    return BookingDto(
      localId: json['id'] as String? ?? json['localId'] as String?,
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
      imagePaths: json['imageUrls'] is List
          ? (json['imageUrls'] as List).map((item) => item.toString()).toList()
          : [],
      voiceNotePath: json['voiceNoteUrl'] as String?,
      voiceTranscript: json['voiceTranscript'] as String?,
      estimatedPrice: (json['estimatedPrice'] as num?)?.toDouble() ?? 0.0,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      status: json['status'] as String? ?? 'PENDING',
      createdAt: json['createdAt'] as String? ?? '',
      customerName: customerData != null
          ? customerData['name'] as String?
          : (json['customerName'] as String?),
      customerPhone: customerData != null
          ? customerData['phoneNumber'] as String?
          : (json['customerPhone'] as String?),
      technicianName: technicianData != null
          ? technicianData['name'] as String?
          : (json['technicianName'] as String?),
      technicianPhone: technicianData != null
          ? technicianData['phoneNumber'] as String?
          : (json['technicianPhone'] as String?),
      technicianId: technicianData != null
          ? technicianData['technicianId'] as String?
          : (json['technicianId'] as String?),
    );
  }
}

class CustomerDto {
  final String id;
  final String name;
  final String phoneNumber;
  final String email;
  final String? avatarUrl;
  final bool isActive;
  final bool isVip;
  final String createdAt;
  final double totalSpend;
  final double rating;
  final int bookingsCount;
  final String? lastBookingDate;
  final String? address;
  final List<BookingDto>? bookings;

  CustomerDto({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.email,
    this.avatarUrl,
    required this.isActive,
    required this.isVip,
    required this.createdAt,
    required this.totalSpend,
    required this.rating,
    required this.bookingsCount,
    this.lastBookingDate,
    this.address,
    this.bookings,
  });

  factory CustomerDto.fromJson(Map<String, dynamic> json) {
    final list = json['bookings'] as List?;
    return CustomerDto(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isVip: json['isVip'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
      totalSpend: (json['totalSpend'] as num? ?? 0.0).toDouble(),
      rating: (json['rating'] as num? ?? 4.8).toDouble(),
      bookingsCount: json['bookingsCount'] as int? ?? 0,
      lastBookingDate: json['lastBookingDate'] as String?,
      address: json['address'] as String?,
      bookings: list != null
          ? list.map((b) => BookingDto.fromJson(Map<String, dynamic>.from(b as Map))).toList()
          : null,
    );
  }
}

class InvoiceDto {
  final String id;
  final String bookingId;
  final String localBookingId;
  final String customerName;
  final String technicianName;
  final double amount;
  final double taxAmount;
  final double discountAmount;
  final double totalAmount;
  final String status;
  final String paymentMethod;
  final String paymentId;
  final String createdAt;

  InvoiceDto({
    required this.id,
    required this.bookingId,
    required this.localBookingId,
    required this.customerName,
    required this.technicianName,
    required this.amount,
    required this.taxAmount,
    required this.discountAmount,
    required this.totalAmount,
    required this.status,
    required this.paymentMethod,
    required this.paymentId,
    required this.createdAt,
  });

  factory InvoiceDto.fromJson(Map<String, dynamic> json) {
    return InvoiceDto(
      id: json['id'] as String? ?? '',
      bookingId: json['bookingId'] as String? ?? '',
      localBookingId: json['localBookingId'] as String? ?? '',
      customerName: json['customerName'] as String? ?? '',
      technicianName: json['technicianName'] as String? ?? '',
      amount: (json['amount'] as num? ?? 0.0).toDouble(),
      taxAmount: (json['taxAmount'] as num? ?? 0.0).toDouble(),
      discountAmount: (json['discountAmount'] as num? ?? 0.0).toDouble(),
      totalAmount: (json['totalAmount'] as num? ?? 0.0).toDouble(),
      status: json['status'] as String? ?? 'UNPAID',
      paymentMethod: json['paymentMethod'] as String? ?? 'COD',
      paymentId: json['paymentId'] as String? ?? 'N/A',
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class ServiceCategoryDto {
  final String id;
  final String nameEn;
  final String nameTa;
  final String icon;
  final List<ServiceItemDto>? items;

  ServiceCategoryDto({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.icon,
    this.items,
  });

  factory ServiceCategoryDto.fromJson(Map<String, dynamic> json) {
    final list = json['items'] as List?;
    return ServiceCategoryDto(
      id: json['id'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameTa: json['nameTa'] as String? ?? '',
      icon: json['icon'] as String? ?? 'home_repair_service',
      items: list != null
          ? list.map((i) => ServiceItemDto.fromJson(Map<String, dynamic>.from(i as Map))).toList()
          : null,
    );
  }
}

class ServiceItemDto {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameTa;
  final String descriptionEn;
  final String descriptionTa;
  final double basePrice;
  final int durationMinutes;

  ServiceItemDto({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameTa,
    required this.descriptionEn,
    required this.descriptionTa,
    required this.basePrice,
    required this.durationMinutes,
  });

  factory ServiceItemDto.fromJson(Map<String, dynamic> json) {
    return ServiceItemDto(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameTa: json['nameTa'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionTa: json['descriptionTa'] as String? ?? '',
      basePrice: (json['basePrice'] as num? ?? 0.0).toDouble(),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
    );
  }
}

class PaymentStatsDto {
  final double totalPaid;
  final double totalUnpaid;
  final double onlineRevenue;
  final double codRevenue;
  final int paidCount;
  final int unpaidCount;
  final int refundCount;
  final double refundAmount;

  PaymentStatsDto({
    required this.totalPaid,
    required this.totalUnpaid,
    required this.onlineRevenue,
    required this.codRevenue,
    required this.paidCount,
    required this.unpaidCount,
    required this.refundCount,
    required this.refundAmount,
  });

  factory PaymentStatsDto.fromJson(Map<String, dynamic> json) {
    return PaymentStatsDto(
      totalPaid: (json['totalPaid'] as num? ?? 0.0).toDouble(),
      totalUnpaid: (json['totalUnpaid'] as num? ?? 0.0).toDouble(),
      onlineRevenue: (json['onlineRevenue'] as num? ?? 0.0).toDouble(),
      codRevenue: (json['codRevenue'] as num? ?? 0.0).toDouble(),
      paidCount: json['paidCount'] as int? ?? 0,
      unpaidCount: json['unpaidCount'] as int? ?? 0,
      refundCount: json['refundCount'] as int? ?? 0,
      refundAmount: (json['refundAmount'] as num? ?? 0.0).toDouble(),
    );
  }
}

class SystemLogDto {
  final String id;
  final String action;
  final String details;
  final String ipAddress;
  final String createdAt;
  final String userName;
  final String? userId;

  SystemLogDto({
    required this.id,
    required this.action,
    required this.details,
    required this.ipAddress,
    required this.createdAt,
    required this.userName,
    this.userId,
  });

  factory SystemLogDto.fromJson(Map<String, dynamic> json) {
    return SystemLogDto(
      id: json['id'] as String? ?? '',
      action: json['action'] as String? ?? '',
      details: json['details'] as String? ?? '',
      ipAddress: json['ipAddress'] as String? ?? '127.0.0.1',
      createdAt: json['createdAt'] as String? ?? '',
      userName: json['userName'] as String? ?? 'System',
      userId: json['userId'] as String?,
    );
  }
}

class NotificationDto {
  final String id;
  final String userId;
  final String title;
  final String message;
  final bool isRead;
  final String createdAt;

  NotificationDto({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationDto.fromJson(Map<String, dynamic> json) {
    return NotificationDto(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] as String? ?? '',
    );
  }
}

class SettingsDto {
  final String businessName;
  final String supportEmail;
  final String supportPhone;
  final List<String> branches;
  final List<String> serviceAreas;
  final double taxRatePercent;
  final String workingHoursStart;
  final String workingHoursEnd;
  final List<String> roles;
  final Map<String, List<String>> permissions;
  final String smtpHost;
  final int smtpPort;
  final String smsGatewayUrl;
  final String whatsAppToken;

  SettingsDto({
    required this.businessName,
    required this.supportEmail,
    required this.supportPhone,
    required this.branches,
    required this.serviceAreas,
    required this.taxRatePercent,
    required this.workingHoursStart,
    required this.workingHoursEnd,
    required this.roles,
    required this.permissions,
    required this.smtpHost,
    required this.smtpPort,
    required this.smsGatewayUrl,
    required this.whatsAppToken,
  });

  factory SettingsDto.fromJson(Map<String, dynamic> json) {
    final permissionsRaw = json['permissions'] as Map? ?? {};
    final permissionsMap = <String, List<String>>{};
    permissionsRaw.forEach((k, v) {
      if (v is List) {
        permissionsMap[k.toString()] = v.map((e) => e.toString()).toList();
      }
    });

    return SettingsDto(
      businessName: json['businessName'] as String? ?? '',
      supportEmail: json['supportEmail'] as String? ?? '',
      supportPhone: json['supportPhone'] as String? ?? '',
      branches: (json['branches'] as List?)?.map((e) => e.toString()).toList() ?? [],
      serviceAreas: (json['serviceAreas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      taxRatePercent: (json['taxRatePercent'] as num? ?? 18.0).toDouble(),
      workingHoursStart: json['workingHoursStart'] as String? ?? '08:00',
      workingHoursEnd: json['workingHoursEnd'] as String? ?? '20:00',
      roles: (json['roles'] as List?)?.map((e) => e.toString()).toList() ?? [],
      permissions: permissionsMap,
      smtpHost: json['smtpHost'] as String? ?? '',
      smtpPort: json['smtpPort'] as int? ?? 587,
      smsGatewayUrl: json['smsGatewayUrl'] as String? ?? '',
      whatsAppToken: json['whatsAppToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'supportEmail': supportEmail,
      'supportPhone': supportPhone,
      'branches': branches,
      'serviceAreas': serviceAreas,
      'taxRatePercent': taxRatePercent,
      'workingHoursStart': workingHoursStart,
      'workingHoursEnd': workingHoursEnd,
      'roles': roles,
      'permissions': permissions,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'smsGatewayUrl': smsGatewayUrl,
      'whatsAppToken': whatsAppToken,
    };
  }
}

class ChartItemDto {
  final String label;
  final double count;

  ChartItemDto({required this.label, required this.count});

  factory ChartItemDto.fromJson(Map<String, dynamic> json) {
    return ChartItemDto(
      label: json['label'] as String? ?? json['name'] as String? ?? '',
      count: (json['count'] as num? ?? json['amount'] as num? ?? 0.0).toDouble(),
    );
  }
}

class AnalyticsDto {
  final List<ChartItemDto> dailyBookings;
  final List<ChartItemDto> weeklyRevenue;
  final List<ChartItemDto> monthlyRevenue;
  final List<ChartItemDto> customerGrowth;
  final List<ChartItemDto> servicePopularity;
  final List<ChartItemDto> peakHours;
  final double completionRate;
  final double cancellationRate;
  final double repeatCustomerRate;
  final double averageServiceTime;

  AnalyticsDto({
    required this.dailyBookings,
    required this.weeklyRevenue,
    required this.monthlyRevenue,
    required this.customerGrowth,
    required this.servicePopularity,
    required this.peakHours,
    required this.completionRate,
    required this.cancellationRate,
    required this.repeatCustomerRate,
    required this.averageServiceTime,
  });

  factory AnalyticsDto.fromJson(Map<String, dynamic> json) {
    return AnalyticsDto(
      dailyBookings: (json['dailyBookings'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      weeklyRevenue: (json['weeklyRevenue'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      monthlyRevenue: (json['monthlyRevenue'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      customerGrowth: (json['customerGrowth'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      servicePopularity: (json['servicePopularity'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      peakHours: (json['peakHours'] as List?)?.map((e) => ChartItemDto.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? [],
      completionRate: (json['completionRate'] as num? ?? 0.0).toDouble(),
      cancellationRate: (json['cancellationRate'] as num? ?? 0.0).toDouble(),
      repeatCustomerRate: (json['repeatCustomerRate'] as num? ?? 0.0).toDouble(),
      averageServiceTime: (json['averageServiceTime'] as num? ?? 0.0).toDouble(),
    );
  }
}
