import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_scaffold.dart';
import '../../providers/order_provider.dart';
import '../../models/catalogue_item.dart';

class ItemSelectionScreen extends ConsumerWidget {
  const ItemSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider);
    final catalogueItems = CatalogueItem.getByCategory(order.itemCategory);
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showPrices = order.isUniformOrder;

    // For linen orders: only one item type per ticket
    final selectedItemId = (order.isLinenOrder && order.items.isNotEmpty)
        ? order.items.first.item.id
        : null;

    return ScreenScaffold(
      title: 'Select Items',
      subtitle: 'Step 3 of 4 — Choose Items & Quantities',
      compact: true,
      child: Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? AppSpacing.lg : AppSpacing.base,
                vertical: AppSpacing.md,
              ),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isLandscape ? 5 : 3,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                childAspectRatio: isLandscape ? 0.95 : 0.85,
              ),
              itemCount: catalogueItems.length,
              itemBuilder: (context, index) {
                final item = catalogueItems[index];
                final inCart = order.items.where((e) => e.item.id == item.id).firstOrNull;
                final qty = inCart?.quantity ?? 0;
                final disabled = selectedItemId != null && selectedItemId != item.id;

                return _ItemCard(
                  item: item,
                  quantity: qty,
                  showPrice: showPrices,
                  disabled: disabled,
                  onAdd: () => ref.read(orderProvider.notifier).addItem(item),
                  onIncrement: () => ref.read(orderProvider.notifier)
                      .updateItemQuantity(item.id, qty + 1),
                  onDecrement: () => ref.read(orderProvider.notifier)
                      .updateItemQuantity(item.id, qty - 1),
                );
              },
            ),
          ),
          _BottomBar(
            itemCount: order.totalItemCount,
            totalPrice: showPrices ? order.totalPrice : null,
            canProceed: order.items.isNotEmpty,
            onNext: () => context.push('/order/review'),
          ),
        ],
      ),
    );
  }
}

class _ItemCard extends StatelessWidget {
  final CatalogueItem item;
  final int quantity;
  final bool showPrice;
  final bool disabled;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _ItemCard({
    required this.item,
    required this.quantity,
    required this.showPrice,
    this.disabled = false,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = quantity > 0;

    return Opacity(
      opacity: disabled ? 0.35 : 1.0,
      child: Material(
        color: isSelected ? AppColors.navy.withValues(alpha: 0.06) : AppColors.white,
        borderRadius: AppRadius.mediumBR,
        elevation: isSelected ? 4 : 2,
        shadowColor: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.navy.withValues(alpha: 0.08),
        child: InkWell(
          onTap: isSelected || disabled ? null : onAdd,
          borderRadius: AppRadius.mediumBR,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.md),
            decoration: BoxDecoration(
              borderRadius: AppRadius.mediumBR,
              border: Border.all(
                color: isSelected ? AppColors.gold : AppColors.grey200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? AppColors.gold.withValues(alpha: 0.12) : AppColors.navy.withValues(alpha: 0.06),
                    border: Border.all(
                      color: isSelected ? AppColors.gold.withValues(alpha: 0.3) : AppColors.navy.withValues(alpha: 0.1),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    item.icon,
                    size: 24,
                    color: isSelected ? AppColors.gold : AppColors.navy.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  item.name,
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: AppTextStyles.labelSize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.navy,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (showPrice && item.price != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    '£${item.price!.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: AppTextStyles.captionSize,
                      color: AppColors.grey600,
                      fontWeight: AppTextStyles.medium,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                if (isSelected)
                  _QuantityStepper(
                    quantity: quantity,
                    onIncrement: onIncrement,
                    onDecrement: onDecrement,
                  )
                else
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.navy.withValues(alpha: 0.08),
                      borderRadius: AppRadius.largeBR,
                    ),
                    child: Text(
                      'Tap to add',
                      style: TextStyle(fontFamily: 'Inter',
                        fontSize: AppTextStyles.captionSize,
                        color: AppColors.navy,
                        fontWeight: AppTextStyles.medium,
                      ),
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

class _QuantityStepper extends StatelessWidget {
  final int quantity;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantityStepper({
    required this.quantity,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: AppRadius.largeBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepperButton(icon: Icons.remove, onTap: onDecrement),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Text(
              '$quantity',
              style: TextStyle(fontFamily: 'Inter',
                fontSize: AppTextStyles.bodySize,
                fontWeight: AppTextStyles.bold,
                color: AppColors.white,
              ),
            ),
          ),
          _StepperButton(icon: Icons.add, onTap: onIncrement),
        ],
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 44,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.largeBR,
        child: Center(
          child: Icon(icon, size: AppSizes.iconSizeMd, color: AppColors.white),
        ),
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final int itemCount;
  final double? totalPrice;
  final bool canProceed;
  final VoidCallback onNext;

  const _BottomBar({
    required this.itemCount,
    this.totalPrice,
    required this.canProceed,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$itemCount ${itemCount == 1 ? 'item' : 'items'} selected',
                  style: TextStyle(fontFamily: 'Inter',
                    fontSize: AppTextStyles.bodySize,
                    fontWeight: AppTextStyles.bold,
                    color: AppColors.navy,
                  ),
                ),
                if (totalPrice != null)
                  Text(
                    'Total: £${totalPrice!.toStringAsFixed(2)}',
                    style: TextStyle(fontFamily: 'Inter',
                      fontSize: AppTextStyles.labelSize,
                      color: AppColors.grey600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            height: AppSizes.buttonHeightMd,
            child: ElevatedButton.icon(
              onPressed: canProceed ? onNext : null,
              icon: Icon(Icons.arrow_forward_rounded, size: AppSizes.iconSizeMd),
              label: const Text('Review Order'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.navy,
                disabledBackgroundColor: AppColors.grey300,
                disabledForegroundColor: AppColors.grey600,
                padding: EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                textStyle: TextStyle(fontFamily: 'Inter', fontSize: AppTextStyles.bodySize, fontWeight: AppTextStyles.bold),
                elevation: 3,
                shadowColor: AppColors.gold.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.mediumBR),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
