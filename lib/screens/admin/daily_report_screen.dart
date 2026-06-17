import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
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
///   1. Received Today        — fully received tickets ('received' log today)
///   2. Partially Received    — 'received' log today but non-napkin items short
///   3. Sent to Laundry Today — orders with a 'sent' status log today
///   4. Still at Laundry      — the FULL backlog of status='sent' orders, aged
///   5. Napkin Returns Today  — linen_ledger 'in' entries today
///
/// Pool-tracked napkins (AppConstants.isPoolTracked) are balanced via the
/// linen pool, NOT per-ticket: napkin LINES are excluded from item counts
/// and napkin-ONLY tickets are excluded from sections 1–4 — they only appear
/// in the napkin section. The server-side email builder applies the same rule.
///
/// On wide/landscape screens the sections render as a 2-column grid
/// (Received | Partial, Sent | Still at Laundry, Napkins full-width); on
/// narrow/portrait they fall back to the vertical list.
///
/// Requires the can_send_report permission — admins without it are denied.
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
  /// Fully received today (non-napkin lines complete).
  List<Map<String, dynamic>> _receivedToday = [];
  /// 'received' log today but at least one non-napkin item came back short
  /// (these spawned a child outstanding ticket).
  List<Map<String, dynamic>> _partialToday = [];
  List<Map<String, dynamic>> _sentToday = [];
  List<_BacklogRow> _backlog = [];
  List<Map<String, dynamic>> _napkinReturns = [];
  Map<String, List<Map<String, dynamic>>> _itemsByOrder = {};
  DateTime? _lastSentAt;
  /// True when [_lastSentAt] falls on today's local calendar day — drives the
  /// "report sent today" banner, the express window, and the send gating.
  bool _reportSentToday = false;
  /// True when the windowed sections (received / partial / sent / napkins)
  /// hold anything — i.e. there is something new to send.
  bool _hasNewActivity = false;
  /// Today explicitly marked "no napkin returns" (app_meta, date-keyed).
  bool _napkinNoneToday = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// Pool-tracked napkin line — excluded from per-ticket counts everywhere.
  static bool _isNapkinLine(Map<String, dynamic> item) =>
      AppConstants.isPoolTracked(item['item_name'] as String? ?? '');

  /// Napkin-only tickets live in the napkin section, not the order sections.
  /// (Bag-only tickets with no items are NOT napkin-only.)
  static bool _isNapkinOnly(List<Map<String, dynamic>> items) =>
      items.isNotEmpty && items.every(_isNapkinLine);

  Future<void> _loadData() async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // ── "Since last send" window ──────────────────────────────────────────
    // If a report was already sent earlier TODAY, the activity sections only
    // show what happened since that send (the next express batch). Otherwise
    // the window is the whole day (today midnight). The "Still at Laundry"
    // backlog below is standing info and is NEVER windowed.
    final lastSentIso = await db.getMeta(_kLastSentMetaKey);
    final lastSentAt = lastSentIso != null ? DateTime.tryParse(lastSentIso) : null;
    final reportSentToday = lastSentAt != null &&
        lastSentAt.year == now.year &&
        lastSentAt.month == now.month &&
        lastSentAt.day == now.day;
    final windowStartIso = (reportSentToday && lastSentIso != null)
        ? lastSentIso
        : todayMidnight.toIso8601String();
    final windowStart = DateTime.parse(windowStartIso);

    final received =
        await db.getOrdersWithStatusLogSince(AppConstants.statusReceived, windowStartIso);
    final sent =
        await db.getOrdersWithStatusLogSince(AppConstants.statusSent, windowStartIso);
    // The whole not-yet-received backlog, any day (standing info, not windowed)
    final backlogOrders =
        await db.getOrders(status: AppConstants.statusSent, limit: 500);

    final allIds = <String>{
      ...received.map((o) => o['id'] as String),
      ...sent.map((o) => o['id'] as String),
      ...backlogOrders.map((o) => o['id'] as String),
    }.toList();
    final itemsByOrder = await db.getOrderItemsByOrderIds(allIds);

    // Split received into fully vs partially received (non-napkin lines
    // only); napkin-only tickets are excluded from both.
    final receivedFull = <Map<String, dynamic>>[];
    final receivedPartial = <Map<String, dynamic>>[];
    for (final order in received) {
      final items = itemsByOrder[order['id'] as String] ?? [];
      if (_isNapkinOnly(items)) continue;
      final isPartial = items.where((i) => !_isNapkinLine(i)).any((i) =>
          (i['quantity_received'] as int? ?? 0) <
          (i['quantity_sent'] as int? ?? 0));
      (isPartial ? receivedPartial : receivedFull).add(order);
    }

    // Sent today — napkin-only tickets excluded (pool ledger covers them).
    final sentFiltered = sent
        .where((o) => !_isNapkinOnly(itemsByOrder[o['id'] as String] ?? []))
        .toList();

    // Aging: days since the latest 'sent' log (fallback created_at)
    final sentDates = await db.getLatestStatusLogDates(
      backlogOrders.map((o) => o['id'] as String).toList(),
      AppConstants.statusSent,
    );

    final backlog = <_BacklogRow>[];
    for (final order in backlogOrders) {
      final orderId = order['id'] as String;
      final items = itemsByOrder[orderId] ?? [];
      if (_isNapkinOnly(items)) continue;
      final awaitedParts = <String>[];
      int awaitedQty = 0;
      if (items.isEmpty) {
        // Bag-based ticket (e.g. guest/resident laundry) — no line items;
        // awaited as whole bags. Mirrors the side panel and the email.
        final bags = order['bag_count'] as int? ?? 0;
        if (bags > 0) {
          awaitedParts.add('$bags bag${bags == 1 ? '' : 's'}');
          awaitedQty += bags;
        }
      } else {
        for (final item in items) {
          if (_isNapkinLine(item)) continue; // pool-tracked, never awaited
          final awaited = (item['quantity_sent'] as int? ?? 0) -
              (item['quantity_received'] as int? ?? 0);
          if (awaited > 0) {
            awaitedParts.add('$awaited× ${item['item_name']}');
            awaitedQty += awaited;
          }
        }
      }
      // Tickets with nothing awaited are omitted
      if (awaitedParts.isEmpty) continue;

      final sentAt = DateTime.tryParse(sentDates[orderId] ?? '') ??
          DateTime.tryParse(order['created_at'] as String? ?? '') ??
          now;
      final days = now.difference(sentAt).inDays.clamp(0, 9999);
      // Exclude tickets sent TODAY (days == 0): they appear under "Sent to
      // Laundry Today", so listing them as outstanding double-counts and
      // wrongly flags same-day sends as overdue. Matches the side panel and
      // the report email (days >= 1).
      if (days < 1) continue;

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

    final ledger = await db.getLedgerEntries(since: windowStart);
    final napkinReturns =
        ledger.where((e) => e['direction'] == 'in').toList();

    final napkinNoneToday = await db.isNapkinNoneMarkedToday();

    // New activity = anything in the window across the four activity sections.
    final hasNewActivity = receivedFull.isNotEmpty ||
        receivedPartial.isNotEmpty ||
        sentFiltered.isNotEmpty ||
        napkinReturns.isNotEmpty;

    if (mounted) {
      setState(() {
        _receivedToday = receivedFull;
        _partialToday = receivedPartial;
        _sentToday = sentFiltered;
        _backlog = backlog;
        _napkinReturns = napkinReturns;
        _itemsByOrder = itemsByOrder;
        _lastSentAt = lastSentAt;
        _reportSentToday = reportSentToday;
        _hasNewActivity = hasNewActivity;
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

    // Express follow-up when a report already went out earlier today.
    final isExpress = _reportSentToday && _hasNewActivity;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isExpress ? 'Send Express Update?' : 'Send Daily Report?'),
        content: Text(
          '${isExpress ? 'Send express update?' : 'Send daily report?'} '
          '${_receivedToday.length} received, '
          '${_partialToday.length} partially received, '
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
            label: Text(isExpress ? 'Send Express Update' : 'Send Report'),
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

      // 2. Invoke the edge function. For an express follow-up pass the last
      //    send time so the email only covers the new batch since then; for a
      //    first/full daily send pass null (whole day).
      final since = _reportSentToday
          ? await DatabaseService.instance.getMeta(_kLastSentMetaKey)
          : null;
      final ok = await SupabaseService.instance.invokeDailyReport(since: since);
      if (!ok) {
        _showError("Couldn't send the report — please try again");
        return;
      }

      final sentAt = DateTime.now();
      await DatabaseService.instance
          .setMeta(_kLastSentMetaKey, sentAt.toIso8601String());
      if (mounted) {
        showThumbsUpConfirmation(context, message: 'Report sent');
        // Re-load so the window recomputes from the new send time: sections
        // empty out and the "sent today" banner appears. Stay on this screen.
        await _loadData();
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
    // Permission gate: admins without can_send_report never see this screen
    // (the dashboard hides the entry points; this denies direct navigation).
    final admin = ref.watch(adminProvider);
    if (admin.currentAdmin?.canSendReport == false) {
      return _buildDeniedScaffold();
    }

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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        // Side-by-side grid on wide/landscape screens;
                        // vertical list fallback on narrow/portrait.
                        final isWide = constraints.maxWidth >= 700 &&
                            MediaQuery.of(context).orientation ==
                                Orientation.landscape;
                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: ConstrainedBox(
                              constraints:
                                  const BoxConstraints(maxWidth: 1100),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (_reportSentToday) ...[
                                    _buildSentBanner(),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  isWide
                                      ? _buildGridLayout()
                                      : _buildVerticalLayout(),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
          ),
          if (!_isLoading) _buildSendBar(),
        ],
      ),
    );
  }

  /// 2-column grid: Received | Partially Received, Sent | Still at Laundry,
  /// then Napkins full-width.
  Widget _buildGridLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildReceivedSection()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildPartialSection()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSentSection()),
              const SizedBox(width: AppSpacing.lg),
              Expanded(child: _buildBacklogSection()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildNapkinSection(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildVerticalLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildReceivedSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildPartialSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildSentSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildBacklogSection(),
        const SizedBox(height: AppSpacing.lg),
        _buildNapkinSection(),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  /// Shown when an admin without can_send_report reaches this route directly.
  Widget _buildDeniedScaffold() {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_outline_rounded,
                      size: 56, color: AppColors.grey400),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'You don\'t have permission to send the daily report',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.titleSize,
                        fontWeight: AppTextStyles.medium,
                        color: AppColors.grey700),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask a manager to enable "Can send report" for your account.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.labelSize,
                        color: AppColors.grey500),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_rounded,
                        size: AppSizes.iconSizeSm),
                    label: const Text('Back to dashboard'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.navy,
                        foregroundColor: AppColors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Export the on-device ticket journal (an immutable snapshot of every
  /// created ticket) as a JSON file via the share sheet — a root-free recovery
  /// path so records can be retrieved (emailed / saved to Drive) even when the
  /// tablet's app-private storage can't be reached directly.
  Future<void> _exportJournal() async {
    try {
      final entries =
          await DatabaseService.instance.getJournalEntries(limit: 5000);
      if (entries.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No ticket history on this device yet.')),
          );
        }
        return;
      }
      final json = const JsonEncoder.withIndent('  ').convert(entries);
      final ts = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/laundry_tickets_$ts.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Stratford laundry — ticket backup ($ts)',
          text: '${entries.length} tickets exported from this device.',
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    }
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
              IconButton(
                icon: const Icon(Icons.download_rounded, color: AppColors.white),
                tooltip: 'Export ticket backup',
                onPressed: _exportJournal,
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

  /// Item description for a ticket — napkin lines excluded (pool-tracked).
  /// Bag-based tickets with no line items (e.g. guest/resident laundry) are
  /// described by their bag count instead of an empty dash.
  String _itemsDesc(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final items = (_itemsByOrder[orderId] ?? [])
        .where((i) => !_isNapkinLine(i))
        .toList();
    if (items.isEmpty) {
      final bags = order['bag_count'] as int? ?? 0;
      return bags > 0 ? '$bags bag${bags == 1 ? '' : 's'}' : '—';
    }
    return items
        .map((i) => '${i['quantity_sent']}× ${i['item_name']}')
        .join(', ');
  }

  /// True when a ticket has no (non-napkin) line items but is a bag-based
  /// order — i.e. guest/resident laundry counted in whole bags.
  bool _isBagTicket(Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final hasItems =
        (_itemsByOrder[orderId] ?? []).any((i) => !_isNapkinLine(i));
    return !hasItems && (order['bag_count'] as int? ?? 0) > 0;
  }

  /// Non-napkin (sent, received) totals for a ticket.
  (int, int) _nonNapkinTotals(String orderId) {
    final items = (_itemsByOrder[orderId] ?? [])
        .where((i) => !_isNapkinLine(i));
    final sent =
        items.fold<int>(0, (s, i) => s + (i['quantity_sent'] as int? ?? 0));
    final received = items.fold<int>(
        0, (s, i) => s + (i['quantity_received'] as int? ?? 0));
    return (sent, received);
  }

  // ── 1. Received Today (fully) ──

  Widget _buildReceivedSection() {
    return _sectionCard(
      title: '1 · Received Today',
      countLabel: '${_receivedToday.length} order${_receivedToday.length == 1 ? '' : 's'}',
      color: AppColors.statusReceived,
      icon: Icons.done_all_rounded,
      emptyMessage: 'Nothing received today.',
      children: _receivedToday.map((order) {
        final orderId = order['id'] as String;
        final isBag = _isBagTicket(order);
        final bags = order['bag_count'] as int? ?? 0;
        final (totalSent, totalReceived) = _nonNapkinTotals(orderId);
        return _reportRow(
          leading: _docketBadge('${order['docket_number']}'),
          name: order['staff_name'] as String? ??
              order['guest_name'] as String? ??
              '—',
          department: order['department_name'] as String? ?? '—',
          detail: _itemsDesc(order),
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  isBag
                      ? '$bags bag${bags == 1 ? '' : 's'} received'
                      : '$totalReceived of $totalSent received',
                  style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppTextStyles.captionSize,
                      fontWeight: AppTextStyles.medium,
                      color: AppColors.grey700)),
              const SizedBox(height: 2),
              Icon(Icons.check_circle_rounded,
                  size: AppSizes.iconSizeSm, color: AppColors.success),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── 2. Partially Received (spawned a follow-up outstanding ticket) ──

  Widget _buildPartialSection() {
    final partialColor = Colors.amber.shade800;
    return _sectionCard(
      title: '2 · Partially Received',
      countLabel: '${_partialToday.length} order${_partialToday.length == 1 ? '' : 's'}',
      color: partialColor,
      icon: Icons.rule_rounded,
      emptyMessage: 'No partial receipts today.',
      children: _partialToday.map((order) {
        final orderId = order['id'] as String;
        final (totalSent, totalReceived) = _nonNapkinTotals(orderId);
        final awaiting = (_itemsByOrder[orderId] ?? [])
            .where((i) => !_isNapkinLine(i))
            .map((i) {
              final short = (i['quantity_sent'] as int? ?? 0) -
                  (i['quantity_received'] as int? ?? 0);
              return short > 0 ? '$short× ${i['item_name']}' : null;
            })
            .whereType<String>()
            .join(', ');
        return _reportRow(
          leading: _docketBadge('${order['docket_number']}'),
          name: order['staff_name'] as String? ??
              order['guest_name'] as String? ??
              '—',
          department: order['department_name'] as String? ?? '—',
          detail: awaiting.isEmpty ? null : 'awaiting $awaiting',
          detailColor: AppColors.error,
          trailing: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm, vertical: 2),
            decoration: BoxDecoration(
              color: partialColor.withValues(alpha: 0.12),
              borderRadius: AppRadius.smallBR,
            ),
            child: Text('$totalReceived of $totalSent',
                style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppTextStyles.captionSize,
                    fontWeight: AppTextStyles.bold,
                    color: partialColor)),
          ),
        );
      }).toList(),
    );
  }

  // ── 3. Sent to Laundry Today ──

  Widget _buildSentSection() {
    return _sectionCard(
      title: '3 · Sent to Laundry Today',
      countLabel: '${_sentToday.length} order${_sentToday.length == 1 ? '' : 's'}',
      color: AppColors.statusSent,
      icon: Icons.local_shipping_rounded,
      emptyMessage: 'Nothing sent to the laundry today.',
      children: _sentToday.map((order) {
        final orderId = order['id'] as String;
        final isBag = _isBagTicket(order);
        final bags = order['bag_count'] as int? ?? 0;
        final (totalQty, _) = _nonNapkinTotals(orderId);
        final qtyLabel = isBag
            ? '$bags bag${bags == 1 ? '' : 's'}'
            : '$totalQty item${totalQty == 1 ? '' : 's'}';
        return _reportRow(
          leading: _docketBadge('${order['docket_number']}'),
          name: order['staff_name'] as String? ??
              order['guest_name'] as String? ??
              '—',
          department: order['department_name'] as String? ?? '—',
          detail: _itemsDesc(order),
          trailing: Text(qtyLabel,
              style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.labelSize,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.statusSent)),
        );
      }).toList(),
    );
  }

  // ── 4. Still at Laundry (full backlog with aging) ──

  Widget _buildBacklogSection() {
    return _sectionCard(
      title: '4 · Still at Laundry',
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
      title: '5 · Napkin Returns Today',
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

  // ── "Report sent today" banner (top of body when sent today) ──

  Widget _buildSentBanner() {
    final at = _lastSentAt != null
        ? DateFormat('HH:mm').format(_lastSentAt!)
        : '—';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.10),
        borderRadius: AppRadius.mediumBR,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded,
              color: AppColors.success, size: AppSizes.iconSizeLg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Report sent today at $at',
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: AppTextStyles.titleSize,
                        fontWeight: AppTextStyles.bold,
                        color: AppColors.success)),
                if (!_hasNewActivity)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text('Nothing new to report since.',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.captionSize,
                            color: AppColors.grey700)),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                        'New activity since — ready to send an express update.',
                        style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: AppTextStyles.captionSize,
                            color: AppColors.grey700)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom send bar ──

  Widget _buildSendBar() {
    final sentToday = _reportSentToday;
    // Re-send only allowed when nothing was sent yet today, or there is new
    // activity since the last send (an express follow-up).
    final canSend = _napkinsResolved && (!sentToday || _hasNewActivity);
    final isExpress = sentToday && _hasNewActivity;
    final atLabel = _lastSentAt != null
        ? DateFormat('HH:mm').format(_lastSentAt!)
        : '—';
    final buttonLabel = _isSending
        ? 'Sending…'
        : isExpress
            ? 'Send Express Update'
            : 'Send Report';

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
                // The napkin warning only matters while a send is the goal —
                // once a report is out for the day with nothing new, suppress
                // it (the windowed napkin list is empty by design) and show the
                // "nothing new" hint instead.
                child: (!_napkinsResolved && (!sentToday || _hasNewActivity))
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
                            _hasNewActivity
                                ? 'Sent at $atLabel — new activity since, ready for an express update.'
                                : 'Nothing new since the last report at $atLabel.',
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
                      (_isSending || !canSend) ? null : _sendReport,
                  icon: _isSending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: AppColors.navy),
                        )
                      : const Icon(Icons.send_rounded,
                          size: AppSizes.iconSizeMd),
                  label: Text(buttonLabel),
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
