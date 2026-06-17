import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/announcement_banner.dart';
import '../../widgets/thumbs_up_confirmation.dart';
import '../../widgets/sync_indicator.dart';
import '../../widgets/today_report_panel.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  StreamSubscription<void>? _syncSub;
  List<Map<String, dynamic>> _orders = [];
  Map<String, int> _counts = {};
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _selectedOrderIds = {};
  Map<String, String> _itemSummaries = {};
  Set<String> _partialOrderIds = {};
  Map<String, String> _sentDates = {};
  Map<String, String> _awaitingSummaries = {};
  String? _allTabDateFilter;
  String? _allTabTypeFilter;
  /// Unsynced sync_queue items on THIS device — drives the discrepancy banner.
  int _pendingSyncCount = 0;
  // Right-side "Today's Report" panel — refreshed after every relevant action.
  final GlobalKey<TodayReportPanelState> _panelKey =
      GlobalKey<TodayReportPanelState>();

  // Tab indices — use these constants instead of hardcoded numbers.
  // The daily flow is receive-first: staff record what came back from the
  // laundry (Receive) BEFORE sending the day's approved items out (Send), so
  // Receive sits at index 2 and Send at index 3. The constants are keyed by
  // the STATUS each tab filters on, so all index-driven logic follows the
  // swap automatically: _kSent (the Receive tab, status 'sent') = 2,
  // _kApproved (the Send tab, status 'approved') = 3.
  static const _kRejected = 0;
  static const _kPending = 1;        // Step 1 — status 'submitted'
  static const _kApproved = 2;       // Step 2 — status 'approved'
  static const _kSent = 3;           // Step 3 "To Be Received" — status 'sent'
  static const _kNapkinReturns = 4;  // Step 4 — Napkins (navigates)
  static const _kReceived = 5;       // Step 5 "For Collection" — status 'received'
  static const _kAll = 6;
  static const _kReport = 7;

  // Tabs follow the daily WORKFLOW left-to-right, numbered Step 1–5:
  // Pending(1) → Approved(2) → To Be Received(3, status 'sent') →
  // Napkins(4) → For Collection(5, status 'received'). Rejected/All/Report are
  // not part of the numbered flow. Labels show where each ticket IS; the action
  // differs (the "To Be Received" tab is where staff mark items received).
  static const _tabs = ['Rejected', 'Pending', 'Approved', 'To Be Received', 'Napkins', 'For Collection', 'All', 'Report'];
  static const _statusFilters = [
    AppConstants.statusRejected,   // 0 Rejected
    AppConstants.statusSubmitted,  // 1 Pending
    AppConstants.statusApproved,   // 2 Approved
    AppConstants.statusSent,       // 3 To Be Received
    null,                          // 4 Napkins — navigates to separate screen
    AppConstants.statusReceived,   // 5 For Collection
    null,                          // 6 All
    null,                          // 7 Report — navigates to separate screen
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _kPending);
    _tabController.addListener(_onTabChanged);
    // Reload orders + counts whenever background sync pulls fresh data from Supabase
    _syncSub = SyncService.instance.onReferenceDataSynced.listen((_) {
      _loadData(silent: true);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).refreshActivity();
    });
    _loadData();
  }

  @override
  void dispose() {
    _syncSub?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(adminProvider.notifier).refreshActivity();
      _selectedOrderIds.clear();
      _allTabDateFilter = null;
      _allTabTypeFilter = null;
      // Clear stale content and show loading indicator while new tab loads
      setState(() {
        _orders = [];
        _itemSummaries = {};
        _isLoading = true;
      });
      _loadOrders(silent: true);
      _loadCounts();
    }
  }

  Future<void> _loadData({bool silent = false}) async {
    // autoCollectReceivedOrders and autoExpireReceivedOrders used to run
    // here on every tab change — wasteful, since they only need to run
    // periodically. They're now invoked once per hour by SyncService's
    // periodic cleanup, so loadData just reads.
    await Future.wait([_loadOrders(silent: silent), _loadCounts()]);
    await _refreshPendingCount();
    // Keep the Today's Report panel in step (covers background sync and
    // returning from child screens — both funnel through here).
    _panelKey.currentState?.refresh();
  }

  /// Refresh the count of unsynced local changes that drives the discrepancy
  /// banner. Cheap COUNT; called on load and on every sync-state change.
  Future<void> _refreshPendingCount() async {
    final n = await DatabaseService.instance.getPendingSyncCount();
    if (mounted && n != _pendingSyncCount) {
      setState(() => _pendingSyncCount = n);
    }
  }

  Future<void> _loadCounts() async {
    final counts = await DatabaseService.instance.getOrderCounts();
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _loadOrders({bool silent = false}) async {
    if (!mounted) return;
    if (!silent) setState(() => _isLoading = true);
    final tabIndex = _tabController.index;
    List<Map<String, dynamic>> orders;

    if (tabIndex == _kAll) {
      // All tab: search-first — only load when search or filters are active
      final hasFilters = _searchQuery.isNotEmpty || _allTabDateFilter != null || _allTabTypeFilter != null;
      if (!hasFilters) {
        orders = [];
      } else {
        String? dateFrom;
        if (_allTabDateFilter == 'today') {
          final now = DateTime.now();
          dateFrom = DateTime(now.year, now.month, now.day).toIso8601String();
        } else if (_allTabDateFilter == '7days') {
          dateFrom = DateTime.now().subtract(const Duration(days: 7)).toIso8601String();
        } else if (_allTabDateFilter == '30days') {
          dateFrom = DateTime.now().subtract(const Duration(days: 30)).toIso8601String();
        }
        orders = List.of(await DatabaseService.instance.getOrders(
          orderType: _allTabTypeFilter,
          dateFrom: dateFrom,
          searchQuery: _searchQuery,
        ));
      }
    } else {
      orders = List.of(await DatabaseService.instance.getOrders(
        status: _statusFilters[tabIndex],
        searchQuery: _searchQuery,
      ));
    }

    final orderIds = orders.map((o) => o['id'] as String).toList();

    // Load item summaries for Sent tab
    Map<String, String> summaries = {};
    if (tabIndex == _kSent && orders.isNotEmpty) {
      summaries = await DatabaseService.instance.getOrderItemSummaries(orderIds);
    }

    // Load partial receipt order IDs for Received / All / Sent tabs
    Set<String> partialIds = {};
    if (tabIndex == _kReceived || tabIndex == _kAll || tabIndex == _kSent) {
      partialIds = await DatabaseService.instance.getPartialReceiptOrderIds();
    }

    // Sent tab: when each order was marked 'sent' (for the aging badge)
    Map<String, String> sentDates = {};
    if (tabIndex == _kSent && orders.isNotEmpty) {
      sentDates = await DatabaseService.instance
          .getLatestStatusLogDates(orderIds, AppConstants.statusSent);
    }

    // Received tab: items still awaited (for the Discrepancy badge)
    Map<String, String> awaitingSummaries = {};
    if (tabIndex == _kReceived && orders.isNotEmpty) {
      awaitingSummaries =
          await DatabaseService.instance.getAwaitingSummaries(orderIds);
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _itemSummaries = summaries;
        _partialOrderIds = partialIds;
        _sentDates = sentDates;
        _awaitingSummaries = awaitingSummaries;
        _isLoading = false;
      });
    }
  }

  /// Centered, double-size thumbs-up confirmation — auto-dismisses and lets
  /// taps pass through, so it never blocks the workflow.
  void _showStatusSnackBar(String message) {
    showThumbsUpConfirmation(context, message: message);
  }

  void _logout() {
    SyncService.instance.fullSync();
    ref.read(adminProvider.notifier).logout();
    context.go('/');
  }

  String? _statusForCurrentTab() => _statusFilters[_tabController.index];

  bool get _isPendingTab => _tabController.index == _kPending;
  bool get _isApprovedTab => _tabController.index == _kApproved;
  bool get _isSentTab => _tabController.index == _kSent;
  bool get _isReceivedTab => _tabController.index == _kReceived;
  bool get _isRejectedTab => _tabController.index == _kRejected;

  Future<void> _quickAction(String orderId, String newStatus, {String? reason}) async {
    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;

    // Optimistic UI: remove order instantly (new list — sqflite lists are unmodifiable)
    // Find the order's actual status BEFORE removing it
    final orderStatus = _orders.where((o) => o['id'] == orderId).firstOrNull?['status'] as String?;
    setState(() {
      _orders = _orders.where((o) => o['id'] != orderId).toList();
      _selectedOrderIds.remove(orderId);
      // Decrement: use actual order status when known
      final decrementKey = orderStatus ?? _statusForCurrentTab();
      if (decrementKey != null && _counts.containsKey(decrementKey)) {
        _counts[decrementKey] = (_counts[decrementKey]! - 1).clamp(0, 999999);
      }
      _counts[newStatus] = (_counts[newStatus] ?? 0) + 1;
    });

    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      _showStatusSnackBar('Order ${AppLabels.statusLabels[newStatus]}');
    }

    // Persist to local SQLite + queue for Supabase push on exit
    await db.updateOrderStatus(orderId, newStatus);
    await db.insertStatusLog({
      'id': const Uuid().v4(),
      'order_id': orderId,
      'status': newStatus,
      'changed_by': admin?.id,
      'changed_by_name': admin?.name,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.addToSyncQueue('orders', orderId, 'update',
        jsonEncode({'id': orderId, 'status': newStatus}));

    // Push immediately — don't wait for the 30s timer
    SyncService.instance.pushPendingNow();
    _panelKey.currentState?.refresh();
  }

  Future<void> _showRejectDialog(String orderId) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Provide a reason for rejection (optional):'),
            SizedBox(height: AppSpacing.md),
            TextField(
              controller: reasonController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Reason...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    final reason = reasonController.text.trim();
    if (confirmed == true) {
      await _quickAction(orderId, AppConstants.statusRejected, reason: reason);
    }
    reasonController.dispose();
  }

  void _toggleOrderSelection(String orderId) {
    setState(() {
      if (_selectedOrderIds.contains(orderId)) {
        _selectedOrderIds.remove(orderId);
      } else {
        _selectedOrderIds.add(orderId);
      }
    });
  }

  void _toggleSelectAll() {
    setState(() {
      if (_selectedOrderIds.length == _orders.length) {
        _selectedOrderIds.clear();
      } else {
        _selectedOrderIds = _orders.map((o) => o['id'] as String).toSet();
      }
    });
  }

  /// Approved tab bulk "Add (N)": marks the selected tickets 'sent'
  /// immediately (they join today's report collection). The daily report
  /// EMAIL is only sent later via the panel's "Preview & Send Report".
  Future<void> _bulkAddToSent() async {
    if (_selectedOrderIds.isEmpty) return;
    final db = DatabaseService.instance;

    // Workflow gate: the daily procedure is receive-first. If nothing has been
    // received today AND there are open 'sent' tickets that could have been
    // received, confirm before adding — a soft nudge, never a hard block.
    final receivedToday =
        await db.hasStatusLogToday(AppConstants.statusReceived);
    if (!receivedToday && await db.hasOpenSentOrders()) {
      if (!mounted) return;
      final proceed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Receive First?'),
          content: const Text(
            'Nothing has been received today yet — the daily procedure is to '
            'record received items first. Add anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusSent),
              child: const Text('Add anyway'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }

    final count = _selectedOrderIds.length;
    final admin = ref.read(adminProvider).currentAdmin;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    // Optimistic UI
    final sentIds = _selectedOrderIds.toSet();
    setState(() {
      _orders = _orders.where((o) => !sentIds.contains(o['id'])).toList();
      _selectedOrderIds.clear();
      final currentStatus = _statusForCurrentTab();
      if (currentStatus != null && _counts.containsKey(currentStatus)) {
        _counts[currentStatus] = (_counts[currentStatus]! - count).clamp(0, 999999);
      }
      _counts[AppConstants.statusSent] = (_counts[AppConstants.statusSent] ?? 0) + count;
    });

    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      _showStatusSnackBar(count == 1
          ? '1 ticket added — sent to laundry'
          : '$count tickets added — sent to laundry');
    }

    for (final orderId in sentIds) {
      await db.updateOrderStatus(orderId, AppConstants.statusSent);
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusSent,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'created_at': now,
      });

      await _logNapkinOutAndAutoReceive(orderId, admin, db, uuid, now);

      final order = await db.getOrder(orderId);
      final finalStatus = order?['status'] ?? AppConstants.statusSent;
      await db.addToSyncQueue('orders', orderId, 'update',
          jsonEncode({'id': orderId, 'status': finalStatus}));
    }

    // Push immediately and WAIT for sync to complete
    await SyncService.instance.pushPendingAndWait();
    _panelKey.currentState?.refresh();
  }

  /// Sent tab bulk "Add (N)": marks each selected ticket as FULLY received —
  /// every item gets quantity_received = quantity_sent (napkins included,
  /// same auto-full treatment as the receive dialog), status → 'received'.
  /// Partial receipts stay on the per-ticket "Receive" button.
  Future<void> _bulkReceiveAll() async {
    if (_selectedOrderIds.isEmpty) return;
    final db = DatabaseService.instance;
    final count = _selectedOrderIds.length;
    final admin = ref.read(adminProvider).currentAdmin;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    // Optimistic UI
    final receivedIds = _selectedOrderIds.toSet();
    setState(() {
      _orders = _orders.where((o) => !receivedIds.contains(o['id'])).toList();
      _selectedOrderIds.clear();
      final currentStatus = _statusForCurrentTab();
      if (currentStatus != null && _counts.containsKey(currentStatus)) {
        _counts[currentStatus] = (_counts[currentStatus]! - count).clamp(0, 999999);
      }
      _counts[AppConstants.statusReceived] =
          (_counts[AppConstants.statusReceived] ?? 0) + count;
    });

    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      _showStatusSnackBar(count == 1
          ? '1 ticket added — all items received'
          : '$count tickets added — all items received');
    }

    for (final orderId in receivedIds) {
      // Full receipt: every item received in the quantity it was sent.
      final items = await db.getOrderItems(orderId);
      if (items.isNotEmpty) {
        final fullReceipt = <String, int>{
          for (final item in items)
            item['id'] as String: item['quantity_sent'] as int? ?? 0,
        };
        await db.updateReceivedQuantities(orderId, fullReceipt);
      }

      await db.updateOrderStatus(orderId, AppConstants.statusReceived);
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusReceived,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'All items received',
        'created_at': now,
      });

      await db.addToSyncQueue('orders', orderId, 'update',
          jsonEncode({'id': orderId, 'status': AppConstants.statusReceived}));
    }

    // Push immediately and WAIT for sync to complete
    await SyncService.instance.pushPendingAndWait();
    _panelKey.currentState?.refresh();
  }

  /// For napkin items: logs OUT to the linen ledger.
  /// For napkin-only orders: auto-moves to 'received' (skips receiving step —
  /// the pool ledger tracks them, not per-ticket counts).
  Future<void> _logNapkinOutAndAutoReceive(
    String orderId, dynamic admin, DatabaseService db, Uuid uuid, String now,
  ) async {
    final napkinQty = await db.getNapkinQuantityForOrder(orderId);
    if (napkinQty <= 0) return;

    // Get the order for department info
    final order = await db.getOrder(orderId);

    // Log OUT to linen ledger
    final ledgerEntryId = uuid.v4();
    await db.insertLedgerEntry({
      'id': ledgerEntryId,
      'item_name': 'Linen Napkins',
      'direction': 'out',
      'quantity': napkinQty,
      'order_id': orderId,
      'department_id': order?['department_id'],
      'note': 'Sent to laundry — Docket #${order?['docket_number'] ?? '?'}',
      'recorded_by': admin?.name,
      'created_at': now,
    });

    // Queue ledger entry for Supabase sync
    await db.addToSyncQueue('linen_ledger', ledgerEntryId, 'insert', jsonEncode({
      'id': ledgerEntryId,
      'item_name': 'Linen Napkins',
      'direction': 'out',
      'quantity': napkinQty,
      'order_id': orderId,
      'department_id': order?['department_id'],
      'note': 'Sent to laundry — Docket #${order?['docket_number'] ?? '?'}',
      'recorded_by': admin?.name,
      'created_at': now,
    }));

    // If order is napkins-only, auto-move to received (skip per-ticket receiving)
    final isNapkinsOnly = await db.orderIsNapkinsOnly(orderId);
    if (isNapkinsOnly) {
      await db.updateOrderStatus(orderId, AppConstants.statusReceived);
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusReceived,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Napkins — pool tracked, auto-received on send',
        'created_at': now,
      });
    }
  }

  Future<void> _returnToPending(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Return to Pending?'),
        content: const Text('This will move the order back to Pending for review.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _quickAction(orderId, AppConstants.statusSubmitted, reason: 'Returned to pending');
    }
  }

  /// Owner picked up their items from the laundry room.
  Future<void> _markCollected(String orderId) async {
    await _quickAction(orderId, AppConstants.statusCollected);
  }

  bool get _isAllTab => _tabController.index == _kAll;
  bool get _allTabHasFilters =>
      _searchQuery.isNotEmpty || _allTabDateFilter != null || _allTabTypeFilter != null;

  void _setDateFilter(String? filter) {
    ref.read(adminProvider.notifier).refreshActivity();
    setState(() {
      _allTabDateFilter = _allTabDateFilter == filter ? null : filter;
    });
    _loadOrders();
  }

  void _setTypeFilter(String? filter) {
    ref.read(adminProvider.notifier).refreshActivity();
    setState(() {
      _allTabTypeFilter = _allTabTypeFilter == filter ? null : filter;
    });
    _loadOrders();
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.navy.withValues(alpha: 0.15),
      checkmarkColor: AppColors.navy,
      labelStyle: TextStyle(fontFamily: 'Inter',
        fontSize: AppTextStyles.labelSize,
        fontWeight: selected ? AppTextStyles.medium : AppTextStyles.regular,
        color: selected ? AppColors.navy : AppColors.grey700,
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
      side: BorderSide(color: selected ? AppColors.navy : AppColors.grey300),
    );
  }

  /// Shows a dialog to enter received quantities per item, then handles
  /// full or partial receipt (splitting the ticket if needed).
  Future<void> _showReceiveItemsDialog(String orderId) async {
    final db = DatabaseService.instance;
    final items = await db.getOrderItems(orderId);

    if (items.isEmpty) {
      // Bag-only order (guest laundry) — just mark it received
      await _quickAction(orderId, AppConstants.statusReceived);
      return;
    }

    // Build controllers for each item.
    // Pre-fill napkin items as fully received — they're pool-tracked,
    // so staff only needs to count non-napkin items.
    final controllers = <String, TextEditingController>{};
    for (final item in items) {
      final name = (item['item_name'] as String? ?? '').toLowerCase();
      final isNapkin = name.contains('napkin');
      final prefill = isNapkin ? '${item['quantity_sent']}' : '0';
      controllers[item['id'] as String] = TextEditingController(text: prefill);
    }

    if (!mounted) return;

    final result = await showDialog<Map<String, int>>(
      context: context,
      builder: (ctx) => _ReceiveItemsDialog(items: items, controllers: controllers),
    );

    // Dispose controllers
    for (final c in controllers.values) {
      c.dispose();
    }

    if (result == null) return; // cancelled

    final admin = ref.read(adminProvider).currentAdmin;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    // Check for outstanding items (pure computation)
    bool hasOutstanding = false;
    int totalSent = 0;
    int totalReceived = 0;
    for (final item in items) {
      final id = item['id'] as String;
      final sent = item['quantity_sent'] as int;
      final received = result[id] ?? 0;
      totalSent += sent;
      totalReceived += received;
      if (received < sent) hasOutstanding = true;
    }

    // Optimistic UI — capture order details before removing it from the list
    final orderRow = _orders.where((o) => o['id'] == orderId).firstOrNull;
    final orderStatus = orderRow?['status'] as String?;
    final docket = orderRow?['docket_number'] ?? '?';
    setState(() {
      _orders = _orders.where((o) => o['id'] != orderId).toList();
      final decrementKey = orderStatus ?? _statusForCurrentTab();
      if (decrementKey != null && _counts.containsKey(decrementKey)) {
        _counts[decrementKey] = (_counts[decrementKey]! - 1).clamp(0, 999999);
      }
      _counts[AppConstants.statusReceived] = (_counts[AppConstants.statusReceived] ?? 0) + 1;
    });

    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      _showStatusSnackBar(
        hasOutstanding
            ? 'Partial receipt — follow-up ticket created'
            : 'All items received',
      );
    }

    // Persist to local SQLite
    await db.updateReceivedQuantities(orderId, result);

    String? newOrderId;
    if (hasOutstanding) {
      newOrderId = await db.createOutstandingOrder(
        originalOrderId: orderId,
        receivedQuantities: result,
      );

      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusReceived,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Partial receipt — received $totalReceived of $totalSent; '
            'outstanding split to follow-up ticket',
        'created_at': now,
      });
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': newOrderId,
        'status': AppConstants.statusSent,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Outstanding items from partial receipt of #$docket',
        'created_at': now,
      });
    } else {
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusReceived,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'created_at': now,
      });
    }

    await db.updateOrderStatus(orderId, AppConstants.statusReceived);

    await db.addToSyncQueue('orders', orderId, 'update',
        jsonEncode({'id': orderId, 'status': AppConstants.statusReceived}));
    if (hasOutstanding && newOrderId != null) {
      final outstandingOrder = await db.getOrder(newOrderId);
      if (outstandingOrder != null) {
        await db.addToSyncQueue('orders', newOrderId, 'insert',
            jsonEncode(outstandingOrder));
      }
    }

    // Push immediately — don't wait for the 30s timer
    SyncService.instance.pushPendingNow();
    _panelKey.currentState?.refresh();
  }

  /// Small sync chip shown in the header next to the cloud icon — ONLY when this
  /// device has unsynced changes or is offline. Tap for a short popup with the
  /// detail + a "Sync now" action. Replaces the old full-width banner so the
  /// alert is unobtrusive.
  Widget _buildSyncBadge() {
    final connectivity = ref.watch(connectivityProvider).valueOrNull;
    final syncState = ref.watch(syncStateProvider).valueOrNull;
    final offline = connectivity == ConnectivityStatus.offline ||
        syncState == SyncState.offline;
    final pending = _pendingSyncCount > 0 || syncState == SyncState.pending;
    if (!offline && !pending) return const SizedBox.shrink();

    final n = _pendingSyncCount;
    final color = offline ? AppColors.error : Colors.orange.shade700;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xs),
      child: GestureDetector(
        onTap: () => _showSyncDetails(offline, n),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: color,
            borderRadius: AppRadius.largeBR,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                  offline
                      ? Icons.cloud_off_rounded
                      : Icons.cloud_upload_rounded,
                  color: AppColors.white,
                  size: 16),
              if (n > 0) ...[
                const SizedBox(width: 4),
                Text('$n',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        color: AppColors.white,
                        fontSize: AppTextStyles.captionSize,
                        fontWeight: AppTextStyles.bold)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Short popup describing the unsynced state, with a "Sync now" action.
  void _showSyncDetails(bool offline, int n) {
    final label = n == 1 ? '1 change' : '$n changes';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(offline ? 'Offline' : 'Waiting to sync'),
        content: Text(offline
            ? '$label saved on this device. They sync automatically when you reconnect to the internet.'
            : '$label waiting to upload to the cloud. Tap "Sync now" to retry.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              SyncService.instance.fullSync(force: true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final width = MediaQuery.of(context).size.width;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    // Narrow / portrait: the docked panel would crush the order list, so it
    // becomes a right-side overlay drawer instead (see _buildBodyArea).
    final isNarrow = width < 900;

    // Keep the unsynced-count fresh as sync state changes (push/pull/offline).
    ref.listen<AsyncValue<SyncState>>(syncStateProvider, (_, _) {
      _refreshPendingCount();
    });

    // Enforce auto-lock timeout
    if (!admin.isAuthenticated || admin.isTimedOut) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminProvider.notifier).logout();
        if (context.mounted) context.go('/admin/login');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          // ── Custom gradient header ──
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.navy, AppColors.navyLight],
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: AppColors.navy.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 4)),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  // Top row: home, title, actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, 0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.home_rounded, color: AppColors.white, size: 26),
                          onPressed: () {
                            SyncService.instance.fullSync();
                            context.go('/');
                          },
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Dashboard',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold)),
                              Text(admin.currentAdmin?.name ?? 'Admin',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontFamily: 'Inter', color: AppColors.gold, fontSize: AppTextStyles.captionSize)),
                            ],
                          ),
                        ),
                        _buildSyncBadge(),
                        SyncIndicator(onSynced: () => _loadData(silent: true)),
                        const SizedBox(width: AppSpacing.xs),
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.white, size: 24),
                          onPressed: _logout,
                          tooltip: 'Logout',
                        ),
                      ],
                    ),
                  ),
                  // Status filter pills
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.base, AppSpacing.md, AppSpacing.base, AppSpacing.lg),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _tabs.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final label = entry.value;
                          final isNapkinTab = idx == _kNapkinReturns;
                          final isReportTab = idx == _kReport;
                          // The Report pill is hidden for admins without the
                          // can_send_report permission.
                          if (isReportTab &&
                              !(admin.currentAdmin?.canSendReport ?? true)) {
                            return const SizedBox.shrink();
                          }
                          // Gold "special" pills navigate to their own screen
                          // instead of switching tabs.
                          final isNapkinTabOrReport = isNapkinTab || isReportTab;
                          final count = isNapkinTabOrReport ? 0 : _getTabCount(label);
                          final isActive = !isNapkinTabOrReport && _tabController.index == idx;
                          final step = _stepFor(label);

                          return Padding(
                            padding: EdgeInsets.only(
                              right: AppSpacing.sm,
                              left: isNapkinTab ? AppSpacing.lg : 0,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Workflow step label (Step 1–5) above the pill;
                                // reserves the same height for non-step tabs so
                                // every pill stays vertically aligned.
                                SizedBox(
                                  height: 15,
                                  child: step == null
                                      ? null
                                      : Center(
                                          child: Text('Step $step',
                                              style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontSize: 10,
                                                  fontWeight: AppTextStyles.bold,
                                                  letterSpacing: 0.5,
                                                  color: AppColors.gold)),
                                        ),
                                ),
                                const SizedBox(height: 3),
                                GestureDetector(
                              onTap: () {
                                if (isNapkinTab) {
                                  context.push('/admin/napkin-returns').then((_) {
                                    _loadData(silent: true);
                                  });
                                } else if (isReportTab) {
                                  context.push('/admin/daily-report').then((_) {
                                    _loadData(silent: true);
                                  });
                                } else {
                                  _tabController.animateTo(idx);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isNapkinTabOrReport
                                      ? AppColors.gold.withValues(alpha: 0.2)
                                      : isActive
                                          ? AppColors.white
                                          : AppColors.white.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.largeBR,
                                  border: Border.all(
                                    color: isNapkinTabOrReport
                                        ? AppColors.gold.withValues(alpha: 0.5)
                                        : isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.2),
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _tabIcon(label),
                                      size: 20,
                                      color: isNapkinTabOrReport
                                          ? AppColors.gold
                                          : isActive ? AppColors.navy : AppColors.white.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: AppTextStyles.captionSize,
                                        fontWeight: isActive || isNapkinTabOrReport ? AppTextStyles.bold : AppTextStyles.medium,
                                        color: isNapkinTabOrReport
                                            ? AppColors.gold
                                            : isActive ? AppColors.navy : AppColors.white.withValues(alpha: 0.85),
                                      ),
                                    ),
                                    if (count > 0) ...[
                                      const SizedBox(width: AppSpacing.sm),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isActive ? AppColors.navy : AppColors.white.withValues(alpha: 0.2),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 13,
                                            fontWeight: AppTextStyles.bold,
                                            color: isActive ? AppColors.white : AppColors.white.withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Active announcements (auto-hides when nothing scheduled) ──
          const AnnouncementBanner(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
          ),
          // ── Body content + Today's Report panel (docked landscape /
          //    overlay drawer in portrait) ──
          Expanded(
            child: _buildBodyArea(admin, isLandscape, isNarrow),
          ),
        ],
      ),
    );
  }

  /// Body = order list + the Today's Report panel.
  ///
  /// Landscape / wide: the panel is docked inline to the right of the list
  /// (its own expand/collapse). Portrait / narrow: the panel becomes a
  /// right-side overlay drawer that slides OVER a full-width order list, so it
  /// never crushes the content. Admins without can_send_report never see the
  /// panel (not even the collapsed tab) in either layout.
  Widget _buildBodyArea(AdminState admin, bool isLandscape, bool isNarrow) {
    final showPanel = admin.currentAdmin?.canSendReport ?? true;
    final orderList = Column(children: _buildBodyContent(isLandscape));

    if (!showPanel) return orderList;

    final panel = TodayReportPanel(
      key: _panelKey,
      overlay: isNarrow,
      // Send-tab (status 'approved') selection shows as "ready to add" ghost
      // chips in the Sent Today card before Add is pressed.
      selectedDockets: _isApprovedTab
          ? _orders
              .where((o) => _selectedOrderIds.contains(o['id']))
              .map((o) => '${o['docket_number']}')
              .toList()
          : const [],
      // Receive-tab (status 'sent') selection shows as ghost chips in the
      // Received Today card (bulk Add = fully received).
      selectedReceiveDockets: _isSentTab
          ? _orders
              .where((o) => _selectedOrderIds.contains(o['id']))
              .map((o) => '${o['docket_number']}')
              .toList()
          : const [],
      adminName: admin.currentAdmin?.name,
      onOpenReport: () {
        ref.read(adminProvider.notifier).refreshActivity();
        context.push('/admin/daily-report').then((_) {
          _loadData(silent: true);
        });
      },
      onLogNapkins: () {
        ref.read(adminProvider.notifier).refreshActivity();
        context.push('/admin/napkin-returns').then((_) {
          _loadData(silent: true);
        });
      },
    );

    // Portrait / narrow: order list full-width, panel as an overlay drawer.
    if (isNarrow) {
      return Stack(
        children: [
          Positioned.fill(child: orderList),
          Positioned.fill(child: panel),
        ],
      );
    }

    // Landscape / wide: inline docked column to the right of the list.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: orderList),
        panel,
      ],
    );
  }

  IconData _tabIcon(String tab) {
    return switch (tab) {
      'Pending' => Icons.schedule_rounded,
      'Approved' => Icons.local_shipping_rounded,
      'To Be Received' => Icons.move_to_inbox_rounded,
      'For Collection' => Icons.done_all_rounded,
      'All' => Icons.list_alt_rounded,
      'Rejected' => Icons.cancel_outlined,
      'Napkins' => Icons.dining,
      'Report' => Icons.summarize_rounded,
      _ => Icons.circle_outlined,
    };
  }

  /// Workflow step number shown above the tab (Step 1–5), or null for tabs that
  /// aren't part of the numbered daily flow (Rejected / All / Report).
  int? _stepFor(String tab) => switch (tab) {
        'Pending' => 1,
        'Approved' => 2,
        'To Be Received' => 3,
        'Napkins' => 4,
        'For Collection' => 5,
        _ => null,
      };

  List<Widget> _buildBodyContent(bool isLandscape) {
    return [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: AppRadius.largeBR,
                boxShadow: AppShadows.soft,
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search by docket number, name...',
                  hintStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey400),
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: AppSpacing.base, right: AppSpacing.sm),
                    child: Icon(Icons.search_rounded, size: AppSizes.iconSizeLg, color: AppColors.grey500),
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear_rounded, size: AppSizes.iconSizeMd, color: AppColors.grey400),
                          onPressed: () {
                            setState(() => _searchQuery = '');
                            _loadOrders();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.largeBR,
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: AppRadius.largeBR,
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: AppRadius.largeBR,
                    borderSide: BorderSide(color: AppColors.navy.withValues(alpha: 0.3), width: 1.5),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
                ),
                onChanged: (v) {
                  ref.read(adminProvider.notifier).refreshActivity();
                  _searchQuery = v;
                  _loadOrders();
                },
              ),
            ),
          ),
          // All tab: filter chips
          if (_isAllTab)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Today', _allTabDateFilter == 'today', () => _setDateFilter('today')),
                    SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Last 7 days', _allTabDateFilter == '7days', () => _setDateFilter('7days')),
                    SizedBox(width: AppSpacing.sm),
                    _buildFilterChip('Last 30 days', _allTabDateFilter == '30days', () => _setDateFilter('30days')),
                    SizedBox(width: AppSpacing.md),
                    Container(width: 1, height: AppSizes.iconSizeLg, color: AppColors.grey300),
                    SizedBox(width: AppSpacing.md),
                    ...AppLabels.orderTypeLabels.entries.map((e) => Padding(
                      padding: EdgeInsets.only(right: AppSpacing.sm),
                      child: _buildFilterChip(e.value, _allTabTypeFilter == e.key, () => _setTypeFilter(e.key)),
                    )),
                  ],
                ),
              ),
            ),
          // Bulk select bar.
          //  • "Approved" tab (status 'approved'): select-all + "Send (N)" → mark sent.
          //  • "Sent" tab (status 'sent'): NO select-all (prevents accidental
          //    mass-receive); per-ticket selection only + "Receive (N)" → mark received.
          if ((_isApprovedTab || _isSentTab) && _orders.isNotEmpty && !_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  // Select-all is intentionally OMITTED on the "Sent" tab so no one
                  // can mark every ticket received in a single tap by mistake.
                  if (_isApprovedTab) ...[
                    SizedBox(
                      width: AppSizes.minTouchTarget, height: AppSizes.minTouchTarget,
                      child: Checkbox(
                        value: _selectedOrderIds.length == _orders.length && _orders.isNotEmpty,
                        onChanged: (_) => _toggleSelectAll(),
                        activeColor: AppColors.navy,
                      ),
                    ),
                    SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    _selectedOrderIds.isEmpty
                        ? (_isApprovedTab
                            ? 'Select all to add to today\'s report'
                            : 'Select tickets to receive')
                        : '${_selectedOrderIds.length} selected',
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: AppColors.grey700),
                  ),
                  const Spacer(),
                  if (_selectedOrderIds.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _isApprovedTab ? _bulkAddToSent : _bulkReceiveAll,
                      icon: Icon(Icons.playlist_add_rounded, size: AppSizes.iconSizeSm),
                      label: Text('${_isApprovedTab ? 'Send' : 'Received'} (${_selectedOrderIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isApprovedTab
                            ? AppColors.statusSent
                            : AppColors.statusReceived,
                        foregroundColor: AppColors.white,
                        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                        textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
                      ),
                    ),
                ],
              ),
            ),
          // Order list / grid
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isAllTab && !_allTabHasFilters
                                  ? Icons.search_rounded
                                  : Icons.inbox_rounded,
                              size: 56, color: AppColors.grey300),
                            SizedBox(height: AppSpacing.md),
                            Text(
                              _isAllTab && !_allTabHasFilters
                                  ? 'Search by docket number or name\nor select a filter to view orders'
                                  : 'No orders found',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontFamily: 'Inter', color: AppColors.grey600, fontSize: AppTextStyles.titleSize)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        // Pull-to-refresh hits the SERVER (forced full pull with
                        // orphan cleanup) then reloads locally — previously it
                        // only re-read local data, so remote deletions never showed.
                        onRefresh: () async {
                          await SyncService.instance.fullSync(force: true);
                          await _loadData(silent: true);
                        },
                        // Width-aware, not orientation-aware: with the Today
                        // panel expanded the list gets ~half the screen, where
                        // two columns clip the cards — drop to a single column.
                        child: LayoutBuilder(
                          builder: (context, constraints) => constraints.maxWidth >= 860
                            ? GridView.builder(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 10,
                                  mainAxisSpacing: 6,
                                  childAspectRatio: 3.6,
                                ),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) => _buildOrderCard(index),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.sm),
                                itemCount: _orders.length,
                                itemBuilder: (context, index) => _buildOrderCard(index),
                              ),
                        ),
                      ),
          ),
        ];
  }

  Widget _buildOrderCard(int index) {
    final orderId = _orders[index]['id'] as String;
    int? daysUntilExpiry;
    if (_isReceivedTab) {
      final updatedAt = DateTime.tryParse(_orders[index]['updated_at'] as String? ?? '');
      if (updatedAt != null) {
        daysUntilExpiry = AppConstants.receivedExpiryDays - DateTime.now().difference(updatedAt).inDays;
      }
    }
    // Sent tab: days since the order was sent to the laundry (aging badge)
    int? daysSinceSent;
    if (_isSentTab) {
      final sentAt = DateTime.tryParse(_sentDates[orderId] ?? '') ??
          DateTime.tryParse(_orders[index]['created_at'] as String? ?? '');
      if (sentAt != null) {
        daysSinceSent = DateTime.now().difference(sentAt).inDays;
      }
    }
    // Received tab: discrepancy = has a child outstanding order OR short-received items
    final awaitingSummary = _awaitingSummaries[orderId];
    final hasDiscrepancy = _isReceivedTab &&
        (_partialOrderIds.contains(orderId) || awaitingSummary != null);
    return _OrderCard(
      order: _orders[index],
      itemSummary: _itemSummaries[orderId],
      hasDiscrepancy: hasDiscrepancy,
      awaitingSummary: awaitingSummary,
      daysUntilExpiry: daysUntilExpiry,
      daysSinceSent: daysSinceSent,
      showActions: _isPendingTab,
      showCheckbox: _isApprovedTab || _isSentTab,
      isSelected: _selectedOrderIds.contains(orderId),
      showReturnToPending: _isApprovedTab || _isRejectedTab,
      showReceiveAction: _isSentTab,
      showCollectedAction: _isReceivedTab,
      onTap: () {
        ref.read(adminProvider.notifier).refreshActivity();
        context.push('/admin/order/$orderId').then((_) {
          _loadData(silent: true);
        });
      },
      onApprove: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _quickAction(orderId, AppConstants.statusApproved);
      },
      onReject: ref.read(adminProvider).currentAdmin?.canRejectOrders == true
        ? () {
            ref.read(adminProvider.notifier).refreshActivity();
            _showRejectDialog(orderId);
          }
        : null,
      onToggleSelect: () => _toggleOrderSelection(orderId),
      onReturnToPending: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _returnToPending(orderId);
      },
      onReceive: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _showReceiveItemsDialog(orderId);
      },
      onMarkCollected: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _markCollected(orderId);
      },
    );
  }

  int _getTabCount(String tab) {
    return switch (tab) {
      'Pending' => _counts[AppConstants.statusSubmitted] ?? 0,
      'Approved' => _counts[AppConstants.statusApproved] ?? 0,
      'To Be Received' => _counts[AppConstants.statusSent] ?? 0,
      'For Collection' => _counts[AppConstants.statusReceived] ?? 0,
      'Rejected' => _counts[AppConstants.statusRejected] ?? 0,
      _ => 0, // All + Napkins — no counter
    };
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? itemSummary;
  /// Received tab: child outstanding order exists OR items were short-received.
  final bool hasDiscrepancy;
  /// e.g. "awaiting 2× Chef Jacket" — what is still at the laundry.
  final String? awaitingSummary;
  final int? daysUntilExpiry;
  /// Sent tab: days since the order was sent to the laundry (aging badge).
  final int? daysSinceSent;
  final bool showActions;
  final bool showCheckbox;
  final bool isSelected;
  final bool showReturnToPending;
  final bool showReceiveAction;
  final bool showCollectedAction;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback? onReject;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onReturnToPending;
  final VoidCallback? onReceive;
  final VoidCallback? onMarkCollected;

  const _OrderCard({
    required this.order,
    this.itemSummary,
    this.hasDiscrepancy = false,
    this.awaitingSummary,
    this.daysUntilExpiry,
    this.daysSinceSent,
    this.showActions = false,
    this.showCheckbox = false,
    this.isSelected = false,
    this.showReturnToPending = false,
    this.showReceiveAction = false,
    this.showCollectedAction = false,
    required this.onTap,
    required this.onApprove,
    this.onReject,
    this.onToggleSelect,
    this.onReturnToPending,
    this.onReceive,
    this.onMarkCollected,
  });

  @override
  Widget build(BuildContext context) {
    final status = order['status'] as String;
    final statusColor = _statusColor(status);
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '');
    final dateStr = createdAt != null ? DateFormat('dd/MM/yy HH:mm').format(createdAt) : '—';
    final deptName = order['department_name'] as String? ?? '—';
    final staffName = order['staff_name'] as String? ?? order['guest_name'] as String? ?? '—';
    final orderType = order['order_type'] as String? ?? '';
    final isGuest = orderType == AppConstants.orderTypeGuestLaundry;
    final isOutstanding = order['parent_order_id'] != null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.mediumBR,
        boxShadow: AppShadows.card,
        border: Border.all(color: AppColors.grey200.withValues(alpha: 0.6), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.mediumBR,
        child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.mediumBR,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.base),
          child: Row(
            children: [
              // Checkbox for Approved tab selection
              if (showCheckbox) ...[
                SizedBox(
                  width: AppSizes.minTouchTarget, height: AppSizes.minTouchTarget,
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => onToggleSelect?.call(),
                    activeColor: AppColors.navy,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
              ],
              // Docket badge — bold gold with star for guest, navy for staff
              Container(
                constraints: const BoxConstraints(minWidth: 60),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isGuest
                      ? AppColors.gold.withValues(alpha: 0.22)
                      : AppColors.navy.withValues(alpha: 0.08),
                  borderRadius: AppRadius.mediumBR,
                  border: Border.all(
                    color: isGuest ? AppColors.gold : AppColors.navy.withValues(alpha: 0.15),
                    width: isGuest ? 2.0 : 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isGuest)
                      Icon(Icons.star_rounded, size: AppTextStyles.labelSize, color: AppColors.gold),
                    Text(
                      '#${order['docket_number']}',
                      style: TextStyle(fontFamily: 'Inter',
                        fontSize: AppTextStyles.bodySize,
                        fontWeight: AppTextStyles.bold,
                        color: isGuest ? AppColors.gold : AppColors.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.md),
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Status chip + badges — small, above the name
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: 2,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.12),
                            borderRadius: AppRadius.smallBR,
                          ),
                          child: Text(
                            AppLabels.statusLabels[status] ?? status,
                            style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: AppTextStyles.medium, color: statusColor),
                          ),
                        ),
                        // Child order from a partial receipt — still awaiting items
                        if (isOutstanding)
                          () {
                            final isResolved = status == AppConstants.statusReceived ||
                                status == AppConstants.statusCollected ||
                                status == AppConstants.statusExpired;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                              decoration: BoxDecoration(
                                color: isResolved
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius: AppRadius.smallBR,
                              ),
                              child: Text(
                                isResolved ? 'Outstanding Resolved' : 'Outstanding — partial',
                                style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: AppTextStyles.bold,
                                    color: isResolved ? AppColors.success : AppColors.error),
                              ),
                            );
                          }(),
                        // Sent tab: aging badge — hidden under 3 days, amber 3-6, red 7+
                        if (daysSinceSent != null && daysSinceSent! >= 3)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                            decoration: BoxDecoration(
                              color: (daysSinceSent! >= 7 ? AppColors.error : AppColors.warning)
                                  .withValues(alpha: 0.15),
                              borderRadius: AppRadius.smallBR,
                            ),
                            child: Text(
                              '${daysSinceSent}d at laundry',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: AppTextStyles.bold,
                                  color: daysSinceSent! >= 7 ? AppColors.error : Colors.orange.shade800),
                            ),
                          ),
                        // Received tab: short receipt or unreturned follow-up items
                        if (hasDiscrepancy)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.12),
                              borderRadius: AppRadius.smallBR,
                            ),
                            child: Text(
                              'Discrepancy',
                              style: TextStyle(fontFamily: 'Inter', fontSize: 10, fontWeight: AppTextStyles.bold, color: AppColors.error),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 2),
                    Text(staffName,
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium, color: AppColors.grey900),
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 2),
                    Text('$deptName • ${AppLabels.orderTypeLabels[orderType] ?? orderType}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600),
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 1),
                    Text(dateStr, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey500)),
                    if (daysUntilExpiry != null && daysUntilExpiry! <= AppConstants.receivedExpiryWarningDays)
                      Text(
                        daysUntilExpiry! <= 1 ? 'Expires today' : '${daysUntilExpiry}d until auto-archive',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium,
                            color: daysUntilExpiry! <= 2 ? AppColors.error : Colors.orange.shade700),
                      ),
                    if (itemSummary != null && itemSummary!.isNotEmpty)
                      Text(itemSummary!,
                          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium, color: AppColors.navy.withValues(alpha: 0.7)),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    // Received tab: what is still at the laundry for this docket
                    if (awaitingSummary != null && awaitingSummary!.isNotEmpty)
                      Text(awaitingSummary!,
                          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium, color: AppColors.error),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                  ],
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              // Pending tab: inline approve/reject buttons — otherwise status badge
              if (showActions) ...[
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: Icon(Icons.check, size: AppSizes.iconSizeSm),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
                if (onReject != null) ...[
                SizedBox(width: AppSpacing.sm),
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: Icon(Icons.close, size: AppSizes.iconSizeSm),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
                ],
              ] else if (showReturnToPending) ...[
                // Approved tab: trailing action, same slot as Receive/Collected
                // (was stacked inside the details column, which overflowed the
                // fixed-height grid cards in landscape)
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: OutlinedButton.icon(
                    onPressed: onReturnToPending,
                    icon: Icon(Icons.undo_rounded, size: AppSizes.iconSizeSm),
                    label: const Text('Return to Pending'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusSubmitted,
                      side: BorderSide(color: AppColors.statusSubmitted.withValues(alpha: 0.5)),
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
              ] else if (showReceiveAction) ...[
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: ElevatedButton.icon(
                    onPressed: onReceive,
                    icon: Icon(Icons.inventory_2_rounded, size: AppSizes.iconSizeSm),
                    label: const Text('Received'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusReceived,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
              ] else if (showCollectedAction) ...[
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: ElevatedButton.icon(
                    onPressed: onMarkCollected,
                    icon: Icon(Icons.check_circle_outline_rounded, size: AppSizes.iconSizeSm),
                    label: const Text('Collected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCollected,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
              ],
              SizedBox(width: AppSpacing.sm),
              Icon(Icons.chevron_right, color: AppColors.grey400, size: AppSizes.iconSizeLg),
            ],
          ),
        ),
      ),
      ),
    );
  }

  Color _statusColor(String status) {
    return switch (status) {
      AppConstants.statusSubmitted => AppColors.statusSubmitted,
      AppConstants.statusApproved => AppColors.statusApproved,
      AppConstants.statusRejected => AppColors.statusRejected,
      AppConstants.statusSent => AppColors.statusSent,
      AppConstants.statusReceived => AppColors.statusReceived,
      AppConstants.statusCollected => AppColors.statusCollected,
      AppConstants.statusExpired => AppColors.grey400,
      _ => AppColors.grey500,
    };
  }
}

/// Dialog for entering received quantities per item with +/− controls.
class _ReceiveItemsDialog extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final Map<String, TextEditingController> controllers;

  const _ReceiveItemsDialog({required this.items, required this.controllers});

  @override
  State<_ReceiveItemsDialog> createState() => _ReceiveItemsDialogState();
}

class _ReceiveItemsDialogState extends State<_ReceiveItemsDialog> {
  void _increment(String id, int max) {
    final c = widget.controllers[id]!;
    final current = int.tryParse(c.text) ?? 0;
    if (current < max) {
      setState(() => c.text = '${current + 1}');
    }
  }

  void _decrement(String id) {
    final c = widget.controllers[id]!;
    final current = int.tryParse(c.text) ?? 0;
    if (current > 0) {
      setState(() => c.text = '${current - 1}');
    }
  }

  void _setAll() {
    setState(() {
      for (final item in widget.items) {
        final id = item['id'] as String;
        widget.controllers[id]!.text = '${item['quantity_sent']}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Expanded(child: Text('Receive Items')),
          TextButton(
            onPressed: _setAll,
            child: Text('All Received', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.navy)),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.items.map((item) {
              final id = item['id'] as String;
              final name = item['item_name'] as String;
              final sent = item['quantity_sent'] as int;
              final controller = widget.controllers[id]!;
              final isNapkin = name.toLowerCase().contains('napkin');

              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium)),
                          if (isNapkin)
                            Text('Pool tracked — auto-filled', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, color: AppColors.success, fontWeight: AppTextStyles.medium))
                          else
                            Text('Sent: $sent', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, color: AppColors.grey600)),
                        ],
                      ),
                    ),
                    // −/+/input controls
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, size: 28),
                      color: AppColors.error,
                      onPressed: () => _decrement(id),
                    ),
                    SizedBox(
                      width: 50,
                      height: AppSizes.buttonHeightSm,
                      child: TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.bold),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.sm),
                          border: OutlineInputBorder(borderRadius: AppRadius.smallBR),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline, size: 28),
                      color: AppColors.success,
                      onPressed: () => _increment(id, sent),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () {
            final result = <String, int>{};
            int total = 0;
            for (final item in widget.items) {
              final id = item['id'] as String;
              final qty = int.tryParse(widget.controllers[id]!.text) ?? 0;
              result[id] = qty;
              total += qty;
            }
            if (total == 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Enter at least one received quantity')),
              );
              return;
            }
            Navigator.pop(context, result);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.navy,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
          child: const Text('Confirm Receipt'),
        ),
        SizedBox(width: AppSpacing.xs),
        ElevatedButton.icon(
          onPressed: () {
            final result = <String, int>{};
            for (final item in widget.items) {
              final id = item['id'] as String;
              result[id] = item['quantity_sent'] as int;
            }
            Navigator.pop(context, result);
          },
          icon: Icon(Icons.done_all_rounded, size: AppSizes.iconSizeMd),
          label: const Text('Received All'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.success,
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          ),
        ),
      ],
    );
  }
}

/// Observes app lifecycle to trigger sync when returning to foreground.
