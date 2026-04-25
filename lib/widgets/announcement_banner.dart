import 'dart:async';
import 'package:flutter/material.dart';
import '../models/announcement.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';
import '../theme/app_theme.dart';

/// Compact banner that shows whatever announcements are active right now.
/// - Auto-hides when nothing's active.
/// - Stacks multiple announcements with the most-severe at the top.
/// - Re-evaluates visibility once per minute so a scheduled window flips
///   on/off automatically without requiring a fresh sync.
/// - Listens to SyncService refresh events so newly-pulled announcements
///   appear on the next sync without waiting for the minute tick.
class AnnouncementBanner extends StatefulWidget {
  /// Outer padding around the banner stack. Pages with their own padding
  /// usually want EdgeInsets.zero.
  final EdgeInsets padding;

  const AnnouncementBanner({super.key, this.padding = EdgeInsets.zero});

  @override
  State<AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<AnnouncementBanner> {
  List<Announcement> _active = const [];
  Timer? _ticker;
  StreamSubscription<void>? _syncSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    // Re-check once per minute so windows flip on/off automatically
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) => _refresh());
    // Re-check immediately after a sync brings in new data
    _syncSub = SyncService.instance.onReferenceDataSynced.listen((_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _syncSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    final list = await DatabaseService.instance.getActiveAnnouncements();
    if (!mounted) return;
    setState(() => _active = list);
  }

  @override
  Widget build(BuildContext context) {
    if (_active.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final a in _active) ...[
            _AnnouncementCard(announcement: a),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Announcement announcement;
  const _AnnouncementCard({required this.announcement});

  @override
  Widget build(BuildContext context) {
    final palette = _palette(announcement.severity);
    return Container(
      decoration: BoxDecoration(
        color: palette.bg,
        border: Border(left: BorderSide(color: palette.accent, width: 4)),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(palette.icon, color: palette.accent, size: AppSizes.iconSizeMd),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  announcement.title,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: AppTextStyles.bodySize,
                    fontWeight: AppTextStyles.bold,
                    color: palette.textStrong,
                  ),
                ),
                if ((announcement.body ?? '').isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    announcement.body!,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: AppTextStyles.captionSize,
                      color: palette.text,
                      height: 1.35,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  _Palette _palette(AnnouncementSeverity severity) {
    switch (severity) {
      case AnnouncementSeverity.critical:
        return const _Palette(
          accent: AppColors.error,
          bg: Color(0xFFFFEBEE),
          text: Color(0xFF7F1D1D),
          textStrong: Color(0xFFB71C1C),
          icon: Icons.error_outline_rounded,
        );
      case AnnouncementSeverity.warning:
        return const _Palette(
          accent: AppColors.warning,
          bg: Color(0xFFFFF8E1),
          text: Color(0xFF7C5800),
          textStrong: Color(0xFF6E4A00),
          icon: Icons.warning_amber_rounded,
        );
      case AnnouncementSeverity.info:
        return const _Palette(
          accent: AppColors.info,
          bg: Color(0xFFE3F2FD),
          text: Color(0xFF0D3B66),
          textStrong: Color(0xFF0B2E50),
          icon: Icons.campaign_outlined,
        );
    }
  }
}

class _Palette {
  final Color accent;
  final Color bg;
  final Color text;
  final Color textStrong;
  final IconData icon;
  const _Palette({
    required this.accent,
    required this.bg,
    required this.text,
    required this.textStrong,
    required this.icon,
  });
}
