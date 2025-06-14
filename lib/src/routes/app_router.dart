import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apex_money/src/features/auth/presentation/pages/login_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/register_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:apex_money/src/features/auth/presentation/pages/profile_screen.dart';
import 'package:apex_money/src/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:apex_money/src/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:apex_money/src/features/transactions/presentation/pages/transaction_create_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/login'),
    GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterPage(),
    ),
    GoRoute(
      path: '/forgot-password',
      builder: (context, state) => const ForgotPasswordPage(),
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/transactions',
      builder: (context, state) => const TransactionListPage(),
    ),
    GoRoute(
      path: '/create-transaction',
      builder: (context, state) => const TransactionCreatePage(),
    ),
  ],
);
