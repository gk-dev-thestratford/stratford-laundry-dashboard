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

  /// Seed data from spec — to be confirmed by Georgi
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

  /// Only departments that staff can select for uniform/linen orders
  static List<Department> get staffDepartments =>
      seedData.where((d) => d.canSubmitUniforms).toList();

  /// Guest/resident departments
  static List<Department> get guestDepartments =>
      seedData.where((d) => !d.canSubmitUniforms).toList();
}
