import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class CatalogueItem {
  final String id;
  final String code;
  final String name;
  final String category; // 'uniform', 'hsk_linen', 'fnb_linen'
  final double? price; // Only for uniforms
  final String? departmentId; // For dept-specific linens
  final int sortOrder;
  final bool isActive;
  final IconData icon;

  const CatalogueItem({
    required this.id,
    required this.code,
    required this.name,
    required this.category,
    this.price,
    this.departmentId,
    this.sortOrder = 0,
    this.isActive = true,
    this.icon = Icons.checkroom,
  });

  /// Uniform items — prices TBC by Georgi
  static final List<CatalogueItem> uniformItems = [
    CatalogueItem(id: 'uni001', code: 'UNI-001', name: 'Shirt', category: 'uniform', price: 3.50, sortOrder: 1, icon: MdiIcons.tshirtCrewOutline),
    CatalogueItem(id: 'uni002', code: 'UNI-002', name: 'Blouse', category: 'uniform', price: 3.50, sortOrder: 2, icon: MdiIcons.tshirtVOutline),
    CatalogueItem(id: 'uni003', code: 'UNI-003', name: 'Trousers', category: 'uniform', price: 4.00, sortOrder: 3, icon: Icons.checkroom),
    CatalogueItem(id: 'uni004', code: 'UNI-004', name: 'Dress', category: 'uniform', price: 5.00, sortOrder: 4, icon: Icons.dry_cleaning),
    CatalogueItem(id: 'uni005', code: 'UNI-005', name: 'Jacket / Blazer', category: 'uniform', price: 6.00, sortOrder: 5, icon: MdiIcons.hanger),
    CatalogueItem(id: 'uni006', code: 'UNI-006', name: 'Apron', category: 'uniform', price: 2.50, sortOrder: 6, icon: Icons.kitchen),
    CatalogueItem(id: 'uni007', code: 'UNI-007', name: 'Tie', category: 'uniform', price: 2.00, sortOrder: 7, icon: MdiIcons.tie),
    CatalogueItem(id: 'uni008', code: 'UNI-008', name: 'Waistcoat', category: 'uniform', price: 4.00, sortOrder: 8, icon: MdiIcons.bowTie),
    CatalogueItem(id: 'uni009', code: 'UNI-009', name: 'Chef Jacket', category: 'uniform', price: 4.50, sortOrder: 9, icon: MdiIcons.chefHat),
    CatalogueItem(id: 'uni010', code: 'UNI-010', name: 'Chef Trousers', category: 'uniform', price: 4.00, sortOrder: 10, icon: Icons.restaurant),
  ];

  /// Housekeeping linen items — no prices
  static const List<CatalogueItem> hskLinenItems = [
    CatalogueItem(id: 'hsk001', code: 'HSK-001', name: 'Curtains', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 1, icon: Icons.curtains),
    CatalogueItem(id: 'hsk002', code: 'HSK-002', name: 'Duvet', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 2, icon: Icons.bed),
    CatalogueItem(id: 'hsk003', code: 'HSK-003', name: 'Duvet Cover', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 3, icon: Icons.bed_outlined),
    CatalogueItem(id: 'hsk004', code: 'HSK-004', name: 'Bathrobe', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 4, icon: Icons.checkroom),
    CatalogueItem(id: 'hsk005', code: 'HSK-005', name: 'Bath Towel', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 5, icon: Icons.dry),
    CatalogueItem(id: 'hsk006', code: 'HSK-006', name: 'Hand Towel', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 6, icon: Icons.dry_outlined),
    CatalogueItem(id: 'hsk007', code: 'HSK-007', name: 'Bath Mat', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 7, icon: Icons.rectangle_outlined),
    CatalogueItem(id: 'hsk008', code: 'HSK-008', name: 'Bed Sheet', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 8, icon: Icons.single_bed),
    CatalogueItem(id: 'hsk009', code: 'HSK-009', name: 'Pillowcase', category: 'hsk_linen', departmentId: 'hsk', sortOrder: 9, icon: Icons.airline_seat_individual_suite),
  ];

  /// F&B linen items — no prices
  static const List<CatalogueItem> fnbLinenItems = [
    CatalogueItem(id: 'fnb001', code: 'FNB-001', name: 'Table Runner', category: 'fnb_linen', departmentId: 'fnb', sortOrder: 1, icon: Icons.table_bar),
    CatalogueItem(id: 'fnb002', code: 'FNB-002', name: 'Tablecloth', category: 'fnb_linen', departmentId: 'fnb', sortOrder: 2, icon: Icons.table_restaurant),
    CatalogueItem(id: 'fnb003', code: 'FNB-003', name: 'Napkin', category: 'fnb_linen', departmentId: 'fnb', sortOrder: 3, icon: Icons.dining),
  ];

  /// Get items by category
  static List<CatalogueItem> getByCategory(String category) {
    switch (category) {
      case 'uniform':
        return uniformItems;
      case 'hsk_linen':
        return hskLinenItems;
      case 'fnb_linen':
        return fnbLinenItems;
      default:
        return [];
    }
  }
}
