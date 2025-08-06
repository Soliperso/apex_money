import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/design_system.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/models/ai_insight_model.dart';
import '../../../../routes/route_constants.dart';
import 'insight_feedback_widget.dart';

class SmartRecommendationCard extends StatelessWidget {
  final AIRecommendation recommendation;
  final Function(bool isHelpful)? onFeedback;
  final VoidCallback? onMarkComplete;

  const SmartRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onFeedback,
    this.onMarkComplete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: _getCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Simplified header
            Row(
              children: [
                // Simple priority dot
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getPriorityColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor().withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    recommendation.priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: _getPriorityColor(),
                    ),
                  ),
                ),
                const Spacer(),
                if (onFeedback != null)
                  InsightFeedbackWidget(onFeedback: onFeedback!, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),

            // Title
            Text(
              recommendation.title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Simplified description
            Text(
              recommendation.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.sm),

            // Simplified bottom row
            Row(
              children: [
                // Compact savings info
                Icon(Icons.savings, size: 14, color: AppTheme.successColor),
                const SizedBox(width: 4),
                Text(
                  recommendation.potentialSavings,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.successColor,
                  ),
                ),
                const Spacer(),

                // Simple action button
                TextButton(
                  onPressed: () => _handleSimpleAction(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Take Action',
                    style: TextStyle(
                      fontSize: 12,
                      color: _getPriorityColor(),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getCardDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final priorityColor = _getPriorityColor();

    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer.withValues(alpha: 0.3)
              : colorScheme.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border.all(
        color: priorityColor.withValues(alpha: 0.15),
        width: 1,
      ),
    );
  }

  /// Simplified action handler
  void _handleSimpleAction(BuildContext context) {
    final actions = _getRecommendationActions();

    if (actions.isNotEmpty) {
      _handleRecommendationAction(context, actions.first);
    } else if (onMarkComplete != null) {
      onMarkComplete!();
    } else {
      // Show dialog with action suggestion
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: Text(recommendation.title),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendation.description),
                  const SizedBox(height: 16),
                  Text(
                    'Suggested Action: ${recommendation.action}',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Close'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    if (onMarkComplete != null) onMarkComplete!();
                  },
                  child: Text('Mark Complete'),
                ),
              ],
            ),
      );
    }
  }

  Color _getPriorityColor() {
    switch (recommendation.priority.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
      default:
        return AppTheme.primaryColor;
    }
  }

  List<Map<String, dynamic>> _getRecommendationActions() {
    final actions = <Map<String, dynamic>>[];

    // Analyze recommendation content for smart actions
    final titleLower = recommendation.title.toLowerCase();
    final actionLower = recommendation.action.toLowerCase();
    final descriptionLower = recommendation.description.toLowerCase();

    // Budget/spending recommendations
    if (titleLower.contains('budget') ||
        titleLower.contains('spending') ||
        actionLower.contains('budget') ||
        actionLower.contains('limit')) {
      actions.add({
        'label': 'View Transactions',
        'icon': Icons.account_balance_wallet,
        'route': '/transactions',
      });
    }

    // Savings/goal recommendations
    if (titleLower.contains('save') ||
        titleLower.contains('goal') ||
        actionLower.contains('save') ||
        actionLower.contains('goal')) {
      actions.add({
        'label': 'Create Goal',
        'icon': Icons.flag,
        'route': '/create-goal',
      });
    }

    // Transaction/expense recommendations
    if (titleLower.contains('expense') ||
        titleLower.contains('transaction') ||
        actionLower.contains('track') ||
        actionLower.contains('record')) {
      actions.add({
        'label': 'Add Expense',
        'icon': Icons.receipt,
        'route': '/create-transaction',
      });
    }

    // Category-specific recommendations
    if (descriptionLower.contains('food') ||
        descriptionLower.contains('dining') ||
        descriptionLower.contains('restaurant')) {
      actions.add({
        'label': 'View Food Expenses',
        'icon': Icons.restaurant,
        'route': '/transactions',
      });
    }

    // Investment recommendations
    if (titleLower.contains('invest') || actionLower.contains('invest')) {
      actions.add({
        'label': 'View Transactions',
        'icon': Icons.trending_up,
        'route': '/transactions',
      });
    }

    return actions;
  }

  void _handleRecommendationAction(
    BuildContext context,
    Map<String, dynamic> action,
  ) {
    final route = action['route'] as String;

    try {
      // Handle special cases with extra parameters
      if (route == '/create-transaction') {
        context.go(route, extra: {'mode': 'create'});
      } else if (route == '/create-goal') {
        context.go(route);
      } else {
        context.go(route);
      }
    } catch (e) {
      // Fallback - show completion dialog
      if (onMarkComplete != null) {
        onMarkComplete!();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening ${action['label']}...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }
}
