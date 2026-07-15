import 'dart:async';
import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:image_picker/image_picker.dart';

class UploadProgressInfo {
  final int sent;
  final int total;
  final double fraction;

  UploadProgressInfo({
    required this.sent,
    required this.total,
    required this.fraction,
  });
}

class MediaService {
  final Dio _dio;
  final Connectivity _connectivity;
  final List<String> _offlineUploadQueue = [];
  final ImagePicker _picker = ImagePicker();

  MediaService({Dio? dio, Connectivity? connectivity})
      : _dio = dio ?? Dio(BaseOptions(baseUrl: 'http://localhost:3000/api/v1')),
        _connectivity = connectivity ?? Connectivity() {
    _monitorNetworkAndSync();
  }

  void _monitorNetworkAndSync() {
    _connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
      if (result != ConnectivityResult.none && _offlineUploadQueue.isNotEmpty) {
        _syncOfflineQueue();
      }
    });
  }

  /// Picks an image from camera or gallery and applies standard compression.
  /// Fully supported on Android and Flutter Web.
  Future<XFile?> pickAndCompressImage(String source, {int compressionQuality = 70}) async {
    final ImageSource imageSource = source == 'camera' ? ImageSource.camera : ImageSource.gallery;
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: imageSource,
        imageQuality: compressionQuality,
        maxWidth: 1080,
        maxHeight: 1080,
      );
      return pickedFile;
    } catch (e) {
      print('[DEBUG] Error picking image: $e');
      return null;
    }
  }

  /// Uploads an XFile directly to the backend.
  /// Uses in-memory bytes to ensure compatibility on Flutter Web where local File access is restricted.
  Future<String> uploadImageDirectly(
    XFile file, {
    Function(UploadProgressInfo)? onProgress,
  }) async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      // Offline mode: Queue file path for auto-sync and return simulated offline url
      final offlineUrl = 'offline_queue://${file.path}';
      _offlineUploadQueue.add(file.path);
      return offlineUrl;
    }

    try {
      final fileName = file.name;
      final bytes = await file.readAsBytes();
      
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: fileName,
          contentType: DioMediaType('image', 'jpeg'),
        ),
      });

      final response = await _dio.post(
        '/media/upload',
        data: formData,
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(UploadProgressInfo(
              sent: sent,
              total: total,
              fraction: total > 0 ? sent / total : 0.0,
            ));
          }
        },
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data['url'] as String;
      } else {
        throw Exception('Server rejected the upload with code: ${response.statusCode}');
      }
    } catch (e) {
      // Failover queueing
      _offlineUploadQueue.add(file.path);
      return 'offline_queue://${file.path}';
    }
  }

  Future<void> _syncOfflineQueue() async {
    final List<String> itemsToSync = List.from(_offlineUploadQueue);
    _offlineUploadQueue.clear();

    for (final path in itemsToSync) {
      try {
        final file = XFile(path);
        await uploadImageDirectly(file);
      } catch (_) {
        _offlineUploadQueue.add(path); // Re-queue on failure
      }
    }
  }

  List<String> get offlineQueue => _offlineUploadQueue;
}
