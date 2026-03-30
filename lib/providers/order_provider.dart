import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/order.dart';
import '../models/catalogue_item.dart';
import '../services/database_service.dart';
import '../services/sync_service.dart';

const _uuid = Uuid();

/// Manages the in-progress order draft across the multi-step form
class OrderNotifier extends StateNotifier<OrderDraft> {
  OrderNotifier() : super(OrderDraft.empty);

  void setOrderType(String type) {
    state = OrderDraft.empty.copyWith(orderType: type);
  }

  /// Update order type without resetting the draft (used when refining linen → hsk_linen/fnb_linen)
  void updateOrderType(String type) {
    state = state.copyWith(orderType: type);
  }

  void updateDetails({
    String? docketNumber,
    String? departmentId,
    String? departmentName,
    String? staffName,
    String? email,
    String? notes,
    String? roomNumber,
    String? guestName,
    int? bagCount,
  }) {
    state = state.copyWith(
      docketNumber: docketNumber,
      departmentId: departmentId,
      departmentName: departmentName,
      staffName: staffName,
      email: email,
      notes: notes,
      roomNumber: roomNumber,
      guestName: guestName,
      bagCount: bagCount,
    );
  }

  void addItem(CatalogueItem item) {
    final existing = state.items.indexWhere((e) => e.item.id == item.id);
    if (existing >= 0) {
      final updated = List<OrderItemEntry>.from(state.items);
      updated[existing] = updated[existing].copyWith(
        quantity: updated[existing].quantity + 1,
      );
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(
        items: [...state.items, OrderItemEntry(item: item)],
      );
    }
  }

  void updateItemQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }
    final updated = state.items.map((e) {
      if (e.item.id == itemId) return e.copyWith(quantity: quantity);
      return e;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((e) => e.item.id != itemId).toList(),
    );
  }

  /// Submit order to local database (and queue for sync)
  Future<String> submitOrder() async {
    final db = DatabaseService.instance;
    final orderId = _uuid.v4();
    final now = DateTime.now().toIso8601String();

    final orderMap = {
      'id': orderId,
      'docket_number': state.docketNumber ?? '',
      'order_type': state.orderType ?? '',
      'department_id': state.departmentId,
      'staff_name': state.isGuestOrder ? state.guestName : state.staffName,
      'guest_name': state.isGuestOrder ? state.guestName : null,
      'email': state.email,
      'room_number': state.roomNumber,
      'bag_count': state.isGuestOrder ? state.bagCount : null,
      'notes': state.notes,
      'status': 'submitted',
      'total_price': state.isUniformOrder ? state.totalPrice : null,
      'created_at': now,
      'updated_at': now,
    };

    await db.insertOrder(orderMap);

    // Insert order items
    if (state.items.isNotEmpty) {
      final itemMaps = state.items.map((entry) => {
        'id': _uuid.v4(),
        'order_id': orderId,
        'item_id': entry.item.id,
        'item_name': entry.item.name,
        'quantity_sent': entry.quantity,
        'price_at_time': entry.item.price,
      }).toList();
      await db.insertOrderItems(itemMaps);
    }

    // Insert initial status log
    await db.insertStatusLog({
      'id': _uuid.v4(),
      'order_id': orderId,
      'status': 'submitted',
      'changed_by': null,
      'changed_by_name': null,
      'reason': null,
      'created_at': now,
    });

    // Queue for sync — push new order + pull latest data to keep local SQLite in sync
    await db.addToSyncQueue('orders', orderId, 'insert', jsonEncode(orderMap));
    SyncService.instance.fullSync();

    reset();
    return orderId;
  }

  void reset() {
    state = OrderDraft.empty;
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderDraft>(
  (ref) => OrderNotifier(),
);
