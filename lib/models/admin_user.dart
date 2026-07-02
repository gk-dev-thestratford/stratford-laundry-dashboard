class AdminUser {
  final String id;
  final String name;
  final bool isActive;
  final bool canDeleteOrders;
  final bool canRejectOrders;
  /// May see the Today's Report panel and send the daily report email.
  /// Defaults to TRUE when missing (mirrors the server-side column default).
  final bool canSendReport;
  /// May APPROVE submitted tickets on the tablet. Defaults to TRUE when missing
  /// (mirrors the server-side column default) so existing users keep approving.
  final bool canApproveOrders;

  const AdminUser({
    required this.id,
    required this.name,
    this.isActive = true,
    this.canDeleteOrders = false,
    this.canRejectOrders = false,
    this.canSendReport = true,
    this.canApproveOrders = true,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
      canDeleteOrders: (map['can_delete_orders'] as int?) == 1,
      canRejectOrders: (map['can_reject_orders'] as int?) == 1,
      canSendReport: (map['can_send_report'] as int? ?? 1) == 1,
      canApproveOrders: (map['can_approve_orders'] as int? ?? 1) == 1,
    );
  }
}
