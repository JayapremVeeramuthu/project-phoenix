import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_api/shared_api.dart';
import 'package:project_phoenix_customer/features/profile/presentation/warranties_screen.dart';

class WarrantyRepository {
  final ApiClient _apiClient;

  WarrantyRepository(this._apiClient);

  Future<List<WarrantyCard>> getWarranties() async {
    try {
      final response = await _apiClient.get('/warranties');
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((json) {
          return WarrantyCard(
            id: json['id'] as String? ?? '',
            itemName: json['itemName'] as String? ?? '',
            installDate: json['installDate'] as String? ?? '',
            expiryDate: json['expiryDate'] as String? ?? '',
            duration: json['duration'] as String? ?? '',
            status: json['status'] as String? ?? 'ACTIVE',
          );
        }).toList();
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

  Future<List<AmcContract>> getAmcContracts() async {
    try {
      final response = await _apiClient.get('/amc');
      if (response.statusCode == 200) {
        final list = response.data as List;
        return list.map((json) {
          return AmcContract(
            id: json['id'] as String? ?? '',
            applianceName: json['applianceName'] as String? ?? '',
            scheduleType: json['scheduleType'] as String? ?? '',
            nextServiceDate: json['nextServiceDate'] as String? ?? '',
            checksRemaining: json['checksRemaining'] as int? ?? 0,
            status: json['status'] as String? ?? 'ACTIVE',
          );
        }).toList();
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
}

final warrantyRepositoryProvider = Provider<WarrantyRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WarrantyRepository(apiClient);
});
