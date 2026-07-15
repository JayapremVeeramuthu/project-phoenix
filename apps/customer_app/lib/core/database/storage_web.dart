import 'dart:convert';
import 'dart:html' as html;
import 'storage_interface.dart';

class WebStorage implements StorageInterface {
  @override
  Future<void> init() async {}

  String _getKey(String table) => 'project_phoenix_$table';

  Future<List<Map<String, dynamic>>> _getList(String table) async {
    final raw = html.window.localStorage[_getKey(table)];
    if (raw == null) return [];
    try {
      final List decoded = jsonDecode(raw);
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveList(String table, List<Map<String, dynamic>> list) async {
    html.window.localStorage[_getKey(table)] = jsonEncode(list);
  }

  @override
  Future<void> cacheProperties(List<Map<String, dynamic>> properties) async {
    await _saveList('properties', properties);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedProperties() async {
    return _getList('properties');
  }

  @override
  Future<void> cacheComplaintsHistory(List<Map<String, dynamic>> historyList) async {
    await _saveList('complaints_history', historyList);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedComplaintsHistory() async {
    return _getList('complaints_history');
  }

  @override
  Future<int> enqueueBooking(Map<String, dynamic> booking) async {
    final list = await _getList('bookings_queue');
    // Remove if exists
    list.removeWhere((item) => item['local_id'] == booking['local_id']);
    list.add(booking);
    await _saveList('bookings_queue', list);
    return 1;
  }

  @override
  Future<List<Map<String, dynamic>>> getQueuedBookings() async {
    final list = await _getList('bookings_queue');
    list.sort((a, b) {
      final aTime = a['created_at'] as String? ?? '';
      final bTime = b['created_at'] as String? ?? '';
      return aTime.compareTo(bTime);
    });
    return list;
  }

  @override
  Future<int> removeQueuedBooking(String localId) async {
    final list = await _getList('bookings_queue');
    final countBefore = list.length;
    list.removeWhere((item) => item['local_id'] == localId);
    await _saveList('bookings_queue', list);
    return countBefore - list.length;
  }

  @override
  Future<void> cacheServices(List<Map<String, dynamic>> services) async {
    await _saveList('services', services);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedServices() async {
    return _getList('services');
  }

  @override
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    await _saveList('profile', [profile]);
  }

  @override
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final list = await _getList('profile');
    if (list.isNotEmpty) return list.first;
    return null;
  }

  @override
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications) async {
    final list = await _getList('notifications');
    final map = {for (var item in list) item['id'] as String: item};
    for (var notif in notifications) {
      map[notif['id'] as String] = notif;
    }
    final newList = map.values.toList();
    newList.sort((a, b) {
      final aTime = a['created_at'] as String? ?? '';
      final bTime = b['created_at'] as String? ?? '';
      return bTime.compareTo(aTime);
    });
    await _saveList('notifications', newList);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    return _getList('notifications');
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    final list = await _getList('notifications');
    for (var item in list) {
      if (item['id'] == id) {
        item['is_read'] = 1;
      }
    }
    await _saveList('notifications', list);
  }
}

StorageInterface getPlatformStorage() => WebStorage();
