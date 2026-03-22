import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/catalogue_item.dart';
import '../services/database_service.dart';

/// Loads catalogue items from local SQLite (kept in sync with Supabase)
final catalogueItemsProvider =
    FutureProvider.family<List<CatalogueItem>, String>((ref, category) async {
  final rows = await DatabaseService.instance.getCatalogueItems(category: category);
  if (rows.isEmpty) return CatalogueItem.getByCategory(category);
  return rows.map((r) => CatalogueItem.fromMap(r)).toList();
});
