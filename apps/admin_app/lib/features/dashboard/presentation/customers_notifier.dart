import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class CustomersState {
  final List<CustomerDto> customers;
  final bool isLoading;
  final String? errorMessage;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final String searchQuery;
  final String? activeFilter; // 'all', 'true', 'false'
  final String? vipFilter; // 'all', 'true', 'false'
  final String sortBy;
  final String sortOrder;
  final CustomerDto? selectedCustomer;

  CustomersState({
    required this.customers,
    required this.isLoading,
    this.errorMessage,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.searchQuery,
    this.activeFilter,
    this.vipFilter,
    required this.sortBy,
    required this.sortOrder,
    this.selectedCustomer,
  });

  factory CustomersState.initial() => CustomersState(
        customers: [],
        isLoading: false,
        page: 1,
        limit: 10,
        total: 0,
        totalPages: 0,
        searchQuery: '',
        activeFilter: 'all',
        vipFilter: 'all',
        sortBy: 'createdAt',
        sortOrder: 'desc',
      );

  CustomersState copyWith({
    List<CustomerDto>? customers,
    bool? isLoading,
    String? errorMessage,
    int? page,
    int? limit,
    int? total,
    int? totalPages,
    String? searchQuery,
    String? activeFilter,
    String? vipFilter,
    String? sortBy,
    String? sortOrder,
    CustomerDto? selectedCustomer,
    bool clearSelected = false,
  }) {
    return CustomersState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      total: total ?? this.total,
      totalPages: totalPages ?? this.totalPages,
      searchQuery: searchQuery ?? this.searchQuery,
      activeFilter: activeFilter ?? this.activeFilter,
      vipFilter: vipFilter ?? this.vipFilter,
      sortBy: sortBy ?? this.sortBy,
      sortOrder: sortOrder ?? this.sortOrder,
      selectedCustomer: clearSelected ? null : (selectedCustomer ?? this.selectedCustomer),
    );
  }
}

class CustomersNotifier extends StateNotifier<CustomersState> {
  final ApiClient _apiClient;

  CustomersNotifier(this._apiClient) : super(CustomersState.initial()) {
    fetchCustomers();
  }

  Future<void> fetchCustomers({int? page}) async {
    final targetPage = page ?? state.page;
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final queryParams = <String, dynamic>{
        'page': targetPage.toString(),
        'limit': state.limit.toString(),
        'sortBy': state.sortBy,
        'sortOrder': state.sortOrder,
      };

      if (state.searchQuery.trim().isNotEmpty) {
        queryParams['search'] = state.searchQuery;
      }
      if (state.activeFilter != null && state.activeFilter != 'all') {
        queryParams['isActive'] = state.activeFilter;
      }
      if (state.vipFilter != null && state.vipFilter != 'all') {
        queryParams['isVip'] = state.vipFilter;
      }

      final uri = Uri(path: '/admin/customers', queryParameters: queryParams).toString();
      final response = await _apiClient.get(uri);

      if (response.statusCode == 200) {
        final list = response.data['data'] as List? ?? [];
        final meta = response.data['meta'] ?? {};
        final fetched = list.map((json) => CustomerDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();

        state = state.copyWith(
          isLoading: false,
          customers: fetched,
          page: targetPage,
          total: meta['total'] as int? ?? fetched.length,
          totalPages: meta['totalPages'] as int? ?? 1,
        );
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve customers.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query, page: 1);
    fetchCustomers();
  }

  void updateFilters({String? active, String? vip, String? sortBy, String? sortOrder}) {
    state = state.copyWith(
      activeFilter: active ?? state.activeFilter,
      vipFilter: vip ?? state.vipFilter,
      sortBy: sortBy ?? state.sortBy,
      sortOrder: sortOrder ?? state.sortOrder,
      page: 1,
    );
    fetchCustomers();
  }

  Future<void> getCustomerDetails(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/admin/customers/$id');
      if (response.statusCode == 200) {
        final customer = CustomerDto.fromJson(Map<String, dynamic>.from(response.data as Map));
        state = state.copyWith(isLoading: false, selectedCustomer: customer);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve customer details.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve customer details.');
    }
  }

  Future<bool> updateCustomer(String id, {required String name, required String email, required String phoneNumber, required String address, required bool isVip}) async {
    try {
      final response = await _apiClient.put('/admin/customers/$id', data: {
        'name': name,
        'email': email,
        'phoneNumber': phoneNumber,
        'address': address,
        'isVip': isVip,
      });
      if (response.statusCode == 200) {
        await fetchCustomers();
        if (state.selectedCustomer?.id == id) {
          await getCustomerDetails(id);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> toggleVIP(String id, bool isVip) async {
    final customer = state.customers.firstWhere((c) => c.id == id);
    return updateCustomer(
      id,
      name: customer.name,
      email: customer.email,
      phoneNumber: customer.phoneNumber,
      address: customer.address ?? '',
      isVip: isVip,
    );
  }

  Future<bool> toggleCustomerStatus(String id, bool isActive) async {
    try {
      final response = await _apiClient.patch('/admin/customers/$id/status', data: {
        'isActive': isActive,
      });
      if (response.statusCode == 200) {
        await fetchCustomers();
        if (state.selectedCustomer?.id == id) {
          await getCustomerDetails(id);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteCustomer(String id) async {
    try {
      final response = await _apiClient.delete('/admin/customers/$id');
      if (response.statusCode == 200) {
        await fetchCustomers();
        if (state.selectedCustomer?.id == id) {
          state = state.copyWith(clearSelected: true);
        }
        return true;
      }
    } catch (_) {}
    return false;
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, CustomersState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CustomersNotifier(apiClient);
});
