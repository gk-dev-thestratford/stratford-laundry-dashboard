import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import '../models/department.dart';
import '../models/catalogue_item.dart';
import '../models/announcement.dart';

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
      version: 8,
      onCreate: _createTables,
      onUpgrade: _upgradeTables,
    );
  }

  Future<void> _upgradeTables(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE orders ADD COLUMN parent_order_id TEXT');
    }
    if (oldVersion < 3) {
      await db.execute('ALTER TABLE admin_users ADD COLUMN can_delete_orders INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS linen_ledger (
          id TEXT PRIMARY KEY,
          item_name TEXT NOT NULL DEFAULT 'Linen Napkins',
          direction TEXT NOT NULL,
          quantity INTEGER NOT NULL,
          order_id TEXT,
          department_id TEXT,
          note TEXT,
          recorded_by TEXT,
          created_at TEXT NOT NULL
        )
      ''');
    }
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE admin_users ADD COLUMN can_reject_orders INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 6) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS item_department_access (
          item_id TEXT NOT NULL,
          department_id TEXT NOT NULL,
          PRIMARY KEY (item_id, department_id)
        )
      ''');
    }
    if (oldVersion < 7) {
      // Key-value table for sync bookkeeping (last-pull timestamps, etc.)
      await db.execute('''
        CREATE TABLE IF NOT EXISTS app_meta (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      // Speeds up dashboard tab queries (filter by status, sort by created_at),
      // search-by-docket, and the per-order item/log fetches.
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_status_created_at ON orders(status, created_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_docket_number ON orders(docket_number)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_updated_at ON orders(updated_at)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_order_status_log_order_id ON order_status_log(order_id)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_order_status_log_created_at ON order_status_log(created_at)');
    }
    if (oldVersion < 8) {
      // Scheduled message cards pushed from the dashboard
      await db.execute('''
        CREATE TABLE IF NOT EXISTS announcements (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT,
          starts_at TEXT NOT NULL,
          ends_at TEXT NOT NULL,
          severity TEXT NOT NULL DEFAULT 'info',
          is_active INTEGER NOT NULL DEFAULT 1
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_announcements_window ON announcements(starts_at, ends_at) WHERE is_active = 1');
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
        is_active INTEGER NOT NULL DEFAULT 1,
        can_delete_orders INTEGER NOT NULL DEFAULT 0,
        can_reject_orders INTEGER NOT NULL DEFAULT 0
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
      CREATE TABLE linen_ledger (
        id TEXT PRIMARY KEY,
        item_name TEXT NOT NULL DEFAULT 'Linen Napkins',
        direction TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        order_id TEXT,
        department_id TEXT,
        note TEXT,
        recorded_by TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE item_department_access (
        item_id TEXT NOT NULL,
        department_id TEXT NOT NULL,
        PRIMARY KEY (item_id, department_id)
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

    await db.execute('''
      CREATE TABLE app_meta (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE announcements (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        body TEXT,
        starts_at TEXT NOT NULL,
        ends_at TEXT NOT NULL,
        severity TEXT NOT NULL DEFAULT 'info',
        is_active INTEGER NOT NULL DEFAULT 1
      )
    ''');
    await db.execute('CREATE INDEX idx_announcements_window ON announcements(starts_at, ends_at) WHERE is_active = 1');

    // Indexes for the queries that are run on every dashboard load
    await db.execute('CREATE INDEX idx_orders_status_created_at ON orders(status, created_at)');
    await db.execute('CREATE INDEX idx_orders_docket_number ON orders(docket_number)');
    await db.execute('CREATE INDEX idx_orders_updated_at ON orders(updated_at)');
    await db.execute('CREATE INDEX idx_order_items_order_id ON order_items(order_id)');
    await db.execute('CREATE INDEX idx_order_status_log_order_id ON order_status_log(order_id)');
    await db.execute('CREATE INDEX idx_order_status_log_created_at ON order_status_log(created_at)');

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

  /// Returns the ID of a non-rejected order with the same docket number
  /// created locally within [within], or null if none exists. Used as a
  /// duplicate-submit safety net at order submission time.
  Future<String?> findRecentOrderByDocket(
    String docketNumber, {
    Duration within = const Duration(seconds: 60),
  }) async {
    if (docketNumber.isEmpty) return null;
    final db = await database;
    final cutoff = DateTime.now().subtract(within).toIso8601String();
    final rows = await db.query(
      'orders',
      columns: ['id'],
      where: "docket_number = ? AND created_at >= ? AND status <> 'rejected'",
      whereArgs: [docketNumber, cutoff],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['id'] as String;
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

  // ── Item Department Access (junction table) ──

  /// Replace all item-department mappings with fresh data from Supabase
  Future<void> syncItemDepartmentAccess(List<Map<String, dynamic>> rows) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('item_department_access');
      for (final row in rows) {
        await txn.insert('item_department_access', {
          'item_id': row['item_id'],
          'department_id': row['department_id'],
        });
      }
    });
  }

  /// Get all department IDs that an item is visible to.
  /// Empty list means visible to all departments.
  Future<List<String>> getDepartmentIdsForItem(String itemId) async {
    final db = await database;
    final rows = await db.query('item_department_access',
        columns: ['department_id'],
        where: 'item_id = ?',
        whereArgs: [itemId]);
    return rows.map((r) => r['department_id'] as String).toList();
  }

  /// Get all item-department mappings as a map: itemId -> [departmentId, ...]
  Future<Map<String, List<String>>> getItemDepartmentMap() async {
    final db = await database;
    final rows = await db.query('item_department_access');
    final map = <String, List<String>>{};
    for (final row in rows) {
      final itemId = row['item_id'] as String;
      final deptId = row['department_id'] as String;
      map.putIfAbsent(itemId, () => []).add(deptId);
    }
    return map;
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
          'can_delete_orders': admin['can_delete_orders'] == true ? 1 : 0,
          'can_reject_orders': admin['can_reject_orders'] == true ? 1 : 0,
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

  // -- Order Sync (pull from Supabase) --

  /// Merge remote orders + their items into local SQLite.
  /// Skips orders that have pending (unsynced) changes in the sync queue.
  /// Merge remote orders + their items into local SQLite in a single
  /// transaction. The previous implementation opened one transaction per
  /// order, which on a 1,100-row pull held the SQLite lock for many seconds
  /// and made foreground reads (e.g. dashboard tab loads) wait. One
  /// transaction with a batch insert is ~50× faster and releases the lock
  /// in a fraction of the time.
  ///
  /// Set [deleteOrphans] to true only when [remoteOrders] represents the
  /// FULL set of orders on the server (not an incremental `since` slice) —
  /// otherwise we'd wrongly delete local rows that just weren't in the
  /// recent batch.
  Future<int> syncOrders(
    List<Map<String, dynamic>> remoteOrders, {
    bool deleteOrphans = false,
  }) async {
    if (remoteOrders.isEmpty && !deleteOrphans) return 0;

    final db = await database;

    // Get IDs of orders with pending local changes — those are skipped to
    // avoid clobbering local edits the user made while offline.
    final pendingItems = await getPendingSyncItems();
    final pendingOrderIds = <String>{};
    for (final item in pendingItems) {
      if (item['table_name'] == 'orders') {
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;
        if (data['id'] != null) pendingOrderIds.add(data['id'] as String);
      }
    }

    final nowIso = DateTime.now().toIso8601String();
    final remoteIds = <String>{};
    int synced = 0;

    await db.transaction((txn) async {
      final batch = txn.batch();

      for (final remote in remoteOrders) {
        final orderId = remote['id'] as String;
        remoteIds.add(orderId);
        if (pendingOrderIds.contains(orderId)) continue;

        batch.insert('orders', {
          'id': orderId,
          'docket_number': remote['docket_number'] ?? '',
          'order_type': remote['order_type'] ?? 'uniform',
          'department_id': remote['department_id'],
          'staff_name': remote['staff_name'],
          'email': remote['email'],
          'room_number': remote['room_number'],
          'guest_name': remote['guest_name'],
          'bag_count': remote['bag_count'],
          'notes': remote['notes'],
          'status': remote['status'] ?? 'submitted',
          'total_price': remote['total_price'] != null
              ? (remote['total_price'] as num).toDouble()
              : null,
          'parent_order_id': remote['parent_order_id'],
          'created_at': remote['created_at'] ?? nowIso,
          'updated_at': remote['updated_at'] ?? nowIso,
          'synced_at': nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final remoteItems = (remote['order_items'] as List<dynamic>?) ?? [];
        for (final item in remoteItems) {
          if (item is! Map<String, dynamic>) continue;
          batch.insert('order_items', {
            'id': item['id'],
            'order_id': orderId,
            'item_id': item['item_id'] ?? '',
            'item_name': item['item_name'] ?? '',
            'quantity_sent': item['quantity_sent'] ?? 0,
            'quantity_received': item['quantity_received'],
            'price_at_time': item['price_at_time'] != null
                ? (item['price_at_time'] as num).toDouble()
                : null,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        }

        synced++;
      }

      if (deleteOrphans) {
        // Remove local orders that no longer exist in Supabase (deleted on web).
        // Only safe when the caller is certain remoteIds is the FULL server set.
        final localOrders = await txn.query('orders', columns: ['id']);
        for (final local in localOrders) {
          final localId = local['id'] as String;
          if (!remoteIds.contains(localId) && !pendingOrderIds.contains(localId)) {
            batch.delete('order_items', where: 'order_id = ?', whereArgs: [localId]);
            batch.delete('order_status_log', where: 'order_id = ?', whereArgs: [localId]);
            batch.delete('orders', where: 'id = ?', whereArgs: [localId]);
          }
        }
      }

      await batch.commit(noResult: true);
    });

    return synced;
  }

  /// Merge remote status logs into local SQLite. Single transaction +
  /// batch insert — same rationale as [syncOrders].
  Future<int> syncStatusLogs(List<Map<String, dynamic>> remoteLogs) async {
    if (remoteLogs.isEmpty) return 0;
    final db = await database;
    final nowIso = DateTime.now().toIso8601String();

    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final log in remoteLogs) {
        batch.insert('order_status_log', {
          'id': log['id'],
          'order_id': log['order_id'],
          'status': log['status'] ?? '',
          'changed_by': log['changed_by'],
          'changed_by_name': log['changed_by_name'],
          'reason': log['reason'],
          'created_at': log['created_at'] ?? nowIso,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }
      await batch.commit(noResult: true);
    });

    return remoteLogs.length;
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

  /// Auto-collects completed orders older than [days] days.
  /// Marks them as picked_up with a system status log.
  Future<int> autoCollectCompletedOrders({int days = 21}) async {
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
        {'status': 'picked_up', 'updated_at': now},
        where: 'id = ?',
        whereArgs: [orderId],
      );
      batch.insert('order_status_log', {
        'id': uuid.v4(),
        'order_id': orderId,
        'status': 'picked_up',
        'changed_by_name': 'System',
        'reason': 'Automatic Rule — Collected after $days days',
        'created_at': now,
      });
    }
    await batch.commit(noResult: true);
    return orders.length;
  }

  /// Returns a set of parent order IDs where the outstanding (child) order
  /// has been completed/received, meaning the outstanding is resolved.
  Future<Set<String>> getResolvedOutstandingOrderIds() async {
    final db = await database;
    final result = await db.rawQuery(
      "SELECT DISTINCT parent_order_id FROM orders "
      "WHERE parent_order_id IS NOT NULL AND status IN ('completed', 'picked_up', 'expired')",
    );
    return result.map((r) => r['parent_order_id'] as String).toSet();
  }

  // ── Data Cleanup ──

  /// Permanently delete expired orders older than [daysAfterExpiry] days.
  /// ON DELETE CASCADE handles order_items and order_status_log.
  Future<int> purgeExpiredOrders({int daysAfterExpiry = 30}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: daysAfterExpiry)).toIso8601String();

    final expired = await db.query('orders',
      columns: ['id'],
      where: "status = 'expired' AND updated_at < ?",
      whereArgs: [cutoff],
    );

    if (expired.isEmpty) return 0;

    for (final order in expired) {
      final id = order['id'] as String;
      await db.delete('order_status_log', where: 'order_id = ?', whereArgs: [id]);
      await db.delete('order_items', where: 'order_id = ?', whereArgs: [id]);
      await db.delete('orders', where: 'id = ?', whereArgs: [id]);
    }

    return expired.length;
  }

  /// Remove sync queue entries that have already been synced and are older than [days] days.
  // ── Announcements ──

  /// Returns all locally-cached announcements that are visible at [now] —
  /// i.e. is_active AND now is in [starts_at, ends_at).
  Future<List<Announcement>> getActiveAnnouncements({DateTime? now}) async {
    final t = now ?? DateTime.now();
    final db = await database;
    final iso = t.toIso8601String();
    final rows = await db.query(
      'announcements',
      where: 'is_active = 1 AND starts_at <= ? AND ends_at > ?',
      whereArgs: [iso, iso],
      orderBy: "case severity when 'critical' then 0 when 'warning' then 1 else 2 end, starts_at desc",
    );
    return rows.map((r) => Announcement.fromMap(r)).toList();
  }

  /// Replace local announcements with the remote set (full pull).
  Future<int> syncAnnouncements(List<Map<String, dynamic>> remote) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('announcements');
      final batch = txn.batch();
      for (final row in remote) {
        batch.insert('announcements', {
          'id': row['id'],
          'title': row['title'] ?? '',
          'body': row['body'],
          'starts_at': row['starts_at'],
          'ends_at': row['ends_at'],
          'severity': row['severity'] ?? 'info',
          'is_active': (row['is_active'] == true) ? 1 : 0,
        });
      }
      await batch.commit(noResult: true);
    });
    return remote.length;
  }

  // ── App Metadata (key/value bookkeeping) ──

  /// Read a metadata value. Returns null if the key doesn't exist.
  Future<String?> getMeta(String key) async {
    final db = await database;
    final rows = await db.query('app_meta', where: 'key = ?', whereArgs: [key], limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  /// Write a metadata value (upsert by key).
  Future<void> setMeta(String key, String value) async {
    final db = await database;
    await db.insert(
      'app_meta',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> cleanSyncQueue({int days = 7}) async {
    final db = await database;
    final cutoff = DateTime.now().subtract(Duration(days: days)).toIso8601String();

    // Clean old completed items
    final cleaned = await db.delete(
      'sync_queue',
      where: 'synced = 1 AND created_at < ?',
      whereArgs: [cutoff],
    );

    // Also abandon stuck unsynced items older than 2 days — they'll never succeed
    final stuckCutoff = DateTime.now().subtract(const Duration(days: 2)).toIso8601String();
    final abandoned = await db.update(
      'sync_queue',
      {'synced': 1},
      where: 'synced = 0 AND created_at < ?',
      whereArgs: [stuckCutoff],
    );
    if (abandoned > 0) {
      debugPrint('[Sync] Abandoned $abandoned stuck queue items older than 2 days');
    }

    return cleaned + abandoned;
  }

  /// Returns counts of data that can be cleaned up for display in admin UI.
  Future<Map<String, int>> getCleanupStats() async {
    final db = await database;
    final cutoffExpired = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
    final cutoffSync = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();

    final expiredResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM orders WHERE status = 'expired' AND updated_at < ?",
      [cutoffExpired],
    );
    final syncResult = await db.rawQuery(
      "SELECT COUNT(*) as count FROM sync_queue WHERE synced = 1 AND created_at < ?",
      [cutoffSync],
    );

    return {
      'expired_orders': (expiredResult.first['count'] as int?) ?? 0,
      'old_sync_entries': (syncResult.first['count'] as int?) ?? 0,
    };
  }

  // ── Linen Napkin Pool Ledger ──

  /// Insert a ledger entry (OUT when collected, IN when received back).
  Future<void> insertLedgerEntry(Map<String, dynamic> entry) async {
    final db = await database;
    await db.insert('linen_ledger', entry);
  }

  /// Get the running pool balance (total OUT - total IN).
  Future<int> getLedgerBalance() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN direction = 'out' THEN quantity ELSE 0 END), 0) -
        COALESCE(SUM(CASE WHEN direction = 'in' THEN quantity ELSE 0 END), 0) AS balance
      FROM linen_ledger
    ''');
    return (result.first['balance'] as int?) ?? 0;
  }

  /// Get ledger entries filtered by date range.
  Future<List<Map<String, dynamic>>> getLedgerEntries({DateTime? since, int limit = 200}) async {
    final db = await database;
    if (since != null) {
      return db.query('linen_ledger',
        where: 'created_at >= ?',
        whereArgs: [since.toIso8601String()],
        orderBy: 'created_at DESC',
        limit: limit,
      );
    }
    return db.query('linen_ledger', orderBy: 'created_at DESC', limit: limit);
  }

  /// Get total OUT and total IN quantities.
  Future<Map<String, int>> getLedgerTotals() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN direction = 'out' THEN quantity ELSE 0 END), 0) AS total_out,
        COALESCE(SUM(CASE WHEN direction = 'in' THEN quantity ELSE 0 END), 0) AS total_in
      FROM linen_ledger
    ''');
    return {
      'total_out': (result.first['total_out'] as int?) ?? 0,
      'total_in': (result.first['total_in'] as int?) ?? 0,
    };
  }

  /// Check if an order contains any pool-tracked (napkin) items.
  Future<bool> orderHasNapkins(String orderId) async {
    final db = await database;
    final items = await db.query('order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
    return items.any((i) =>
      (i['item_name'] as String? ?? '').toLowerCase().contains('napkin'));
  }

  /// Check if an order contains ONLY pool-tracked (napkin) items.
  Future<bool> orderIsNapkinsOnly(String orderId) async {
    final db = await database;
    final items = await db.query('order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
    if (items.isEmpty) return false;
    return items.every((i) =>
      (i['item_name'] as String? ?? '').toLowerCase().contains('napkin'));
  }

  /// Get total napkin quantity sent for an order.
  Future<int> getNapkinQuantityForOrder(String orderId) async {
    final db = await database;
    final items = await db.query('order_items',
      where: 'order_id = ?', whereArgs: [orderId]);
    int total = 0;
    for (final item in items) {
      if ((item['item_name'] as String? ?? '').toLowerCase().contains('napkin')) {
        total += (item['quantity_sent'] as int?) ?? 0;
      }
    }
    return total;
  }
}
