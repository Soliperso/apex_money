import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/notification_provider.dart';
import '../models/notification_model.dart';
import '../theme/app_spacing.dart';

/// A list widget for displaying notifications
class NotificationList extends StatelessWidget {
  final bool showOnlyUnread;
  final int? maxItems;
  final VoidCallback? onNotificationTap;
  final Function(NotificationModel)? onNotificationSelected;
  final bool enableActions;
  final EdgeInsetsGeometry? padding;

  const NotificationList({
    Key? key,
    this.showOnlyUnread = false,
    this.maxItems,
    this.onNotificationTap,
    this.onNotificationSelected,
    this.enableActions = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        if (notificationProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (notificationProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 48,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  notificationProvider.error!,
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        List<NotificationModel> notifications =
            showOnlyUnread
                ? notificationProvider.unreadNotifications
                : notificationProvider.notifications;

        if (maxItems != null && notifications.length > maxItems!) {
          notifications = notifications.take(maxItems!).toList();
        }

        if (notifications.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: padding ?? const EdgeInsets.all(AppSpacing.md),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final notification = notifications[index];
            return _buildNotificationTile(
              context,
              notification,
              notificationProvider,
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                showOnlyUnread
                    ? Icons.notifications_none
                    : Icons.notifications_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              showOnlyUnread ? 'No unread notifications' : 'No notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.white
                        : colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              showOnlyUnread
                  ? 'You\'re all caught up! Great job staying on top of things.'
                  : 'When you receive notifications, they\'ll appear here.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color:
                    theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.8)
                        : colorScheme.onSurface.withValues(alpha: 0.8),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationTile(
    BuildContext context,
    NotificationModel notification,
    NotificationProvider notificationProvider,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          if (!notification.isRead) {
            notificationProvider.markAsRead(notification.id);
          }
          onNotificationSelected?.call(notification);
          onNotificationTap?.call();
        },
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notification icon
              _buildNotificationIcon(context, notification),
              const SizedBox(width: AppSpacing.sm),

              // Notification content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and timestamp
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight:
                                  notification.isRead
                                      ? FontWeight.normal
                                      : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Message
                    Text(
                      notification.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            notification.isRead
                                ? colorScheme.onSurfaceVariant
                                : colorScheme.onSurface,
                      ),
                    ),

                    // Actions (if enabled)
                    if (enableActions && !notification.isRead)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () {
                                notificationProvider.markAsRead(
                                  notification.id,
                                );
                              },
                              child: const Text('Mark as Read'),
                            ),
                            if (enableActions)
                              TextButton(
                                onPressed: () {
                                  notificationProvider.removeNotification(
                                    notification.id,
                                  );
                                },
                                child: const Text('Dismiss'),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Unread indicator
              if (!notification.isRead)
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationIcon(
    BuildContext context,
    NotificationModel notification,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    IconData iconData;
    Color iconColor;

    switch (notification.type) {
      case NotificationType.billCreated:
        iconData = Icons.receipt;
        iconColor = colorScheme.primary;
        break;
      case NotificationType.debtReminder:
        iconData = Icons.account_balance_wallet;
        iconColor = colorScheme.error;
        break;
      case NotificationType.settlementConfirmation:
        iconData = Icons.check_circle;
        iconColor = const Color(0xFF4CAF50); // Success green
        break;
      case NotificationType.groupInvitation:
        iconData = Icons.group_add;
        iconColor = colorScheme.secondary;
        break;
      case NotificationType.paymentReceived:
        iconData = Icons.payment;
        iconColor = const Color(0xFF4CAF50); // Success green
        break;
      case NotificationType.systemAlert:
        iconData = Icons.info;
        iconColor = colorScheme.tertiary;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(iconData, size: 20, color: iconColor),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(timestamp);
    }
  }
}

/// A compact notification summary widget
class NotificationSummary extends StatelessWidget {
  final VoidCallback? onTap;

  const NotificationSummary({Key? key, this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, _) {
        final unreadCount = notificationProvider.unreadCount;
        final totalCount = notificationProvider.notifications.length;

        return InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Icon(Icons.notifications, color: colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Notifications', style: theme.textTheme.titleSmall),
                      Text(
                        unreadCount > 0
                            ? '$unreadCount unread of $totalCount'
                            : 'All caught up!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
