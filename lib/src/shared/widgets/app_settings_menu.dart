import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../theme/theme_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_spacing.dart';

class AppSettingsMenu extends StatelessWidget {
  final Color? iconColor;

  const AppSettingsMenu({Key? key, this.iconColor}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon color based on context
    final effectiveIconColor =
        iconColor ??
        (theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9));

    return PopupMenuButton<String>(
      icon: Icon(Icons.settings, color: effectiveIconColor),
      onSelected: (value) => _handleMenuSelection(context, value),
      itemBuilder:
          (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'profile',
              child: Row(
                children: [
                  Icon(
                    Icons.person,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('Profile'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'theme',
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, child) {
                  return Row(
                    children: [
                      Icon(
                        themeProvider.isDarkMode
                            ? Icons.light_mode
                            : Icons.dark_mode,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
                      ),
                    ],
                  );
                },
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Logout',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
    );
  }

  void _handleMenuSelection(BuildContext context, String value) {
    switch (value) {
      case 'profile':
        context.go('/profile');
        break;
      case 'theme':
        context.read<ThemeProvider>().toggleTheme();
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performLogout(context);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _performLogout(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Perform logout
      await AuthService().logout();

      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Navigate to login
        context.go('/login');

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Logged out successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Logout failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}
