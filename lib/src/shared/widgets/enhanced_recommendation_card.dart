import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/design_system.dart';
import '../models/ai_insight_model.dart';

/// Enhanced recommendation card that presents AI recommendations
/// with clear value propositions, confidence levels, and guided actions
class EnhancedRecommendationCard extends StatelessWidget {
  final AIRecommendation recommendation;
  final VoidCallback? onImplement;
  final VoidCallback? onDismiss;
  final bool showImplementationGuide;

  const EnhancedRecommendationCard({
    Key? key,
    required this.recommendation,
    this.onImplement,
    this.onDismiss,
    this.showImplementationGuide = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: DesignSystem.glassContainerElevated(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: AppSpacing.md),
            _buildDescription(context),
            const SizedBox(height: AppSpacing.md),
            _buildValueProposition(context),
            if (showImplementationGuide) ...[
              const SizedBox(height: AppSpacing.md),
              _buildImplementationGuide(context),
            ],
            const SizedBox(height: AppSpacing.lg),
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final priorityData = _getPriorityData();

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: priorityData['color'].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            priorityData['icon'],
            color: priorityData['color'],
            size: 24,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _getActionableTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildPriorityBadge(context),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _getTimeframeEstimate(),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: priorityData['color'],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      _getPersonalizedDescription(),
      style: theme.textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurfaceVariant,
        height: 1.4,
      ),
    );
  }

  Widget _buildValueProposition(BuildContext context) {
    final theme = Theme.of(context);
    final savingsData = _parseSavingsData();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.successColor.withValues(alpha: 0.1),
            AppTheme.successColor.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppTheme.successColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.savings_rounded, color: AppTheme.successColor, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Potential Impact',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  savingsData['display'],
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppTheme.successColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (savingsData['confidence'] != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: AppTheme.successColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
              child: Text(
                '${savingsData['confidence']}% confidence',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppTheme.successColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildImplementationGuide(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final steps = _getImplementationSteps();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to implement:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.primaryColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    step,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildPriorityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final priorityData = _getPriorityData();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: priorityData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(
          color: priorityData['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        priorityData['label'],
        style: theme.textTheme.labelSmall?.copyWith(
          color: priorityData['color'],
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final primaryAction = _getPrimaryAction();

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _handlePrimaryAction(context),
            icon: Icon(primaryAction['icon'], size: 18),
            label: Text(primaryAction['label']),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getPriorityData()['color'],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => _showMoreDetails(context),
          icon: Icon(Icons.info_outline_rounded, size: 18),
          label: Text('Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
          ),
        ),
        if (onDismiss != null) ...[
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close_rounded),
            tooltip: 'Dismiss',
          ),
        ],
      ],
    );
  }

  // Helper methods for recommendation enhancement

  String _getActionableTitle() {
    // Transform generic titles into specific, actionable language
    final title = recommendation.title.toLowerCase();

    if (title.contains('reduce') && title.contains('food')) {
      return '🍽️ Optimize Food Spending';
    } else if (title.contains('budget')) {
      return '📊 Set Smart Budget Limits';
    } else if (title.contains('saving')) {
      return '💰 Boost Your Savings';
    } else if (title.contains('goal')) {
      return '🎯 Accelerate Goal Progress';
    } else if (title.contains('expense')) {
      return '📉 Cut Unnecessary Expenses';
    }

    return recommendation.title;
  }

  String _getPersonalizedDescription() {
    String description = recommendation.description;

    // Make descriptions more personal and specific
    description = description
        .replaceAll('You\'re spending', 'Your current spending is')
        .replaceAll('You should', 'Consider')
        .replaceAll('recommended', 'suggested based on your patterns');

    // Add contextual encouragement
    if (recommendation.priority == 'high') {
      description +=
          '\n\nThis change could have a significant positive impact on your financial health.';
    } else if (recommendation.priority == 'medium') {
      description +=
          '\n\nImplementing this gradually will help improve your financial habits.';
    }

    return description;
  }

  String _getTimeframeEstimate() {
    // Provide realistic timeframe estimates
    switch (recommendation.priority) {
      case 'high':
        return 'Implement this week';
      case 'medium':
        return 'Start within 2 weeks';
      case 'low':
      default:
        return 'Consider for next month';
    }
  }

  Map<String, dynamic> _getPriorityData() {
    switch (recommendation.priority) {
      case 'high':
        return {
          'label': 'HIGH IMPACT',
          'color': AppTheme.errorColor,
          'icon': Icons.priority_high_rounded,
        };
      case 'medium':
        return {
          'label': 'GOOD OPPORTUNITY',
          'color': AppTheme.warningColor,
          'icon': Icons.trending_up_rounded,
        };
      case 'low':
      default:
        return {
          'label': 'WORTH CONSIDERING',
          'color': AppTheme.infoColor,
          'icon': Icons.lightbulb_outline_rounded,
        };
    }
  }

  Map<String, dynamic> _parseSavingsData() {
    final savings = recommendation.potentialSavings;

    if (savings.contains('\$')) {
      // Extract monetary amount
      final match = RegExp(
        r'\$(\d+(?:,\d{3})*(?:\.\d{2})?)',
      ).firstMatch(savings);
      if (match != null) {
        final amount = match.group(1)!;
        return {
          'display': '\$${amount} potential savings',
          'confidence': _estimateConfidence(),
        };
      }
    }

    if (savings.contains('%')) {
      // Extract percentage
      final match = RegExp(r'(\d+)%').firstMatch(savings);
      if (match != null) {
        final percent = match.group(1)!;
        return {
          'display': '${percent}% reduction possible',
          'confidence': _estimateConfidence(),
        };
      }
    }

    return {
      'display': savings.isNotEmpty ? savings : 'Positive financial impact',
      'confidence': null,
    };
  }

  int _estimateConfidence() {
    // Estimate confidence based on recommendation characteristics
    if (recommendation.action.contains('specific') ||
        recommendation.action.contains('set')) {
      return 85;
    } else if (recommendation.action.contains('consider') ||
        recommendation.action.contains('try')) {
      return 70;
    } else {
      return 60;
    }
  }

  List<String> _getImplementationSteps() {
    final action = recommendation.action.toLowerCase();

    if (action.contains('budget')) {
      return [
        'Review your current spending in this category',
        'Set a realistic monthly limit based on your income',
        'Use the app to track and monitor your progress',
        'Adjust the budget after 2-3 weeks if needed',
      ];
    } else if (action.contains('reduce') || action.contains('cut')) {
      return [
        'Identify your highest expenses in this area',
        'Look for alternatives or ways to optimize',
        'Start with small reductions to build the habit',
        'Track your progress and celebrate small wins',
      ];
    } else if (action.contains('save') || action.contains('goal')) {
      return [
        'Set up a specific savings goal in the app',
        'Automate transfers to make saving easier',
        'Review and adjust your goal monthly',
        'Celebrate milestones along the way',
      ];
    } else {
      return [
        'Start by reviewing your current patterns',
        'Make small, gradual changes',
        'Track your progress regularly',
        'Adjust your approach based on results',
      ];
    }
  }

  Map<String, dynamic> _getPrimaryAction() {
    final action = recommendation.action.toLowerCase();

    if (action.contains('budget') || action.contains('set')) {
      return {
        'label': 'Create Budget',
        'icon': Icons.pie_chart_rounded,
        'route': '/transactions',
      };
    } else if (action.contains('goal')) {
      return {
        'label': 'Set Goal',
        'icon': Icons.flag_rounded,
        'route': '/goals',
      };
    } else if (action.contains('transaction') || action.contains('expense')) {
      return {
        'label': 'View Expenses',
        'icon': Icons.receipt_long_rounded,
        'route': '/transactions',
      };
    } else {
      return {
        'label': 'Take Action',
        'icon': Icons.rocket_launch_rounded,
        'action': 'implement',
      };
    }
  }

  void _handlePrimaryAction(BuildContext context) {
    final primaryAction = _getPrimaryAction();

    if (primaryAction['route'] != null) {
      context.go(primaryAction['route']);
    } else if (onImplement != null) {
      onImplement!();
    }
  }

  void _showMoreDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Recommendation Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    recommendation.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'What this means:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(recommendation.description),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Recommended action:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(recommendation.action),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Why this helps:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_getRecommendationRationale()),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Got it'),
              ),
            ],
          ),
    );
  }

  String _getRecommendationRationale() {
    // Provide educational context about why this recommendation matters
    switch (recommendation.priority) {
      case 'high':
        return 'This recommendation addresses a significant opportunity to improve your financial situation. Acting on it could lead to meaningful positive changes in your financial health and help you reach your goals faster.';
      case 'medium':
        return 'This recommendation represents a good opportunity to optimize your financial habits. While not urgent, implementing it could provide steady improvements over time.';
      case 'low':
      default:
        return 'This recommendation offers a way to fine-tune your financial habits. Consider it when you\'re ready to make additional optimizations to your spending or saving patterns.';
    }
  }
}
