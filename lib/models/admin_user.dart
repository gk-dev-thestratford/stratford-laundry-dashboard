class AdminUser {
  final String id;
  final String name;
  final bool isActive;
  final bool canDeleteOrders;
  final bool canRejectOrders;

  const AdminUser({
    required this.id,
    required this.name,
    this.isActive = true,
    this.canDeleteOrders = false,
    this.canRejectOrders = false,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
      canDeleteOrders: (map['can_delete_orders'] as int?) == 1,
      canRejectOrders: (map['can_reject_orders'] as int?) == 1,
    );
  }
}
