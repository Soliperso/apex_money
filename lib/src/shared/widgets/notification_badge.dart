import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

/// A badge widget that shows notification count
class NotificationBadge extends StatelessWidget {
  final Widget child;
  final bool showWhenZero;
  final Color? backgroundColor;
  final Color? textColor;
  final double? size;
  final EdgeInsetsGeometry? padding;
  final Alignment alignment;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.showWhenZero = false,
    this.backgroundColor,
    this.textColor,
    this.size,
    this.padding,
    this.alignment = Alignment.topRight,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final count = notificationProvider.unreadCount;

        if (count == 0 && !showWhenZero) {
          return child;
        }

        return Stack(
          alignment: alignment,
          children: [
            child,
            if (count > 0 || showWhenZero)
              Container(
                padding: padding ?? const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: backgroundColor ?? colorScheme.error,
                  borderRadius: BorderRadius.circular(size ?? 12),
                  border: Border.all(color: colorScheme.surface, width: 2),
                ),
                constraints: BoxConstraints(
                  minWidth: size ?? 20,
                  minHeight: size ?? 20,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? colorScheme.onError,
                    fontSize: (size ?? 20) * 0.6,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        );
      },
    );
  }
}

/// A simple notification indicator dot
class NotificationDot extends StatelessWidget {
  final double size;
  final Color? color;
  final bool animate;

  const NotificationDot({
    Key? key,
    this.size = 8.0,
    this.color,
    this.animate = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final hasUnread = notificationProvider.unreadCount > 0;

        if (!hasUnread) {
          return const SizedBox.shrink();
        }

        Widget dot = Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? colorScheme.error,
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.surface, width: 1),
          ),
        );

        if (animate) {
          return TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(opacity: 0.7 + (0.3 * value), child: dot),
              );
            },
          );
        }

        return dot;
      },
    );
  }
}

/// A notification icon with badge
class NotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final IconData icon;
  final double iconSize;
  final Color? iconColor;
  final Color? badgeColor;
  final Color? badgeTextColor;

  const NotificationIcon({
    Key? key,
    this.onTap,
    this.icon = Icons.notifications,
    this.iconSize = 24.0,
    this.iconColor,
    this.badgeColor,
    this.badgeTextColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return NotificationBadge(
      backgroundColor: badgeColor,
      textColor: badgeTextColor,
      child: IconButton(
        onPressed: onTap,
        icon: Icon(
          icon,
          size: iconSize,
          color: iconColor ?? colorScheme.onSurface,
        ),
        tooltip: 'Notifications',
      ),
    );
  }
}

/// A notification counter widget for bottom navigation
class NotificationCounter extends StatelessWidget {
  final TextStyle? textStyle;
  final String prefix;
  final String suffix;

  const NotificationCounter({
    Key? key,
    this.textStyle,
    this.prefix = '',
    this.suffix = '',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final count = notificationProvider.unreadCount;

        if (count == 0) {
          return const SizedBox.shrink();
        }

        return Text(
          '$prefix$count$suffix',
          style:
              textStyle ??
              TextStyle(
                color: colorScheme.error,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
        );
      },
    );
  }
}
