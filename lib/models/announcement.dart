enum AnnouncementSeverity { info, warning, critical }

class Announcement {
  final String id;
  final String title;
  final String? body;
  final DateTime startsAt;
  final DateTime endsAt;
  final AnnouncementSeverity severity;
  final bool isActive;

  const Announcement({
    required this.id,
    required this.title,
    this.body,
    required this.startsAt,
    required this.endsAt,
    required this.severity,
    required this.isActive,
  });

  /// True when [now] falls within [startsAt, endsAt) and the row is active.
  bool isVisibleAt(DateTime now) {
    if (!isActive) return false;
    return !now.isBefore(startsAt) && now.isBefore(endsAt);
  }

  factory Announcement.fromMap(Map<String, dynamic> m) {
    return Announcement(
      id: m['id'] as String,
      title: m['title'] as String,
      body: m['body'] as String?,
      startsAt: DateTime.parse(m['starts_at'] as String),
      endsAt: DateTime.parse(m['ends_at'] as String),
      severity: _parseSeverity(m['severity'] as String?),
      isActive: m['is_active'] is bool
          ? m['is_active'] as bool
          : (m['is_active'] as int? ?? 1) == 1,
    );
  }

  Map<String, dynamic> toLocalRow() => {
        'id': id,
        'title': title,
        'body': body,
        'starts_at': startsAt.toIso8601String(),
        'ends_at': endsAt.toIso8601String(),
        'severity': severity.name,
        'is_active': isActive ? 1 : 0,
      };

  static AnnouncementSeverity _parseSeverity(String? v) {
    switch (v) {
      case 'critical':
        return AnnouncementSeverity.critical;
      case 'warning':
        return AnnouncementSeverity.warning;
      case 'info':
      default:
        return AnnouncementSeverity.info;
    }
  }
}
