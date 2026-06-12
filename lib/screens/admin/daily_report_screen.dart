import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../providers/admin_provider.dart';
import '../../services/connectivity_service.dart';
import '../../services/database_service.dart';
import '../../services/supabase_service.dart';
import '../../services/sync_service.dart';
import '../../widgets/thumbs_up_confirmation.dart';

/// Daily Report — a local preview of exactly what the combined daily report
/// email will contain, with an explicit "Send Report" button.
///
/// Sections (operational order, mirrors supabase/functions/daily-report):
///   1. Received Today        — orders with a 'received' status log today
///   2. Sent to Laundry Today — orders with a 'sent' status log today
///   3. Still at Laundry      — the FULL backlog of status='sent' orders, aged
///   4. Napkin Returns Today  — linen_ledger 'in' entries today
///
/// All data comes from the LOCAL database (offline-first). Sending pushes
/// pending local work to Supabase first, then invokes the edge function with
/// no payload so the email is built from the freshly-synced server data.
class DailyReportScreen extends ConsumerStatefulWidget {
  const DailyReportScreen({super.key});

  @override
  ConsumerState<DailyReportScreen> createState() => _DailyReportScreenState();
}

/// One row of the "Still at Laundry" backlog, pre-computed for display.
class _BacklogRow {
  final String docket;
  final bool isPartial;
  final String department;
  final String name;
  final String awaitedDesc;
  final int awaitedQty;
  final int days;

  const _BacklogRow({
    required this.docket,
    required this.isPartial,
    required this.department,
    required this.name,
    required this.awaitedDesc,
    required this.awaitedQty,
    required this.days,
  });
}

class _DailyReportScreenState extends ConsumerState<DailyReportScreen> {
  static const _kLastSentMetaKey = 'daily_report_last_sent_at';

  bool _isLoading = true;
  bool _isSending = false;
  List<Map<String, dynamic>> _receivedToday = [];
  List<Map<String, dynamic>> _sentToday = [];
  List<_BacklogRow> _backlog = [];
  List<Map<String, dynamic>> _napkinReturns = [];
  Map<String, List<Map<String, dynamic>>> _itemsByOrder = {};
  DateTime? _lastSentAt;
  /// Today explicitly marked "no napkin returns" (app_meta, date-keyed).
  bool _napkinNoneToday = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    final received =
        await db.getOrdersWithStatusLogToday(AppConstants.statusReceived);
    final sent = await db.getOrdersWithStatusLogToday(AppConstants.statusSent);
    // The whole not-yet-received backlog, any day
    final backlogOrders =
        await db.getOrders(status: AppConstants.statusSent, limit: 500);

    final allIds = <String>{
      ...received.map((o) => o['id'] as String),
      ...sent.map((o) => o['id'] as String),
      ...backlogOrders.map((o) => o['id'] as String),
    }.toList();
    final itemsByOrder = await db.getOrderItemsByOrderIds(allIds);

    // Aging: days since the latest 'sent' log (fallback created_at)
    final sentDates = await db.getLatestStatusLogDates(
      backlogOrders.map((o) => o['id'] as String).toList(),
      AppConstants.statusSent,
    );

    final backlog = <_BacklogRow>[];
    for (final order in backlogOrders) {
      final orderId = order['id'] as String;
      final items = itemsByOrder[orderId] ?? [];
      final awaitedParts = <String>[];
      int awaitedQty = 0;
      for (final item in items) {
        final awaited = (item['quantity_sent'] as int? ?? 0) -
            (item['quantity_received'] as int? ?? 0);
        if (awaited > 0) {
          awaitedParts.add('$awaited× ${item['item_name']}');
          awaitedQty += awaited;
        }
      }
      // Mirror the edge function: tickets with nothing awaited are omitted
      if (awaitedParts.isEmpty) continue;

      final sentAt = DateTime.tryParse(sentDates[orderId] ?? '') ??
          DateTime.tryParse(order['created_at'] as String? ?? '') ??
          now;
      final days = now.difference(sentAt).inDays.clamp(0, 9999);

      backlog.add(_BacklogRow(
        docket: '${order['docket_number']}',
        isPartial: order['parent_order_id'] != null,
        department: order['department_name'] as String? ?? '—',
        name: order['staff_name'] as String? ??
            order['guest_name'] as String? ??
            '—',
        awaitedDesc: awaitedParts.join(', '),
        awaitedQty: awaitedQty,
        days: days,
      ));
    }
    // Oldest first — matches the email's ordering
    backlog.sort((a, b) => b.days.compareTo(a.days));

    final ledger = await db.getLedgerEntries(since: todayMidnight);
    final napkinReturns =
        ledger.where((e) => e['direction'] == 'in').toList();

    final lastSentIso = await db.getMeta(_kLastSentMetaKey);
    final napkinNoneToday = await db.isNapkinNoneMarkedToday();

    if (mounted) {
      setState(() {
        _receivedToday = received;
        _sentToday = sent;
        _backlog = backlog;
        _napkinReturns = napkinReturns;
        _itemsByOrder = itemsByOrder;
        _lastSentAt =
            lastSentIso != null ? DateTime.tryParse(lastSentIso) : null;
        _napkinNoneToday = napkinNoneToday;
        _isLoading = false;
      });
    }
  }

  int get _stillAtLaundryQty =>
      _backlog.fold(0, (sum, row) => sum + row.awaitedQty);

  int get _napkinQty =>
      _napkinReturns.fold(0, (sum, e) => sum + (e['quantity'] as int? ?? 0));

  /// Napkin state resolved: returns logged today OR explicitly marked none.
  /// Send Report is gated on this (the preview itself stays accessible).
  bool get _napkinsResolved => _napkinReturns.isNotEmpty || _napkinNoneToday;

  Future<void> _sendReport() async {
    ref.read(adminProvider.notifier).refreshActivity();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Daily Report?'),
        content: Text(
          'Send daily report? ${_receivedToday.length} received, '
          '${_sentToday.length} sent, $_stillAtLaundryQty items still at '
          'laundry, $_napkinQty napkins — will be emailed to the laundry '
          'company and management.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.send_rounded, size: AppSizes.iconSizeSm),
            label: const Text('Send Report'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isSending = true);
    try {
      // 1. The email is built from SERVER data — local work must be pushed first.
      if (ConnectivityService.instance.currentStatus !=
              ConnectivityStatus.online ||
          !SupabaseService.instance.isInitialized) {
        _showError("Couldn't sync — check connection and try again");
        return;
      }
      await SyncService.instance.pushPendingAndWait();
      final remaining = await DatabaseService.instance.getPendingSyncItems();
      if (remaining.isNotEmpty) {
        _showError("Couldn't sync — check connection and try again");
        return;
      }

      // 2. Invoke the edge function (no payload — it self-fetches from the server).
      final ok = await SupabaseService.instance.invokeDailyReport();
      if (!ok) {
        _showError("Couldn't send the report — please try again");
        return;
      }

      final sentAt = DateTime.now();
      await DatabaseService.instance
          .setMeta(_kLastSentMetaKey, sentAt.toIso8601String());
      if (mounted) {
        setState(() => _lastSentAt = sentAt);
        showThumbsUpConfirmation(context, message: 'Report sent');
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
              fontFamily: 'Inter', fontWeight: AppTextStyles.medium),
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 900),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildReceivedSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildSentSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildBacklogSection(),
                              const SizedBox(height: AppSpacing.lg),
                              _buildNapkinSection(),
                              const SizedBox(height: AppSpacing.xl),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
          if (!_isLoading) _buildSendBar(),
        ],
      ),
    );
  }

  // ── Header (matches Napkin Returns screen styling) ──

  Widget _buildHeader() {
    final today = DateFormat('EEEE d MMMM').format(DateTime.now());
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, AppColors.navyLight],
        ),
        borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm, AppSpacing.sm, AppSpacing.lg, AppSpacing.xl),
          child: Row(
            children: [
              IconButton(
                icon:
                    const Icon(Icons.arrow_back_rounded, color: AppColors.white),
                onPressed: () => Navigator.pop(context),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Daily Report',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.white,
                            fontSize: AppTextStyles.titleSize,
                            fontWeight: AppTextStyles.bold)),
                    Text('Preview & send — $today',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            color: AppColors.gold,
                            fontSize: AppTextStyles.captionSize)),
                  ],
                ),
              ),
              Icon(Icons.summarize_rounded,
                  color: AppColors.gold.withValues(alpha: 0.85),
                  size: AppSizes.iconSizeLg),
            ],
          ),
        ),
      ),
    );
  }

  // ── Section scaffolding ──

  Widget _sectionCard({
    required String title,
    required String countLabel,
    required Color color,
    required IconData icon,
    required List<Widget> children,
    required String emptyMessage,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: AppSizes.iconSizeMd),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: AppTextStyles.titleSize,
                          fontWeight: AppTextStyles.bold,
                          color: AppColors.navy)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.largeBR,
                  ),
                  child: Text(countLabel,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: AppTextStyles.captionSize,
                          fontWeight: AppTextStyles.bold,
                          color: color)),
                ),
              ],
            ),
            const Divider(height: AppSpacing.xl),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Row(
                  children: [
                    Icon(Icons.check_circle_outline_rounded,
                        size: AppSizes.iconSizeSm, color: AppColors.grey400),
                    const SizedBox(width: AppSpacing.sm),
                    Text(emptyMessage,
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.labelSize,
                            fontStyle: FontStyle.italic,
                            color: AppColors.grey500)),
                  ],
                ),
              )
            else
              ...children,
          ],
        ),
      ),
    );
  }

  Widget _docketBadge(String docket, {bool isPartial = false}) {
    return Container(
      constraints: const BoxConstraints(minWidth: 64),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.08),
        borderRadius: AppRadius.smallBR,
        border:
            Border.all(color: AppColors.navy.withValues(alpha: 0.15)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('#$docket',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.navy)),
          if (isPartial)
            Text('(partial)',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.statusSent)),
        ],
      ),
    );
  }

  String _itemsDesc(String orderId) {
    final items = _itemsByOrder[orderId] ?? [];
    if (items.isEmpty) return '—';
    return items
        .map((i) => '${i['quantity_sent']}× ${i['item_name']}')
        .join(', ');
  }

  // ── 1. Received Today ──

  Widget _buildReceivedSection() {
    return _sectionCard(
      title: '1 · Received Today',
      countLabel: '${_receivedToday.length} order${_receivedToday.length == 1 ? '' : 's'}',
      color: AppColors.statusReceived,
      icon: Icons.done_all_rounded,
      emptyMessage: 'Nothing received today.',
      children: _receivedToday.map((order) {
        final orderId = order['id'] as String;
        final items = _itemsByOrder[orderId] ?? [];
        final totalSent = items.fold<int>(
            0, (s, i) => s + (i['quantity_sent'] as int? ?? 0));
        final totalReceived = items.fold<int>(
            0, (s, i) => s + (i['quantity_received'] as int? ?? 0));
        final short = totalSent - totalReceived;
        return _reportRow(
          leading: _docketBadge('${order['docket_number']}'),
          name: order['staff_name'] as String? ??
              order['guest_name'] as String? ??
              '—',
          department: order['department_name'] as String? ?? '—',
          detail: _itemsDesc(orderId),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$totalReceived of $totalSent received',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppTextStyles.captionSize,
                      fontWeight: AppTextStyles.medium,
                      color: AppColors.grey700)),
              const SizedBox(height: 2),
              if (short > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: AppRadius.smallBR,
                  ),
                  child: Text('$short short',
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: AppTextStyles.captionSize,
                          fontWeight: AppTextStyles.bold,
                          color: AppColors.error)),
                )
              else
                Icon(Icons.check_circle_rounded,
                    size: AppSizes.iconSizeSm, color: AppColors.success),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 2. Sent to Laundry Today ──

  Widget _buildSentSection() {
    return _sectionCard(
      title: '2 · Sent to Laundry Today',
      countLabel: '${_sentToday.length} order${_sentToday.length == 1 ? '' : 's'}',
      color: AppColors.statusSent,
      icon: Icons.local_shipping_rounded,
      emptyMessage: 'Nothing sent to the laundry today.',
      children: _sentToday.map((order) {
        final orderId = order['id'] as String;
        final items = _itemsByOrder[orderId] ?? [];
        final totalQty = items.fold<int>(
            0, (s, i) => s + (i['quantity_sent'] as int? ?? 0));
        return _reportRow(
          leading: _docketBadge('${order['docket_number']}'),
          name: order['staff_name'] as String? ??
              order['guest_name'] as String? ??
              '—',
          department: order['department_name'] as String? ?? '—',
          detail: _itemsDesc(orderId),
          trailing: Text('$totalQty item${totalQty == 1 ? '' : 's'}',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.statusSent)),
        );
      }).toList(),
    );
  }

  // ── 3. Still at Laundry (full backlog with aging) ──

  Widget _buildBacklogSection() {
    return _sectionCard(
      title: '3 · Still at Laundry',
      countLabel: _backlog.isEmpty
          ? 'all clear'
          : '$_stillAtLaundryQty item${_stillAtLaundryQty == 1 ? '' : 's'} / ${_backlog.length} ticket${_backlog.length == 1 ? '' : 's'}',
      color: AppColors.error,
      icon: Icons.local_laundry_service_rounded,
      emptyMessage: 'Nothing outstanding at the laundry.',
      children: _backlog.map((row) {
        final ageColor = row.days >= 7
            ? AppColors.error
            : row.days >= 3
                ? Colors.orange.shade800
                : AppColors.grey600;
        return _reportRow(
          leading: _docketBadge(row.docket, isPartial: row.isPartial),
          name: row.name,
          department: row.department,
          detail: 'awaiting ${row.awaitedDesc}',
          detailColor: AppColors.error,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (row.days >= 7)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(Icons.warning_amber_rounded,
                      size: AppSizes.iconSizeSm, color: AppColors.error),
                ),
              Text('${row.days}d',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppTextStyles.labelSize,
                      fontWeight: AppTextStyles.bold,
                      color: ageColor)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 4. Napkin Returns Today ──

  Widget _buildNapkinSection() {
    return _sectionCard(
      title: '4 · Napkin Returns Today',
      countLabel: '$_napkinQty napkin${_napkinQty == 1 ? '' : 's'}',
      color: AppColors.gold,
      icon: Icons.dining,
      emptyMessage: _napkinNoneToday
          ? 'Marked: no napkin returns today.'
          : 'No napkin returns today.',
      children: _napkinReturns.map((entry) {
        final time =
            DateTime.tryParse(entry['created_at'] as String? ?? '');
        return _reportRow(
          leading: Container(
            constraints: const BoxConstraints(minWidth: 64),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.gold.withValues(alpha: 0.18),
              borderRadius: AppRadius.smallBR,
              border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.5)),
            ),
            child: Text('${entry['quantity']}',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppTextStyles.labelSize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.goldDark)),
          ),
          name: entry['note'] as String? ?? 'Napkin return',
          department: 'Recorded by ${entry['recorded_by'] ?? '—'}',
          detail: null,
          trailing: Text(
              time != null ? DateFormat('HH:mm').format(time) : '—',
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.captionSize,
                  color: AppColors.grey500)),
        );
      }).toList(),
    );
  }

  /// Shared row layout: leading badge, name + department + detail, trailing.
  Widget _reportRow({
    required Widget leading,
    required String name,
    required String department,
    required String? detail,
    Color? detailColor,
    required Widget trailing,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: AppColors.grey200, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          leading,
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.labelSize,
                        fontWeight: AppTextStyles.medium,
                        color: AppColors.grey900),
                    overflow: TextOverflow.ellipsis),
                Text(department,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.captionSize,
                        color: AppColors.grey600),
                    overflow: TextOverflow.ellipsis),
                if (detail != null && detail.isNotEmpty)
                  Text(detail,
                      style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: AppTextStyles.captionSize,
                          fontWeight: AppTextStyles.medium,
                          color: detailColor ??
                              AppColors.navy.withValues(alpha: 0.7)),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          trailing,
        ],
      ),
    );
  }

  // ── Bottom send bar ──

  Widget _buildSendBar() {
    final now = DateTime.now();
    final sentToday = _lastSentAt != null &&
        _lastSentAt!.year == now.year &&
        _lastSentAt!.month == now.month &&
        _lastSentAt!.day == now.day;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.navy.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.base),
          child: Row(
            children: [
              Expanded(
                child: !_napkinsResolved
                    ? Row(
                        children: [
                          Icon(Icons.warning_amber_rounded,
                              size: AppSizes.iconSizeSm,
                              color: Colors.orange.shade800),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                                'Napkins not recorded — log returns or mark '
                                '"None today" before sending',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: AppTextStyles.captionSize,
                                    fontWeight: AppTextStyles.medium,
                                    color: Colors.orange.shade800)),
                          ),
                        ],
                      )
                    : sentToday
                        ? Text(
                            'Last sent today at ${DateFormat('HH:mm').format(_lastSentAt!)}',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: AppTextStyles.captionSize,
                                fontWeight: AppTextStyles.medium,
                                color: AppColors.grey600))
                        : Text('Not sent today',
                            style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: AppTextStyles.captionSize,
                                color: AppColors.grey500)),
              ),
              SizedBox(
                height: AppSizes.buttonHeightLg,
                child: ElevatedButton.icon(
                  onPressed:
                      (_isSending || !_napkinsResolved) ? null : _sendReport,
                  icon: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.navy),
                        )
                      : const Icon(Icons.send_rounded,
                          size: AppSizes.iconSizeMd),
                  label: Text(_isSending ? 'Sending…' : 'Send Report'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    disabledBackgroundColor:
                        AppColors.gold.withValues(alpha: 0.5),
                    disabledForegroundColor:
                        AppColors.navy.withValues(alpha: 0.6),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xl),
                    textStyle: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.bodySize,
                        fontWeight: AppTextStyles.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.mediumBR),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
