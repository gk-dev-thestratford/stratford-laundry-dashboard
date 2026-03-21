import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/admin_user.dart';
import '../services/database_service.dart';

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

  Future<bool> login(String adminId, String adminName, String pin) async {
    final valid = await DatabaseService.instance.verifyPin(adminId, pin);
    if (valid) {
      state = AdminState(
        currentAdmin: AdminUser(id: adminId, name: adminName),
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
