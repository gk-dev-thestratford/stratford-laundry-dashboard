import 'catalogue_item.dart';

/// Represents a single item line in an order
class OrderItemEntry {
  final CatalogueItem item;
  int quantity;

  OrderItemEntry({required this.item, this.quantity = 1});

  double get lineTotal => (item.price ?? 0) * quantity;

  OrderItemEntry copyWith({int? quantity}) {
    return OrderItemEntry(
      item: item,
      quantity: quantity ?? this.quantity,
    );
  }
}

/// The in-progress order being built through the multi-step form
class OrderDraft {
  final String? orderType; // 'uniform', 'hsk_linen', 'fnb_linen', 'guest_laundry'
  final String? docketNumber;
  final String? departmentId;
  final String? departmentName;
  final String? staffName;
  final String? email;
  final String? notes;
  // Guest-specific
  final String? roomNumber;
  final String? guestName;
  final int bagCount;
  // Items
  final List<OrderItemEntry> items;

  const OrderDraft({
    this.orderType,
    this.docketNumber,
    this.departmentId,
    this.departmentName,
    this.staffName,
    this.email,
    this.notes,
    this.roomNumber,
    this.guestName,
    this.bagCount = 1,
    this.items = const [],
  });

  bool get isGuestOrder =>
      orderType == 'guest_laundry';

  bool get isUniformOrder =>
      orderType == 'uniform';

  bool get isLinenOrder =>
      orderType == 'hsk_linen' || orderType == 'fnb_linen';

  /// For linens, determine category from department
  String get itemCategory {
    switch (orderType) {
      case 'uniform':
        return 'uniform';
      case 'hsk_linen':
        return 'hsk_linen';
      case 'fnb_linen':
        return 'fnb_linen';
      default:
        return '';
    }
  }

  double get totalPrice =>
      items.fold(0.0, (sum, entry) => sum + entry.lineTotal);

  int get totalItemCount =>
      items.fold(0, (sum, entry) => sum + entry.quantity);

  OrderDraft copyWith({
    String? orderType,
    String? docketNumber,
    String? departmentId,
    String? departmentName,
    String? staffName,
    String? email,
    String? notes,
    String? roomNumber,
    String? guestName,
    int? bagCount,
    List<OrderItemEntry>? items,
  }) {
    return OrderDraft(
      orderType: orderType ?? this.orderType,
      docketNumber: docketNumber ?? this.docketNumber,
      departmentId: departmentId ?? this.departmentId,
      departmentName: departmentName ?? this.departmentName,
      staffName: staffName ?? this.staffName,
      email: email ?? this.email,
      notes: notes ?? this.notes,
      roomNumber: roomNumber ?? this.roomNumber,
      guestName: guestName ?? this.guestName,
      bagCount: bagCount ?? this.bagCount,
      items: items ?? this.items,
    );
  }

  /// Reset to empty
  static const OrderDraft empty = OrderDraft();
}
