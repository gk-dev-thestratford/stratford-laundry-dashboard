import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/sync_service.dart';
import 'department_provider.dart';
import 'catalogue_provider.dart';

/// Listens for reference data sync events and invalidates cached providers
/// so the UI picks up fresh departments, items, etc. from local SQLite.
final syncRefreshProvider = Provider<void>((ref) {
  final sub = SyncService.instance.onReferenceDataSynced.listen((_) {
    ref.invalidate(departmentsProvider);
    ref.invalidate(staffDepartmentsProvider);
    ref.invalidate(linenDepartmentsProvider);
    // catalogueItemsProvider is a family — invalidating it clears all categories
    ref.invalidate(catalogueItemsProvider);
    ref.invalidate(itemDepartmentMapProvider);
  });
  ref.onDispose(() => sub.cancel());
});
