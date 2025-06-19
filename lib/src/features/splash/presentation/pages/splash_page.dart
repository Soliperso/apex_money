import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../shared/services/auth_service.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAuthenticationStatus();
  }

  Future<void> _checkAuthenticationStatus() async {
    // Add a small delay for splash screen effect
    await Future.delayed(const Duration(seconds: 1));

    try {
      final prefs = await SharedPreferences.getInstance();
      final keepSignedIn = prefs.getBool('keepSignedIn') ?? false;
      final hasToken = prefs.getString('access_token') != null;

      if (keepSignedIn && hasToken) {
        // Validate the token to make sure it's still valid
        final isValidToken = await _authService.validateToken();

        if (isValidToken && mounted) {
          // Token is valid, go to dashboard
          GoRouter.of(context).go('/dashboard');
          return;
        } else {
          // Token is invalid, clear it
          await prefs.remove('access_token');
        }
      }

      // No valid session, go to login
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      // Error checking auth, go to login
      if (mounted) {
        GoRouter.of(context).go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: AppGradientBackground(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xxl),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 48,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Apex Money',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Personal Finance Management',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.huge),
              CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
