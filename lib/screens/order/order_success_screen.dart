import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';

class OrderSuccessScreen extends StatefulWidget {
  final String? docketNumber;

  const OrderSuccessScreen({super.key, this.docketNumber});

  @override
  State<OrderSuccessScreen> createState() => _OrderSuccessScreenState();
}

class _OrderSuccessScreenState extends State<OrderSuccessScreen> {
  static const _autoRedirectSeconds = 10;
  late int _secondsLeft;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsLeft = _autoRedirectSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_secondsLeft <= 1) {
        _timer?.cancel();
        if (mounted) context.go('/');
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Icon(Icons.check_rounded, size: 56, color: AppColors.white),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Order Submitted!',
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: AppTextStyles.bold,
                  ),
                ),
                if (widget.docketNumber != null && widget.docketNumber!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Docket #${widget.docketNumber}',
                    style: TextStyle(fontFamily: 'Inter',
                      color: AppColors.gold,
                      fontSize: AppTextStyles.headingSize,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.base),
                Text(
                  'Your laundry order has been recorded successfully.',
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.white.withValues(alpha: 0.7),
                    fontSize: AppTextStyles.titleSize,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                ElevatedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_rounded, size: AppSizes.iconSizeLg),
                  label: const Text('Return to Home'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: AppColors.navy,
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
                    elevation: 4,
                    shadowColor: AppColors.gold.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
                    textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'Returning to home in $_secondsLeft seconds...',
                  style: TextStyle(fontFamily: 'Inter',
                    color: AppColors.white.withValues(alpha: 0.6),
                    fontSize: AppTextStyles.labelSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
