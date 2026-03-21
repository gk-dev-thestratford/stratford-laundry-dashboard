import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../config/constants.dart';
import '../../widgets/screen_scaffold.dart';
import '../../providers/order_provider.dart';
import '../../models/order.dart';

class OrderReviewScreen extends ConsumerWidget {
  const OrderReviewScreen({super.key});

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final docket = ref.read(orderProvider).docketNumber;
    await ref.read(orderProvider.notifier).submitOrder();
    if (context.mounted) context.go('/order/success', extra: docket);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final isGuest = order.isGuestOrder;
    final stepLabel = isGuest ? 'Step 3 of 3 — Confirm & Submit' : 'Step 4 of 4 — Confirm & Submit';

    return ScreenScaffold(
      title: 'Review Order',
      subtitle: stepLabel,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 80 : 20,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 700),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Order header card
                      _buildHeaderCard(order),
                      const SizedBox(height: AppSpacing.base),
                      // Items or bag count
                      if (isGuest)
                        _buildGuestSummaryCard(order)
                      else
                        _buildItemsCard(order),
                      const SizedBox(height: AppSpacing.base),
                      // Notes
                      if (order.notes != null && order.notes!.isNotEmpty)
                        _buildNotesCard(order.notes!),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Submit bar
          _buildSubmitBar(context, ref, order),
        ],
      ),
    );
  }

  Widget _buildHeaderCard(OrderDraft order) {
    final now = DateFormat('dd/MM/yyyy — HH:mm').format(DateTime.now());
    final typeLabel = AppLabels.orderTypeLabels[order.orderType] ?? order.orderType ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long, color: AppColors.navy, size: AppSizes.iconSizeLg),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Order Summary',
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: AppTextStyles.titleSize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            _detailRow('Date', now),
            _detailRow('Docket Number', order.docketNumber ?? '—'),
            _detailRow('Order Type', typeLabel),
            _detailRow('Department', order.departmentName ?? '—'),
            if (order.isGuestOrder) ...[
              _detailRow('Room Number', order.roomNumber ?? '—'),
              _detailRow('Guest Name', order.staffName ?? order.guestName ?? '—'),
            ] else ...[
              _detailRow('Staff Name', order.staffName ?? '—'),
              if (order.email != null && order.email!.isNotEmpty)
                _detailRow('Email', order.email!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGuestSummaryCard(OrderDraft order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.navy.withValues(alpha: 0.08),
                borderRadius: AppRadius.mediumBR,
                border: Border.all(color: AppColors.navy.withValues(alpha: 0.15), width: 1.5),
              ),
              child: Center(
                child: Text(
                  '${order.bagCount}',
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: AppTextStyles.headingSize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.navy,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Text(
              order.bagCount == 1 ? 'Laundry Bag' : 'Laundry Bags',
              style: TextStyle(fontFamily: 'Inter',
                fontSize: AppTextStyles.titleSize,
                fontWeight: AppTextStyles.medium,
                color: AppColors.grey800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsCard(OrderDraft order) {
    final showPrices = order.isUniformOrder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list_alt, color: AppColors.navy, size: AppSizes.iconSizeLg),
                const SizedBox(width: AppSpacing.md),
                Text(
                  'Items (${order.totalItemCount})',
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: AppTextStyles.titleSize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            // Table header
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text('Item', style: _headerStyle()),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text('Qty', style: _headerStyle(), textAlign: TextAlign.center),
                  ),
                  if (showPrices)
                    SizedBox(
                      width: 90,
                      child: Text('Price', style: _headerStyle(), textAlign: TextAlign.right),
                    ),
                ],
              ),
            ),
            // Item rows
            ...order.items.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      entry.item.name,
                      style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey800),
                    ),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text(
                      '×${entry.quantity}',
                      style: TextStyle(fontFamily: 'Inter',
                        fontSize: AppTextStyles.bodySize,
                        fontWeight: AppTextStyles.medium,
                        color: AppColors.navy,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (showPrices)
                    SizedBox(
                      width: 90,
                      child: Text(
                        '£${entry.lineTotal.toStringAsFixed(2)}',
                        style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey700),
                        textAlign: TextAlign.right,
                      ),
                    ),
                ],
              ),
            )),
            // Total (uniforms only)
            if (showPrices) ...[
              const Divider(height: AppSpacing.lg),
              Row(
                children: [
                  const Spacer(),
                  Text(
                    'Total:',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: AppTextStyles.titleSize,
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.base),
                  Text(
                    '£${order.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: AppTextStyles.headingSize,
                      fontWeight: AppTextStyles.bold,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotesCard(String notes) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notes, color: AppColors.grey600, size: AppSizes.iconSizeLg),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notes',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: AppTextStyles.labelSize,
                      fontWeight: AppTextStyles.medium,
                      color: AppColors.grey600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    notes,
                    style: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, color: AppColors.grey800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitBar(BuildContext context, WidgetRef ref, OrderDraft order) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.base),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded, size: AppSizes.iconSizeMd),
              label: const Text('Go Back'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.medium),
              ),
            ),
            const Spacer(),
            SizedBox(
              height: AppSizes.buttonHeightLg,
              child: ElevatedButton.icon(
                onPressed: () => _submit(context, ref),
                icon: const Icon(Icons.check_circle_outline, size: AppSizes.iconSizeLg),
                label: const Text('Submit Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.navy,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                  textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.bold),
                  elevation: 3,
                  shadowColor: AppColors.gold.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: TextStyle(fontFamily: 'Inter',
                fontSize: AppTextStyles.labelSize,
                color: AppColors.grey600,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontFamily: 'Inter',
                fontSize: AppTextStyles.bodySize,
                color: AppColors.grey900,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _headerStyle() {
    return TextStyle(fontFamily: 'Inter',
      fontSize: AppTextStyles.labelSize,
      fontWeight: AppTextStyles.medium,
      color: AppColors.grey600,
    );
  }
}
