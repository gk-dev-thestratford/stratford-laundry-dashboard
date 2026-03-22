import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/department.dart';
import '../models/catalogue_item.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._();

  DatabaseService._();

  Future<Database> get database async {
    _database ??= await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final path = join(await getDatabasesPath(), 'stratford_laundry.db');
    return openDatabase(
      path,
      version: 2,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE orders ADD COLUMN parent_order_id TEXT');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE departments (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        can_submit_uniforms INTEGER NOT NULL DEFAULT 1,
        has_linen_items INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE item_catalogue (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        price REAL,
        department_id TEXT,
        sort_order INTEGER NOT NULL DEFAULT 0,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE admin_users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        pin_hash TEXT NOT NULL,
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');

    await db.execute('''
      CREATE TABLE orders (
        id TEXT PRIMARY KEY,
        docket_number TEXT NOT NULL,
        order_type TEXT NOT NULL,
        department_id TEXT,
        staff_name TEXT,
        email TEXT,
        room_number TEXT,
        guest_name TEXT,
        bag_count INTEGER,
        notes TEXT,
        status TEXT NOT NULL DEFAULT 'submitted',
        total_price REAL,
        parent_order_id TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        synced_at TEXT,
        remote_id TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE order_items (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        item_id TEXT NOT NULL,
        item_name TEXT NOT NULL,
        quantity_sent INTEGER NOT NULL,
        quantity_received INTEGER,
        price_at_time REAL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE order_status_log (
        id TEXT PRIMARY KEY,
        order_id TEXT NOT NULL,
        status TEXT NOT NULL,
        changed_by TEXT,
        changed_by_name TEXT,
        reason TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        operation TEXT NOT NULL,
        data TEXT NOT NULL,
        created_at TEXT NOT NULL,
        synced INTEGER NOT NULL DEFAULT 0
      )
    ''');

    // Seed data
    await _seedDepartments(db);
    await _seedCatalogueItems(db);
    await _seedAdminUsers(db);
  }

  Future<void> _seedDepartments(Database db) async {
    for (final dept in Department.seedData) {
      await db.insert('departments', {
        'id': dept.id,
        'code': dept.code,
        'name': dept.name,
        'can_submit_uniforms': dept.canSubmitUniforms ? 1 : 0,
        'has_linen_items': dept.hasLinenItems ? 1 : 0,
        'is_active': 1,
      });
    }
  }

  Future<void> _seedCatalogueItems(Database db) async {
    final allItems = [
      ...CatalogueItem.uniformItems,
      ...CatalogueItem.hskLinenItems,
      ...CatalogueItem.fnbLinenItems,
    ];
    for (final item in allItems) {
      await db.insert('item_catalogue', {
        'id': item.id,
        'code': item.code,
        'name': item.name,
        'category': item.category,
        'price': item.price,
        'department_id': item.departmentId,
        'sort_order': item.sortOrder,
        'is_active': 1,
      });
    }
  }

  Future<void> _seedAdminUsers(Database db) async {
    // Default admin users — PINs to be changed by Georgi
    final admins = [
      {'id': 'admin1', 'name': 'Georgi', 'pin': '1234'},
      {'id': 'admin2', 'name': 'Admin', 'pin': '0000'},
    ];
    for (final admin in admins) {
      final pinHash = sha256.convert(utf8.encode(admin['pin']!)).toString();
      await db.insert('admin_users', {
        'id': admin['id'],
        'name': admin['name'],
        'pin_hash': pinHash,
        'is_active': 1,
      });
    }
  }

  // ── Orders CRUD ──

  Future<String> insertOrder(Map<String, dynamic> order) async {
    final db = await database;
    await db.insert('orders', order);
    return order['id'] as String;
  }

  Future<void> insertOrderItems(List<Map<String, dynamic>> items) async {
    final db = await database;
    final batch = db.batch();
    for (final item in items) {
      batch.insert('order_items', item);
    }
    await batch.commit(noResult: true);
  }

  Future<void> insertStatusLog(Map<String, dynamic> log) async {
    final db = await database;
    await db.insert('order_status_log', log);
  }

  Future<List<Map<String, dynamic>>> getOrders({
    String? status,
    String? departmentId,
    String? orderType,
    String? dateFrom,
    String? searchQuery,
    int limit = 100,
    int offset = 0,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <dynamic>[];

    if (status != null) {
      where.add('o.status = ?');
      args.add(status);
    }
    if (departmentId != null) {
      where.add('o.department_id = ?');
      args.add(departmentId);
    }
    if (orderType != null) {
      where.add('o.order_type = ?');
      args.add(orderType);
    }
    if (dateFrom != null) {
      where.add('o.created_at >= ?');
      args.add(dateFrom);
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      where.add('(o.docket_number LIKE ? OR o.staff_name LIKE ? OR o.guest_name LIKE ?)');
      args.addAll(['%$searchQuery%', '%$searchQuery%', '%$searchQuery%']);
    }

    final whereClause = where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}';

    return db.rawQuery('''
      SELECT o.*, d.name as department_name, d.code as department_code
      FROM orders o
      LEFT JOIN departments d ON o.department_id = d.id
      $whereClause
      ORDER BY o.created_at DESC
      LIMIT ? OFFSET ?
    ''', [...args, limit, offset]);
  }

  Future<Map<String, dynamic>?> getOrder(String id) async {
    final db = await database;
    final results = await db.rawQuery('''
      SELECT o.*, d.name as department_name, d.code as department_code
      FROM orders o
      LEFT JOIN departments d ON o.department_id = d.id
      WHERE o.id = ?
    ''', [id]);
    return results.isEmpty ? null : results.first;
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final db = await database;
    return db.query('order_items', where: 'order_id = ?', whereArgs: [orderId]);
  }

  Future<List<Map<String, dynamic>>> getOrderStatusLog(String orderId) async {
    final db = await database;
    return db.query('order_status_log',
        where: 'order_id = ?', whereArgs: [orderId], orderBy: 'created_at ASC');
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final db = await database;
    await db.update(
      'orders',
      {'status': status, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [orderId],
    );
  }

  Future<void> updateReceivedQuantities(String orderId, Map<String, int> received) async {
    final db = await database;
    final batch = db.batch();
    for (final entry in received.entries) {
      batch.update(
        'order_items',
        {'quantity_received': entry.value},
        where: 'id = ? AND order_id = ?',
        whereArgs: [entry.key, orderId],
      );
    }
    await batch.commit(noResult: true);
  }

  /// Creates a new "outstanding" order from a partially received order.
  /// Clones the original order with remaining (sent - received) quantities.
  /// Returns the new order ID.
  Future<String> createOutstandingOrder({
    required String originalOrderId,
    required Map<String, int> receivedQuantities,
  }) async {
    final db = await database;
    final original = await getOrder(originalOrderId);
    final originalItems = await getOrderItems(originalOrderId);
    if (original == null) throw Exception('Order not found');

    final uuid = const Uuid();
    final newOrderId = uuid.v4();
    final now = DateTime.now().toIso8601String();

    await db.insert('orders', {
      'id': newOrderId,
      'docket_number': original['docket_number'],
      'order_type': original['order_type'],
      'department_id': original['department_id'],
      'staff_name': original['staff_name'],
      'email': original['email'],
      'room_number': original['room_number'],
      'guest_name': original['guest_name'],
      'bag_count': original['bag_count'],
      'notes': 'Outstanding from #${original['docket_number']}',
      'status': 'in_processing',
      'total_price': null,
      'parent_order_id': originalOrderId,
      'created_at': now,
      'updated_at': now,
    });

    final batch = db.batch();
    for (final item in originalItems) {
      final itemId = item['id'] as String;
      final sent = item['quantity_sent'] as int;
      final received = receivedQuantities[itemId] ?? 0;
      final outstanding = sent - received;

      if (outstanding > 0) {
        batch.insert('order_items', {
          'id': uuid.v4(),
          'order_id': newOrderId,
          'item_id': item['item_id'],
          'item_name': item['item_name'],
          'quantity_sent': outstanding,
          'quantity_received': null,
          'price_at_time': item['price_at_time'],
        });
      }
    }
    await batch.commit(noResult: true);

    return newOrderId;
  }

  Future<void> deleteOrder(String orderId) async {
    final db = await database;
    await db.delete('order_status_log', where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('order_items', where: 'order_id = ?', whereArgs: [orderId]);
    await db.delete('orders', where: 'id = ?', whereArgs: [orderId]);
  }

  // ── Departments ──

  Future<List<Map<String, dynamic>>> getDepartments({bool activeOnly = true}) async {
    final db = await database;
    if (activeOnly) {
      return db.query('departments', where: 'is_active = 1');
    }
    return db.query('departments');
  }

  /// Replace all departments with fresh data from Supabase
  Future<void> syncDepartments(List<Map<String, dynamic>> remoteDepts) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('departments');
      for (final dept in remoteDepts) {
        await txn.insert('departments', {
          'id': dept['id'],
          'code': dept['code'] ?? '',
          'name': dept['name'],
          'can_submit_uniforms': (dept['can_submit_uniforms'] == true) ? 1 : 0,
          'has_linen_items': (dept['has_linen_items'] == true) ? 1 : 0,
          'is_active': (dept['is_active'] == true) ? 1 : 0,
        });
      }
    });
  }

  // ── Catalogue Items ──

  Future<List<Map<String, dynamic>>> getCatalogueItems({String? category}) async {
    final db = await database;
    if (category != null) {
      return db.query('item_catalogue',
          where: 'is_active = 1 AND category = ?',
          whereArgs: [category],
          orderBy: 'sort_order');
    }
    return db.query('item_catalogue', where: 'is_active = 1', orderBy: 'sort_order');
  }

  /// Replace all catalogue items with fresh data from Supabase
  Future<void> syncCatalogueItems(List<Map<String, dynamic>> remoteItems) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('item_catalogue');
      for (final item in remoteItems) {
        await txn.insert('item_catalogue', {
          'id': item['id'],
          'code': item['code'] ?? '',
          'name': item['name'],
          'category': item['category'] ?? 'uniform',
          'price': item['price'],
          'department_id': item['department_id'],
          'sort_order': item['sort_order'] ?? 0,
          'is_active': (item['is_active'] == true) ? 1 : 0,
        });
      }
    });
  }

  // ── Admin Users ──

  Future<List<Map<String, dynamic>>> getAdminUsers() async {
    final db = await database;
    return db.query('admin_users', where: 'is_active = 1');
  }

  /// Replace all admin users with fresh data from Supabase
  Future<void> syncAdminUsers(List<Map<String, dynamic>> remoteAdmins) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('admin_users');
      for (final admin in remoteAdmins) {
        await txn.insert('admin_users', {
          'id': admin['id'],
          'name': admin['name'],
          'pin_hash': admin['pin_hash'],
          'is_active': admin['is_active'] == true ? 1 : 0,
        });
      }
    });
  }

  Future<bool> verifyPin(String adminId, String pin) async {
    final db = await database;
    final pinHash = sha256.convert(utf8.encode(pin)).toString();
    final results = await db.query(
      'admin_users',
      where: 'id = ? AND pin_hash = ? AND is_active = 1',
      whereArgs: [adminId, pinHash],
    );
    return results.isNotEmpty;
  }

  // ── Sync Queue ──

  Future<void> addToSyncQueue(String tableName, String recordId, String operation, String data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'operation': operation,
      'data': data,
      'created_at': DateTime.now().toIso8601String(),
      'synced': 0,
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return db.query('sync_queue', where: 'synced = 0', orderBy: 'created_at ASC');
  }

  Future<void> markSynced(int id) async {
    final db = await database;
    await db.update('sync_queue', {'synced': 1}, where: 'id = ?', whereArgs: [id]);
  }

  // ── Dashboard Stats ──

  Future<Map<String, int>> getOrderCounts() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT status, COUNT(*) as count FROM orders GROUP BY status
    ''');
    final counts = <String, int>{};
    for (final row in result) {
      counts[row['status'] as String] = row['count'] as int;
    }
    return counts;
  }

  /// Returns a compact item summary string for each order ID, e.g. "62 Table Runner, 10 Napkin".
  Future<Map<String, String>> getOrderItemSummaries(List<String> orderIds) async {
    if (orderIds.isEmpty) return {};
    final db = await database;
    final summaries = <String, String>{};
    for (final id in orderIds) {
      final items = await db.query('order_items', where: 'order_id = ?', whereArgs: [id]);
      if (items.isNotEmpty) {
        summaries[id] = items.map((i) => '${i['quantity_sent']} ${i['item_name']}').join(', ');
      }
    }
    return summaries;
  }

  /// Returns the set of order IDs that have child "outstanding" orders (i.e. were partially received).
  Future<Set<String>> getPartialReceiptOrderIds() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT DISTINCT parent_order_id FROM orders WHERE parent_order_id IS NOT NULL',
    );
    return result.map((r) => r['parent_order_id'] as String).toSet();
  }

  /// Auto-expires completed orders older than [days] days.
  Future<int> autoExpireCompletedOrders({int days = 20}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();
    final now = DateTime.now().toIso8601String();

    final orders = await db.query('orders',
      where: "status = 'completed' AND updated_at < ?",
      whereArgs: [cutoff],
    );

    if (orders.isEmpty) return 0;

    final uuid = const Uuid();
    final batch = db.batch();
    for (final order in orders) {
      final orderId = order['id'] as String;
      batch.update(
        'orders',
        {'status': 'expired', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [orderId],
      );
      batch.insert('order_status_log', {
        'id': uuid.v4(),
        'order_id': orderId,
        'status': 'expired',
        'changed_by': 'system',
        'changed_by_name': 'Auto-expiry',
        'reason': 'Not collected within $days days',
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
    return orders.length;
  }
}
