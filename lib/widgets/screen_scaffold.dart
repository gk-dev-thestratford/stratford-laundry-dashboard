import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';

/// Shared scaffold for all non-home screens.
/// Provides a consistent app bar with back button, title, and optional subtitle.
class ScreenScaffold extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showBackButton;
  final bool compact;

  const ScreenScaffold({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.actions,
    this.showBackButton = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        toolbarHeight: compact ? 56 : 68,
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white, size: 26),
                onPressed: () => context.pop(),
                padding: compact ? EdgeInsets.zero : const EdgeInsets.all(AppSpacing.sm),
                constraints: const BoxConstraints(
                  minWidth: AppSizes.minTouchTarget,
                  minHeight: AppSizes.minTouchTarget,
                ),
              )
            : null,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: TextStyle(fontFamily: 'Inter',
                color: AppColors.white,
                fontSize: compact ? AppTextStyles.bodySize : AppTextStyles.titleSize,
                fontWeight: AppTextStyles.medium,
              ),
            ),
            if (subtitle != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  subtitle!,
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.gold,
                    fontSize: AppTextStyles.captionSize,
                    fontWeight: AppTextStyles.regular,
                  ),
                ),
              ),
          ],
        ),
        centerTitle: true,
        actions: actions,
        elevation: 2,
        shadowColor: AppColors.navyDark.withValues(alpha: 0.3),
      ),
      body: child,
    );
  }
}
