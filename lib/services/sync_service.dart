import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
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

  /// Force a full sync — pull reference data + push pending items.
  /// Can be called from UI (e.g. refresh button).
  Future<void> fullSync() async {
    return _fullSync();
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
        await DatabaseService.instance.autoCollectCompletedOrders(days: 21);
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
      debugPrint('[Sync] Pulled ${remoteDepts.length} departments');
      if (remoteDepts.isNotEmpty) {
        await DatabaseService.instance.syncDepartments(remoteDepts);
        didSync = true;
      }
    } catch (e) {
      debugPrint('[Sync] Failed to sync departments: $e');
    }

    try {
      final remoteItems = await SupabaseService.instance.fetchCatalogueItems();
      debugPrint('[Sync] Pulled ${remoteItems.length} catalogue items');
      if (remoteItems.isNotEmpty) {
        await DatabaseService.instance.syncCatalogueItems(remoteItems);
        didSync = true;
      }
    } catch (e) {
      debugPrint('[Sync] Failed to sync catalogue items: $e');
    }

    try {
      final remoteAdmins = await SupabaseService.instance.fetchAdminUsers();
      debugPrint('[Sync] Pulled ${remoteAdmins.length} admin users');
      if (remoteAdmins.isNotEmpty) {
        await DatabaseService.instance.syncAdminUsers(remoteAdmins);
        didSync = true;
      }
    } catch (e) {
      debugPrint('[Sync] Failed to sync admin users: $e');
    }

    // Pull orders (with nested order_items) from Supabase into local SQLite
    try {
      final remoteOrders = await SupabaseService.instance.fetchOrders();
      debugPrint('[Sync] Pulled ${remoteOrders.length} orders from Supabase');
      if (remoteOrders.isNotEmpty) {
        final synced = await DatabaseService.instance.syncOrders(remoteOrders);
        debugPrint('[Sync] Synced $synced orders into local DB');
        didSync = true;
      }
    } catch (e) {
      debugPrint('[Sync] Failed to sync orders: $e');
    }

    // Pull order status logs
    try {
      final remoteLogs = await SupabaseService.instance.fetchOrderStatusLogs();
      debugPrint('[Sync] Pulled ${remoteLogs.length} status logs');
      if (remoteLogs.isNotEmpty) {
        final synced = await DatabaseService.instance.syncStatusLogs(remoteLogs);
        debugPrint('[Sync] Synced $synced status logs into local DB');
        didSync = true;
      }
    } catch (e) {
      debugPrint('[Sync] Failed to sync status logs: $e');
    }

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

      debugPrint('[Push] ${pending.length} pending items to sync');

      for (final item in pending) {
        final tableName = item['table_name'] as String;
        final operation = item['operation'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        try {
          debugPrint('[Push] $operation $tableName: ${data['id']}');
          switch (operation) {
            case 'insert':
              if (tableName == 'orders') {
                await SupabaseService.instance.pushOrder(data);
                // Also push order items and status logs for this order
                final orderId = data['id'] as String;
                final items = await DatabaseService.instance.getOrderItems(orderId);
                if (items.isNotEmpty) {
                  await SupabaseService.instance.pushOrderItems(items);
                  debugPrint('[Push] Pushed ${items.length} order items');
                }
                final logs = await DatabaseService.instance.getOrderStatusLog(orderId);
                for (final log in logs) {
                  await SupabaseService.instance.pushStatusLog(log);
                }
                if (logs.isNotEmpty) debugPrint('[Push] Pushed ${logs.length} status logs');
              }
            case 'update':
              if (tableName == 'orders') {
                final orderId = data['id'] as String;
                final newStatus = data['status'] as String;
                await SupabaseService.instance.updateOrderStatus(
                  orderId,
                  newStatus,
                );
                // Push only status logs that haven't been synced yet.
                // We fetch all logs and check which ones exist in Supabase,
                // but for simplicity we just INSERT new logs (not upsert)
                // to avoid UPDATE RLS issues on order_status_log.
                final logs = await DatabaseService.instance.getOrderStatusLog(orderId);
                for (final log in logs) {
                  await SupabaseService.instance.insertStatusLog(log);
                }
                if (logs.isNotEmpty) debugPrint('[Push] Pushed ${logs.length} status logs');
              }
            case 'delete':
              if (tableName == 'orders') {
                await SupabaseService.instance.deleteOrder(data['id'] as String);
              }
          }

          // Handle linen_ledger entries (separate from orders switch)
          if (tableName == 'linen_ledger' && operation == 'insert') {
            await SupabaseService.instance.insertLedgerEntry(data);
          }

          await DatabaseService.instance.markSynced(item['id'] as int);
          debugPrint('[Push] Synced successfully');
        } catch (e) {
          debugPrint('[Push] FAILED $operation $tableName: $e');
          // Mark as synced if it's a data error (won't succeed on retry)
          final isDataError = e.toString().contains('22P02') || // invalid UUID
              e.toString().contains('23') || // integrity constraint
              e.toString().contains('42');   // syntax/schema error
          if (isDataError) {
            await DatabaseService.instance.markSynced(item['id'] as int);
            debugPrint('[Push] Marked as synced (permanent failure, won\'t retry)');
          }
        }
      }

      // Check if any items remain unsynced
      final remaining = await DatabaseService.instance.getPendingSyncItems();
      if (remaining.isEmpty) {
        _updateState(SyncState.synced);
      } else {
        debugPrint('[Push] ${remaining.length} items still pending');
        _updateState(SyncState.pending);
      }
    } catch (e) {
      debugPrint('[Push] Fatal error: $e');
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
