import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../widgets/screen_scaffold.dart';
import '../../providers/order_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../models/catalogue_item.dart';
import '../../services/sync_service.dart';

class ItemSelectionScreen extends ConsumerWidget {
  const ItemSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider);
    final catalogueAsync = ref.watch(catalogueItemsProvider(order.itemCategory));
    final allItems = catalogueAsync.valueOrNull ?? CatalogueItem.getByCategory(order.itemCategory);
    final itemDeptMap = ref.watch(itemDepartmentMapProvider).valueOrNull ?? {};
    // Filter items by department using the junction table:
    // - If item has entries in item_department_access, only show for those departments
    // - If item has NO entries, fall back to old department_id field or show for all
    final catalogueItems = allItems.where((item) {
      final allowedDepts = itemDeptMap[item.id];
      if (allowedDepts != null && allowedDepts.isNotEmpty) {
        return order.departmentId != null && allowedDepts.contains(order.departmentId);
      }
      // Fallback: legacy single department_id or no restriction
      return item.departmentId == null ||
          item.departmentId!.isEmpty ||
          item.departmentId == order.departmentId;
    }).toList();
    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
    final showPrices = order.isUniformOrder;

    // For HSK linen orders: only one item type per ticket
    // For F&B linen: allow multiple items (numeric input for all)
    final selectedItemId = (order.itemCategory == 'hsk_linen' && order.items.isNotEmpty)
        ? order.items.first.item.id
        : null;

    return ScreenScaffold(
      title: 'Select Items',
      subtitle: 'Step 3 of 4 — Choose Items & Quantities',
      compact: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          tooltip: 'Refresh items from server',
          onPressed: () {
            SyncService.instance.fullSync();
            ref.invalidate(catalogueItemsProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Refreshing items...'), duration: Duration(seconds: 1)),
            );
          },
        ),
      ],
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
                  useNumericInput: order.itemCategory == 'fnb_linen',
                  onAdd: () => ref.read(orderProvider.notifier).addItem(item),
                  onIncrement: () => ref.read(orderProvider.notifier)
                      .updateItemQuantity(item.id, qty + 1),
                  onDecrement: () => ref.read(orderProvider.notifier)
                      .updateItemQuantity(item.id, qty - 1),
                  onQuantityChanged: (newQty) => ref.read(orderProvider.notifier)
                      .updateItemQuantity(item.id, newQty),
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

class _ItemCard extends StatefulWidget {
  final CatalogueItem item;
  final int quantity;
  final bool showPrice;
  final bool disabled;
  final bool useNumericInput;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<int> onQuantityChanged;

  const _ItemCard({
    required this.item,
    required this.quantity,
    required this.showPrice,
    this.disabled = false,
    this.useNumericInput = false,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
    required this.onQuantityChanged,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  late TextEditingController _qtyController;

  @override
  void initState() {
    super.initState();
    _qtyController = TextEditingController(
      text: widget.quantity > 0 ? '${widget.quantity}' : '',
    );
  }

  @override
  void didUpdateWidget(_ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync controller when quantity changes externally (e.g. remove item)
    final expected = widget.quantity > 0 ? '${widget.quantity}' : '';
    if (_qtyController.text != expected && !_qtyController.text.endsWith('.')) {
      _qtyController.text = expected;
      _qtyController.selection = TextSelection.collapsed(offset: expected.length);
    }
  }

  @override
  void dispose() {
    _qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.quantity > 0;

    final cardBody = Container(
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
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: CatalogueItem.iconBackgroundColor(widget.item.category, selected: isSelected),
              border: Border.all(
                color: CatalogueItem.iconBorderColor(widget.item.category, selected: isSelected),
                width: 2,
              ),
            ),
            child: Icon(
              widget.item.icon,
              size: 29,
              color: CatalogueItem.iconAccentColor(widget.item.category, selected: isSelected),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            widget.item.name,
            style: TextStyle(fontFamily: 'Inter',
              fontSize: AppTextStyles.labelSize,
              fontWeight: AppTextStyles.bold,
              color: AppColors.navy,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.showPrice && widget.item.price != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              '£${widget.item.price!.toStringAsFixed(2)}',
              style: TextStyle(fontFamily: 'Inter',
                fontSize: AppTextStyles.captionSize,
                color: AppColors.grey600,
                fontWeight: AppTextStyles.medium,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          if (widget.useNumericInput)
            _NumericQuantityField(
              controller: _qtyController,
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 0;
                if (qty > 0 && widget.quantity == 0) {
                  // Item not in order yet — add it first, then set quantity
                  widget.onAdd();
                }
                widget.onQuantityChanged(qty);
              },
            )
          else if (isSelected)
            _QuantityStepper(
              quantity: widget.quantity,
              onIncrement: widget.onIncrement,
              onDecrement: widget.onDecrement,
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
    );

    // For numeric input cards: no InkWell wrapper so the TextField can receive focus
    if (widget.useNumericInput) {
      return Opacity(
        opacity: widget.disabled ? 0.35 : 1.0,
        child: Material(
          color: isSelected ? AppColors.navy.withValues(alpha: 0.06) : AppColors.white,
          borderRadius: AppRadius.mediumBR,
          elevation: isSelected ? 4 : 2,
          shadowColor: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.navy.withValues(alpha: 0.08),
          child: cardBody,
        ),
      );
    }

    return Opacity(
      opacity: widget.disabled ? 0.35 : 1.0,
      child: Material(
        color: isSelected ? AppColors.navy.withValues(alpha: 0.06) : AppColors.white,
        borderRadius: AppRadius.mediumBR,
        elevation: isSelected ? 4 : 2,
        shadowColor: isSelected ? AppColors.gold.withValues(alpha: 0.2) : AppColors.navy.withValues(alpha: 0.08),
        child: InkWell(
          onTap: isSelected || widget.disabled ? null : widget.onAdd,
          borderRadius: AppRadius.mediumBR,
          child: cardBody,
        ),
      ),
    );
  }
}

class _NumericQuantityField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _NumericQuantityField({
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 40,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: AppTextStyles.bodySize,
          fontWeight: AppTextStyles.bold,
          color: AppColors.navy,
        ),
        textAlign: TextAlign.center,
        decoration: InputDecoration(
          hintText: '0',
          hintStyle: TextStyle(color: AppColors.grey600),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: OutlineInputBorder(borderRadius: AppRadius.mediumBR),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.mediumBR,
            borderSide: BorderSide(color: AppColors.gold, width: 2),
          ),
        ),
        onChanged: onChanged,
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
