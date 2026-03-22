import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/department.dart';
import '../services/database_service.dart';

/// Loads departments from local SQLite (which is kept in sync with Supabase)
final departmentsProvider = FutureProvider<List<Department>>((ref) async {
  final rows = await DatabaseService.instance.getDepartments();
  if (rows.isEmpty) return Department.seedData;
  return rows.map((r) => Department.fromMap(r)).toList();
});

/// Only departments that staff can select for uniform orders
final staffDepartmentsProvider = FutureProvider<List<Department>>((ref) async {
  final all = await ref.watch(departmentsProvider.future);
  return all.where((d) => d.canSubmitUniforms).toList();
});

/// Departments with linen items
final linenDepartmentsProvider = FutureProvider<List<Department>>((ref) async {
  final all = await ref.watch(departmentsProvider.future);
  return all.where((d) => d.hasLinenItems).toList();
});
