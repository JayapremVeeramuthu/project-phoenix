import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'storage_interface.dart';

class MobileStorage implements StorageInterface {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  @override
  Future<void> init() async {
    await database;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'project_phoenix.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    // 1. Offline Booking Queue
    await db.execute('''
      CREATE TABLE offline_bookings_queue (
        local_id TEXT PRIMARY KEY,
        customer_id TEXT NOT NULL,
        property_id TEXT NOT NULL,
        address TEXT NOT NULL,
        service_id TEXT NOT NULL,
        scheduled_at TEXT NOT NULL,
        time_slot TEXT NOT NULL,
        is_emergency INTEGER DEFAULT 0,
        description TEXT,
        image_paths TEXT, -- JSON array of local file paths
        voice_note_path TEXT,
        estimated_price REAL,
        status TEXT DEFAULT 'PENDING_SYNC',
        created_at TEXT NOT NULL
      )
    ''');

    // 2. Cached Service Catalog
    await db.execute('''
      CREATE TABLE cached_services (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        duration_minutes INTEGER NOT NULL
      )
    ''');

    // 3. Cached Customer Profile
    await db.execute('''
      CREATE TABLE cached_profile (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        phone_number TEXT NOT NULL,
        avatar_url TEXT
      )
    ''');

    // 4. Cached Notifications
    await db.execute('''
      CREATE TABLE cached_notifications (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // 5. Cached Properties
    await db.execute('''
      CREATE TABLE cached_properties (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        address TEXT NOT NULL,
        appliances TEXT, -- Comma-separated or JSON list of installed appliances
        warranty_info TEXT,
        amc_info TEXT,
        service_history TEXT,
        notes TEXT
      )
    ''');

    // 6. Cached Complaints/Service History
    await db.execute('''
      CREATE TABLE cached_complaints_history (
        id TEXT PRIMARY KEY,
        service_name TEXT NOT NULL,
        date TEXT NOT NULL,
        complaint_notes TEXT,
        technician_notes TEXT,
        branch_notes TEXT,
        materials_used TEXT,
        recommendations TEXT
      )
    ''');
  }

  @override
  Future<void> cacheProperties(List<Map<String, dynamic>> properties) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_properties');
    for (var prop in properties) {
      batch.insert('cached_properties', prop);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedProperties() async {
    final db = await database;
    return await db.query('cached_properties');
  }

  @override
  Future<void> cacheComplaintsHistory(List<Map<String, dynamic>> historyList) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_complaints_history');
    for (var item in historyList) {
      batch.insert('cached_complaints_history', item);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedComplaintsHistory() async {
    final db = await database;
    return await db.query('cached_complaints_history');
  }

  @override
  Future<int> enqueueBooking(Map<String, dynamic> booking) async {
    final db = await database;
    return await db.insert(
      'offline_bookings_queue',
      booking,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getQueuedBookings() async {
    final db = await database;
    return await db.query('offline_bookings_queue', orderBy: 'created_at ASC');
  }

  @override
  Future<int> removeQueuedBooking(String localId) async {
    final db = await database;
    return await db.delete(
      'offline_bookings_queue',
      where: 'local_id = ?',
      whereArgs: [localId],
    );
  }

  @override
  Future<void> cacheServices(List<Map<String, dynamic>> services) async {
    final db = await database;
    final batch = db.batch();
    batch.delete('cached_services');
    for (var service in services) {
      batch.insert('cached_services', service);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedServices() async {
    final db = await database;
    return await db.query('cached_services');
  }

  @override
  Future<void> cacheProfile(Map<String, dynamic> profile) async {
    final db = await database;
    await db.delete('cached_profile');
    await db.insert('cached_profile', profile);
  }

  @override
  Future<Map<String, dynamic>?> getCachedProfile() async {
    final db = await database;
    final results = await db.query('cached_profile', limit: 1);
    if (results.isNotEmpty) return results.first;
    return null;
  }

  @override
  Future<void> cacheNotifications(List<Map<String, dynamic>> notifications) async {
    final db = await database;
    final batch = db.batch();
    for (var notif in notifications) {
      batch.insert('cached_notifications', notif,
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<List<Map<String, dynamic>>> getCachedNotifications() async {
    final db = await database;
    return await db.query('cached_notifications', orderBy: 'created_at DESC');
  }

  @override
  Future<void> markNotificationAsRead(String id) async {
    final db = await database;
    await db.update(
      'cached_notifications',
      {'is_read': 1},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

StorageInterface getPlatformStorage() => MobileStorage();
