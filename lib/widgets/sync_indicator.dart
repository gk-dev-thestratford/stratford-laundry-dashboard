import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

/// Resolves the current sync visual state from connectivity + sync providers.
({Color color, String label, IconData icon}) _resolveSyncState(WidgetRef ref) {
  final connectivity = ref.watch(connectivityProvider);
  final syncState = ref.watch(syncStateProvider);

  return connectivity.when(
    data: (status) {
      if (status == ConnectivityStatus.offline) {
        return (color: AppColors.syncOffline, label: 'Offline', icon: Icons.cloud_off_rounded);
      }
      return syncState.when(
        data: (state) => switch (state) {
          SyncState.synced => (color: AppColors.syncOnline, label: 'Online', icon: Icons.cloud_done_rounded),
          SyncState.syncing => (color: AppColors.syncSyncing, label: 'Syncing...', icon: Icons.sync_rounded),
          SyncState.pending => (color: AppColors.syncSyncing, label: 'Pending', icon: Icons.cloud_upload_rounded),
          SyncState.offline => (color: AppColors.syncOffline, label: 'Offline', icon: Icons.cloud_off_rounded),
        },
        loading: () => (color: AppColors.syncSyncing, label: 'Connecting...', icon: Icons.sync_rounded),
        error: (_, _) => (color: AppColors.syncOnline, label: 'Online', icon: Icons.cloud_done_rounded),
      );
    },
    loading: () => (color: AppColors.syncSyncing, label: 'Connecting...', icon: Icons.sync_rounded),
    error: (_, _) => (color: AppColors.syncOnline, label: 'Online', icon: Icons.cloud_done_rounded),
  );
}

/// Full sync indicator — pill with icon + label. Used on home and admin screens.
class SyncIndicator extends ConsumerWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = _resolveSyncState(ref);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: s.color.withValues(alpha: 0.15),
        borderRadius: AppRadius.largeBR,
        border: Border.all(color: s.color.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: AppSizes.iconSizeMd, color: s.color),
          const SizedBox(width: AppSpacing.sm),
          Text(
            s.label,
            style: TextStyle(fontFamily: 'Inter',
              color: s.color,
              fontSize: AppTextStyles.captionSize,
              fontWeight: AppTextStyles.medium,
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact sync indicator for app bars — shows only icon when online/synced,
/// expands to icon + label when offline or pending.
class SyncIndicatorCompact extends ConsumerWidget {
  const SyncIndicatorCompact({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = _resolveSyncState(ref);
    final isNormal = s.label == 'Online';

    // When online and synced, show just a small green dot
    if (isNormal) {
      return Padding(
        padding: const EdgeInsets.only(right: AppSpacing.md),
        child: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.syncOnline,
            border: Border.all(color: AppColors.white.withValues(alpha: 0.5), width: 1.5),
          ),
        ),
      );
    }

    // When offline/syncing/pending, show icon + label
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: s.color.withValues(alpha: 0.2),
          borderRadius: AppRadius.smallBR,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(s.icon, size: 18, color: s.color),
            const SizedBox(width: AppSpacing.xs),
            Text(
              s.label,
              style: TextStyle(fontFamily: 'Inter',
                color: s.color,
                fontSize: 13,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
