import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityProvider);
    final syncState = ref.watch(syncStateProvider);

    final (color, label, icon) = connectivity.when(
      data: (status) {
        if (status == ConnectivityStatus.offline) {
          return (AppColors.syncOffline, 'Offline', Icons.cloud_off_rounded);
        }
        return syncState.when(
          data: (state) => switch (state) {
            SyncState.synced => (AppColors.syncOnline, 'Online', Icons.cloud_done_rounded),
            SyncState.syncing => (AppColors.syncSyncing, 'Syncing...', Icons.sync_rounded),
            SyncState.pending => (AppColors.syncSyncing, 'Pending', Icons.cloud_upload_rounded),
            SyncState.offline => (AppColors.syncOffline, 'Offline', Icons.cloud_off_rounded),
          },
          loading: () => (AppColors.syncSyncing, 'Connecting...', Icons.sync_rounded),
          error: (_, _) => (AppColors.syncOnline, 'Online', Icons.cloud_done_rounded),
        );
      },
      loading: () => (AppColors.syncSyncing, 'Connecting...', Icons.sync_rounded),
      error: (_, _) => (AppColors.syncOnline, 'Online', Icons.cloud_done_rounded),
    );

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppRadius.largeBR,
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSizes.iconSizeMd, color: color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: TextStyle(fontFamily: 'Inter',
              color: color,
              fontSize: AppTextStyles.captionSize,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ],
      ),
    );
  }
}
