import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../services/database_service.dart';
import '../services/supabase_service.dart';

class AdminState {
  final AdminUser? currentAdmin;
  final bool isAuthenticated;
  final DateTime? lastActivity;

  const AdminState({
    this.currentAdmin,
    this.isAuthenticated = false,
    this.lastActivity,
  });

  AdminState copyWith({
    AdminUser? currentAdmin,
    bool? isAuthenticated,
    DateTime? lastActivity,
  }) {
    return AdminState(
      currentAdmin: currentAdmin ?? this.currentAdmin,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      lastActivity: lastActivity ?? this.lastActivity,
    );
  }

  bool get isTimedOut {
    if (lastActivity == null) return true;
    return DateTime.now().difference(lastActivity!) > const Duration(minutes: 5);
  }

  static const empty = AdminState();
}

class AdminNotifier extends StateNotifier<AdminState> {
  AdminNotifier() : super(AdminState.empty);

  Future<List<AdminUser>> getAdminUsers() async {
    final rows = await DatabaseService.instance.getAdminUsers();
    return rows.map((r) => AdminUser.fromMap(r)).toList();
  }

  Future<bool> login(String adminId, String adminName, String pin, {bool canDeleteOrders = false, bool canRejectOrders = false}) async {
    final valid = await DatabaseService.instance.verifyPin(adminId, pin);
    if (valid) {
      // Try to fetch fresh permissions from Supabase (with timeout so login isn't blocked)
      bool deletePermission = canDeleteOrders;
      bool rejectPermission = canRejectOrders;
      try {
        final remoteAdmins = await SupabaseService.instance
            .fetchAdminUsers()
            .timeout(const Duration(seconds: 3));
        final match = remoteAdmins.where((a) => a['id'] == adminId).toList();
        if (match.isNotEmpty) {
          deletePermission = match.first['can_delete_orders'] == true;
          rejectPermission = match.first['can_reject_orders'] == true;
          // Also update local DB while we have fresh data
          await DatabaseService.instance.syncAdminUsers(remoteAdmins);
        }
      } catch (e) {
        // Supabase unavailable, fall back to local value
      }

      state = AdminState(
        currentAdmin: AdminUser(id: adminId, name: adminName, canDeleteOrders: deletePermission, canRejectOrders: rejectPermission),
        isAuthenticated: true,
        lastActivity: DateTime.now(),
      );
    }
    return valid;
  }

  void refreshActivity() {
    if (state.isAuthenticated) {
      state = state.copyWith(lastActivity: DateTime.now());
    }
  }

  void logout() {
    state = AdminState.empty;
  }

  bool checkTimeout() {
    if (state.isAuthenticated && state.isTimedOut) {
      logout();
      return true;
    }
    return false;
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>(
  (ref) => AdminNotifier(),
);
