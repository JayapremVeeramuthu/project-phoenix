import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/profile/domain/entities/property_model.dart';

class PropertyRepository {
  final ApiClient _apiClient;

  PropertyRepository(this._apiClient);

  Future<List<Property>> getProperties() async {
    try {
      final response = await _apiClient.get('/properties');
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((json) => Property.fromMap(json)).toList();
      }
      return [];
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<Property> addProperty(Property property) async {
    try {
      final response =
          await _apiClient.post('/properties', data: property.toMap());
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Property.fromMap(response.data);
      }
      throw Exception('Unexpected status: ${response.statusCode}');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }

  Future<void> deleteProperty(String id) async {
    try {
      await _apiClient.delete('/properties/$id');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        type: ApiExceptionType.unknown,
        message: e.toString(),
      );
    }
  }
}

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return PropertyRepository(apiClient);
});
