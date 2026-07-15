abstract class StorageInterface {
  Future<void> init();
  Future<void> cacheProperties(List<Map<String, dynamic>> properties);
  Future<List<Map<String, dynamic>>> getCachedProperties();
  Future<void> cacheComplaintsHistory(List<Map<String, dynamic>> historyList);
  Future<List<Map<String, dynamic>>> getCachedComplaintsHistory();
  Future<int> enqueueBooking(Map<String, dynamic> booking);
  Future<List<Map<String, dynamic>>> getQueuedBookings();
  Future<int> removeQueuedBooking(String localId);
  Future<void> cacheServices(List<Map<String, dynamic>> services);
  Future<List<Map<String, dynamic>>> getCachedServices();
  Future<void> cacheProfile(Map<String, dynamic> profile);
  Future<Map<String, dynamic>?> getCachedProfile();
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications);
  Future<List<Map<String, dynamic>>> getCachedNotifications();
  Future<void> markNotificationAsRead(String id);
}
