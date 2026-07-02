import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Supabase service layer — handles all remote database operations.
/// Falls back gracefully when Supabase is not configured.
class SupabaseService {
  static final SupabaseService instance = SupabaseService._();
  SupabaseService._();

  bool _initialized = false;

  bool get isConfigured => SupabaseConfig.isConfigured;
  bool get isInitialized => _initialized && isConfigured;

  SupabaseClient? get _client => _initialized ? Supabase.instance.client : null;

  Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) return;
    await Supabase.initialize(
      url: SupabaseConfig.url,
      anonKey: SupabaseConfig.anonKey,
    );
    _initialized = true;
  }

  // ── Orders ──

  Future<void> pushOrder(Map<String, dynamic> order) async {
    if (!isInitialized) return;
    // Strip local-only / joined columns before upserting. The Supabase 'orders'
    // table has none of these; sending them makes the upsert fail with an
    // undefined-column error (which the push loop would then wrongly classify
    // and abandon). 'department_name'/'department_code' leak in when the
    // payload is built from getOrder() (e.g. partial-receipt follow-up tickets).
    final clean = Map<String, dynamic>.from(order)
      ..remove('locally_originated')
      ..remove('synced_at')
      ..remove('remote_id')
      ..remove('department_name')
      ..remove('department_code');
    await _client!.from('orders').upsert(clean);
  }

  Future<void> pushOrderItems(List<Map<String, dynamic>> items) async {
    if (!isInitialized) return;
    await _client!.from('order_items').upsert(items);
  }

  Future<void> pushStatusLog(Map<String, dynamic> log) async {
    if (!isInitialized) return;
    await _client!.from('order_status_log').upsert(log);
  }

  /// Insert a status log — ignores duplicates, re-throws real errors.
  Future<void> insertStatusLog(Map<String, dynamic> log) async {
    if (!isInitialized) return;
    try {
      await _client!.from('order_status_log').insert(log);
    } on PostgrestException catch (e) {
      if (e.code == '23505') return; // duplicate key = already synced, safe to ignore
      debugPrint('[Supabase] insertStatusLog failed: ${e.message}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchOrders({DateTime? since}) async {
    if (!isInitialized) return [];
    var query = _client!.from('orders').select('*, departments(*), order_items(*, item_catalogue(*))');
    if (since != null) {
      query = query.gte('updated_at', since.toIso8601String());
    }
    return await query.order('created_at', ascending: false);
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (!isInitialized) return;
    await _client!.from('orders').update({
      'status': status,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', orderId);
  }

  /// Fetch all status logs, optionally only those created since [since].
  Future<List<Map<String, dynamic>>> fetchOrderStatusLogs({DateTime? since}) async {
    if (!isInitialized) return [];
    var query = _client!.from('order_status_log').select();
    if (since != null) {
      query = query.gte('created_at', since.toIso8601String());
    }
    return await query.order('created_at', ascending: false);
  }

  Future<void> deleteOrder(String orderId) async {
    if (!isInitialized) return;
    await _client!.from('orders').delete().eq('id', orderId);
  }

  // ── Reference Data ──

  Future<List<Map<String, dynamic>>> fetchDepartments() async {
    if (!isInitialized) return [];
    return await _client!.from('departments').select().eq('is_active', true);
  }

  Future<List<Map<String, dynamic>>> fetchCatalogueItems() async {
    if (!isInitialized) return [];
    return await _client!.from('item_catalogue').select().eq('is_active', true).order('sort_order');
  }

  /// Fetch the item_department_access junction table (multi-department visibility)
  Future<List<Map<String, dynamic>>> fetchItemDepartmentAccess() async {
    if (!isInitialized) return [];
    return await _client!.from('item_department_access').select('item_id, department_id');
  }

  Future<List<Map<String, dynamic>>> fetchAdminUsers() async {
    if (!isInitialized) return [];
    return await _client!.from('admin_users').select('id, name, pin_hash, is_active, can_delete_orders, can_reject_orders, can_send_report, can_approve_orders');
  }

  // ── Announcements ──

  /// Fetch all announcements (active + upcoming) so the tablet can pre-cache
  /// upcoming ones and switch them on automatically when the start time hits.
  Future<List<Map<String, dynamic>>> fetchAnnouncements() async {
    if (!isInitialized) return [];
    return await _client!
        .from('announcements')
        .select()
        .eq('is_active', true)
        .gte('ends_at', DateTime.now().subtract(const Duration(hours: 1)).toIso8601String())
        .order('starts_at', ascending: true);
  }

  // ── Edge Functions ──

  /// Invoke the daily-report Edge Function to send the combined daily report.
  /// Returns true when the function ran and every email was accepted.
  /// [since] (ISO-8601 UTC) makes it an express follow-up: Received/Sent/Napkins
  /// then cover only items after that time (the new batch since the last send).
  Future<bool> invokeDailyReport({String? since}) async {
    if (!isInitialized) return false;
    try {
      final res = await _client!.functions.invoke(
        'daily-report',
        body: since != null ? {'since': since} : null,
      );
      final data = res.data;
      if (data is Map && data['success'] == false) {
        debugPrint('[Supabase] daily-report reported failure: $data');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[Supabase] Failed to invoke daily-report: $e');
      return false;
    }
  }

  // ── Linen Ledger ──

  Future<void> insertLedgerEntry(Map<String, dynamic> entry) async {
    if (!isInitialized) return;
    try {
      await _client!.from('linen_ledger').insert(entry);
    } catch (_) {
      // Ignore duplicate key errors
    }
  }

  Future<List<Map<String, dynamic>>> fetchLedgerEntries() async {
    if (!isInitialized) return [];
    return await _client!.from('linen_ledger').select().order('created_at', ascending: false);
  }

  // ── Sync-health heartbeat (cross-device discrepancy visibility) ──

  /// Best-effort upsert of this device's sync status. Silently ignored if the
  /// optional `device_sync_status` table is not provisioned yet, so it never
  /// affects normal operation.
  Future<void> upsertDeviceSyncStatus(Map<String, dynamic> row) async {
    if (!isInitialized) return;
    try {
      await _client!.from('device_sync_status').upsert(row);
    } catch (_) {
      // Heartbeat is non-critical — table may not exist yet.
    }
  }
}
