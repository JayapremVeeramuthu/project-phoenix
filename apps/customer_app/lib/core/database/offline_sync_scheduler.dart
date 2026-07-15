import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:project_phoenix_customer/core/database/sqlite_helper.dart';
import 'package:project_phoenix_customer/core/network/api_client.dart';
import 'package:project_phoenix_customer/core/network/minio_upload_service.dart';

class OfflineSyncScheduler {
  final ApiClient _apiClient;
  final MinioUploadService _uploadService;
  StreamSubscription<ConnectivityResult>? _subscription;
  bool _isSyncing = false;

  OfflineSyncScheduler(this._apiClient)
      : _uploadService = MinioUploadService(_apiClient);

  void startListening() {
    _subscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none) {
        syncOfflineQueue();
      }
    });
  }

  void stopListening() {
    _subscription?.cancel();
  }

  Future<void> syncOfflineQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final queuedList = await SqliteHelper().getQueuedBookings();
      if (queuedList.isEmpty) {
        _isSyncing = false;
        return;
      }

      for (var row in queuedList) {
        final localId = row['local_id'] as String;
        final imagePathsRaw = row['image_paths'] as String? ?? '';
        final voiceNotePath = row['voice_note_path'] as String? ?? '';

        final List<String> remoteImageUrls = [];
        String? remoteVoiceUrl;

        try {
          // 1. Upload local images to MinIO if present
          if (!kIsWeb && imagePathsRaw.isNotEmpty) {
            final List<String> localPaths =
                imagePathsRaw.split(',').where((p) => p.isNotEmpty).toList();
            for (var path in localPaths) {
              if (File(path).existsSync()) {
                final url = await _uploadService.uploadFile(
                    File(path), 'customer-attachments');
                remoteImageUrls.add(url);
              }
            }
          }

          // 2. Upload local voice notes to MinIO if present
          if (!kIsWeb && voiceNotePath.isNotEmpty && File(voiceNotePath).existsSync()) {
            remoteVoiceUrl = await _uploadService.uploadFile(
                File(voiceNotePath), 'customer-voice-notes');
          }

          // 3. Post to backend NestJS endpoint
          final payload = {
            'localId': localId,
            'customerId': row['customer_id'],
            'propertyId': row['property_id'],
            'address': row['address'],
            'serviceId': row['service_id'],
            'scheduledAt': row['scheduled_at'],
            'timeSlot': row['time_slot'],
            'isEmergency': row['is_emergency'] == 1,
            'description': row['description'] ?? '',
            'imagePaths': remoteImageUrls,
            'voiceNotePath': remoteVoiceUrl,
            'estimatedPrice': row['estimated_price'],
          };

          final response =
              await _apiClient.dio.post('/bookings', data: payload);
          if (response.statusCode == 200 || response.statusCode == 201) {
            // Delete from offline queue upon successful sync
            await SqliteHelper().removeQueuedBooking(localId);
          }
        } catch (e) {
          // If a single record fails (e.g. duplicate key or validation error), proceed to other items
          continue;
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
