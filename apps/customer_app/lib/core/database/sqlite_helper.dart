import 'storage_interface.dart';
import 'storage_stub.dart'
    if (dart.library.html) 'storage_web.dart'
    if (dart.library.io) 'storage_mobile.dart';

class SqliteHelper {
  static final SqliteHelper _instance = SqliteHelper._internal();
  factory SqliteHelper() => _instance;
  SqliteHelper._internal();

  final StorageInterface _storage = getPlatformStorage();

  Future<void> init() async {
    await _storage.init();
  }

  Future<void> cacheProperties(List<Map<String, dynamic>> properties) => _storage.cacheProperties(properties);
  Future<List<Map<String, dynamic>>> getCachedProperties() => _storage.getCachedProperties();
  Future<void> cacheComplaintsHistory(List<Map<String, dynamic>> historyList) => _storage.cacheComplaintsHistory(historyList);
  Future<List<Map<String, dynamic>>> getCachedComplaintsHistory() => _storage.getCachedComplaintsHistory();
  Future<int> enqueueBooking(Map<String, dynamic> booking) => _storage.enqueueBooking(booking);
  Future<List<Map<String, dynamic>>> getQueuedBookings() => _storage.getQueuedBookings();
  Future<int> removeQueuedBooking(String localId) => _storage.removeQueuedBooking(localId);
  Future<void> cacheServices(List<Map<String, dynamic>> services) => _storage.cacheServices(services);
  Future<List<Map<String, dynamic>>> getCachedServices() => _storage.getCachedServices();
  Future<void> cacheProfile(Map<String, dynamic> profile) => _storage.cacheProfile(profile);
  Future<Map<String, dynamic>?> getCachedProfile() => _storage.getCachedProfile();
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications) => _storage.cacheNotifications(notifications);
  Future<List<Map<String, dynamic>>> getCachedNotifications() => _storage.getCachedNotifications();
  Future<void> markNotificationAsRead(String id) => _storage.markNotificationAsRead(id);
}
