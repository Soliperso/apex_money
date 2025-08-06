import 'package:flutter/material.dart';
import 'notification_badge.dart';
import '../pages/notifications_page.dart';

/// A notification action button that can be used in app bars
class NotificationActionButton extends StatelessWidget {
  final Color? iconColor;
  final bool showAsSheet;
  final VoidCallback? onTap;

  const NotificationActionButton({
    Key? key,
    this.iconColor,
    this.showAsSheet = false,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Determine icon color based on context
    final effectiveIconColor =
        iconColor ??
        (theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9));

    return NotificationBadge(
      child: IconButton(
        onPressed: onTap ?? () => _handleNotificationTap(context),
        icon: Icon(Icons.notifications_outlined, color: effectiveIconColor),
        tooltip: 'Notifications',
      ),
    );
  }

  void _handleNotificationTap(BuildContext context) {
    // For now, always show as sheet - it's more elegant and works reliably
    showNotificationSheet(context);
  }
}

/// A notification action button specifically for light app bars
class LightNotificationActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showAsSheet;

  const LightNotificationActionButton({
    Key? key,
    this.onTap,
    this.showAsSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationActionButton(
      iconColor: Colors.white.withValues(alpha: 0.9),
      showAsSheet: showAsSheet,
      onTap: onTap,
    );
  }
}

/// A notification action button specifically for dark app bars
class DarkNotificationActionButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool showAsSheet;

  const DarkNotificationActionButton({
    Key? key,
    this.onTap,
    this.showAsSheet = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationActionButton(
      iconColor: Theme.of(context).colorScheme.onSurface,
      showAsSheet: showAsSheet,
      onTap: onTap,
    );
  }
}
