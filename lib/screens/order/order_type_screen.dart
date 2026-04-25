import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_scaffold.dart';
import '../../widgets/announcement_banner.dart';
import '../../providers/order_provider.dart';

class OrderTypeScreen extends ConsumerWidget {
  const OrderTypeScreen({super.key});

  void _selectType(BuildContext context, WidgetRef ref, String type) {
    // setOrderType already resets the draft to empty before setting the new type
    ref.read(orderProvider.notifier).setOrderType(type);
    context.push('/order/details');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return ScreenScaffold(
      title: 'New Laundry Order',
      subtitle: 'Step 1 of 4 — Select Order Type',
      child: Column(
        children: [
          AnnouncementBanner(
            padding: EdgeInsets.fromLTRB(
              isLandscape ? AppSpacing.xxl : AppSpacing.lg,
              AppSpacing.md,
              isLandscape ? AppSpacing.xxl : AppSpacing.lg,
              0,
            ),
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isLandscape ? AppSpacing.xxl : AppSpacing.lg,
                  vertical: AppSpacing.lg,
                ),
                child: isLandscape
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildCards(context, ref, isLandscape),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _buildCards(context, ref, isLandscape),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildCards(BuildContext context, WidgetRef ref, bool isLandscape) {
    final gap = SizedBox(
      width: isLandscape ? AppSpacing.xl : 0,
      height: isLandscape ? 0 : AppSpacing.base,
    );

    return [
      _OrderTypeCard(
        icon: Icons.checkroom_rounded,
        title: 'Staff Uniform',
        description: 'Shirts, trousers, jackets, aprons & more',
        color: AppColors.navy,
        onTap: () => _selectType(context, ref, 'uniform'),
      ),
      gap,
      _OrderTypeCard(
        icon: Icons.bed_rounded,
        title: 'Department Linen',
        description: 'Sheets, towels, tablecloths & napkins',
        color: const Color(0xFF2E7D6F),
        onTap: () => _selectType(context, ref, 'linen'),
      ),
      gap,
      _OrderTypeCard(
        icon: Icons.luggage_rounded,
        title: 'Guest / Resident',
        description: 'Guest laundry bags by room number',
        color: const Color(0xFF6D4C8A),
        onTap: () => _selectType(context, ref, 'guest_laundry'),
      ),
    ];
  }
}

class _OrderTypeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _OrderTypeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return SizedBox(
      width: isLandscape ? 260 : double.infinity,
      child: Material(
        color: AppColors.white,
        borderRadius: AppRadius.mediumBR,
        elevation: 3,
        shadowColor: color.withValues(alpha: 0.15),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.mediumBR,
          child: Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.xl,
              horizontal: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mediumBR,
              border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
                  ),
                  child: Icon(icon, size: 38, color: color),
                ),
                const SizedBox(height: AppSpacing.base),
                Text(
                  title,
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.grey900,
                    fontSize: AppTextStyles.titleSize,
                    fontWeight: AppTextStyles.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.grey600,
                    fontSize: AppTextStyles.labelSize,
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
}
