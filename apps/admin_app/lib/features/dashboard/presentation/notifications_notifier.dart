import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_api/shared_api.dart';
import 'package:shared_models/shared_models.dart';

class NotificationsState {
  final List<NotificationDto> notifications;
  final bool isLoading;
  final String? errorMessage;

  NotificationsState({
    required this.notifications,
    required this.isLoading,
    this.errorMessage,
  });

  factory NotificationsState.initial() => NotificationsState(
        notifications: [],
        isLoading: false,
      );

  NotificationsState copyWith({
    List<NotificationDto>? notifications,
    bool? isLoading,
    String? errorMessage,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final ApiClient _apiClient;
  final Ref _ref;
  StreamSubscription? _createdSub;
  StreamSubscription? _acceptedSub;
  StreamSubscription? _statusSub;

  NotificationsNotifier(this._apiClient, this._ref) : super(NotificationsState.initial()) {
    fetchNotifications();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    final socket = _ref.read(socketServiceProvider);
    socket.connect();

    _createdSub = socket.bookingCreatedStream.listen((data) {
      final id = data['id'] ?? data['bookingId'] ?? 'booking_id';
      final isEmergency = data['isEmergency'] as bool? ?? false;
      _addNewNotification(
        title: isEmergency ? '🚨 Emergency Booking Created' : '📅 New Booking Registered',
        message: 'Booking ID: $id at address: ${data['address'] ?? 'General Location'}',
      );
    });

    _acceptedSub = socket.bookingAcceptedStream.listen((data) {
      _addNewNotification(
        title: '🛠️ Booking Accepted',
        message: 'Technician ${data['technicianName'] ?? 'assigned'} has accepted Booking: ${data['bookingId']}',
      );
    });

    _statusSub = socket.bookingStatusUpdatedStream.listen((data) {
      _addNewNotification(
        title: '🔄 Booking Status Updated',
        message: 'Booking ${data['bookingId']} is now: ${data['status']}',
      );
    });
  }

  void _addNewNotification({required String title, required String message}) {
    final mockNotification = NotificationDto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: 'admin',
      title: title,
      message: message,
      isRead: false,
      createdAt: DateTime.now().toIso8601String(),
    );
    state = state.copyWith(
      notifications: [mockNotification, ...state.notifications],
    );
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final response = await _apiClient.get('/admin/notifications');
      if (response.statusCode == 200) {
        final list = response.data as List? ?? [];
        final fetched = list.map((json) => NotificationDto.fromJson(Map<String, dynamic>.from(json as Map))).toList();
        state = state.copyWith(isLoading: false, notifications: fetched);
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'Failed to retrieve notifications.');
      }
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Connection failed.');
    }
  }

  Future<bool> markRead(String id) async {
    try {
      final response = await _apiClient.patch('/admin/notifications/$id/read');
      if (response.statusCode == 200) {
        state = state.copyWith(
          notifications: state.notifications.map((n) {
            if (n.id == id) {
              return NotificationDto(
                id: n.id,
                userId: n.userId,
                title: n.title,
                message: n.message,
                isRead: true,
                createdAt: n.createdAt,
              );
            }
            return n;
          }).toList(),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> deleteNotification(String id) async {
    try {
      final response = await _apiClient.delete('/admin/notifications/$id');
      if (response.statusCode == 200) {
        state = state.copyWith(
          notifications: state.notifications.where((n) => n.id != id).toList(),
        );
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  void dispose() {
    _createdSub?.cancel();
    _acceptedSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return NotificationsNotifier(apiClient, ref);
});
