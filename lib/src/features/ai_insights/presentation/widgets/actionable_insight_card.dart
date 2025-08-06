import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/design_system.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/models/ai_insight_model.dart';
import '../../../../routes/route_constants.dart';
import 'severity_indicator.dart';
import 'insight_feedback_widget.dart';

class ActionableInsightCard extends StatelessWidget {
  final AIInsight insight;
  final Function(bool isHelpful)? onFeedback;

  const ActionableInsightCard({
    Key? key,
    required this.insight,
    this.onFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: _getCardDecoration(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with severity and action indicator
            Row(
              children: [
                SeverityIndicator(
                  severity: insight.severity,
                  type: insight.type,
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.bolt, size: 16, color: AppTheme.primaryColor),
                const SizedBox(width: 4),
                Text(
                  'ACTIONABLE',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                if (onFeedback != null)
                  InsightFeedbackWidget(onFeedback: onFeedback!, compact: true),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Title
            Text(
              insight.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Description
            Text(
              insight.description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Smart action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getCardDecoration(ThemeData theme) {
    return DesignSystem.glassContainerElevated(theme).copyWith(
      border: Border.all(
        color: AppTheme.primaryColor.withValues(alpha: 0.2),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = _getContextualActions();

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        // Primary action (full width)
        if (actions.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _handleAction(context, actions.first),
              icon: Icon(actions.first['icon'], size: 18),
              label: Text(actions.first['label']),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
              ),
            ),
          ),

        // Secondary actions (if available)
        if (actions.length > 1) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children:
                actions
                    .skip(1)
                    .take(2)
                    .map(
                      (action) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: action == actions.last ? 0 : AppSpacing.sm,
                          ),
                          child: OutlinedButton.icon(
                            onPressed: () => _handleAction(context, action),
                            icon: Icon(action['icon'], size: 16),
                            label: Text(
                              action['label'],
                              style: const TextStyle(fontSize: 12),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.primaryColor,
                              side: BorderSide(
                                color: AppTheme.primaryColor.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.sm,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ],
    );
  }

  List<Map<String, dynamic>> _getContextualActions() {
    final actions = <Map<String, dynamic>>[];

    // Analyze insight content to suggest relevant actions
    final titleLower = insight.title.toLowerCase();
    final descriptionLower = insight.description.toLowerCase();

    // Spending-related insights
    if (titleLower.contains('spending') ||
        titleLower.contains('expense') ||
        descriptionLower.contains('spending') ||
        descriptionLower.contains('expense')) {
      actions.add({
        'label': 'View Transactions',
        'icon': Icons.receipt_long,
        'route': Routes.transactions,
        'category': 'spending',
      });

      if (descriptionLower.contains('category') ||
          descriptionLower.contains('food') ||
          descriptionLower.contains('entertainment') ||
          descriptionLower.contains('shopping')) {
        actions.add({
          'label': 'Filter Category',
          'icon': Icons.filter_list,
          'route': Routes.transactions,
          'category': 'filter',
        });
      }
    }

    // Goal-related insights
    if (titleLower.contains('goal') ||
        titleLower.contains('saving') ||
        descriptionLower.contains('goal') ||
        descriptionLower.contains('saving')) {
      actions.add({
        'label': 'View Goals',
        'icon': Icons.track_changes,
        'route': Routes.goals,
        'category': 'goals',
      });

      if (descriptionLower.contains('create') ||
          descriptionLower.contains('new') ||
          descriptionLower.contains('set')) {
        actions.add({
          'label': 'Create Goal',
          'icon': Icons.add_task,
          'route': Routes.createGoal,
          'category': 'create',
        });
      }
    }

    // Budget-related insights
    if (titleLower.contains('budget') ||
        titleLower.contains('limit') ||
        descriptionLower.contains('budget') ||
        descriptionLower.contains('over')) {
      actions.add({
        'label': 'View Transactions',
        'icon': Icons.account_balance_wallet,
        'route': Routes.transactions,
        'category': 'budget',
      });
    }

    // Income-related insights
    if (titleLower.contains('income') ||
        titleLower.contains('earning') ||
        descriptionLower.contains('income')) {
      actions.add({
        'label': 'Add Income',
        'icon': Icons.attach_money,
        'route': Routes.createTransaction,
        'category': 'income',
      });
    }

    // GROUPS FUNCTIONALITY COMMENTED OUT
    // Group/bill-related insights
    // if (titleLower.contains('group') ||
    //     titleLower.contains('bill') ||
    //     titleLower.contains('shared') ||
    //     descriptionLower.contains('group') ||
    //     descriptionLower.contains('bill')) {
    //   actions.add({
    //     'label': 'View Groups',
    //     'icon': Icons.group,
    //     'route': Routes.groups,
    //     'category': 'groups',
    //   });
    // }

    // Default general action if no specific match
    if (actions.isEmpty) {
      actions.add({
        'label': 'View Dashboard',
        'icon': Icons.dashboard,
        'route': Routes.dashboard,
        'category': 'general',
      });
    }

    return actions;
  }

  void _handleAction(BuildContext context, Map<String, dynamic> action) {
    final route = action['route'] as String;
    final category = action['category'] as String?;
    final label = action['label'] as String;

    // Validate route before navigation
    if (!Routes.isValidRoute(route)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invalid route: $route'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      // Handle special cases with extra parameters
      if (route == Routes.createTransaction && category == 'income') {
        context.go(route, extra: {'mode': 'create', 'type': 'income'});
      } else {
        context.go(route);
      }
    } catch (e) {
      // Fallback navigation with more descriptive error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to open $label'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'RETRY',
            onPressed: () => _handleAction(context, action),
          ),
        ),
      );
    }
  }
}
