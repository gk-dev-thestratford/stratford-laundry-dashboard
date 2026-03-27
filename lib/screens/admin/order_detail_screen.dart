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
import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';

class AdminOrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const AdminOrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends ConsumerState<AdminOrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  List<Map<String, dynamic>> _statusLog = [];
  bool _isLoading = true;
  bool _canDelete = false;
  final _reasonController = TextEditingController();

  // For received quantities
  final Map<String, TextEditingController> _receivedControllers = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).refreshActivity();
    });
    _loadOrder();
    _checkDeletePermission();
  }

  Future<void> _checkDeletePermission() async {
    final adminId = ref.read(adminProvider).currentAdmin?.id;
    if (adminId == null) return;

    // First check local
    final localAdmin = ref.read(adminProvider).currentAdmin;
    if (localAdmin?.canDeleteOrders == true) {
      setState(() => _canDelete = true);
      return;
    }

    // Try Supabase directly
    try {
      final remoteAdmins = await SupabaseService.instance
          .fetchAdminUsers()
          .timeout(const Duration(seconds: 5));
      final match = remoteAdmins.where((a) => a['id'] == adminId).toList();
      if (match.isNotEmpty && match.first['can_delete_orders'] == true) {
        if (mounted) setState(() => _canDelete = true);
      }
      // Update local DB with fresh data
      await DatabaseService.instance.syncAdminUsers(remoteAdmins);
    } catch (e) {
      // Supabase unavailable, fall back to local/provider value
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (final c in _receivedControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadOrder() async {
    final db = DatabaseService.instance;
    final order = await db.getOrder(widget.orderId);
    final items = await db.getOrderItems(widget.orderId);
    final log = await db.getOrderStatusLog(widget.orderId);

    for (final item in items) {
      final id = item['id'] as String;
      _receivedControllers[id] ??= TextEditingController(
        text: (item['quantity_received'] ?? '').toString(),
      );
    }

    if (mounted) {
      setState(() {
        _order = order;
        _items = items;
        _statusLog = log;
        _isLoading = false;
      });
    }
  }

  Future<void> _changeStatus(String newStatus, {String? reason}) async {
    ref.read(adminProvider.notifier).refreshActivity();
    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;
    final uuid = const Uuid();

    await db.updateOrderStatus(widget.orderId, newStatus);
    await db.insertStatusLog({
      'id': uuid.v4(),
      'order_id': widget.orderId,
      'status': newStatus,
      'changed_by': admin?.id,
      'changed_by_name': admin?.name,
      'reason': reason,
      'created_at': DateTime.now().toIso8601String(),
    });

    // Queue for Supabase sync
    await db.addToSyncQueue('orders', widget.orderId, 'update',
        jsonEncode({'id': widget.orderId, 'status': newStatus}));
    SyncService.instance.pushPendingNow();

    await _loadOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to ${AppLabels.statusLabels[newStatus]}')),
      );
    }
  }

  /// Handles receiving items — supports partial receipts with ticket splitting.
  Future<void> _receiveItems() async {
    ref.read(adminProvider.notifier).refreshActivity();
    final admin = ref.read(adminProvider).currentAdmin;
    final db = DatabaseService.instance;
    final uuid = const Uuid();

    // Collect received quantities from text fields
    final received = <String, int>{};
    bool hasOutstanding = false;
    int totalReceived = 0;

    for (final item in _items) {
      final id = item['id'] as String;
      final sent = item['quantity_sent'] as int;
      final controller = _receivedControllers[id];
      final qty = (controller != null && controller.text.isNotEmpty)
          ? (int.tryParse(controller.text) ?? 0)
          : 0;
      received[id] = qty;
      totalReceived += qty;
      if (qty < sent) hasOutstanding = true;
    }

    if (totalReceived == 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter received quantities first')),
        );
      }
      return;
    }

    // Build confirmation message
    final message = hasOutstanding
        ? 'Some items have outstanding quantities. This will:\n'
          '• Complete this ticket with the received amounts\n'
          '• Create a new In Progress ticket for the outstanding items\n\n'
          'Continue?'
        : 'All items fully received. Complete this order?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(hasOutstanding ? 'Partial Receipt' : 'Complete Receipt'),
        content: Text(message),
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
    if (confirmed != true) return;

    // Save received quantities on original order
    await db.updateReceivedQuantities(widget.orderId, received);

    String? newOrderId;
    if (hasOutstanding) {
      // Create new ticket with outstanding quantities
      newOrderId = await db.createOutstandingOrder(
        originalOrderId: widget.orderId,
        receivedQuantities: received,
      );

      // Log original as completed (partial receipt)
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': widget.orderId,
        'status': AppConstants.statusCompleted,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Partial receipt — outstanding items moved to new ticket',
        'created_at': DateTime.now().toIso8601String(),
      });

      // Log the new outstanding order
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': newOrderId,
        'status': AppConstants.statusInProcessing,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'reason': 'Outstanding items from partial receipt',
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // All received — log completion
      await db.insertStatusLog({
        'id': uuid.v4(),
        'order_id': widget.orderId,
        'status': AppConstants.statusCompleted,
        'changed_by': admin?.id,
        'changed_by_name': admin?.name,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    // Mark original as completed
    await db.updateOrderStatus(widget.orderId, AppConstants.statusCompleted);

    // Queue for Supabase sync
    await db.addToSyncQueue('orders', widget.orderId, 'update',
        jsonEncode({'id': widget.orderId, 'status': AppConstants.statusCompleted}));
    if (hasOutstanding && newOrderId != null) {
      final outstandingOrder = await db.getOrder(newOrderId);
      if (outstandingOrder != null) {
        await db.addToSyncQueue('orders', newOrderId, 'insert',
            jsonEncode(outstandingOrder));
      }
    }
    SyncService.instance.pushPendingNow();

    await _loadOrder();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          hasOutstanding
              ? 'Partial receipt recorded — outstanding items on new ticket'
              : 'All items received — order completed',
        )),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.navy),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_order == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.navy),
        body: const Center(child: Text('Order not found')),
      );
    }

    final status = _order!['status'] as String;
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        toolbarHeight: 68,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 26),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text('Order #${_order!['docket_number']}',
                style: TextStyle(fontFamily: 'Inter', color: AppColors.white, fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.medium)),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(AppLabels.statusLabels[status] ?? status,
                  style: TextStyle(fontFamily: 'Inter', color: AppColors.gold, fontSize: AppTextStyles.captionSize)),
            ),
          ],
        ),
        centerTitle: true,
        elevation: 2,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.3),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
          horizontal: isLandscape ? AppSpacing.xxl : AppSpacing.base,
          vertical: AppSpacing.base,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 750),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildDetailsCard(),
                SizedBox(height: AppSpacing.md),
                _buildItemsCard(),
                SizedBox(height: AppSpacing.md),
                if (_order!['notes'] != null && (_order!['notes'] as String).isNotEmpty)
                  ...[_buildNotesCard(), SizedBox(height: AppSpacing.md)],
                _buildStatusTimeline(),
                SizedBox(height: AppSpacing.md),
                _buildActionButtons(status),
                SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsCard() {
    final createdAt = DateTime.tryParse(_order!['created_at'] as String? ?? '');
    final dateStr = createdAt != null ? DateFormat('dd/MM/yyyy HH:mm').format(createdAt) : '—';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: _sectionTitle()),
            const Divider(height: AppSpacing.lg),
            _row('Date', dateStr),
            _row('Docket Number', _order!['docket_number'] ?? '—'),
            _row('Order Type', AppLabels.orderTypeLabels[_order!['order_type']] ?? _order!['order_type'] ?? ''),
            _row('Department', _order!['department_name'] ?? '—'),
            _row('Staff / Guest', _order!['staff_name'] ?? _order!['guest_name'] ?? '—'),
            if (_order!['room_number'] != null) _row('Room', _order!['room_number']),
            if (_order!['email'] != null && (_order!['email'] as String).isNotEmpty)
              _row('Email', _order!['email']),
            if (_order!['bag_count'] != null) _row('Bags', '${_order!['bag_count']}'),
            if (_order!['total_price'] != null && (_order!['total_price'] as num) > 0)
              _row('Total', '£${(_order!['total_price'] as num).toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard() {
    if (_items.isEmpty && _order!['bag_count'] != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Text('${_order!['bag_count']}', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.headingSize, fontWeight: AppTextStyles.bold, color: AppColors.navy)),
              SizedBox(width: AppSpacing.base),
              Text('Laundry Bag(s)', style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, color: AppColors.grey700)),
            ],
          ),
        ),
      );
    }

    final status = _order!['status'] as String;
    final showReceived = status == AppConstants.statusInProcessing ||
        status == AppConstants.statusReceived ||
        status == AppConstants.statusCompleted;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Items (${_items.length})', style: _sectionTitle()),
            const Divider(height: AppSpacing.lg),
            // Header
            Row(
              children: [
                Expanded(flex: 3, child: Text('Item', style: _headerStyle())),
                SizedBox(width: 70, child: Text('Sent', style: _headerStyle(), textAlign: TextAlign.center)),
                if (showReceived)
                  SizedBox(width: 90, child: Text('Received', style: _headerStyle(), textAlign: TextAlign.center)),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            ...List.generate(_items.length, (i) {
              final item = _items[i];
              final id = item['id'] as String;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(item['item_name'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey800)),
                    ),
                    SizedBox(
                      width: 70,
                      child: Text('${item['quantity_sent']}', textAlign: TextAlign.center,
                          style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium, color: AppColors.navy)),
                    ),
                    if (showReceived)
                      SizedBox(
                        width: 90,
                        child: status == AppConstants.statusInProcessing
                            ? SizedBox(
                                height: 42,
                                child: TextField(
                                  controller: _receivedControllers[id],
                                  keyboardType: TextInputType.number,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize),
                                  decoration: InputDecoration(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
                                    border: OutlineInputBorder(borderRadius: AppRadius.smallBR),
                                    hintText: '0',
                                  ),
                                ),
                              )
                            : Text('${item['quantity_received'] ?? 0}', textAlign: TextAlign.center,
                                style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium)),
                      ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes, color: AppColors.grey600, size: AppSizes.iconSizeLg),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Notes', style: _headerStyle()),
                  SizedBox(height: AppSpacing.xs),
                  Text(_order!['notes'] as String, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusTimeline() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Status History', style: _sectionTitle()),
            const Divider(height: AppSpacing.lg),
            if (_statusLog.isEmpty)
              Text('No status changes recorded', style: TextStyle(fontFamily: 'Inter', color: AppColors.grey600, fontSize: AppTextStyles.labelSize)),
            ...List.generate(_statusLog.length, (i) {
              final log = _statusLog[i];
              final time = DateTime.tryParse(log['created_at'] as String? ?? '');
              final timeStr = time != null ? DateFormat('dd/MM/yy HH:mm').format(time) : '';
              return Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.navy,
                        border: Border.all(color: AppColors.navyLight, width: 2),
                      ),
                    ),
                    SizedBox(width: AppSpacing.base),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${AppLabels.statusLabels[log['status']] ?? log['status']}${log['changed_by_name'] != null ? ' by ${log['changed_by_name']}' : ''}',
                            style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: AppColors.grey800),
                          ),
                          if (log['reason'] != null && (log['reason'] as String).isNotEmpty)
                            Text('Reason: ${log['reason']}',
                                style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600, fontStyle: FontStyle.italic)),
                          Text(timeStr, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey500)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(String status) {
    final actions = <Widget>[];

    switch (status) {
      case AppConstants.statusSubmitted:
        actions.addAll([
          _actionButton('Approve', Icons.check_circle, AppColors.success, () => _confirmAction('Approve', AppConstants.statusApproved)),
          SizedBox(width: AppSpacing.md),
          _actionButton('Reject', Icons.cancel, AppColors.error, () => _showRejectDialog()),
        ]);
      case AppConstants.statusApproved:
        actions.add(_actionButton('Mark Collected', Icons.local_shipping, AppColors.statusCollected, () => _confirmAction('Mark as Collected', AppConstants.statusCollected)));
      case AppConstants.statusCollected:
        actions.add(_actionButton('Mark In Processing', Icons.settings, AppColors.statusInProcessing, () => _confirmAction('Mark as In Processing', AppConstants.statusInProcessing)));
      case AppConstants.statusInProcessing:
        actions.add(_actionButton('Receive Items', Icons.inventory, AppColors.statusReceived, _receiveItems));
      case AppConstants.statusRejected:
        actions.add(
          _actionButton('Reinstate', Icons.undo_rounded, AppColors.statusSubmitted, () => _confirmAction('Reinstate to Pending', AppConstants.statusSubmitted)),
        );
        if (_canDelete) {
          actions.addAll([
            SizedBox(width: AppSpacing.md),
            _actionButton('Delete Order', Icons.delete_forever, AppColors.error, _confirmDelete),
          ]);
        }
    }

    if (actions.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Actions', style: _sectionTitle()),
            SizedBox(height: AppSpacing.base),
            Wrap(spacing: AppSpacing.base, runSpacing: AppSpacing.md, children: actions),
          ],
        ),
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: AppSizes.iconSizeMd),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.white,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
        textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium),
        elevation: 2,
        shadowColor: color.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
      ),
    );
  }

  Future<void> _confirmAction(String actionLabel, String newStatus) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$actionLabel Order?'),
        content: Text('Are you sure you want to $actionLabel this order?'),
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
      await _changeStatus(newStatus);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Order?'),
        content: const Text('This will permanently delete this order and all its items. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final db = DatabaseService.instance;
      await db.deleteOrder(widget.orderId);
      // Queue delete for Supabase sync
      await db.addToSyncQueue('orders', widget.orderId, 'delete',
          jsonEncode({'id': widget.orderId}));
      SyncService.instance.pushPendingNow();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order deleted')),
        );
        context.pop();
      }
    }
  }

  Future<void> _showRejectDialog() async {
    _reasonController.clear();
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
              controller: _reasonController,
              maxLines: 3,
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
    if (confirmed == true) {
      await _changeStatus(AppConstants.statusRejected, reason: _reasonController.text.trim());
    }
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 1),
      child: Row(
        children: [
          SizedBox(width: 140, child: Text(label, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, color: AppColors.grey600))),
          Expanded(child: Text(value, style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium, color: AppColors.grey900))),
        ],
      ),
    );
  }

  TextStyle _sectionTitle() => TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.titleSize, fontWeight: AppTextStyles.bold, color: AppColors.navy);
  TextStyle _headerStyle() => TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.labelSize, fontWeight: AppTextStyles.medium, color: AppColors.grey600);
}
