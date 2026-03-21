class AdminUser {
  final String id;
  final String name;
  final bool isActive;

  const AdminUser({
    required this.id,
    required this.name,
    this.isActive = true,
  });

  factory AdminUser.fromMap(Map<String, dynamic> map) {
    return AdminUser(
      id: map['id'] as String,
      name: map['name'] as String,
      isActive: (map['is_active'] as int) == 1,
    );
  }
}
