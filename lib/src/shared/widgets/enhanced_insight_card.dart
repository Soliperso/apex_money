import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_theme.dart';
import '../theme/app_spacing.dart';
import '../theme/design_system.dart';
import '../models/ai_insight_model.dart';

/// Enhanced insight card that transforms complex AI analysis into
/// clear, actionable, and user-friendly interface elements
class EnhancedInsightCard extends StatelessWidget {
  final AIInsight insight;
  final VoidCallback? onTap;
  final bool showActions;
  final bool showConfidenceLevel;

  const EnhancedInsightCard({
    Key? key,
    required this.insight,
    this.onTap,
    this.showActions = true,
    this.showConfidenceLevel = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: DesignSystem.glassContainer(theme),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                const SizedBox(height: AppSpacing.md),
                _buildDescription(context),
                if (showConfidenceLevel) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildConfidenceIndicator(context),
                ],
                if (showActions) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _buildActionButtons(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final insightColor = _getInsightColor();
    final urgencyData = _getUrgencyData();

    return Row(
      children: [
        // Visual urgency indicator
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: insightColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(urgencyData['icon'], color: insightColor, size: 20),
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
                      _getSimplifiedTitle(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  _buildSeverityBadge(context),
                ],
              ),
              if (urgencyData['timeframe'] != null) ...[
                const SizedBox(height: 2),
                Text(
                  urgencyData['timeframe'],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: insightColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getSimplifiedDescription(),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            height: 1.4,
          ),
        ),
        if (_hasFinancialImpact()) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildImpactIndicator(context),
        ],
      ],
    );
  }

  Widget _buildImpactIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final impactData = _getFinancialImpact();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.infoColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: AppTheme.infoColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up_rounded, size: 16, color: AppTheme.infoColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            impactData,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.infoColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfidenceIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final confidence = _getConfidenceLevel();

    return Row(
      children: [
        Icon(
          Icons.psychology_rounded,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          'Confidence: ${confidence.level}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: LinearProgressIndicator(
            value: confidence.value,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(confidence.color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }

  Widget _buildSeverityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final severityData = _getSeverityData();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: severityData['color'].withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        border: Border.all(
          color: severityData['color'].withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        severityData['label'],
        style: theme.textTheme.labelSmall?.copyWith(
          color: severityData['color'],
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final actions = _getContextualActions();

    if (actions.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.xs,
      children:
          actions.map((action) => _buildActionButton(context, action)).toList(),
    );
  }

  Widget _buildActionButton(BuildContext context, Map<String, dynamic> action) {
    final theme = Theme.of(context);
    final isPrimary = action['isPrimary'] == true;

    return isPrimary
        ? ElevatedButton.icon(
          onPressed: () => _handleAction(context, action),
          icon: Icon(action['icon'], size: 16),
          label: Text(action['label']),
          style: ElevatedButton.styleFrom(
            backgroundColor: _getInsightColor(),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        )
        : OutlinedButton.icon(
          onPressed: () => _handleAction(context, action),
          icon: Icon(action['icon'], size: 16),
          label: Text(action['label']),
          style: OutlinedButton.styleFrom(
            foregroundColor: theme.colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),
        );
  }

  // Helper methods for insight analysis and simplification

  String _getSimplifiedTitle() {
    // Transform technical titles into user-friendly language
    final title = insight.title.toLowerCase();

    if (title.contains('spending increase') || title.contains('expense')) {
      return '💸 Higher Spending Alert';
    } else if (title.contains('goal') && title.contains('achievement')) {
      return '🎯 Goal Progress Update';
    } else if (title.contains('category') && title.contains('alert')) {
      return '📊 Spending Pattern Notice';
    } else if (title.contains('daily spending')) {
      return '📅 Daily Budget Check';
    } else if (title.contains('velocity') || title.contains('trend')) {
      return '📈 Spending Trend Analysis';
    }

    return insight.title;
  }

  String _getSimplifiedDescription() {
    // Transform technical descriptions into plain language
    String description = insight.description;

    // Replace financial jargon with simple terms
    description = description
        .replaceAll('spending velocity', 'spending rate')
        .replaceAll('category concentration', 'category focus')
        .replaceAll('anomalies detected', 'unusual patterns found')
        .replaceAll('deceleration', 'slowdown')
        .replaceAll('acceleration', 'increase');

    // Add context and explanation
    if (insight.type == 'negative' && insight.severity == 'high') {
      description +=
          '\n\n💡 This needs your attention to keep your finances on track.';
    } else if (insight.type == 'positive') {
      description += '\n\n✨ This is a positive trend in your financial habits.';
    }

    return description;
  }

  Color _getInsightColor() {
    switch (insight.type) {
      case 'positive':
        return AppTheme.successColor;
      case 'negative':
        return insight.severity == 'high'
            ? AppTheme.errorColor
            : AppTheme.warningColor;
      case 'neutral':
      default:
        return AppTheme.infoColor;
    }
  }

  Map<String, dynamic> _getUrgencyData() {
    if (insight.severity == 'high' && insight.type == 'negative') {
      return {'icon': Icons.warning_rounded, 'timeframe': 'Action needed soon'};
    } else if (insight.severity == 'high' && insight.type == 'positive') {
      return {
        'icon': Icons.celebration_rounded,
        'timeframe': 'Great progress!',
      };
    } else if (insight.severity == 'medium') {
      return {'icon': Icons.info_rounded, 'timeframe': 'Worth monitoring'};
    } else {
      return {'icon': Icons.insights_rounded, 'timeframe': null};
    }
  }

  Map<String, dynamic> _getSeverityData() {
    switch (insight.severity) {
      case 'high':
        return {
          'label': 'PRIORITY',
          'color':
              insight.type == 'negative'
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
        };
      case 'medium':
        return {'label': 'REVIEW', 'color': AppTheme.warningColor};
      case 'low':
      default:
        return {'label': 'INFO', 'color': AppTheme.infoColor};
    }
  }

  bool _hasFinancialImpact() {
    // Check if the insight mentions financial amounts or percentages
    final description = insight.description.toLowerCase();
    return description.contains('\$') ||
        description.contains('%') ||
        description.contains('percent') ||
        description.contains('savings') ||
        description.contains('budget');
  }

  String _getFinancialImpact() {
    final description = insight.description;

    // Extract financial impact information
    if (description.contains('increased') && description.contains('%')) {
      final match = RegExp(r'(\d+)%').firstMatch(description);
      if (match != null) {
        return 'Impact: ${match.group(1)}% change';
      }
    }

    if (description.contains('\$')) {
      final match = RegExp(
        r'\$(\d+(?:,\d{3})*(?:\.\d{2})?)',
      ).firstMatch(description);
      if (match != null) {
        return 'Amount: \$${match.group(1)}';
      }
    }

    return 'Financial impact detected';
  }

  ({String level, double value, Color color}) _getConfidenceLevel() {
    // Calculate confidence based on insight characteristics
    double confidence = 0.7; // Default confidence

    if (insight.description.contains('detected') ||
        insight.description.contains('analysis')) {
      confidence = 0.85;
    } else if (insight.description.contains('suggests') ||
        insight.description.contains('may')) {
      confidence = 0.6;
    }

    String level;
    Color color;

    if (confidence >= 0.8) {
      level = 'High';
      color = AppTheme.successColor;
    } else if (confidence >= 0.6) {
      level = 'Medium';
      color = AppTheme.warningColor;
    } else {
      level = 'Low';
      color = AppTheme.errorColor;
    }

    return (level: level, value: confidence, color: color);
  }

  List<Map<String, dynamic>> _getContextualActions() {
    final actions = <Map<String, dynamic>>[];

    // Determine relevant actions based on insight content
    final title = insight.title.toLowerCase();
    final description = insight.description.toLowerCase();

    if (description.contains('spending') || description.contains('expense')) {
      actions.add({
        'label': 'View Transactions',
        'icon': Icons.receipt_long_rounded,
        'route': '/transactions',
        'isPrimary': false,
      });
    }

    if (description.contains('goal') || description.contains('saving')) {
      actions.add({
        'label': 'Check Goals',
        'icon': Icons.flag_rounded,
        'route': '/goals',
        'isPrimary': false,
      });
    }

    if (description.contains('category') || description.contains('budget')) {
      actions.add({
        'label': 'Review Budget',
        'icon': Icons.pie_chart_rounded,
        'route': '/transactions',
        'isPrimary': false,
      });
    }

    // Always include "Learn More" for complex insights
    if (insight.severity == 'high' || description.length > 100) {
      actions.add({
        'label': 'Learn More',
        'icon': Icons.info_outline_rounded,
        'action': 'showDetails',
        'isPrimary': true,
      });
    }

    return actions;
  }

  void _handleAction(BuildContext context, Map<String, dynamic> action) {
    if (action['route'] != null) {
      context.go(action['route']);
    } else if (action['action'] == 'showDetails') {
      _showInsightDetails(context);
    }
  }

  void _showInsightDetails(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Insight Details'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    insight.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(insight.description),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'How this helps you:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(_getInsightExplanation()),
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

  String _getInsightExplanation() {
    // Provide educational context about why this insight matters
    switch (insight.type) {
      case 'negative':
        return 'This insight helps you identify potential areas where you might be overspending or developing concerning financial habits. Taking action now can help improve your financial health.';
      case 'positive':
        return 'This insight highlights positive changes in your financial behavior. Understanding what\'s working well can help you maintain good habits and apply them to other areas.';
      case 'neutral':
      default:
        return 'This insight provides information about your spending patterns. Use it to better understand your financial habits and make informed decisions.';
    }
  }
}
