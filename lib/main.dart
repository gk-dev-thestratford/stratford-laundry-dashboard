import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'providers/sync_refresh_provider.dart';
import 'services/supabase_service.dart';
import 'services/connectivity_service.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

/// Pull all reference data from Supabase into local SQLite.
/// Called at startup and by background sync.
Future<bool> initialSync() async {
  final db = DatabaseService.instance;
  final supa = SupabaseService.instance;
  if (!supa.isInitialized) return false;

  bool synced = false;
  try {
    final depts = await supa.fetchDepartments();
    debugPrint('[Sync] Fetched ${depts.length} departments from Supabase');
    if (depts.isNotEmpty) {
      await db.syncDepartments(depts);
      synced = true;
    }
  } catch (e) {
    debugPrint('[Sync] Failed to sync departments: $e');
  }

  try {
    final items = await supa.fetchCatalogueItems();
    debugPrint('[Sync] Fetched ${items.length} catalogue items from Supabase');
    if (items.isNotEmpty) {
      await db.syncCatalogueItems(items);
      synced = true;
    }
  } catch (e) {
    debugPrint('[Sync] Failed to sync catalogue items: $e');
  }

  try {
    final admins = await supa.fetchAdminUsers();
    debugPrint('[Sync] Fetched ${admins.length} admin users from Supabase');
    if (admins.isNotEmpty) {
      await db.syncAdminUsers(admins);
      synced = true;
    }
  } catch (e) {
    debugPrint('[Sync] Failed to sync admin users: $e');
  }

  return synced;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database (creates tables + seeds on first run)
  await DatabaseService.instance.database;

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();
  debugPrint('[Init] Connectivity: ${ConnectivityService.instance.currentStatus}');

  // Initialize Supabase (no-op if not configured)
  await SupabaseService.instance.initialize();
  debugPrint('[Init] Supabase initialized: ${SupabaseService.instance.isInitialized}');

  // Kick off reference-data pull, but DO NOT block the UI on it. The login
  // screen reads admins from local SQLite which works offline, and the
  // background sync service will refresh the rest. Previously this awaited
  // a 5s startup sync, then SyncService.initialize() kicked off another
  // full sync — both of which competed with the login query for the
  // SQLite write-lock and made first-load feel like 15-20s.
  if (SupabaseService.instance.isInitialized) {
    unawaited(
      initialSync().timeout(const Duration(seconds: 8)).then(
        (result) => debugPrint('[Init] Startup sync completed: $result'),
        onError: (Object e) =>
            debugPrint('[Init] Startup sync failed/timed out: $e'),
      ),
    );
  }

  // Start sync service — keeps data fresh in background, pushes pending changes
  SyncService.instance.initialize();

  runApp(const ProviderScope(child: StratfordLaundryApp()));
}

/// Removes the overscroll bounce/glow effect on all scrollable widgets.
class _NoOverscrollBehavior extends ScrollBehavior {
  const _NoOverscrollBehavior();

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // No glow or stretch effect
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Clamp instead of bounce
  }
}

class StratfordLaundryApp extends ConsumerWidget {
  const StratfordLaundryApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Eagerly initialize — listens for sync events and invalidates data providers
    ref.watch(syncRefreshProvider);

    return MaterialApp.router(
      title: 'Stratford Laundry',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      routerConfig: AppRouter.router,
      // Remove overscroll bounce/glow on all scrollables
      scrollBehavior: const _NoOverscrollBehavior(),
    );
  }
}
