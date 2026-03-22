import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/router.dart';
import 'services/supabase_service.dart';
import 'services/connectivity_service.dart';
import 'services/database_service.dart';
import 'services/sync_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local database (creates tables + seeds on first run)
  await DatabaseService.instance.database;

  // Initialize connectivity monitoring
  await ConnectivityService.instance.initialize();

  // Initialize Supabase (no-op if not configured)
  await SupabaseService.instance.initialize();

  // Start sync service (pulls departments, items, admins from Supabase)
  SyncService.instance.initialize();

  runApp(const ProviderScope(child: StratfordLaundryApp()));
}

class StratfordLaundryApp extends StatelessWidget {
  const StratfordLaundryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stratford Laundry',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.navy),
        fontFamily: 'Inter',
        useMaterial3: true,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.white,
          border: OutlineInputBorder(borderRadius: AppRadius.mediumBR),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.mediumBR,
            borderSide: BorderSide(color: AppColors.grey300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mediumBR,
            borderSide: BorderSide(color: AppColors.navy, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.base,
          ),
        ),
      ),
      routerConfig: AppRouter.router,
    );
  }
}
