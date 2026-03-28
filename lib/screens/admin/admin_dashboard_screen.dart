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
import '../../services/database_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/sync_indicator.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _orders = [];
  Map<String, int> _counts = {};
  bool _isLoading = true;
  String _searchQuery = '';
  Set<String> _selectedOrderIds = {};
  Map<String, String> _itemSummaries = {};
  Set<String> _partialOrderIds = {};
  String? _allTabDateFilter;
  String? _allTabTypeFilter;

  // Tab indices — use these constants instead of hardcoded numbers
  static const _kRejected = 0;
  static const _kPending = 1;
  static const _kApproved = 2;
  static const _kInProgress = 3;
  static const _kCompleted = 4;
  static const _kAll = 5;
  static const _kNapkinReturns = 6;

  static const _tabs = ['Rejected', 'Pending', 'Approved', 'In Progress', 'Completed', 'All', 'Napkins'];
  static const _statusFilters = [
    AppConstants.statusRejected,
    AppConstants.statusSubmitted,
    AppConstants.statusApproved,
    null, // In Progress = collected + in_processing
    AppConstants.statusCompleted,
    null, // All
    null, // Napkin Returns — navigates to separate screen
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this, initialIndex: _kPending);
    _tabController.addListener(_onTabChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).refreshActivity();
    });
    // Pull latest reference data from Supabase on screen open
    SyncService.instance.fullSync();
    _loadData();
    // Re-sync when app returns to foreground
    WidgetsBinding.instance.addObserver(_lifecycleObserver);
    // Reload data when sync completes (e.g. from login screen or background)
    _syncSub = SyncService.instance.onReferenceDataSynced.listen((_) {
      _loadData();
    });
  }

  late final _lifecycleObserver = _AppLifecycleObserver(onResume: () {
    SyncService.instance.fullSync();
    _loadData();
  });

  late final StreamSubscription<void> _syncSub;

  @override
  void dispose() {
    _syncSub.cancel();
    WidgetsBinding.instance.removeObserver(_lifecycleObserver);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      ref.read(adminProvider.notifier).refreshActivity();
      _selectedOrderIds.clear();
      _allTabDateFilter = null;
      _allTabTypeFilter = null;
      _loadOrders();
    }
  }

  Future<void> _loadData() async {
    await DatabaseService.instance.autoCollectCompletedOrders(
      days: AppConstants.autoCollectDays,
    );
    await DatabaseService.instance.autoExpireCompletedOrders(
      days: AppConstants.completedExpiryDays,
    );
    await Future.wait([_loadOrders(), _loadCounts()]);
  }

  Future<void> _loadCounts() async {
    final counts = await DatabaseService.instance.getOrderCounts();
    if (mounted) setState(() => _counts = counts);
  }

  Future<void> _loadOrders() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final tabIndex = _tabController.index;
    List<Map<String, dynamic>> orders;

    if (tabIndex == _kInProgress) {
      // In Progress = collected + in_processing
      final c = await DatabaseService.instance.getOrders(status: AppConstants.statusCollected, searchQuery: _searchQuery);
      final p = await DatabaseService.instance.getOrders(status: AppConstants.statusInProcessing, searchQuery: _searchQuery);
      orders = [...c, ...p];
    } else if (tabIndex == _kAll) {
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
        orders = await DatabaseService.instance.getOrders(
          orderType: _allTabTypeFilter,
          dateFrom: dateFrom,
          searchQuery: _searchQuery,
        );
      }
    } else {
      orders = await DatabaseService.instance.getOrders(
        status: _statusFilters[tabIndex],
        searchQuery: _searchQuery,
      );
    }

    // Load item summaries for In Progress tab
    Map<String, String> summaries = {};
    if (tabIndex == _kInProgress && orders.isNotEmpty) {
      summaries = await DatabaseService.instance.getOrderItemSummaries(
        orders.map((o) => o['id'] as String).toList(),
      );
    }

    // Load partial receipt order IDs for Completed / All tabs
    Set<String> partialIds = {};
    if (tabIndex == _kCompleted || tabIndex == _kAll || tabIndex == _kInProgress) {
      partialIds = await DatabaseService.instance.getPartialReceiptOrderIds();
    }

    if (mounted) {
      setState(() {
        _orders = orders;
        _itemSummaries = summaries;
        _partialOrderIds = partialIds;
        _isLoading = false;
      });
    }
  }

  void _logout() {
    ref.read(adminProvider.notifier).logout();
    context.go('/');
  }

  bool get _isPendingTab => _tabController.index == _kPending;
  bool get _isApprovedTab => _tabController.index == _kApproved;
  bool get _isInProgressTab => _tabController.index == _kInProgress;
  bool get _isCompletedTab => _tabController.index == _kCompleted;
  bool get _isRejectedTab => _tabController.index == _kRejected;

  Future<void> _quickAction(String orderId, String newStatus, {String? reason}) async {
    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;

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

    // Queue status change for Supabase sync
    await db.addToSyncQueue('orders', orderId, 'update',
        jsonEncode({'id': orderId, 'status': newStatus}));
    SyncService.instance.pushPendingNow();

    await _loadData();
    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${AppLabels.statusLabels[newStatus]}')),
      );
    }
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

  Future<void> _bulkCollect() async {
    if (_selectedOrderIds.isEmpty) return;
    final count = _selectedOrderIds.length;
    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;
    final uuid = const Uuid();
    final now = DateTime.now().toIso8601String();

    for (final orderId in _selectedOrderIds.toList()) {
      await db.updateOrderStatus(orderId, AppConstants.statusCollected);
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusCollected,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'created_at': now,
      });

      // Log napkin OUT to ledger + auto-complete napkin-only orders
      await _logNapkinOutAndAutoComplete(orderId, admin, db, uuid, now);

      // Queue status change for Supabase sync
      final order = await db.getOrder(orderId);
      final finalStatus = order?['status'] ?? AppConstants.statusCollected;
      await db.addToSyncQueue('orders', orderId, 'update',
          jsonEncode({'id': orderId, 'status': finalStatus}));
    }
    SyncService.instance.pushPendingNow();

    _selectedOrderIds.clear();
    await _loadData();
    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count order(s) marked as Collected')),
      );
    }
  }

  /// For napkin items: logs OUT to the linen ledger.
  /// For napkin-only orders: auto-completes (skips receiving step).
  Future<void> _logNapkinOutAndAutoComplete(
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
      'note': 'Collected — Docket #${order?['docket_number'] ?? '?'}',
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
      'note': 'Collected — Docket #${order?['docket_number'] ?? '?'}',
      'recorded_by': admin?.name,
      'created_at': now,
    }));

    // If order is napkins-only, auto-complete (skip receiving)
    final isNapkinsOnly = await db.orderIsNapkinsOnly(orderId);
    if (isNapkinsOnly) {
      await db.updateOrderStatus(orderId, AppConstants.statusCompleted);
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusCompleted,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Napkins — pool tracked, auto-completed on collection',
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

  Future<void> _markCollected(String orderId) async {
    await _quickAction(orderId, AppConstants.statusPickedUp);
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
      // Bag-only order (guest laundry) — just complete it
      await _quickAction(orderId, AppConstants.statusCompleted);
      return;
    }

    // Build controllers for each item
    final controllers = <String, TextEditingController>{};
    for (final item in items) {
      controllers[item['id'] as String] = TextEditingController(text: '0');
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

    // Check for outstanding items
    bool hasOutstanding = false;
    for (final item in items) {
      final id = item['id'] as String;
      final sent = item['quantity_sent'] as int;
      final received = result[id] ?? 0;
      if (received < sent) hasOutstanding = true;
    }

    // Save received quantities
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
        'status': AppConstants.statusCompleted,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Partial receipt — outstanding items moved to new ticket',
        'created_at': now,
      });
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': newOrderId,
        'status': AppConstants.statusInProcessing,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Outstanding items from partial receipt',
        'created_at': now,
      });
    } else {
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': orderId,
        'status': AppConstants.statusCompleted,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'created_at': now,
      });
    }

    await db.updateOrderStatus(orderId, AppConstants.statusCompleted);

    // Queue completion for sync
    await db.addToSyncQueue('orders', orderId, 'update',
        jsonEncode({'id': orderId, 'status': AppConstants.statusCompleted}));
    if (hasOutstanding && newOrderId != null) {
      // Queue the new outstanding order for sync
      final outstandingOrder = await db.getOrder(newOrderId);
      if (outstandingOrder != null) {
        await db.addToSyncQueue('orders', newOrderId, 'insert',
            jsonEncode(outstandingOrder));
      }
    }
    SyncService.instance.pushPendingNow();

    await _loadData();

    if (mounted) {
      ref.read(adminProvider.notifier).refreshActivity();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          hasOutstanding
              ? 'Partial receipt — outstanding items on new ticket'
              : 'All items received — order completed',
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = ref.watch(adminProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

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
                          onPressed: () => context.go('/'),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Admin Dashboard',
                                  style: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold)),
                              Text(admin.currentAdmin?.name ?? 'Admin',
                                  style: TextStyle(fontFamily: 'Inter', color: AppColors.gold, fontSize: AppTextStyles.captionSize)),
                            ],
                          ),
                        ),
                        const SyncIndicator(),
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
                          final count = isNapkinTab ? 0 : _getTabCount(label);
                          final isActive = !isNapkinTab && _tabController.index == idx;

                          return Padding(
                            padding: EdgeInsets.only(
                              right: AppSpacing.sm,
                              left: isNapkinTab ? AppSpacing.lg : 0,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                if (isNapkinTab) {
                                  context.push('/admin/napkin-returns').then((_) {
                                    SyncService.instance.fullSync();
                                    _loadData();
                                  });
                                } else {
                                  _tabController.animateTo(idx);
                                }
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isNapkinTab
                                      ? AppColors.gold.withValues(alpha: 0.2)
                                      : isActive
                                          ? AppColors.white
                                          : AppColors.white.withValues(alpha: 0.12),
                                  borderRadius: AppRadius.largeBR,
                                  border: Border.all(
                                    color: isNapkinTab
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
                                      color: isNapkinTab
                                          ? AppColors.gold
                                          : isActive ? AppColors.navy : AppColors.white.withValues(alpha: 0.8),
                                    ),
                                    const SizedBox(width: AppSpacing.sm),
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: AppTextStyles.captionSize,
                                        fontWeight: isActive || isNapkinTab ? AppTextStyles.bold : AppTextStyles.medium,
                                        color: isNapkinTab
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
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ── Body content ──
          ..._buildBodyContent(isLandscape),
        ],
      ),
    );
  }

  IconData _tabIcon(String tab) {
    return switch (tab) {
      'Pending' => Icons.schedule_rounded,
      'Approved' => Icons.check_circle_outline_rounded,
      'In Progress' => Icons.local_shipping_rounded,
      'Completed' => Icons.done_all_rounded,
      'All' => Icons.list_alt_rounded,
      'Rejected' => Icons.cancel_outlined,
      'Napkins' => Icons.dining,
      _ => Icons.circle_outlined,
    };
  }

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
          // Bulk select bar for Approved tab
          if (_isApprovedTab && _orders.isNotEmpty && !_isLoading)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: AppSpacing.base, vertical: AppSpacing.xs),
              child: Row(
                children: [
                  SizedBox(
                    width: AppSizes.minTouchTarget, height: AppSizes.minTouchTarget,
                    child: Checkbox(
                      value: _selectedOrderIds.length == _orders.length && _orders.isNotEmpty,
                      onChanged: (_) => _toggleSelectAll(),
                      activeColor: AppColors.navy,
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Text(
                    _selectedOrderIds.isEmpty
                        ? 'Select All for Collected'
                        : '${_selectedOrderIds.length} selected',
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: AppColors.grey700),
                  ),
                  const Spacer(),
                  if (_selectedOrderIds.isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _bulkCollect,
                      icon: Icon(Icons.local_shipping_rounded, size: AppSizes.iconSizeSm),
                      label: Text('Collect (${_selectedOrderIds.length})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusCollected,
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
                        onRefresh: _loadData,
                        child: isLandscape
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
        ];
  }

  Widget _buildOrderCard(int index) {
    final orderId = _orders[index]['id'] as String;
    int? daysUntilExpiry;
    if (_isCompletedTab) {
      final updatedAt = DateTime.tryParse(_orders[index]['updated_at'] as String? ?? '');
      if (updatedAt != null) {
        daysUntilExpiry = AppConstants.completedExpiryDays - DateTime.now().difference(updatedAt).inDays;
      }
    }
    return _OrderCard(
      order: _orders[index],
      itemSummary: _itemSummaries[orderId],
      isPartiallyCompleted: _partialOrderIds.contains(orderId),
      daysUntilExpiry: daysUntilExpiry,
      showActions: _isPendingTab,
      showCheckbox: _isApprovedTab,
      isSelected: _selectedOrderIds.contains(orderId),
      showReturnToPending: _isApprovedTab || _isRejectedTab,
      showReceiveAction: _isInProgressTab,
      showCollectedAction: _isCompletedTab,
      onTap: () {
        ref.read(adminProvider.notifier).refreshActivity();
        context.push('/admin/order/$orderId').then((_) {
          SyncService.instance.fullSync();
          _loadData();
        });
      },
      onApprove: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _quickAction(orderId, AppConstants.statusApproved);
      },
      onReject: () {
        ref.read(adminProvider.notifier).refreshActivity();
        _showRejectDialog(orderId);
      },
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
      'In Progress' => (_counts[AppConstants.statusCollected] ?? 0) + (_counts[AppConstants.statusInProcessing] ?? 0),
      'Completed' => _counts[AppConstants.statusCompleted] ?? 0,
      'Rejected' => _counts[AppConstants.statusRejected] ?? 0,
      _ => 0, // All + Napkins — no counter
    };
  }
}

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;
  final String? itemSummary;
  final bool isPartiallyCompleted;
  final int? daysUntilExpiry;
  final bool showActions;
  final bool showCheckbox;
  final bool isSelected;
  final bool showReturnToPending;
  final bool showReceiveAction;
  final bool showCollectedAction;
  final VoidCallback onTap;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onReturnToPending;
  final VoidCallback? onReceive;
  final VoidCallback? onMarkCollected;

  const _OrderCard({
    required this.order,
    this.itemSummary,
    this.isPartiallyCompleted = false,
    this.daysUntilExpiry,
    this.showActions = false,
    this.showCheckbox = false,
    this.isSelected = false,
    this.showReturnToPending = false,
    this.showReceiveAction = false,
    this.showCollectedAction = false,
    required this.onTap,
    required this.onApprove,
    required this.onReject,
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
                    Row(
                      children: [
                        Flexible(
                          child: Text(staffName,
                              style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium, color: AppColors.grey900),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (isOutstanding) ...[
                          SizedBox(width: AppSpacing.sm),
                          () {
                            final isResolved = status == AppConstants.statusCompleted ||
                                status == AppConstants.statusPickedUp ||
                                status == AppConstants.statusExpired;
                            return Container(
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                              decoration: BoxDecoration(
                                color: isResolved
                                    ? AppColors.success.withValues(alpha: 0.12)
                                    : AppColors.error.withValues(alpha: 0.12),
                                borderRadius: AppRadius.smallBR,
                              ),
                              child: Text(
                                isResolved ? 'Outstanding Resolved' : 'Outstanding',
                                style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.bold,
                                    color: isResolved ? AppColors.success : AppColors.error),
                              ),
                            );
                          }(),
                        ],
                      ],
                    ),
                    SizedBox(height: 2),
                    Text('$deptName • ${AppLabels.orderTypeLabels[orderType] ?? orderType}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600),
                        overflow: TextOverflow.ellipsis),
                    SizedBox(height: 1),
                    Text(dateStr, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey500)),
                    if (daysUntilExpiry != null && daysUntilExpiry! <= AppConstants.completedExpiryWarningDays)
                      Text(
                        daysUntilExpiry! <= 1 ? 'Expires today' : '${daysUntilExpiry}d until auto-archive',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium,
                            color: daysUntilExpiry! <= 2 ? AppColors.error : Colors.orange.shade700),
                      ),
                    if (itemSummary != null && itemSummary!.isNotEmpty)
                      Text(itemSummary!,
                          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium, color: AppColors.navy.withValues(alpha: 0.7)),
                          overflow: TextOverflow.ellipsis, maxLines: 1),
                    // Return to Pending button — inside card content
                    if (showReturnToPending) ...[
                      SizedBox(height: AppSpacing.sm),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SizedBox(
                          height: 36,
                          child: OutlinedButton.icon(
                            onPressed: onReturnToPending,
                            icon: Icon(Icons.undo_rounded, size: 16),
                            label: const Text('Return to Pending'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.statusSubmitted,
                              side: BorderSide(color: AppColors.statusSubmitted.withValues(alpha: 0.5)),
                              padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                              textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.captionSize, fontWeight: AppTextStyles.medium),
                              shape: RoundedRectangleBorder(borderRadius: AppRadius.largeBR),
                            ),
                          ),
                        ),
                      ),
                    ],
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
              ] else if (showReturnToPending) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smallBR,
                  ),
                  child: Text(
                    AppLabels.statusLabels[status] ?? status,
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: statusColor),
                  ),
                ),
              ] else if (showReceiveAction) ...[
                SizedBox(
                  height: AppSizes.buttonHeightSm,
                  child: ElevatedButton.icon(
                    onPressed: onReceive,
                    icon: Icon(Icons.inventory_2_rounded, size: AppSizes.iconSizeSm),
                    label: const Text('Receive'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusReceived,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smallBR,
                  ),
                  child: Text(
                    AppLabels.statusLabels[status] ?? status,
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: statusColor),
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
                      backgroundColor: AppColors.success,
                      foregroundColor: AppColors.white,
                      padding: EdgeInsets.symmetric(horizontal: AppSpacing.base),
                      textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium),
                      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
                    ),
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smallBR,
                  ),
                  child: Text(
                    (status == AppConstants.statusCompleted && isPartiallyCompleted)
                        ? 'Partly Completed'
                        : (AppLabels.statusLabels[status] ?? status),
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: statusColor),
                  ),
                ),
              ] else ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smallBR,
                  ),
                  child: Text(
                    (status == AppConstants.statusCompleted && isPartiallyCompleted)
                        ? 'Partly Completed'
                        : (AppLabels.statusLabels[status] ?? status),
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: statusColor),
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
      AppConstants.statusCollected => AppColors.statusCollected,
      AppConstants.statusInProcessing => AppColors.statusInProcessing,
      AppConstants.statusReceived => AppColors.statusReceived,
      AppConstants.statusCompleted => AppColors.statusCompleted,
      AppConstants.statusPickedUp => AppColors.success,
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

              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium)),
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
class _AppLifecycleObserver extends WidgetsBindingObserver {
  final VoidCallback onResume;
  _AppLifecycleObserver({required this.onResume});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      onResume();
    }
  }
}
