import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class ServicesState {
  final List<ServiceCategoryDto> categories;
  final bool isLoading;
  final String? errorMessage;
  final ServiceCategoryDto? selectedCategory;
  final ServiceItemDto? selectedItem;

  ServicesState({
    required this.categories,
    required this.isLoading,
    this.errorMessage,
    this.selectedCategory,
    this.selectedItem,
  });

  factory ServicesState.initial() => ServicesState(
        categories: [],
        isLoading: false,
      );

  ServicesState copyWith({
    List<ServiceCategoryDto>? categories,
    bool? isLoading,
    String? errorMessage,
    ServiceCategoryDto? selectedCategory,
    ServiceItemDto? selectedItem,
    bool clearSelectedCategory = false,
    bool clearSelectedItem = false,
  }) {
    return ServicesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedCategory: clearSelectedCategory ? null : (selectedCategory ?? this.selectedCategory),
      selectedItem: clearSelectedItem ? null : (selectedItem ?? this.selectedItem),
    );
  }
}

class ServicesNotifier extends StateNotifier<ServicesState> {
  final ApiClient _apiClient;

  ServicesNotifier(this._apiClient) : super(ServicesState.initial()) {
    fetchCatalog();
  }

  Future<void> fetchCatalog() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/services/categories?limit=100');
      if (response.statusCode == 200) {
        final list = response.data['data'] as List? ?? [];
        final fetched = list.map((json) => ServiceCategoryDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();
        state = state.copyWith(isLoading: false, categories: fetched);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to fetch services.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  // Category CRUD
  Future<bool> createCategory({required String id, required String nameEn, required String nameTa, String? icon}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.post('/admin/services/categories', data: {
        'id': id,
        'nameEn': nameEn,
        'nameTa': nameTa,
        'icon': icon,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> updateCategory(String id, {required String nameEn, required String nameTa, String? icon}) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.put('/admin/services/categories/$id', data: {
        'nameEn': nameEn,
        'nameTa': nameTa,
        'icon': icon,
      });
      if (response.statusCode == 200) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> deleteCategory(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.delete('/admin/services/categories/$id');
      if (response.statusCode == 200) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  // Item CRUD
  Future<bool> createItem({
    required String id,
    required String categoryId,
    required String nameEn,
    required String nameTa,
    required String descriptionEn,
    required String descriptionTa,
    required double basePrice,
    required int durationMinutes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.post('/admin/services/items', data: {
        'id': id,
        'categoryId': categoryId,
        'nameEn': nameEn,
        'nameTa': nameTa,
        'descriptionEn': descriptionEn,
        'descriptionTa': descriptionTa,
        'basePrice': basePrice,
        'durationMinutes': durationMinutes,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> updateItem(
    String id, {
    required String categoryId,
    required String nameEn,
    required String nameTa,
    required String descriptionEn,
    required String descriptionTa,
    required double basePrice,
    required int durationMinutes,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.put('/admin/services/items/$id', data: {
        'categoryId': categoryId,
        'nameEn': nameEn,
        'nameTa': nameTa,
        'descriptionEn': descriptionEn,
        'descriptionTa': descriptionTa,
        'basePrice': basePrice,
        'durationMinutes': durationMinutes,
      });
      if (response.statusCode == 200) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }

  Future<bool> deleteItem(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.delete('/admin/services/items/$id');
      if (response.statusCode == 200) {
        await fetchCatalog();
        return true;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
    return false;
  }
}

final servicesProvider = StateNotifierProvider<ServicesNotifier, ServicesState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ServicesNotifier(apiClient);
});
