class Department {
  final String id;
  final String code;
  final String name;
  final bool canSubmitUniforms;
  final bool hasLinenItems;
  final bool isActive;

  const Department({
    required this.id,
    required this.code,
    required this.name,
    this.canSubmitUniforms = true,
    this.hasLinenItems = false,
    this.isActive = true,
  });

  factory Department.fromMap(Map<String, dynamic> map) {
    return Department(
      id: map['id'] as String,
      code: map['code'] as String? ?? '',
      name: map['name'] as String,
      canSubmitUniforms: (map['can_submit_uniforms'] == 1 || map['can_submit_uniforms'] == true),
      hasLinenItems: (map['has_linen_items'] == 1 || map['has_linen_items'] == true),
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
    );
  }

  /// Fallback seed data — used only on first install before Supabase sync
  static const List<Department> seedData = [
    Department(id: 'hsk', code: 'HSK', name: 'Housekeeping', canSubmitUniforms: true, hasLinenItems: true),
    Department(id: 'fnb', code: 'FNB', name: 'Food & Beverage', canSubmitUniforms: true, hasLinenItems: true),
    Department(id: 'foh', code: 'FOH', name: 'Front Office', canSubmitUniforms: true),
    Department(id: 'kit', code: 'KIT', name: 'Kitchen', canSubmitUniforms: true),
    Department(id: 'mnt', code: 'MNT', name: 'Maintenance', canSubmitUniforms: true),
    Department(id: 'spa', code: 'SPA', name: 'Spa / Leisure', canSubmitUniforms: true),
    Department(id: 'mgt', code: 'MGT', name: 'Management', canSubmitUniforms: true),
    Department(id: 'sec', code: 'SEC', name: 'Security', canSubmitUniforms: true),
    Department(id: 'gst', code: 'GST', name: 'Guest', canSubmitUniforms: false),
    Department(id: 'lft', code: 'LFT', name: 'Loft Resident', canSubmitUniforms: false),
  ];
}
