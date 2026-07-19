import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';

class TechnicianDto {
  final String id;
  final String technicianId;
  final String name;
  final String phoneNumber;
  final String email;
  final String branch;
  final List<String> skills;
  final List<String> serviceAreas;
  final String experience;
  final bool isActive;
  final bool isOnline;
  final double rating;
  final int completedJobsCount;
  final double earnings;
  final String? currentJobId;
  final String? currentJobAddress;
  final double acceptanceRate;
  final double completionRate;

  TechnicianDto({
    required this.id,
    required this.technicianId,
    required this.name,
    required this.phoneNumber,
    required this.email,
    required this.branch,
    required this.skills,
    required this.serviceAreas,
    required this.experience,
    required this.isActive,
    required this.isOnline,
    required this.rating,
    required this.completedJobsCount,
    required this.earnings,
    this.currentJobId,
    this.currentJobAddress,
    required this.acceptanceRate,
    required this.completionRate,
  });

  factory TechnicianDto.fromJson(Map<String, dynamic> json) {
    return TechnicianDto(
      id: json['id'] as String? ?? '',
      technicianId: json['technicianId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String? ?? '',
      email: json['email'] as String? ?? '',
      branch: json['branch'] as String? ?? '',
      skills: (json['skills'] as List?)?.map((e) => e.toString()).toList() ?? [],
      serviceAreas: (json['serviceAreas'] as List?)?.map((e) => e.toString()).toList() ?? [],
      experience: json['experience'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      rating: (json['rating'] as num? ?? 4.9).toDouble(),
      completedJobsCount: json['completedJobsCount'] as int? ?? 0,
      earnings: (json['earnings'] as num? ?? 0.0).toDouble(),
      currentJobId: json['currentJobId'] as String?,
      currentJobAddress: json['currentJobAddress'] as String?,
      acceptanceRate: (json['acceptanceRate'] as num? ?? 96.0).toDouble(),
      completionRate: (json['completionRate'] as num? ?? 98.0).toDouble(),
    );
  }
}

class TechniciansState {
  final bool isLoading;
  final List<TechnicianDto> technicians;
  final String? errorMessage;
  final String search;
  final String branch;
  final String isActiveFilter; // 'all', 'true', 'false'

  TechniciansState({
    required this.isLoading,
    required this.technicians,
    this.errorMessage,
    required this.search,
    required this.branch,
    required this.isActiveFilter,
  });

  factory TechniciansState.initial() => TechniciansState(
        isLoading: false,
        technicians: [],
        search: '',
        branch: '',
        isActiveFilter: 'all',
      );

  TechniciansState copyWith({
    bool? isLoading,
    List<TechnicianDto>? technicians,
    String? errorMessage,
    String? search,
    String? branch,
    String? isActiveFilter,
  }) {
    return TechniciansState(
      isLoading: isLoading ?? this.isLoading,
      technicians: technicians ?? this.technicians,
      errorMessage: errorMessage,
      search: search ?? this.search,
      branch: branch ?? this.branch,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
    );
  }
}

class TechniciansNotifier extends StateNotifier<TechniciansState> {
  final ApiClient _apiClient;

  TechniciansNotifier(this._apiClient) : super(TechniciansState.initial()) {
    fetchTechnicians();
  }

  Future<void> fetchTechnicians({String? search, String? branch, String? isActiveFilter}) async {
    final querySearch = search ?? state.search;
    final queryBranch = branch ?? state.branch;
    final queryIsActiveFilter = isActiveFilter ?? state.isActiveFilter;

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      search: querySearch,
      branch: queryBranch,
      isActiveFilter: queryIsActiveFilter,
    );

    try {
      final queryParams = <String, String>{};
      if (querySearch.trim().isNotEmpty) {
        queryParams['search'] = querySearch;
      }
      if (queryBranch.trim().isNotEmpty) {
        queryParams['branch'] = queryBranch;
      }
      if (queryIsActiveFilter != 'all') {
        queryParams['isActive'] = queryIsActiveFilter;
      }

      final uri = Uri(path: '/admin/technicians', queryParameters: queryParams).toString();
      final response = await _apiClient.get(uri);

      if (response.statusCode == 200) {
        final list = response.data as List;
        final techs = list.map((json) => TechnicianDto.fromJson(json)).toList();
        state = state.copyWith(isLoading: false, technicians: techs);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve technicians.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  Future<Map<String, dynamic>?> createTechnician({
    required String name,
    required String phoneNumber,
    required String email,
    required String branch,
    required List<String> skills,
    required List<String> serviceAreas,
    required String experience,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.post('/admin/technician', data: {
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'branch': branch,
        'skills': skills,
        'serviceAreas': serviceAreas,
        'experience': experience,
        'password': password,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchTechnicians();
        return response.data as Map<String, dynamic>?;
      }
      state = state.copyWith(isLoading: false);
      return null;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return null;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return null;
    }
  }

  Future<bool> updateTechnician(
    String id, {
    required String name,
    required String phoneNumber,
    required String email,
    required String branch,
    required List<String> skills,
    required List<String> serviceAreas,
    required String experience,
  }) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.put('/admin/technician/$id', data: {
        'name': name,
        'phoneNumber': phoneNumber,
        'email': email,
        'branch': branch,
        'skills': skills,
        'serviceAreas': serviceAreas,
        'experience': experience,
      });

      if (response.statusCode == 200) {
        await fetchTechnicians();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }

  Future<bool> toggleStatus(String id, bool isActive) async {
    try {
      final response = await _apiClient.patch('/admin/technician/$id/status', data: {
        'isActive': isActive,
      });
      if (response.statusCode == 200) {
        await fetchTechnicians();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<String?> resetPassword(String id) async {
    try {
      final response = await _apiClient.post('/admin/technician/$id/reset-password');
      if (response.statusCode == 200) {
        return response.data['temporaryPassword'] as String?;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<bool> deleteTechnician(String id) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await _apiClient.delete('/admin/technician/$id');
      if (response.statusCode == 200) {
        await fetchTechnicians();
        return true;
      }
      state = state.copyWith(isLoading: false);
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false);
      return false;
    }
  }
}

final techniciansProvider = StateNotifierProvider<TechniciansNotifier, TechniciansState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TechniciansNotifier(apiClient);
});
