import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'database_service.dart';
import 'supabase_service.dart';
import 'connectivity_service.dart';

enum SyncState { synced, syncing, pending, offline }

class SyncService {
  static final SyncService instance = SyncService._();
  SyncService._();

  final _stateController = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _stateController.stream;
  SyncState _currentState = SyncState.offline;
  SyncState get currentState => _currentState;

  /// Emitted after reference data (departments, items, admins) is pulled from Supabase.
  /// Providers should invalidate their caches when this fires.
  final _refreshController = StreamController<void>.broadcast();
  Stream<void> get onReferenceDataSynced => _refreshController.stream;

  Timer? _syncTimer;
  DateTime? _lastRefPull;
  DateTime? _lastCleanup;
  bool _isPushing = false;

  /// How often to pull reference data from Supabase (safety-net interval)
  static const _refPullInterval = Duration(seconds: 90);

  /// How often the periodic timer ticks (checks if work is needed)
  static const _timerInterval = Duration(seconds: 30);

  void initialize() {
    // Listen to connectivity changes
    ConnectivityService.instance.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        // Connectivity restored — do a full sync immediately
        _fullSync();
      } else {
        _updateState(SyncState.offline);
      }
    });

    // Periodic safety-net timer
    _syncTimer = Timer.periodic(_timerInterval, (_) {
      if (ConnectivityService.instance.currentStatus == ConnectivityStatus.online) {
        _periodicSync();
      }
    });

    // Trigger initial sync if already online
    if (ConnectivityService.instance.currentStatus == ConnectivityStatus.online) {
      _fullSync();
    }
  }

  /// Push pending sync queue items immediately (called after meaningful actions).
  /// Non-blocking — fires and forgets. Safe to call from UI code.
  void pushPendingNow() {
    if (_isPushing) return;
    if (ConnectivityService.instance.currentStatus != ConnectivityStatus.online) return;
    if (!SupabaseService.instance.isInitialized) return;

    // Fire and forget — don't block the caller
    _pushPending();
  }

  /// Full sync: pull reference data + push pending items.
  /// Called on connectivity restore and on first initialize.
  Future<void> _fullSync() async {
    if (!SupabaseService.instance.isInitialized) {
      _updateState(SyncState.synced);
      return;
    }

    await _pullReferenceData();
    await _pushPending();
  }

  /// Periodic timer handler: only does work when needed.
  Future<void> _periodicSync() async {
    if (!SupabaseService.instance.isInitialized) {
      _updateState(SyncState.synced);
      return;
    }

    // Pull reference data only if stale
    final now = DateTime.now();
    if (_lastRefPull == null || now.difference(_lastRefPull!) > _refPullInterval) {
      await _pullReferenceData();
    }

    // Push any remaining pending items (safety net)
    final pending = await DatabaseService.instance.getPendingSyncItems();
    if (pending.isNotEmpty) {
      await _pushPending();
    } else if (_currentState != SyncState.synced) {
      _updateState(SyncState.synced);
    }

    // Run data cleanup once per hour
    if (_lastCleanup == null || now.difference(_lastCleanup!) > const Duration(hours: 1)) {
      _lastCleanup = now;
      try {
        await DatabaseService.instance.autoExpireCompletedOrders(days: 20);
        await DatabaseService.instance.purgeExpiredOrders(daysAfterExpiry: 30);
        await DatabaseService.instance.cleanSyncQueue(days: 7);
      } catch (_) {
        // Non-critical — will retry next hour
      }
    }
  }

  /// Pull departments, items, admin users from Supabase into local SQLite.
  Future<void> _pullReferenceData() async {
    bool didSync = false;

    try {
      final remoteDepts = await SupabaseService.instance.fetchDepartments();
      if (remoteDepts.isNotEmpty) {
        await DatabaseService.instance.syncDepartments(remoteDepts);
        didSync = true;
      }
    } catch (_) {}

    try {
      final remoteItems = await SupabaseService.instance.fetchCatalogueItems();
      if (remoteItems.isNotEmpty) {
        await DatabaseService.instance.syncCatalogueItems(remoteItems);
        didSync = true;
      }
    } catch (_) {}

    try {
      final remoteAdmins = await SupabaseService.instance.fetchAdminUsers();
      if (remoteAdmins.isNotEmpty) {
        await DatabaseService.instance.syncAdminUsers(remoteAdmins);
        didSync = true;
      }
    } catch (_) {}

    _lastRefPull = DateTime.now();

    // Notify listeners so providers can invalidate caches
    if (didSync) {
      _refreshController.add(null);
    }
  }

  /// Push all pending sync queue items to Supabase.
  Future<void> _pushPending() async {
    if (_isPushing) return;
    if (!SupabaseService.instance.isInitialized) return;

    _isPushing = true;
    _updateState(SyncState.syncing);

    try {
      final pending = await DatabaseService.instance.getPendingSyncItems();

      if (pending.isEmpty) {
        _updateState(SyncState.synced);
        _isPushing = false;
        return;
      }

      for (final item in pending) {
        final tableName = item['table_name'] as String;
        final operation = item['operation'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        switch (operation) {
          case 'insert':
            if (tableName == 'orders') {
              await SupabaseService.instance.pushOrder(data);
              // Also push order items and status logs for this order
              final orderId = data['id'] as String;
              final items = await DatabaseService.instance.getOrderItems(orderId);
              if (items.isNotEmpty) {
                await SupabaseService.instance.pushOrderItems(items);
              }
              final logs = await DatabaseService.instance.getOrderStatusLog(orderId);
              for (final log in logs) {
                await SupabaseService.instance.pushStatusLog(log);
              }
            }
          case 'update':
            if (tableName == 'orders') {
              final orderId = data['id'] as String;
              await SupabaseService.instance.updateOrderStatus(
                orderId,
                data['status'] as String,
              );
              // Push latest status log entry for this order
              final logs = await DatabaseService.instance.getOrderStatusLog(orderId);
              if (logs.isNotEmpty) {
                await SupabaseService.instance.pushStatusLog(logs.last);
              }
            }
          case 'delete':
            await SupabaseService.instance.deleteOrder(data['id'] as String);
        }

        await DatabaseService.instance.markSynced(item['id'] as int);
      }

      _updateState(SyncState.synced);
    } catch (_) {
      _updateState(SyncState.pending);
    } finally {
      _isPushing = false;
    }
  }

  void _updateState(SyncState state) {
    _currentState = state;
    _stateController.add(state);
  }

  void dispose() {
    _syncTimer?.cancel();
    _stateController.close();
    _refreshController.close();
  }
}

final syncStateProvider = StreamProvider<SyncState>((ref) {
  return SyncService.instance.stateStream;
});
