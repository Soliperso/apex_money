import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/error_boundary.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/utils/currency_formatter.dart';

class GroupActivityPage extends StatefulWidget {
  final String groupId;

  const GroupActivityPage({super.key, required this.groupId});

  @override
  State<GroupActivityPage> createState() => _GroupActivityPageState();
}

class _GroupActivityPageState extends State<GroupActivityPage> {
  final BillService _billService = BillService();

  List<ActivityEvent> _activities = [];
  GroupWithMembersModel? _group;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load group data
      final provider = context.read<GroupsProvider>();
      _group = provider.getGroupById(widget.groupId);

      if (_group == null) {
        await provider.loadGroups();
        _group = provider.getGroupById(widget.groupId);
      }

      if (_group == null) {
        throw Exception('Group not found');
      }

      // Load bills and create activity timeline
      final bills = await _billService.fetchGroupBills(widget.groupId);

      // Convert bills to activity events
      final activities = <ActivityEvent>[];

      for (final bill in bills) {
        // Add bill creation event
        final payer =
            _group!.members
                .where((m) => m.userId == bill.paidByUserId)
                .firstOrNull;

        activities.add(
          ActivityEvent(
            id: '${bill.id}_created',
            type: ActivityType.billCreated,
            timestamp: bill.dateCreated,
            title: 'Bill created: ${bill.title}',
            description:
                'Created by ${payer?.userName ?? "Unknown"} for ${CurrencyFormatter.format(bill.totalAmount)}',
            relatedBillId: bill.id,
            amount: bill.totalAmount,
            userId: bill.paidByUserId,
          ),
        );

        // Add settlement events for paid splits
        for (final split in bill.splits.where(
          (s) => s.isPaid && s.paidDate != null,
        )) {
          final member =
              _group!.members
                  .where((m) => m.userId == split.userId)
                  .firstOrNull;

          activities.add(
            ActivityEvent(
              id: '${bill.id}_${split.userId}_paid',
              type: ActivityType.paymentMade,
              timestamp: split.paidDate!,
              title: 'Payment received',
              description:
                  '${member?.userName ?? "Unknown"} paid ${CurrencyFormatter.format(split.amount)} for "${bill.title}"',
              relatedBillId: bill.id,
              amount: split.amount,
              userId: split.userId,
            ),
          );
        }

        // Add bill settlement event if fully settled
        if (bill.status == 'settled') {
          final lastPayment = bill.splits
              .where((s) => s.isPaid && s.paidDate != null)
              .map((s) => s.paidDate!)
              .reduce((a, b) => a.isAfter(b) ? a : b);

          activities.add(
            ActivityEvent(
              id: '${bill.id}_settled',
              type: ActivityType.billSettled,
              timestamp: lastPayment,
              title: 'Bill fully settled',
              description: '"${bill.title}" has been completely settled',
              relatedBillId: bill.id,
              amount: bill.totalAmount,
              userId: bill.paidByUserId,
            ),
          );
        }
      }

      // Sort activities by timestamp (newest first)
      activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      setState(() {
        _activities = activities;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breadcrumb navigation
            Row(
              children: [
                Icon(
                  Icons.group,
                  size: 14,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
                const SizedBox(width: 4),
                Text(
                  'Groups',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? colorScheme.onSurface.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
                if (_group != null)
                  Flexible(
                    child: Text(
                      _group!.group.name,
                      style: TextStyle(
                        fontSize: 11,
                        color:
                            isDark
                                ? colorScheme.onSurface.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.7),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
            // Page title
            Text(
              'Activity Timeline',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: isDark ? colorScheme.onSurface : Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
      ),
      body: AppGradientBackground(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return ErrorBoundary(
        errorTitle: 'Unable to Load Activity',
        errorMessage:
            'There was a problem loading the group activity timeline.',
        onRetry: () {
          HapticService().buttonPress();
          _loadData();
        },
        child: const SizedBox.shrink(),
      );
    }

    if (_activities.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _activities.length,
        itemBuilder: (context, index) {
          return withErrorBoundary(
            _buildActivityTile(_activities[index], index),
            errorTitle: 'Activity Display Error',
            errorMessage: 'Unable to display this activity.',
            onRetry: _loadData,
          );
        },
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          8,
          (index) => const SkeletonCard(
            height: 80,
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              Row(
                children: [
                  SkeletonAvatar(size: 40),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(height: 16, width: 200),
                        SizedBox(height: 6),
                        SkeletonText(height: 12, width: 150),
                      ],
                    ),
                  ),
                  SkeletonText(height: 12, width: 60),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline_outlined,
            size: 64,
            color: colorScheme.outline.withValues(alpha: 0.5),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No activity yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Group activity will appear here as bills are created and settled',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTile(ActivityEvent activity, int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final member =
        _group?.members.where((m) => m.userId == activity.userId).firstOrNull;

    final activityColor = _getActivityColor(activity.type, colorScheme);
    final activityIcon = _getActivityIcon(activity.type);

    // Group activities by day
    final isNewDay =
        index == 0 ||
        !_isSameDay(_activities[index - 1].timestamp, activity.timestamp);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date header
        if (isNewDay) ...[
          Padding(
            padding: EdgeInsets.only(
              top: index == 0 ? 0 : AppSpacing.lg,
              bottom: AppSpacing.md,
            ),
            child: Text(
              _formatDateHeader(activity.timestamp),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],

        // Activity item
        Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          decoration: BoxDecoration(
            color:
                isDark
                    ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                    : colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap:
                activity.relatedBillId != null
                    ? () => _navigateToBillDetail(activity.relatedBillId!)
                    : null,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Activity icon
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: activityColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(activityIcon, color: activityColor, size: 20),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Activity content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          activity.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activity.description,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Time and amount
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _formatTime(activity.timestamp),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (activity.amount != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          CurrencyFormatter.format(activity.amount!),
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: _getAmountColor(activity.type, colorScheme),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getActivityColor(ActivityType type, ColorScheme colorScheme) {
    switch (type) {
      case ActivityType.billCreated:
        return colorScheme.primary;
      case ActivityType.paymentMade:
        return Colors.green;
      case ActivityType.billSettled:
        return Colors.blue;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getActivityIcon(ActivityType type) {
    switch (type) {
      case ActivityType.billCreated:
        return Icons.receipt_long;
      case ActivityType.paymentMade:
        return Icons.payment;
      case ActivityType.billSettled:
        return Icons.check_circle;
      default:
        return Icons.event;
    }
  }

  Color _getAmountColor(ActivityType type, ColorScheme colorScheme) {
    switch (type) {
      case ActivityType.paymentMade:
      case ActivityType.billSettled:
        return Colors.green;
      case ActivityType.billCreated:
        return colorScheme.primary;
      default:
        return colorScheme.onSurface;
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final targetDate = DateTime(date.year, date.month, date.day);

    if (targetDate == today) {
      return 'Today';
    } else if (targetDate == yesterday) {
      return 'Yesterday';
    } else {
      final months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    }
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _navigateToBillDetail(String billId) {
    HapticService().light();
    context.go('/groups/${widget.groupId}/bills/$billId');
  }
}

// Activity models
enum ActivityType { billCreated, paymentMade, billSettled }

class ActivityEvent {
  final String id;
  final ActivityType type;
  final DateTime timestamp;
  final String title;
  final String description;
  final String? relatedBillId;
  final double? amount;
  final String userId;

  ActivityEvent({
    required this.id,
    required this.type,
    required this.timestamp,
    required this.title,
    required this.description,
    this.relatedBillId,
    this.amount,
    required this.userId,
  });
}
