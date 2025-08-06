import 'package:go_router/go_router.dart';
import 'package:apex_money/src/features/auth/presentation/pages/modern_login_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/modern_register_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/modern_forgot_password_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/profile_screen.dart';
import 'package:apex_money/src/features/dashboard/presentation/pages/modern_dashboard_page.dart';
import 'package:apex_money/src/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:apex_money/src/features/transactions/presentation/pages/transaction_create_page.dart';
import 'package:apex_money/src/features/transactions/data/models/transaction_model.dart';
import 'package:apex_money/src/features/goals/presentation/pages/goals_page.dart';
import 'package:apex_money/src/features/goals/presentation/pages/enhanced_goal_create_page.dart';
import 'package:apex_money/src/features/goals/data/models/goal_model.dart';
// GROUPS FUNCTIONALITY COMMENTED OUT
// import 'package:apex_money/src/features/groups/presentation/pages/groups_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/group_detail_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/create_bill_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/bill_detail_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/bills_list_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/group_activity_page.dart';
// import 'package:apex_money/src/features/groups/presentation/pages/settlement_history_page.dart';
// import 'package:apex_money/src/features/groups/data/models/bill_model.dart';
import 'package:apex_money/src/features/ai_insights/presentation/pages/ai_insights_page.dart';
import 'package:apex_money/src/features/splash/presentation/pages/splash_page.dart';
import 'package:apex_money/src/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:apex_money/src/shared/pages/notifications_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashPage()),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const ModernLoginPage(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const ModernRegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder:
          (context, state) => ModernForgotPasswordPage(
            initialEmail: state.uri.queryParameters['email'],
          ),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ModernDashboardPage(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionListPage(),
    ),
    GoRoute(
      path: '/create-transaction',
      builder:
          (context, state) => TransactionCreatePage(
            mode:
                state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['mode']
                            as String? ??
                        'create'
                    : 'create',
            transaction:
                state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['transaction']
                        as Transaction?
                    : null,
            initialTransactionType:
                state.extra is Map<String, dynamic>
                    ? (state.extra as Map<String, dynamic>)['transactionType']
                        as String?
                    : null,
          ),
    ),
    // GROUPS ROUTES COMMENTED OUT
    // GoRoute(path: '/groups', builder: (context, state) => const GroupsPage()),
    // GoRoute(
    //   path: '/groups/:groupId',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     return GroupDetailPage(groupId: groupId);
    //   },
    // ),
    // GoRoute(
    //   path: '/groups/:groupId/create-bill',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     final extra = state.extra as Map<String, dynamic>?;
    //     return CreateBillPage(
    //       groupId: groupId,
    //       mode: extra?['mode'] ?? 'create',
    //       bill: extra?['bill'],
    //     );
    //   },
    // ),
    // GoRoute(
    //   path: '/groups/:groupId/bills',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     return BillsListPage(groupId: groupId);
    //   },
    // ),
    // GoRoute(
    //   path: '/groups/:groupId/bills/:billId',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     final billId = state.pathParameters['billId']!;
    //     return BillDetailPage(groupId: groupId, billId: billId);
    //   },
    // ),
    // GoRoute(
    //   path: '/groups/:groupId/activity',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     return GroupActivityPage(groupId: groupId);
    //   },
    // ),
    // GoRoute(
    //   path: '/groups/:groupId/settlements',
    //   builder: (context, state) {
    //     final groupId = state.pathParameters['groupId']!;
    //     return SettlementHistoryPage(groupId: groupId);
    //   },
    // ),
    GoRoute(
      path: '/ai-insights',
      builder: (context, state) => const AIInsightsPage(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsPage(),
    ),
    GoRoute(path: '/goals', builder: (context, state) => const GoalsPage()),
    GoRoute(
      path: '/create-goal',
      builder:
          (context, state) => EnhancedGoalCreatePage(
            goal: state.extra is Goal ? state.extra as Goal : null,
          ),
    ),
  ],
);
