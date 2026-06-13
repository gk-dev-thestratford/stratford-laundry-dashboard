import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/constants.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';

/// Right-side "Today's Report" panel for the admin dashboard.
///
/// Expanded (landscape, wide screens) it shows FIVE groups as a grid of
/// compact cards — the same groups the daily report email contains:
///
///   Row 1: RECEIVED today (fully)   | PARTIALLY RECEIVED today
///   Row 2: SENT today               | OUTSTANDING (still at laundry, ≥1 day)
///   Row 3: NAPKINS strip (pool-tracked — state only + "Open Napkin Returns")
///
/// followed by the step checkmarks and the "Preview & Send Report" button
/// pinned at the bottom.
///
/// Pool-tracked napkins (AppConstants.isPoolTracked) are balanced via the
/// linen pool, NOT per-ticket — napkin LINES are excluded from the counts
/// and napkin-ONLY tickets are excluded entirely from the four order groups.
/// The server-side email builder applies the identical rule. Napkin logging
/// and the "no returns today" marker live on the Napkin Returns screen; the
/// strip here only shows whether today's napkins are resolved.
///
/// In landscape / on wide screens it docks inline to the right of the order
/// list. In portrait / narrow ([overlay] = true) it becomes a right-anchored
/// sliding drawer over a dismissable scrim, so it never crushes the content.
/// Collapses to a slim vertical "Today" edge tab. All data comes from local
/// SQLite — the host calls [TodayReportPanelState.refresh] after every
/// relevant action (no polling).
class TodayReportPanel extends StatefulWidget {
  /// Docket numbers currently selected on the Approved tab — rendered as
  /// dashed "ready to add" ghost chips inside the SENT today card.
  final List<String> selectedDockets;

  /// Docket numbers currently selected on the Sent tab — rendered as dashed
  /// ghost chips inside the RECEIVED today card (bulk Add = fully received).
  final List<String> selectedReceiveDockets;

  /// Name of the logged-in admin — recorded on inline napkin log entries.
  final String? adminName;

  /// Opens the full Daily Report preview screen.
  final VoidCallback onOpenReport;

  /// Navigates to the Napkin Returns screen.
  final VoidCallback onLogNapkins;

  /// Overlay (portrait) mode. When true the panel renders as a right-anchored
  /// sliding sheet over a dark scrim instead of an inline docked column, so it
  /// never shrinks the content beneath it. The host must place this inside a
  /// Stack that fills the body. Defaults to false (inline docked, landscape).
  final bool overlay;

  const TodayReportPanel({
    super.key,
    required this.selectedDockets,
    this.selectedReceiveDockets = const [],
    this.adminName,
    required this.onOpenReport,
    required this.onLogNapkins,
    this.overlay = false,
  });

  @override
  TodayReportPanelState createState() => TodayReportPanelState();
}

/// One open ticket still (partly) at the laundry.
class _OutstandingRow {
  final String docket;
  final int days;
  const _OutstandingRow({required this.docket, required this.days});
}

/// One ticket received today, with non-napkin quantities and (for partials)
/// what is still awaited.
class _ReceivedRow {
  final String docket;
  final int receivedQty;
  final int sentQty;
  final String? awaiting;
  const _ReceivedRow({
    required this.docket,
    required this.receivedQty,
    required this.sentQty,
    this.awaiting,
  });
}

class TodayReportPanelState extends State<TodayReportPanel> {
  static const double _collapsedWidth = 56;
  // Below this width an expanded panel would crush the order list.
  static const double _minWidthToExpand = 700;
  // Shared with DailyReportScreen — the last successful daily-report send (ISO,
  // local). Drives the "since last send" express window.
  static const _kLastSentMetaKey = 'daily_report_last_sent_at';

  bool _loading = true;
  List<_OutstandingRow> _outstanding = [];
  List<_ReceivedRow> _receivedToday = [];
  List<_ReceivedRow> _partialToday = [];
  List<String> _sentTodayDockets = [];
  /// Raw count of tickets sent today INCLUDING napkin-only ones — drives the
  /// "Add" step checkmark (napkin-only sends still count as work done).
  int _sentTodayRawCount = 0;
  int _napkinQtyToday = 0;
  bool _napkinNoneToday = false;
  int _approvedCount = 0;

  // ── "Since last send" sent-state ──
  /// A daily report was already sent earlier today.
  bool _reportSentToday = false;
  /// There is windowed activity (received / partial / sent / napkins since the
  /// last send) — i.e. an express follow-up is warranted.
  bool _hasNewActivity = false;
  /// When the last report went out today (HH:mm display).
  DateTime? _lastSentAt;

  /// null = follow the orientation default (landscape expanded).
  bool? _userExpanded;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != null && orientation != _lastOrientation) {
      // Orientation changed — drop any manual toggle and re-apply the default.
      _userExpanded = null;
    }
    _lastOrientation = orientation;
  }

  /// Reloads all panel data from local SQLite. Called by the dashboard after
  /// every relevant action (receive, add, napkin log, returning from child
  /// screens, background sync).
  Future<void> refresh() => _load();

  /// Napkin-only tickets are pool-tracked end-to-end — they never belong in
  /// the per-ticket order groups. (Bag-only tickets with no items are NOT
  /// napkin-only — they're awaited as a whole.)
  static bool _isNapkinOnly(List<Map<String, dynamic>> items) =>
      items.isNotEmpty &&
      items.every(
          (i) => AppConstants.isPoolTracked(i['item_name'] as String? ?? ''));

  static bool _isNapkinLine(Map<String, dynamic> item) =>
      AppConstants.isPoolTracked(item['item_name'] as String? ?? '');

  Future<void> _load() async {
    final db = DatabaseService.instance;
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);

    // ── "Since last send" window ──────────────────────────────────────────
    // After a report goes out the activity cards (Received / Partial / Sent /
    // Napkins) only show what happened since that send — the next express
    // batch. Before any send today, the window is the whole day. The
    // Outstanding backlog below is standing info and is NEVER windowed.
    final lastSentIso = await db.getMeta(_kLastSentMetaKey);
    final lastSentAt =
        lastSentIso != null ? DateTime.tryParse(lastSentIso) : null;
    final reportSentToday = lastSentAt != null &&
        lastSentAt.year == now.year &&
        lastSentAt.month == now.month &&
        lastSentAt.day == now.day;
    final windowStartIso = (reportSentToday && lastSentIso != null)
        ? lastSentIso
        : todayMidnight.toIso8601String();
    final windowStart = DateTime.parse(windowStartIso);

    final received = await db.getOrdersWithStatusLogSince(
        AppConstants.statusReceived, windowStartIso);
    final sent = await db.getOrdersWithStatusLogSince(
        AppConstants.statusSent, windowStartIso);
    final backlogOrders =
        await db.getOrders(status: AppConstants.statusSent, limit: 500);

    final itemIds = <String>{
      ...backlogOrders.map((o) => o['id'] as String),
      ...received.map((o) => o['id'] as String),
      ...sent.map((o) => o['id'] as String),
    }.toList();
    final itemsByOrder = await db.getOrderItemsByOrderIds(itemIds);
    final sentDates = await db.getLatestStatusLogDates(
      backlogOrders.map((o) => o['id'] as String).toList(),
      AppConstants.statusSent,
    );
    // What is still awaited per received-today ticket (napkins already
    // excluded by the query) — shown on Partially Received chips.
    final awaitingSummaries = await db.getAwaitingSummaries(
        received.map((o) => o['id'] as String).toList());

    // OUTSTANDING — mirror the daily report's "Still at Laundry" rules:
    // open 'sent' tickets with NON-NAPKIN items still awaited (bag-only
    // tickets with no items count too — they're awaited as a whole).
    final outstanding = <_OutstandingRow>[];
    for (final order in backlogOrders) {
      final orderId = order['id'] as String;
      final items = itemsByOrder[orderId] ?? [];
      if (_isNapkinOnly(items)) continue;
      if (items.isNotEmpty) {
        final awaited = items.where((i) => !_isNapkinLine(i)).fold<int>(
            0,
            (s, i) =>
                s +
                ((i['quantity_sent'] as int? ?? 0) -
                        (i['quantity_received'] as int? ?? 0))
                    .clamp(0, 999999));
        if (awaited <= 0) continue;
      }
      final sentAt = DateTime.tryParse(sentDates[orderId] ?? '') ??
          DateTime.tryParse(order['created_at'] as String? ?? '') ??
          now;
      final days = now.difference(sentAt).inDays.clamp(0, 9999);
      // Tickets sent TODAY (days == 0) already appear in the Sent card —
      // listing them as Outstanding double-counts and wrongly flags same-day
      // sends. Only items at the laundry a day or more are "outstanding".
      // (The server email builder applies the identical days >= 1 rule.)
      if (days < 1) continue;
      outstanding.add(_OutstandingRow(
        docket: '${order['docket_number']}',
        days: days,
      ));
    }
    outstanding.sort((a, b) => b.days.compareTo(a.days));

    // RECEIVED today — split into fully vs partially received based on
    // NON-NAPKIN lines only; napkin-only tickets skipped entirely.
    final receivedFull = <_ReceivedRow>[];
    final receivedPartial = <_ReceivedRow>[];
    for (final order in received) {
      final orderId = order['id'] as String;
      final items = itemsByOrder[orderId] ?? [];
      if (_isNapkinOnly(items)) continue;
      final nonNapkin = items.where((i) => !_isNapkinLine(i)).toList();
      final sentQty = nonNapkin.fold<int>(
          0, (s, i) => s + (i['quantity_sent'] as int? ?? 0));
      final receivedQty = nonNapkin.fold<int>(
          0, (s, i) => s + (i['quantity_received'] as int? ?? 0));
      final isPartial = nonNapkin.any((i) =>
          (i['quantity_received'] as int? ?? 0) <
          (i['quantity_sent'] as int? ?? 0));
      final row = _ReceivedRow(
        docket: '${order['docket_number']}',
        receivedQty: receivedQty,
        sentQty: sentQty,
        awaiting: awaitingSummaries[orderId],
      );
      (isPartial ? receivedPartial : receivedFull).add(row);
    }

    // SENT today — napkin-only tickets excluded from the card (pool handles
    // them) but still counted for the step checkmark.
    final sentDockets = <String>[];
    for (final order in sent) {
      final items = itemsByOrder[order['id'] as String] ?? [];
      if (_isNapkinOnly(items)) continue;
      sentDockets.add('${order['docket_number']}');
    }

    final napkinQty = await db.getNapkinReturnsTodayTotal();
    final napkinNone = await db.isNapkinNoneMarkedToday();
    final counts = await db.getOrderCounts();

    // Napkins WITHIN the window — only counts for "new activity" (the step
    // gate below stays today-based on [napkinQty]).
    final windowLedger = await db.getLedgerEntries(since: windowStart);
    final napkinQtyWindow = windowLedger
        .where((e) => e['direction'] == 'in')
        .fold<int>(0, (s, e) => s + (e['quantity'] as int? ?? 0));

    // New activity = anything in the window across the four activity cards.
    final hasNewActivity = receivedFull.isNotEmpty ||
        receivedPartial.isNotEmpty ||
        sentDockets.isNotEmpty ||
        napkinQtyWindow > 0;

    if (!mounted) return;
    setState(() {
      _outstanding = outstanding;
      _receivedToday = receivedFull;
      _partialToday = receivedPartial;
      _sentTodayDockets = sentDockets;
      _sentTodayRawCount = sent.length;
      _napkinQtyToday = napkinQty;
      _napkinNoneToday = napkinNone;
      _approvedCount = counts[AppConstants.statusApproved] ?? 0;
      _reportSentToday = reportSentToday;
      _hasNewActivity = hasNewActivity;
      _lastSentAt = lastSentAt;
      _loading = false;
    });
  }

  // ── Workflow step state (shown as 1/2/3 checkmarks) ──

  /// Receive step done: something was received today, or there was nothing
  /// at the laundry to receive.
  bool get _receiveDone =>
      _receivedToday.isNotEmpty ||
      _partialToday.isNotEmpty ||
      _outstanding.isEmpty;

  /// Add step done: something was added (sent) today, or nothing approved
  /// is waiting.
  bool get _addDone => _sentTodayRawCount > 0 || _approvedCount == 0;

  /// Napkin step resolved: returns logged today OR explicitly marked none.
  /// Logging and "none today" both happen on the Napkin Returns screen now;
  /// the panel only reflects the resolved state.
  bool get _napkinsResolved => _napkinQtyToday > 0 || _napkinNoneToday;

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    // ── Overlay (portrait) mode — slides over the content, never shrinks it.
    if (widget.overlay) {
      // An overlay can always expand: it floats above the content rather than
      // taking width from it, so the narrow-screen "open full report instead"
      // fallback never applies. Default state is collapsed (don't cover the
      // content on load).
      final expanded = _userExpanded ?? false;
      return _buildOverlay(expanded, mq);
    }

    // ── Inline docked mode (landscape / wide screens) — unchanged. ──
    final canExpand = mq.size.width >= _minWidthToExpand;
    final expanded =
        canExpand && (_userExpanded ?? mq.orientation == Orientation.landscape);
    // ~52% of the screen in landscape — wide enough for the 2-column grid.
    final expandedWidth = (mq.size.width * 0.52).clamp(520.0, 900.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: expanded ? expandedWidth : _collapsedWidth,
      child: expanded ? _buildExpanded() : _buildCollapsedTab(canExpand),
    );
  }

  // ── Overlay: right-anchored sliding sheet over a dismissable scrim ──

  Widget _buildOverlay(bool expanded, MediaQueryData mq) {
    // ~85% of the screen, capped so it never feels oversized on larger
    // portrait tablets.
    final sheetWidth = (mq.size.width * 0.85).clamp(280.0, 560.0);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Dark scrim — fades in with the sheet, dismisses on tap.
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !expanded,
            child: GestureDetector(
              onTap: () => setState(() => _userExpanded = false),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                color: Colors.black
                    .withValues(alpha: expanded ? 0.45 : 0.0),
              ),
            ),
          ),
        ),
        // Thin "Today" edge tab — only while collapsed, on the right edge.
        if (!expanded)
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: SizedBox(
              width: _collapsedWidth,
              child: _buildCollapsedTab(true),
            ),
          ),
        // Sliding sheet — full height, slides in from the right edge.
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: expanded ? 0 : -sheetWidth,
          width: sheetWidth,
          child: Material(
            elevation: 12,
            child: expanded
                ? _buildExpanded()
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  // ── Collapsed: slim vertical "Today" tab ──

  Widget _buildCollapsedTab(bool canExpand) {
    final badge = _outstanding.length + (_napkinsResolved ? 0 : 1);
    return Center(
      child: GestureDetector(
        // On screens too narrow for the docked panel, fall back to opening
        // the full Daily Report screen instead of squeezing the order list.
        onTap: () {
          if (canExpand) {
            setState(() => _userExpanded = true);
          } else {
            widget.onOpenReport();
          }
        },
        child: Container(
          width: 44,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(AppRadius.md)),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.chevron_left_rounded,
                  color: AppColors.gold, size: AppSizes.iconSizeSm),
              const SizedBox(height: AppSpacing.xs),
              RotatedBox(
                quarterTurns: 1,
                child: Text(
                  'Today',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: AppColors.white,
                    fontSize: AppTextStyles.captionSize,
                    fontWeight: AppTextStyles.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              if (badge > 0) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      color: AppColors.white,
                      fontSize: 12,
                      fontWeight: AppTextStyles.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Expanded panel: 2×2 grid of group cards + napkins strip ──

  Widget _buildExpanded() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(left: BorderSide(color: AppColors.grey200)),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _buildHeader(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm + 2),
                    child: _buildBody(),
                  ),
          ),
          const Divider(height: 1),
          _buildStepsRow(),
          _buildSendButton(),
        ],
      ),
    );
  }

  /// Body content — switches on the "since last send" sent-state:
  ///   • sent today, nothing new  → "Report sent" hero (replaces the four
  ///     activity cards); Outstanding + Napkins stay below.
  ///   • sent today, new activity → normal cards (the express batch) with a
  ///     "New since last report (HH:mm)" caption above them.
  ///   • not sent today           → normal cards (original layout).
  Widget _buildBody() {
    if (_reportSentToday && !_hasNewActivity) {
      // Sent, nothing new: hero panel in place of the activity cards.
      return Column(
        children: [
          Expanded(child: _buildSentHero()),
          const SizedBox(height: AppSpacing.sm),
          // Outstanding stays visible — it's standing info, never windowed.
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [Expanded(child: _outstandingCard())],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _napkinStrip(),
        ],
      );
    }

    // Normal cards (express batch when sent today + new activity, else today).
    return Column(
      children: [
        if (_reportSentToday && _hasNewActivity) ...[
          _buildNewSinceCaption(),
          const SizedBox(height: AppSpacing.xs + 2),
        ],
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _receivedCard()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _partialCard()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _sentCard()),
              const SizedBox(width: AppSpacing.sm),
              Expanded(child: _outstandingCard()),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _napkinStrip(),
      ],
    );
  }

  // ── Individual activity cards (extracted so the sent-state can recompose) ──

  Widget _receivedCard() => _groupCard(
        title: 'Received Today',
        color: AppColors.statusReceived,
        icon: Icons.done_all_rounded,
        countLabel: widget.selectedReceiveDockets.isEmpty
            ? '${_receivedToday.length}'
            : '${_receivedToday.length} +${widget.selectedReceiveDockets.length}',
        emptyText: 'Nothing received yet',
        chips: [
          ..._receivedToday.map(_receivedChip),
          ...widget.selectedReceiveDockets
              .map((d) => _ghostChip(d, AppColors.statusReceived)),
        ],
      );

  Widget _partialCard() => _groupCard(
        title: 'Partially Received',
        color: Colors.amber.shade800,
        icon: Icons.rule_rounded,
        countLabel: '${_partialToday.length}',
        emptyText: 'No partial receipts',
        chips: _partialToday.map(_partialChip).toList(),
      );

  Widget _sentCard() => _groupCard(
        title: 'Sent Today',
        color: AppColors.statusSent,
        icon: Icons.local_shipping_rounded,
        countLabel: widget.selectedDockets.isEmpty
            ? '${_sentTodayDockets.length}'
            : '${_sentTodayDockets.length} +${widget.selectedDockets.length}',
        emptyText: 'Nothing sent yet',
        chips: [
          ..._sentTodayDockets.map(_sentChip),
          ...widget.selectedDockets
              .map((d) => _ghostChip(d, AppColors.statusSent)),
        ],
      );

  Widget _outstandingCard() => _groupCard(
        title: 'Outstanding',
        color: AppColors.error,
        icon: Icons.local_laundry_service_rounded,
        countLabel: '${_outstanding.length}',
        emptyText: 'Nothing at the laundry',
        chips: _outstanding.map(_outstandingChip).toList(),
      );

  /// Small header caption shown above the express batch cards.
  Widget _buildNewSinceCaption() {
    final at = _lastSentAt != null
        ? DateFormat('HH:mm').format(_lastSentAt!)
        : '—';
    return Row(
      children: [
        Icon(Icons.fiber_new_rounded,
            size: 16, color: AppColors.statusSent),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            'New since last report ($at)',
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: AppTextStyles.bold,
              color: AppColors.navy,
            ),
          ),
        ),
      ],
    );
  }

  /// Clean "Report sent at HH:mm" hero — shown in place of the activity cards
  /// when a report already went out today and nothing new has happened since.
  Widget _buildSentHero() {
    final at = _lastSentAt != null
        ? DateFormat('HH:mm').format(_lastSentAt!)
        : '—';
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: AppRadius.mediumBR,
        border: Border.all(color: AppColors.success.withValues(alpha: 0.45)),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_rounded,
                  size: AppSizes.iconSizeLg, color: AppColors.success),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Report sent at $at',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.titleSize,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.success,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Nothing new to report since.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: AppTextStyles.captionSize,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, AppSpacing.sm, AppSpacing.xs, AppSpacing.sm),
      decoration: const BoxDecoration(color: AppColors.navy),
      child: Row(
        children: [
          const Icon(Icons.summarize_rounded,
              color: AppColors.gold, size: AppSizes.iconSizeSm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              "Today's Report",
              style: TextStyle(
                fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: AppTextStyles.labelSize,
                fontWeight: AppTextStyles.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded,
                color: AppColors.white, size: AppSizes.iconSizeMd),
            onPressed: () => setState(() => _userExpanded = false),
            tooltip: 'Collapse',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  // ── Step checkmarks: 1 Receive / 2 Add / 3 Napkins ──

  Widget _buildStepsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _stepChip('1 Receive', done: _receiveDone),
          _stepChip('2 Add', done: _addDone),
          _stepChip('3 Napkins', done: _napkinsResolved, warnWhenPending: true),
        ],
      ),
    );
  }

  Widget _stepChip(String label, {required bool done, bool warnWhenPending = false}) {
    final color = done
        ? AppColors.success
        : warnWhenPending
            ? Colors.orange.shade800
            : AppColors.grey500;
    return Expanded(
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : warnWhenPending
                    ? Icons.warning_amber_rounded
                    : Icons.circle_outlined,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight:
                    done ? AppTextStyles.medium : AppTextStyles.bold,
                color: done ? AppColors.grey600 : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Group card scaffolding ──

  Widget _groupCard({
    required String title,
    required Color color,
    required IconData icon,
    required String countLabel,
    required String emptyText,
    required List<Widget> chips,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: AppRadius.mediumBR,
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colored header with count badge
          Container(
            color: color.withValues(alpha: 0.10),
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 2),
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: AppSpacing.xs + 2),
                Expanded(
                  child: Text(
                    title.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: AppTextStyles.bold,
                      letterSpacing: 0.6,
                      color: color,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    countLabel,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: AppTextStyles.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scrollable chip content / friendly empty text
          Expanded(
            child: chips.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: Text(
                        emptyText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.grey500,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: Wrap(
                      spacing: AppSpacing.sm - 2,
                      runSpacing: AppSpacing.sm - 2,
                      children: chips,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── Chips ──

  Widget _outstandingChip(_OutstandingRow row) {
    // Same aging palette as the Sent-tab badge: amber 3+, red 7+.
    final ageColor = row.days >= 7
        ? AppColors.error
        : row.days >= 3
            ? Colors.orange.shade800
            : AppColors.grey600;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: AppRadius.smallBR,
        border: Border.all(
          color: row.days >= 3
              ? ageColor.withValues(alpha: 0.6)
              : AppColors.grey300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${row.docket}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: AppTextStyles.bold,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '${row.days}d',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: AppTextStyles.bold,
              color: ageColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _receivedChip(_ReceivedRow row) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: AppColors.statusReceived.withValues(alpha: 0.10),
        borderRadius: AppRadius.smallBR,
        border: Border.all(
            color: AppColors.statusReceived.withValues(alpha: 0.35)),
      ),
      child: Text(
        '#${row.docket}',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: AppTextStyles.bold,
          color: AppColors.statusReceived,
        ),
      ),
    );
  }

  /// Partially received: docket + "x of y" (non-napkin) + awaiting summary.
  Widget _partialChip(_ReceivedRow row) {
    final color = Colors.amber.shade800;
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.smallBR,
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '#${row.docket}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: AppTextStyles.bold,
                  color: color,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${row.receivedQty} of ${row.sentQty}',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  fontWeight: AppTextStyles.medium,
                  color: AppColors.grey700,
                ),
              ),
            ],
          ),
          if (row.awaiting != null && row.awaiting!.isNotEmpty)
            Text(
              row.awaiting!,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                fontWeight: AppTextStyles.medium,
                color: AppColors.error,
              ),
            ),
        ],
      ),
    );
  }

  Widget _sentChip(String docket) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
      decoration: BoxDecoration(
        color: AppColors.statusSent.withValues(alpha: 0.10),
        borderRadius: AppRadius.smallBR,
        border:
            Border.all(color: AppColors.statusSent.withValues(alpha: 0.35)),
      ),
      child: Text(
        '#$docket',
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 13,
          fontWeight: AppTextStyles.bold,
          color: AppColors.statusSent,
        ),
      ),
    );
  }

  /// Dashed-border "ready to add" chip for the current tab selection — these
  /// tickets WILL appear in the card once the Add button is pressed.
  Widget _ghostChip(String docket, Color color) {
    return CustomPaint(
      painter: _DashedBorderPainter(color: color, radius: AppRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs + 1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '#$docket',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: AppTextStyles.bold,
                color: color,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'selected',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: AppTextStyles.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Napkins strip (full width, pool-tracked — own card) ──

  /// State-only napkin strip. All logging + "none today" now happens on the
  /// Napkin Returns screen — this just shows whether today's napkins are
  /// resolved and links across to record them.
  Widget _napkinStrip() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm + 2, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.gold.withValues(alpha: 0.07),
        borderRadius: AppRadius.mediumBR,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          const Icon(Icons.dining, size: 18, color: AppColors.goldDark),
          const SizedBox(width: AppSpacing.xs + 2),
          Text(
            'NAPKINS',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: AppTextStyles.bold,
              letterSpacing: 0.6,
              color: AppColors.goldDark,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // State only — no inline entry.
          Expanded(child: _napkinState()),
          const SizedBox(width: AppSpacing.sm),
          // Everything happens on the Napkin Returns screen now.
          SizedBox(
            height: 38,
            child: ElevatedButton.icon(
              onPressed: widget.onLogNapkins,
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('Open Napkin Returns'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.navy,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                textStyle: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: AppTextStyles.medium),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _napkinState() {
    final IconData icon;
    final Color color;
    final String text;
    if (_napkinQtyToday > 0) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      text = '$_napkinQtyToday napkin${_napkinQtyToday == 1 ? '' : 's'} logged today';
    } else if (_napkinNoneToday) {
      icon = Icons.check_circle_rounded;
      color = AppColors.success;
      text = 'No returns today';
    } else {
      icon = Icons.warning_amber_rounded;
      color = Colors.orange.shade800;
      text = 'Napkins not recorded yet';
    }
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs + 2),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: AppTextStyles.medium,
              color: AppColors.grey800,
            ),
          ),
        ),
      ],
    );
  }

  // ── Bottom button ──

  Widget _buildSendButton() {
    // Sent today with nothing new → muted "Report sent ✓" (still opens the
    // report so they can review; the report screen gates the re-send).
    final muted = _reportSentToday && !_hasNewActivity;
    final label = muted
        ? 'Report sent ✓'
        : (_reportSentToday && _hasNewActivity)
            ? 'Preview & Send Update'
            : 'Preview & Send Report';

    return Container(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.base, 0, AppSpacing.base, AppSpacing.base),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightSm,
        child: ElevatedButton.icon(
          onPressed: widget.onOpenReport,
          icon: Icon(muted ? Icons.check_rounded : Icons.send_rounded,
              size: 18),
          label: Text(label),
          style: ElevatedButton.styleFrom(
            backgroundColor: muted ? AppColors.grey200 : AppColors.gold,
            foregroundColor:
                muted ? AppColors.grey700 : AppColors.navy,
            elevation: muted ? 0 : null,
            textStyle: TextStyle(
              fontFamily: 'Inter',
              fontSize: 15,
              fontWeight: AppTextStyles.bold,
            ),
            shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect border (Flutter has no built-in dashed
/// BorderStyle) — used for the "ready to add" ghost chips.
class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;

  const _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final path = Path()
      ..addRRect(RRect.fromRectAndRadius(
          Offset.zero & size, Radius.circular(radius)));
    const dash = 5.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
              distance, math.min(distance + dash, metric.length)),
          paint,
        );
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.radius != radius;
}
