import 'dart:io';
import 'package:dio/dio.dart';
import 'api_client.dart';

class MinioUploadService {
  final ApiClient _apiClient;

  MinioUploadService(this._apiClient);

  Future<String> uploadFile(File file, String bucketName) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'bucket': bucketName,
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _apiClient.dio.post(
      '/media/upload',
      data: formData,
      options: Options(
        headers: {
          'Content-Type': 'multipart/form-data',
        },
      ),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 211 ||
        response.statusCode == 201) {
      return response.data['url'] as String;
    } else {
      throw Exception('Failed to upload file to MinIO bucket');
    }
  }
}
