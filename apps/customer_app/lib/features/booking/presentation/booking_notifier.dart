import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:project_phoenix_customer/core/database/sqlite_helper.dart';
import 'package:project_phoenix_customer/features/services/domain/entities/service_item.dart';
import 'package:project_phoenix_customer/features/booking/data/repositories/booking_repository.dart';
import 'package:project_phoenix_customer/core/network/minio_upload_service.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_api/shared_api.dart';

class BookingFormState {
  final List<ServiceItem> services;
  final String propertyName;
  final String address;
  final DateTime? date;
  final String timeSlot;
  final bool isEmergency;
  final String description;
  final List<String> imagePaths;
  final String? voiceNotePath;
  final String? voiceTranscript;
  final double estimatedPrice;
  final double discountAmount;
  final double totalAmount;
  final String? couponCode;
  final int currentStep;
  final String? generatedBookingId;
  final bool isOfflineSaved;
  final bool isLoading;
  final double? latitude;
  final double? longitude;
  final bool hasDraftRecovered;

  BookingFormState({
    this.services = const [],
    this.propertyName = 'Home',
    this.address = '',
    this.date,
    this.timeSlot = 'ANYTIME',
    this.isEmergency = false,
    this.description = '',
    this.imagePaths = const [],
    this.voiceNotePath,
    this.voiceTranscript,
    this.estimatedPrice = 0.0,
    this.discountAmount = 0.0,
    this.totalAmount = 0.0,
    this.couponCode,
    this.currentStep = 0,
    this.generatedBookingId,
    this.isOfflineSaved = false,
    this.isLoading = false,
    this.latitude,
    this.longitude,
    this.hasDraftRecovered = false,
  });

  BookingFormState copyWith({
    List<ServiceItem>? services,
    String? propertyName,
    String? address,
    DateTime? date,
    String? timeSlot,
    bool? isEmergency,
    String? description,
    List<String>? imagePaths,
    String? voiceNotePath,
    String? voiceTranscript,
    double? estimatedPrice,
    double? discountAmount,
    double? totalAmount,
    String? couponCode,
    int? currentStep,
    String? generatedBookingId,
    bool? isOfflineSaved,
    bool? isLoading,
    double? latitude,
    double? longitude,
    bool? hasDraftRecovered,
  }) {
    return BookingFormState(
      services: services ?? this.services,
      propertyName: propertyName ?? this.propertyName,
      address: address ?? this.address,
      date: date ?? this.date,
      timeSlot: timeSlot ?? this.timeSlot,
      isEmergency: isEmergency ?? this.isEmergency,
      description: description ?? this.description,
      imagePaths: imagePaths ?? this.imagePaths,
      voiceNotePath: voiceNotePath ?? this.voiceNotePath,
      voiceTranscript: voiceTranscript ?? this.voiceTranscript,
      estimatedPrice: estimatedPrice ?? this.estimatedPrice,
      discountAmount: discountAmount ?? this.discountAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      couponCode: couponCode ?? this.couponCode,
      currentStep: currentStep ?? this.currentStep,
      generatedBookingId: generatedBookingId ?? this.generatedBookingId,
      isOfflineSaved: isOfflineSaved ?? this.isOfflineSaved,
      isLoading: isLoading ?? this.isLoading,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hasDraftRecovered: hasDraftRecovered ?? this.hasDraftRecovered,
    );
  }

  /// Compute sum of base prices of all selected services.
  double get servicesBasePrice =>
      services.fold(0.0, (sum, s) => sum + s.basePrice);

  /// Compute sum of durations of all selected services.
  int get totalDurationMinutes =>
      services.fold(0, (sum, s) => sum + s.durationMinutes);
}

class BookingNotifier extends StateNotifier<BookingFormState> {
  final BookingRepository _bookingRepository;
  final MinioUploadService _minioUploadService;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  BookingNotifier(this._bookingRepository, this._minioUploadService) : super(BookingFormState());

  /// Called when entering the booking flow from catalog with a pre-selected service.
  void initBookingWithService(ServiceItem service) {
    final services = [service];
    final basePrice = service.basePrice;
    state = BookingFormState(
      services: services,
      estimatedPrice: basePrice,
      totalAmount: basePrice,
    );
    _loadDraft();
  }

  /// Toggle a service in/out of the selected list and recalculate pricing.
  void toggleService(ServiceItem service) {
    final current = List<ServiceItem>.from(state.services);
    final existingIndex = current.indexWhere((s) => s.id == service.id);
    if (existingIndex >= 0) {
      current.removeAt(existingIndex);
    } else {
      current.add(service);
    }

    final basePrice = current.fold(0.0, (sum, s) => sum + s.basePrice);
    final adjustedPrice = state.isEmergency ? basePrice * 1.25 : basePrice;

    double discount = 0.0;
    if (state.couponCode == 'PHOENIX15') {
      discount = adjustedPrice * 0.15;
    }

    state = state.copyWith(
      services: current,
      estimatedPrice: adjustedPrice,
      discountAmount: discount,
      totalAmount: adjustedPrice - discount,
    );
  }

  void _saveDraft() {
    try {
      _secureStorage.write(key: 'draft_property_name', value: state.propertyName);
      _secureStorage.write(key: 'draft_address', value: state.address);
      _secureStorage.write(key: 'draft_description', value: state.description);
      _secureStorage.write(key: 'draft_emergency', value: state.isEmergency.toString());
      if (state.latitude != null) {
        _secureStorage.write(key: 'draft_latitude', value: state.latitude.toString());
        _secureStorage.write(key: 'draft_longitude', value: state.longitude.toString());
      }
    } catch (_) {}
  }

  Future<void> _loadDraft() async {
    try {
      final name = await _secureStorage.read(key: 'draft_property_name');
      final address = await _secureStorage.read(key: 'draft_address');
      final desc = await _secureStorage.read(key: 'draft_description');
      final isEmergencyStr = await _secureStorage.read(key: 'draft_emergency');
      final latStr = await _secureStorage.read(key: 'draft_latitude');
      final lngStr = await _secureStorage.read(key: 'draft_longitude');

      if (name != null || address != null || desc != null) {
        state = state.copyWith(
          propertyName: name ?? state.propertyName,
          address: address ?? state.address,
          description: desc ?? state.description,
          isEmergency: isEmergencyStr == 'true' ? true : state.isEmergency,
          latitude: latStr != null ? double.tryParse(latStr) : null,
          longitude: lngStr != null ? double.tryParse(lngStr) : null,
          hasDraftRecovered: true,
        );
      }
    } catch (_) {}
  }

  Future<void> clearDraft() async {
    try {
      await _secureStorage.delete(key: 'draft_property_name');
      await _secureStorage.delete(key: 'draft_address');
      await _secureStorage.delete(key: 'draft_description');
      await _secureStorage.delete(key: 'draft_emergency');
      await _secureStorage.delete(key: 'draft_latitude');
      await _secureStorage.delete(key: 'draft_longitude');
    } catch (_) {}
  }

  void updateProperty(String name, String address) {
    state = state.copyWith(propertyName: name, address: address);
    _saveDraft();
  }

  void updateCoordinates(double lat, double lng) {
    state = state.copyWith(latitude: lat, longitude: lng);
    _saveDraft();
  }

  void updateDateTime(DateTime? date, String slot) {
    state = state.copyWith(date: date, timeSlot: slot);
    _saveDraft();
  }

  void toggleEmergency(bool isEmergency) {
    final basePrice = state.services.fold(0.0, (sum, s) => sum + s.basePrice);
    final adjustedPrice = isEmergency ? basePrice * 1.25 : basePrice;

    double discount = 0.0;
    if (state.couponCode == 'PHOENIX15') {
      discount = adjustedPrice * 0.15;
    }

    state = state.copyWith(
      isEmergency: isEmergency,
      estimatedPrice: adjustedPrice,
      discountAmount: discount,
      totalAmount: adjustedPrice - discount,
    );
    _saveDraft();
  }

  bool applyCoupon(String code) {
    if (code.trim().toUpperCase() == 'PHOENIX15') {
      final discount = state.estimatedPrice * 0.15;
      state = state.copyWith(
        couponCode: 'PHOENIX15',
        discountAmount: discount,
        totalAmount: state.estimatedPrice - discount,
      );
      _saveDraft();
      return true;
    }
    return false;
  }

  void removeCoupon() {
    state = BookingFormState(
      services: state.services,
      propertyName: state.propertyName,
      address: state.address,
      date: state.date,
      timeSlot: state.timeSlot,
      isEmergency: state.isEmergency,
      description: state.description,
      imagePaths: state.imagePaths,
      voiceNotePath: state.voiceNotePath,
      voiceTranscript: state.voiceTranscript,
      estimatedPrice: state.estimatedPrice,
      discountAmount: 0.0,
      totalAmount: state.estimatedPrice,
      couponCode: null,
      currentStep: state.currentStep,
      generatedBookingId: state.generatedBookingId,
      isOfflineSaved: state.isOfflineSaved,
      isLoading: state.isLoading,
      latitude: state.latitude,
      longitude: state.longitude,
      hasDraftRecovered: state.hasDraftRecovered,
    );
    _saveDraft();
  }

  void updateDescription(String desc) {
    state = state.copyWith(description: desc);
    _saveDraft();
  }

  void addImage(String path) {
    state = state.copyWith(imagePaths: [...state.imagePaths, path]);
    _saveDraft();
  }

  void removeImage(int index) {
    final list = List<String>.from(state.imagePaths)..removeAt(index);
    state = state.copyWith(imagePaths: list);
    _saveDraft();
  }

  void addVoiceNote(String path, {String? transcript}) {
    state = state.copyWith(
      voiceNotePath: path,
      voiceTranscript:
          transcript ?? 'Leaking pipe under the main basin in kitchen.',
    );
    _saveDraft();
  }

  void setStep(int step) {
    state = state.copyWith(currentStep: step);
  }

  Future<bool> confirmBooking(String customerId) async {
    state = state.copyWith(isLoading: true);
    final bookingId = 'PHX-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final serviceIdsCombined = state.services.map((s) => s.id).join(',');

    try {
      // Try to upload images to MinIO
      final List<String> uploadedImageUrls = [];
      if (!kIsWeb) {
        for (var path in state.imagePaths) {
          if (path.isNotEmpty) {
            final file = File(path);
            if (await file.exists()) {
              final url = await _minioUploadService.uploadFile(file, 'project-phoenix');
              uploadedImageUrls.add(url);
            }
          }
        }
      }

      // Try to upload voice note to MinIO
      String? voiceUrl;
      if (!kIsWeb && state.voiceNotePath != null && state.voiceNotePath!.isNotEmpty) {
        final file = File(state.voiceNotePath!);
        if (await file.exists()) {
          voiceUrl = await _minioUploadService.uploadFile(file, 'project-phoenix');
        }
      }

      final bookingDto = BookingDto(
        localId: bookingId,
        customerId: customerId,
        propertyId: '',
        address: state.address,
        serviceIds: state.services.map((s) => s.id).toList(),
        scheduledAt: state.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
        timeSlot: state.timeSlot,
        isEmergency: state.isEmergency,
        description: state.description.trim().isEmpty ? 'No description provided' : state.description.trim(),
        imagePaths: uploadedImageUrls,
        voiceNotePath: voiceUrl,
        voiceTranscript: state.voiceTranscript,
        estimatedPrice: state.totalAmount,
        latitude: state.latitude,
        longitude: state.longitude,
        status: 'PENDING',
        createdAt: DateTime.now().toIso8601String(),
      );

      // Verify createBooking() is calling the backend
      final result = await _bookingRepository.createBooking(bookingDto);
      await clearDraft();

      // Ensure successful booking creation returns the backend booking immediately
      state = state.copyWith(
        isLoading: false,
        generatedBookingId: result.localId ?? bookingId,
        isOfflineSaved: false,
      );
      return true;
    } catch (e) {
      // Check if it is a true network/timeout failure
      if (_isNetworkError(e)) {
        // Only true network failures use the SQLite offline queue
        final offlineBooking = {
          'local_id': bookingId,
          'customer_id': customerId,
          'property_id': '',
          'address': state.address,
          'service_id': serviceIdsCombined,
          'scheduled_at': state.date?.toIso8601String() ?? DateTime.now().toIso8601String(),
          'time_slot': state.timeSlot,
          'is_emergency': state.isEmergency ? 1 : 0,
          'description': state.description.trim().isEmpty ? 'No description provided' : state.description.trim(),
          'image_paths': state.imagePaths.join(','),
          'voice_note_path': state.voiceNotePath ?? '',
          'estimated_price': state.totalAmount,
          'status': 'PENDING_SYNC',
          'created_at': DateTime.now().toIso8601String(),
        };

        await SqliteHelper().enqueueBooking(offlineBooking);
        state = state.copyWith(
          isLoading: false,
          generatedBookingId: bookingId,
          isOfflineSaved: true,
        );
        return true;
      } else {
        // It's a non-network exception (e.g. 400 Bad Request, 500, or a programming exception)
        // We do NOT use the offline queue, and we bubble/rethrow the exception.
        state = state.copyWith(isLoading: false);
        rethrow;
      }
    }
  }

  bool _isNetworkError(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.connectionError) {
        return true;
      }
      if (error.type == DioExceptionType.unknown) {
        final msg = error.message?.toLowerCase() ?? '';
        if (msg.contains('socketexception') ||
            msg.contains('xmlhttprequest') ||
            error.response == null) {
          return true;
        }
      }
    } else if (error is ApiException) {
      if (error.type == ApiExceptionType.network ||
          error.type == ApiExceptionType.timeout) {
        return true;
      }
    } else if (error.toString().toLowerCase().contains('socketexception') ||
               error.toString().toLowerCase().contains('xmlhttprequest')) {
      return true;
    }
    return false;
  }

  // Sync worker to process offline queue bookings
  Future<void> syncOfflineQueue() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) return;

    final queuedList = await SqliteHelper().getQueuedBookings();
    if (queuedList.isEmpty) return;

    for (var item in queuedList) {
      try {
        final List<String> localImagePaths = (item['image_paths'] as String).split(',').where((p) => p.isNotEmpty).toList();
        final List<String> uploadedUrls = [];

        // Upload local images to MinIO
        if (!kIsWeb) {
          for (var path in localImagePaths) {
            final file = File(path);
            if (await file.exists()) {
              final url = await _minioUploadService.uploadFile(file, 'project-phoenix');
              uploadedUrls.add(url);
            }
          }
        }

        // Upload voice note to MinIO
        String? voiceUrl;
        final localVoicePath = item['voice_note_path'] as String;
        if (!kIsWeb && localVoicePath.isNotEmpty) {
          final file = File(localVoicePath);
          if (await file.exists()) {
            voiceUrl = await _minioUploadService.uploadFile(file, 'project-phoenix');
          }
        }

        // Parse service IDs from comma-separated string
        final rawServiceId = item['service_id'] as String;
        final serviceIdsList = rawServiceId.split(',').where((s) => s.isNotEmpty).toList();

        // Post booking to NestJS
        final bookingDto = BookingDto(
          localId: item['local_id'] as String,
          customerId: item['customer_id'] as String,
          propertyId: item['property_id'] as String,
          address: item['address'] as String,
          serviceIds: serviceIdsList,
          scheduledAt: item['scheduled_at'] as String,
          timeSlot: item['time_slot'] as String,
          isEmergency: (item['is_emergency'] as int) == 1,
          description: item['description'] as String? ?? '',
          imagePaths: uploadedUrls,
          voiceNotePath: voiceUrl,
          voiceTranscript: 'Simulated offline sync voice transcript',
          estimatedPrice: (item['estimated_price'] as num).toDouble(),
          status: 'PENDING',
          createdAt: item['created_at'] as String,
        );

        await _bookingRepository.createBooking(bookingDto);

        // Delete from local SQLite queue on success
        await SqliteHelper().removeQueuedBooking(item['local_id'] as String);
      } catch (_) {
        // Continue processing others
      }
    }
  }
}

final bookingNotifierProvider =
    StateNotifierProvider<BookingNotifier, BookingFormState>((ref) {
  final bookingRepo = ref.watch(bookingRepositoryProvider);
  final apiClient = ref.watch(apiClientProvider);
  final minioUpload = MinioUploadService(apiClient);
  return BookingNotifier(bookingRepo, minioUpload);
});
