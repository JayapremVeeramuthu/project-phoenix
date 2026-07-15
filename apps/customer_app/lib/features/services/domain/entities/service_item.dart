import 'package:flutter/material.dart';

class ServiceCategory {
  final String id;
  final String nameEn;
  final String nameTa;
  final IconData icon;
  final List<ServiceItem> items;

  ServiceCategory({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.icon,
    required this.items,
  });

  String getName(Locale locale) {
    return locale.languageCode == 'ta' ? nameTa : nameEn;
  }

  static IconData getIconData(String? iconName) {
    switch (iconName) {
      case 'home_repair_service':
        return Icons.home_repair_service_rounded;
      case 'handyman':
        return Icons.handyman_rounded;
      case 'cleaning_services':
        return Icons.cleaning_services_rounded;
      case 'medical_services':
        return Icons.medical_services_rounded;
      case 'spa':
        return Icons.spa_rounded;
      case 'local_shipping':
        return Icons.local_shipping_rounded;
      case 'yard':
        return Icons.yard_rounded;
      case 'devices':
        return Icons.devices_rounded;
      case 'celebration':
        return Icons.celebration_rounded;
      case 'school':
        return Icons.school_rounded;
      case 'business':
        return Icons.business_center_rounded;
      case 'star_rounded':
        return Icons.star_rounded;
      default:
        return Icons.category_rounded;
    }
  }

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameTa: json['nameTa'] as String? ?? '',
      icon: getIconData(json['icon'] as String?),
      items: (json['items'] as List?)
              ?.map(
                  (item) => ServiceItem.fromJson(item as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ServiceItem {
  final String id;
  final String categoryId;
  final String nameEn;
  final String nameTa;
  final String descriptionEn;
  final String descriptionTa;
  final double basePrice;
  final int durationMinutes;

  ServiceItem({
    required this.id,
    required this.categoryId,
    required this.nameEn,
    required this.nameTa,
    required this.descriptionEn,
    required this.descriptionTa,
    required this.basePrice,
    required this.durationMinutes,
  });

  String getName(Locale locale) {
    return locale.languageCode == 'ta' ? nameTa : nameEn;
  }

  String getDescription(Locale locale) {
    return locale.languageCode == 'ta' ? descriptionTa : descriptionEn;
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) {
    return ServiceItem(
      id: json['id'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      nameEn: json['nameEn'] as String? ?? '',
      nameTa: json['nameTa'] as String? ?? '',
      descriptionEn: json['descriptionEn'] as String? ?? '',
      descriptionTa: json['descriptionTa'] as String? ?? '',
      basePrice: (json['basePrice'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] as int? ?? 0,
    );
  }
}
