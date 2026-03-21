import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/order/order_type_screen.dart';
import '../screens/order/order_details_screen.dart';
import '../screens/order/item_selection_screen.dart';
import '../screens/order/order_review_screen.dart';
import '../screens/order/order_success_screen.dart';
import '../screens/admin/admin_login_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/order_detail_screen.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      // Staff order flow
      GoRoute(
        path: '/order/type',
        name: 'orderType',
        builder: (context, state) => const OrderTypeScreen(),
      ),
      GoRoute(
        path: '/order/details',
        name: 'orderDetails',
        builder: (context, state) => const OrderDetailsScreen(),
      ),
      GoRoute(
        path: '/order/items',
        name: 'orderItems',
        builder: (context, state) => const ItemSelectionScreen(),
      ),
      GoRoute(
        path: '/order/review',
        name: 'orderReview',
        builder: (context, state) => const OrderReviewScreen(),
      ),
      GoRoute(
        path: '/order/success',
        name: 'orderSuccess',
        builder: (context, state) => OrderSuccessScreen(
          docketNumber: state.extra as String?,
        ),
      ),
      // Admin flow
      GoRoute(
        path: '/admin/login',
        name: 'adminLogin',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin/dashboard',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/order/:orderId',
        name: 'adminOrderDetail',
        builder: (context, state) => AdminOrderDetailScreen(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
    ],
  );
}
