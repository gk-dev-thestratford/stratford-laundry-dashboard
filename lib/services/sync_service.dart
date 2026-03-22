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

  final _controller = StreamController<SyncState>.broadcast();
  Stream<SyncState> get stateStream => _controller.stream;
  SyncState _currentState = SyncState.offline;
  SyncState get currentState => _currentState;

  Timer? _syncTimer;

  void initialize() {
    // Listen to connectivity changes
    ConnectivityService.instance.statusStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        _scheduleSyncIfNeeded();
      } else {
        _updateState(SyncState.offline);
      }
    });

    // Periodic sync attempt every 30 seconds when online
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (ConnectivityService.instance.currentStatus == ConnectivityStatus.online) {
        _scheduleSyncIfNeeded();
      }
    });
  }

  Future<void> _scheduleSyncIfNeeded() async {
    if (!SupabaseService.instance.isInitialized) {
      // Supabase not configured — just report as synced (local-only mode)
      _updateState(SyncState.synced);
      return;
    }

    // Always sync reference data from Supabase so changes appear on the tablet
    await _syncDepartments();
    await _syncCatalogueItems();
    await _syncAdminUsers();

    final pending = await DatabaseService.instance.getPendingSyncItems();
    if (pending.isEmpty) {
      _updateState(SyncState.synced);
      return;
    }

    await syncNow();
  }

  /// Pull departments from Supabase and update local SQLite
  Future<void> _syncDepartments() async {
    try {
      final remoteDepts = await SupabaseService.instance.fetchDepartments();
      if (remoteDepts.isNotEmpty) {
        await DatabaseService.instance.syncDepartments(remoteDepts);
      }
    } catch (_) {
      // Non-critical — departments will update on next sync
    }
  }

  /// Pull catalogue items from Supabase and update local SQLite
  Future<void> _syncCatalogueItems() async {
    try {
      final remoteItems = await SupabaseService.instance.fetchCatalogueItems();
      if (remoteItems.isNotEmpty) {
        await DatabaseService.instance.syncCatalogueItems(remoteItems);
      }
    } catch (_) {
      // Non-critical — items will update on next sync
    }
  }

  /// Pull admin users from Supabase and update local SQLite
  Future<void> _syncAdminUsers() async {
    try {
      final remoteAdmins = await SupabaseService.instance.fetchAdminUsers();
      if (remoteAdmins.isNotEmpty) {
        await DatabaseService.instance.syncAdminUsers(remoteAdmins);
      }
    } catch (_) {
      // Non-critical — admin list will update on next sync
    }
  }

  Future<void> syncNow() async {
    if (!SupabaseService.instance.isInitialized) return;

    _updateState(SyncState.syncing);

    try {
      final pending = await DatabaseService.instance.getPendingSyncItems();

      for (final item in pending) {
        final tableName = item['table_name'] as String;
        final operation = item['operation'] as String;
        final data = jsonDecode(item['data'] as String) as Map<String, dynamic>;

        switch (operation) {
          case 'insert':
            if (tableName == 'orders') {
              await SupabaseService.instance.pushOrder(data);
              // Also push order items for this order
              final items = await DatabaseService.instance.getOrderItems(data['id'] as String);
              if (items.isNotEmpty) {
                await SupabaseService.instance.pushOrderItems(items);
              }
            }
          case 'update':
            if (tableName == 'orders') {
              await SupabaseService.instance.updateOrderStatus(
                data['id'] as String,
                data['status'] as String,
              );
            }
          case 'delete':
            await SupabaseService.instance.deleteOrder(data['id'] as String);
        }

        await DatabaseService.instance.markSynced(item['id'] as int);
      }

      _updateState(SyncState.synced);
    } catch (_) {
      _updateState(SyncState.pending);
    }
  }

  void _updateState(SyncState state) {
    _currentState = state;
    _controller.add(state);
  }

  void dispose() {
    _syncTimer?.cancel();
    _controller.close();
  }
}

final syncStateProvider = StreamProvider<SyncState>((ref) {
  return SyncService.instance.stateStream;
});
