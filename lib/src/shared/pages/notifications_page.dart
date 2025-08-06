import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_list.dart';
import '../widgets/app_gradient_background.dart';
import '../theme/app_spacing.dart';
import '../models/notification_model.dart';

/// Page for displaying and managing notifications
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppGradientBackground(
        child: Column(
          children: [
            // Custom App Bar
            _buildAppBar(context),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color:
                    theme.brightness == Brightness.dark
                        ? colorScheme.surface
                        : colorScheme.primary,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [Tab(text: 'All'), Tab(text: 'Unread')],
                labelColor:
                    theme.brightness == Brightness.dark
                        ? colorScheme.primary
                        : Colors.white,
                unselectedLabelColor:
                    theme.brightness == Brightness.dark
                        ? colorScheme.onSurfaceVariant
                        : Colors.white.withValues(alpha: 0.7),
                indicatorColor:
                    theme.brightness == Brightness.dark
                        ? colorScheme.primary
                        : Colors.white,
                dividerColor: Colors.transparent,
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // All notifications
                  NotificationList(
                    showOnlyUnread: false,
                    onNotificationSelected: _handleNotificationTap,
                  ),

                  // Unread notifications
                  NotificationList(
                    showOnlyUnread: true,
                    onNotificationSelected: _handleNotificationTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + AppSpacing.sm,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surface : colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(AppSpacing.radiusLg),
          bottomRight: Radius.circular(AppSpacing.radiusLg),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => context.pop(),
            icon: Icon(
              Icons.arrow_back,
              color: isDark ? colorScheme.onSurface : Colors.white,
            ),
            tooltip: 'Back',
          ),

          const SizedBox(width: AppSpacing.md),

          // Title
          Expanded(
            child: Text(
              'Notifications',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? colorScheme.onSurface : Colors.white,
              ),
            ),
          ),

          // Action buttons
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, _) {
              final hasUnread = notificationProvider.unreadCount > 0;
              final hasAny = notificationProvider.notifications.isNotEmpty;

              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mark all as read
                  if (hasUnread)
                    TextButton(
                      onPressed: () {
                        notificationProvider.markAllAsRead();
                        _showSnackBar(
                          context,
                          'All notifications marked as read',
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor:
                            isDark ? colorScheme.onSurface : Colors.white,
                      ),
                      child: const Text('Mark all read'),
                    ),

                  // More options menu
                  if (hasAny)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleMenuAction(context, value),
                      itemBuilder:
                          (context) => [
                            const PopupMenuItem(
                              value: 'clear_all',
                              child: Row(
                                children: [
                                  Icon(Icons.clear_all),
                                  SizedBox(width: 8),
                                  Text('Clear all'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'cleanup',
                              child: Row(
                                children: [
                                  Icon(Icons.cleaning_services),
                                  SizedBox(width: 8),
                                  Text('Cleanup old'),
                                ],
                              ),
                            ),
                          ],
                      icon: Icon(
                        Icons.more_vert,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Navigate to relevant page based on notification type
    switch (notification.type) {
      // GROUPS-RELATED NOTIFICATIONS - NO NAVIGATION (groups functionality disabled)
      case NotificationType.billCreated:
        // Groups functionality disabled - no navigation
        break;
      case NotificationType.debtReminder:
        // Groups functionality disabled - no navigation
        break;
      case NotificationType.settlementConfirmation:
        // Groups functionality disabled - no navigation
        break;
      case NotificationType.groupInvitation:
        // Groups functionality disabled - no navigation
        break;
      case NotificationType.paymentReceived:
        // Navigate to transactions page
        context.go('/transactions');
        break;
      case NotificationType.systemAlert:
        // Stay on notifications page or navigate to settings
        break;
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    final notificationProvider = Provider.of<NotificationProvider>(
      context,
      listen: false,
    );

    switch (action) {
      case 'clear_all':
        _showConfirmationDialog(
          context,
          'Clear All Notifications',
          'Are you sure you want to clear all notifications? This action cannot be undone.',
          () {
            notificationProvider.clearAllNotifications();
            _showSnackBar(context, 'All notifications cleared');
          },
        );
        break;
      case 'cleanup':
        notificationProvider.cleanupOldNotifications();
        _showSnackBar(context, 'Old notifications cleaned up');
        break;
    }
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onConfirm();
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }
}

/// A simple notification sheet that can be shown as a modal
class NotificationSheet extends StatelessWidget {
  final int maxItems;
  final bool showActions;

  const NotificationSheet({
    Key? key,
    this.maxItems = 10,
    this.showActions = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.95)
                : colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: AppSpacing.sm),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Consumer<NotificationProvider>(
                  builder: (context, notificationProvider, _) {
                    final unreadCount = notificationProvider.unreadCount;

                    return Row(
                      children: [
                        if (unreadCount > 0)
                          TextButton(
                            onPressed: () {
                              notificationProvider.markAllAsRead();
                            },
                            child: const Text('Mark all read'),
                          ),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            // Use a small delay to ensure the bottom sheet is fully dismissed
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                if (context.mounted) {
                                  context.push('/notifications');
                                }
                              },
                            );
                          },
                          child: const Text('See all'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // Notifications list
          Flexible(
            child: NotificationList(
              maxItems: maxItems,
              enableActions: showActions,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              onNotificationTap: () => Navigator.of(context).pop(),
            ),
          ),

          // Safe area padding
          SizedBox(
            height: MediaQuery.of(context).padding.bottom + AppSpacing.md,
          ),
        ],
      ),
    );
  }
}

/// Helper function to show notification sheet
void showNotificationSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.7,
    ),
    builder: (context) => const NotificationSheet(),
  );
}
