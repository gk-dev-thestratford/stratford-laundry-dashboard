import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/constants.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import 'thumbs_up_confirmation.dart';

/// Right-side "Today's Report" panel for the admin dashboard.
///
/// Guides the daily procedure top-to-bottom:
///   1. OUTSTANDING   — open 'sent' tickets still awaited (receive these first)
///   2. RECEIVED today — what came back today
///   3. SENT today     — what went out today + "ready to send" ghost chips for
///                       the Approved-tab selection (before Send is pressed)
///   4. NAPKINS        — logged / explicitly "none today" / not recorded yet
///   5. Preview & Send Report button
///
/// Expanded by default in landscape; collapses to a slim vertical "Today" tab
/// in portrait, when toggled, or on narrow screens. All data comes from local
/// SQLite — the dashboard calls [TodayReportPanelState.refresh] after every
/// relevant action (no polling).
class TodayReportPanel extends StatefulWidget {
  /// Docket numbers currently selected on the Approved tab — rendered as
  /// dashed "ready to send" ghost chips under SENT today.
  final List<String> selectedDockets;

  /// Opens the full Daily Report preview screen.
  final VoidCallback onOpenReport;

  /// Navigates to the Napkin Returns screen.
  final VoidCallback onLogNapkins;

  const TodayReportPanel({
    super.key,
    required this.selectedDockets,
    required this.onOpenReport,
    required this.onLogNapkins,
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

/// One ticket received today, with quantities for the partial badge.
class _ReceivedRow {
  final String docket;
  final int receivedQty;
  final int sentQty;
  const _ReceivedRow({
    required this.docket,
    required this.receivedQty,
    required this.sentQty,
  });

  bool get isPartial => sentQty > 0 && receivedQty < sentQty;
}

class TodayReportPanelState extends State<TodayReportPanel> {
  static const double _expandedWidth = 330;
  static const double _collapsedWidth = 56;
  // Below this width an expanded panel would crush the order list.
  static const double _minWidthToExpand = 700;

  bool _loading = true;
  List<_OutstandingRow> _outstanding = [];
  List<_ReceivedRow> _receivedToday = [];
  List<String> _sentTodayDockets = [];
  int _napkinQtyToday = 0;
  bool _napkinNoneToday = false;
  int _approvedCount = 0;

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
  /// every relevant action (receive, send, napkin log, returning from child
  /// screens, background sync).
  Future<void> refresh() => _load();

  Future<void> _load() async {
    final db = DatabaseService.instance;

    final received =
        await db.getOrdersWithStatusLogToday(AppConstants.statusReceived);
    final sent = await db.getOrdersWithStatusLogToday(AppConstants.statusSent);
    final backlogOrders =
        await db.getOrders(status: AppConstants.statusSent, limit: 500);

    final itemIds = <String>{
      ...backlogOrders.map((o) => o['id'] as String),
      ...received.map((o) => o['id'] as String),
    }.toList();
    final itemsByOrder = await db.getOrderItemsByOrderIds(itemIds);
    final sentDates = await db.getLatestStatusLogDates(
      backlogOrders.map((o) => o['id'] as String).toList(),
      AppConstants.statusSent,
    );

    // OUTSTANDING — mirror the daily report's "Still at Laundry" rules:
    // open 'sent' tickets with items still awaited (bag-only tickets with no
    // items count too — they're awaited as a whole).
    final now = DateTime.now();
    final outstanding = <_OutstandingRow>[];
    for (final order in backlogOrders) {
      final orderId = order['id'] as String;
      final items = itemsByOrder[orderId] ?? [];
      if (items.isNotEmpty) {
        final awaited = items.fold<int>(
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
      outstanding.add(_OutstandingRow(
        docket: '${order['docket_number']}',
        days: now.difference(sentAt).inDays.clamp(0, 9999),
      ));
    }
    outstanding.sort((a, b) => b.days.compareTo(a.days));

    // RECEIVED today — with quantities for the "x of y" partial badge.
    final receivedRows = received.map((order) {
      final items = itemsByOrder[order['id'] as String] ?? [];
      return _ReceivedRow(
        docket: '${order['docket_number']}',
        receivedQty: items.fold<int>(
            0, (s, i) => s + (i['quantity_received'] as int? ?? 0)),
        sentQty: items.fold<int>(
            0, (s, i) => s + (i['quantity_sent'] as int? ?? 0)),
      );
    }).toList();

    final napkinQty = await db.getNapkinReturnsTodayTotal();
    final napkinNone = await db.isNapkinNoneMarkedToday();
    final counts = await db.getOrderCounts();

    if (!mounted) return;
    setState(() {
      _outstanding = outstanding;
      _receivedToday = receivedRows;
      _sentTodayDockets =
          sent.map((o) => '${o['docket_number']}').toList();
      _napkinQtyToday = napkinQty;
      _napkinNoneToday = napkinNone;
      _approvedCount = counts[AppConstants.statusApproved] ?? 0;
      _loading = false;
    });
  }

  // ── Workflow step state (shown as 1/2/3 checkmarks) ──

  /// Receive step done: something was received today, or there was nothing
  /// at the laundry to receive.
  bool get _receiveDone => _receivedToday.isNotEmpty || _outstanding.isEmpty;

  /// Send step done: something was sent today, or nothing approved is waiting.
  bool get _sendDone => _sentTodayDockets.isNotEmpty || _approvedCount == 0;

  /// Napkin step resolved: returns logged today OR explicitly marked none.
  bool get _napkinsResolved => _napkinQtyToday > 0 || _napkinNoneToday;

  Future<void> _markNoneToday() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('No Napkin Returns Today?'),
        content: const Text(
          'Mark today as having no napkin returns from the laundry. '
          'If napkins are logged later today, this marker is ignored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.navy),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await DatabaseService.instance.markNapkinNoneToday();
    await _load();
    if (mounted) {
      showThumbsUpConfirmation(context,
          message: 'Marked no napkin returns today');
    }
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final canExpand = mq.size.width >= _minWidthToExpand;
    final expanded =
        canExpand && (_userExpanded ?? mq.orientation == Orientation.landscape);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: expanded ? _expandedWidth : _collapsedWidth,
      child: expanded ? _buildExpanded() : _buildCollapsedTab(canExpand),
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

  // ── Expanded panel ──

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
          _buildStepsRow(),
          const Divider(height: 1),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.all(AppSpacing.base),
                    children: [
                      _section(
                        title: 'Outstanding',
                        color: AppColors.error,
                        icon: Icons.local_laundry_service_rounded,
                        countLabel: '${_outstanding.length}',
                        emptyText: 'Nothing at the laundry',
                        chips:
                            _outstanding.map(_outstandingChip).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _section(
                        title: 'Received today',
                        color: AppColors.statusReceived,
                        icon: Icons.done_all_rounded,
                        countLabel: '${_receivedToday.length}',
                        emptyText: 'Nothing received yet',
                        chips: _receivedToday.map(_receivedChip).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _section(
                        title: 'Sent today',
                        color: AppColors.statusSent,
                        icon: Icons.local_shipping_rounded,
                        countLabel: widget.selectedDockets.isEmpty
                            ? '${_sentTodayDockets.length}'
                            : '${_sentTodayDockets.length} +${widget.selectedDockets.length}',
                        emptyText: widget.selectedDockets.isEmpty
                            ? 'Nothing sent yet'
                            : '',
                        chips: [
                          ..._sentTodayDockets.map(_sentChip),
                          ...widget.selectedDockets.map(_ghostChip),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _napkinSection(),
                    ],
                  ),
          ),
          _buildSendButton(),
        ],
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

  // ── Step checkmarks: 1 Receive / 2 Send / 3 Napkins ──

  Widget _buildStepsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.base, vertical: AppSpacing.sm),
      child: Row(
        children: [
          _stepChip('1 Receive', done: _receiveDone),
          _stepChip('2 Send', done: _sendDone),
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

  // ── Section scaffolding ──

  Widget _section({
    required String title,
    required Color color,
    required IconData icon,
    required String countLabel,
    required String emptyText,
    required List<Widget> chips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: AppSpacing.xs + 2),
            Expanded(
              child: Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: AppTextStyles.bold,
                  letterSpacing: 0.8,
                  color: color,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
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
        const SizedBox(height: AppSpacing.sm),
        if (chips.isEmpty)
          Text(
            emptyText,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppColors.grey500,
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm - 2,
            runSpacing: AppSpacing.sm - 2,
            children: chips,
          ),
      ],
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '#${row.docket}',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              fontWeight: AppTextStyles.bold,
              color: AppColors.statusReceived,
            ),
          ),
          if (row.isPartial) ...[
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

  /// Dashed-border "ready to send" chip for the Approved-tab selection —
  /// these tickets WILL appear under Sent once the Send button is pressed.
  Widget _ghostChip(String docket) {
    return CustomPaint(
      painter: _DashedBorderPainter(
          color: AppColors.statusSent, radius: AppRadius.sm),
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
                color: AppColors.statusSent,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.statusSent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'selected',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  fontWeight: AppTextStyles.bold,
                  color: AppColors.statusSent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Napkins row ──

  Widget _napkinSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.dining, size: 18, color: AppColors.goldDark),
            const SizedBox(width: AppSpacing.xs + 2),
            Text(
              'NAPKINS',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: AppTextStyles.bold,
                letterSpacing: 0.8,
                color: AppColors.goldDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (_napkinQtyToday > 0)
          _napkinStateRow(
              Icons.check_circle_rounded,
              AppColors.success,
              '$_napkinQtyToday napkin${_napkinQtyToday == 1 ? '' : 's'} logged today')
        else if (_napkinNoneToday)
          _napkinStateRow(Icons.check_circle_rounded, AppColors.success,
              'No returns today')
        else ...[
          _napkinStateRow(Icons.warning_amber_rounded,
              Colors.orange.shade800, 'Not recorded yet'),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onLogNapkins,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Log returns'),
                  style: _napkinActionStyle(AppColors.navy),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _markNoneToday,
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('None today'),
                  style: _napkinActionStyle(AppColors.grey700),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  ButtonStyle _napkinActionStyle(Color color) {
    return OutlinedButton.styleFrom(
      foregroundColor: color,
      side: BorderSide(color: color.withValues(alpha: 0.5)),
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      textStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: AppTextStyles.medium,
      ),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.smallBR),
    );
  }

  Widget _napkinStateRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs + 2),
        Expanded(
          child: Text(
            text,
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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.base),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: AppSizes.buttonHeightSm,
        child: ElevatedButton.icon(
          onPressed: widget.onOpenReport,
          icon: const Icon(Icons.send_rounded, size: 18),
          label: const Text('Preview & Send Report'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: AppColors.navy,
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
/// BorderStyle) — used for the "ready to send" ghost chips.
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
