import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../widgets/sync_indicator.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Timer _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _clockTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.navy, AppColors.navyDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildTopBar(),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isLandscape ? size.width * 0.08 : AppSpacing.xl,
                      vertical: AppSpacing.lg,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildBranding(isLandscape),
                        SizedBox(height: isLandscape ? AppSpacing.xxl : AppSpacing.xl + AppSpacing.sm),
                        _buildDivider(),
                        SizedBox(height: isLandscape ? AppSpacing.xxl : AppSpacing.xl + AppSpacing.sm),
                        _buildActionButtons(isLandscape, size),
                      ],
                    ),
                  ),
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    final dateStr = DateFormat('EEEE, d MMMM yyyy').format(_now);
    final timeStr = DateFormat('HH:mm').format(_now);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.base,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SyncIndicator(),
          Text(
            '$dateStr  •  $timeStr',
            style: TextStyle(fontFamily: 'Inter',
              color: AppColors.white.withValues(alpha: 0.7),
              fontSize: AppTextStyles.bodySize,
              fontWeight: AppTextStyles.regular,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding(bool isLandscape) {
    return Column(
      children: [
        Container(
          width: isLandscape ? 96 : 80,
          height: isLandscape ? 96 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.gold, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withValues(alpha: 0.2),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            Icons.hotel,
            color: AppColors.gold,
            size: isLandscape ? 48 : 40,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.appName.toUpperCase(),
          style: TextStyle(fontFamily: 'Inter',
            color: AppColors.white,
            fontSize: isLandscape ? 36 : AppTextStyles.headingSize,
            fontWeight: AppTextStyles.bold,
            letterSpacing: 3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          AppConstants.hotelTagline,
          style: TextStyle(fontFamily: 'Inter',
            color: AppColors.gold,
            fontSize: isLandscape ? AppTextStyles.bodySize : AppTextStyles.labelSize,
            fontWeight: AppTextStyles.regular,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          AppConstants.appSubtitle,
          style: TextStyle(fontFamily: 'Inter',
            color: AppColors.white.withValues(alpha: 0.8),
            fontSize: isLandscape ? AppTextStyles.titleSize : AppTextStyles.bodySize,
            fontWeight: AppTextStyles.regular,
          ),
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 56, height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
        const SizedBox(width: AppSpacing.base),
        Icon(Icons.diamond_outlined, color: AppColors.gold.withValues(alpha: 0.6), size: AppTextStyles.bodySize),
        const SizedBox(width: AppSpacing.base),
        Container(width: 56, height: 1, color: AppColors.gold.withValues(alpha: 0.4)),
      ],
    );
  }

  Widget _buildActionButtons(bool isLandscape, Size size) {
    if (isLandscape) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildMainButton(
            icon: Icons.local_laundry_service_rounded,
            label: 'New Laundry Order',
            subtitle: 'Submit uniforms, linens, or guest laundry',
            onTap: () => context.push('/order/type'),
          ),
          const SizedBox(width: AppSpacing.xl),
          _buildMainButton(
            icon: Icons.admin_panel_settings_rounded,
            label: 'Admin Login',
            subtitle: 'Manage orders and update statuses',
            onTap: () => context.push('/admin/login'),
            isSecondary: true,
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildMainButton(
          icon: Icons.local_laundry_service_rounded,
          label: 'New Laundry Order',
          subtitle: 'Submit uniforms, linens, or guest laundry',
          onTap: () => context.push('/order/type'),
          fullWidth: true,
        ),
        const SizedBox(height: AppSpacing.lg),
        _buildMainButton(
          icon: Icons.admin_panel_settings_rounded,
          label: 'Admin Login',
          subtitle: 'Manage orders and update statuses',
          onTap: () => context.push('/admin/login'),
          isSecondary: true,
          fullWidth: true,
        ),
      ],
    );
  }

  Widget _buildMainButton({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    bool isSecondary = false,
    bool fullWidth = false,
  }) {
    final bgColor = isSecondary
        ? AppColors.white.withValues(alpha: 0.08)
        : AppColors.gold;
    final fgColor = isSecondary ? AppColors.white : AppColors.navy;
    final borderColor = isSecondary ? AppColors.white.withValues(alpha: 0.2) : AppColors.gold;
    final subtitleColor = isSecondary
        ? AppColors.white.withValues(alpha: 0.7)
        : AppColors.navy.withValues(alpha: 0.7);

    return SizedBox(
      width: fullWidth ? double.infinity : 300,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.md + 4),
        elevation: 4,
        shadowColor: (isSecondary ? AppColors.white : AppColors.gold).withValues(alpha: 0.25),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.md + 4),
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.md + 4),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: fgColor.withValues(alpha: 0.1),
                    border: Border.all(color: fgColor.withValues(alpha: 0.2), width: 1.5),
                  ),
                  child: Icon(icon, size: 36, color: fgColor),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  label,
                  style: TextStyle(fontFamily: 'Inter',
                    color: fgColor,
                    fontSize: AppTextStyles.titleSize,
                    fontWeight: AppTextStyles.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: TextStyle(fontFamily: 'Inter',
                    color: subtitleColor,
                    fontSize: AppTextStyles.labelSize,
                    fontWeight: AppTextStyles.regular,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return const SizedBox(height: AppSpacing.md);
  }
}
