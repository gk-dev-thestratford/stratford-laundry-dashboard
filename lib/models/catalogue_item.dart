// NOTE 2026-06-12: material_design_icons_flutter removed — it extends IconData,
// which Flutter 3.44 made final, so the package no longer compiles and is
// unmaintained. Icons below use closest built-in Material equivalents.
import 'package:flutter/material.dart';

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

  factory CatalogueItem.fromMap(Map<String, dynamic> map) {
    final category = map['category'] as String? ?? 'uniform';
    final name = map['name'] as String;
    return CatalogueItem(
      id: map['id'] as String,
      code: map['code'] as String? ?? '',
      name: name,
      category: category,
      price: (map['price'] as num?)?.toDouble(),
      departmentId: map['department_id'] as String?,
      sortOrder: (map['sort_order'] as int?) ?? 0,
      isActive: (map['is_active'] == 1 || map['is_active'] == true),
      icon: iconForItemName(name, category),
    );
  }

  static IconData _defaultIconForCategory(String category) {
    switch (category) {
      case 'hsk_linen':
        return Icons.bed;
      case 'fnb_linen':
        return Icons.restaurant;
      default:
        return Icons.checkroom;
    }
  }

  /// Returns a specific icon for each item name (used when items come from DB).
  /// Each item gets a unique, visually distinct icon.
  static IconData iconForItemName(String name, String category) {
    final lower = name.toLowerCase();

    // ── Uniform items (from Supabase) ──
    if (lower.contains('t-shirt') || lower.contains('polo shirt'))  return Icons.checkroom_outlined;   // Casual top
    if (lower.contains('shirt') && !lower.contains('chef'))          return Icons.dry_cleaning_outlined; // Shirt on hanger
    if (lower.contains('blouse'))                                     return Icons.dry_cleaning;          // Blouse on hanger
    if (lower.contains('chef') && lower.contains('trouser'))         return Icons.soup_kitchen;          // Chef uniform bottom
    if (lower.contains('trouser') || lower.contains('jean'))         return Icons.accessibility_new;     // Standing figure (trousers/full-length)
    if (lower.contains('dress'))                                      return Icons.woman;                 // Female silhouette (dress shape)
    if (lower.contains('chef') && lower.contains('jacket'))          return Icons.soup_kitchen;          // Chef
    if (lower.contains('jacket') || lower.contains('blazer'))        return Icons.checkroom;             // Jacket on hanger
    if (lower.contains('apron'))                                      return Icons.restaurant_menu;       // Service/kitchen
    if (lower.contains('waistcoat') || lower.contains('vest'))       return Icons.style;                 // Formal vest
    if (lower.contains('suit'))                                       return Icons.business_center;       // Formal suit
    if (lower.contains('hoody') || lower.contains('hoodie') || lower.contains('jumper')) return Icons.dry_cleaning; // Heavy top
    if (lower.contains('coat'))                                       return Icons.checkroom;             // Coat on rack
    if (lower.contains('pullover') || lower.contains('sweater'))     return Icons.dry_cleaning_outlined; // Knitwear

    // ── HSK linen items ──
    if (lower.contains('curtain'))                                    return Icons.curtains;
    if (lower.contains('duvet cover'))                                return Icons.bed_outlined;
    if (lower.contains('duvet'))                                      return Icons.bed;
    if (lower.contains('bathrobe') || lower.contains('robe'))        return Icons.bathtub_outlined;
    if (lower.contains('bath towel'))                                 return Icons.dry;
    if (lower.contains('hand towel'))                                 return Icons.dry_outlined;
    if (lower.contains('bath mat'))                                   return Icons.rectangle_outlined;
    if (lower.contains('bed sheet') || lower.contains('sheet'))      return Icons.single_bed;
    if (lower.contains('pillowcase') || lower.contains('pillow'))    return Icons.airline_seat_individual_suite;

    // ── F&B linen items ──
    if (lower.contains('runner'))                                     return Icons.table_bar;
    if (lower.contains('tablecloth') || lower.contains('table cloth')) return Icons.table_restaurant;
    if (lower.contains('napkin'))                                      return Icons.dining;

    // Fallback
    return _defaultIconForCategory(category);
  }

  /// Returns a background color for the icon circle — blue fill for all categories
  static Color iconBackgroundColor(String category, {bool selected = false}) {
    if (selected) return const Color(0xFF384845); // Solid dark teal when selected
    return const Color(0xFF384845).withValues(alpha: 0.12); // Teal tint
  }

  /// Returns the icon color — gold for all categories
  static Color iconAccentColor(String category, {bool selected = false}) {
    if (selected) return const Color(0xFFD4AF37); // Gold
    return const Color(0xFFD4AF37); // Gold always
  }

  /// Returns the border color for the icon circle
  static Color iconBorderColor(String category, {bool selected = false}) {
    if (selected) return const Color(0xFFD4AF37).withValues(alpha: 0.5);
    return const Color(0xFF384845).withValues(alpha: 0.3); // Teal border
  }

  /// Uniform items — prices TBC by Georgi
  static final List<CatalogueItem> uniformItems = [
    CatalogueItem(id: 'uni001', code: 'UNI-001', name: 'Shirt', category: 'uniform', price: 3.50, sortOrder: 1, icon: Icons.dry_cleaning_outlined),
    CatalogueItem(id: 'uni002', code: 'UNI-002', name: 'Blouse', category: 'uniform', price: 3.50, sortOrder: 2, icon: Icons.dry_cleaning),
    CatalogueItem(id: 'uni003', code: 'UNI-003', name: 'Trousers', category: 'uniform', price: 4.00, sortOrder: 3, icon: Icons.checkroom),
    CatalogueItem(id: 'uni004', code: 'UNI-004', name: 'Dress', category: 'uniform', price: 5.00, sortOrder: 4, icon: Icons.woman),
    CatalogueItem(id: 'uni005', code: 'UNI-005', name: 'Jacket / Blazer', category: 'uniform', price: 6.00, sortOrder: 5, icon: Icons.checkroom),
    CatalogueItem(id: 'uni006', code: 'UNI-006', name: 'Apron', category: 'uniform', price: 2.50, sortOrder: 6, icon: Icons.kitchen),
    CatalogueItem(id: 'uni007', code: 'UNI-007', name: 'Tie', category: 'uniform', price: 2.00, sortOrder: 7, icon: Icons.business_center),
    CatalogueItem(id: 'uni008', code: 'UNI-008', name: 'Waistcoat', category: 'uniform', price: 4.00, sortOrder: 8, icon: Icons.style),
    CatalogueItem(id: 'uni009', code: 'UNI-009', name: 'Chef Jacket', category: 'uniform', price: 4.50, sortOrder: 9, icon: Icons.soup_kitchen),
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
