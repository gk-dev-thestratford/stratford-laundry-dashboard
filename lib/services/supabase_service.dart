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
    await _client!.from('orders').upsert(order);
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
    return await _client!.from('admin_users').select('id, name, pin_hash, is_active, can_delete_orders, can_reject_orders');
  }

  // ── Edge Functions ──

  /// Invoke the daily-report Edge Function to send collection report emails
  Future<void> invokeDailyReport() async {
    if (!isInitialized) return;
    try {
      await _client!.functions.invoke('daily-report');
    } catch (e) {
      debugPrint('[Supabase] Failed to invoke daily-report: $e');
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
}
