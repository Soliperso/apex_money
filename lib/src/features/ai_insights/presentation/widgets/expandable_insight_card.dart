import 'package:flutter/material.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/design_system.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/models/ai_insight_model.dart';
import 'severity_indicator.dart';
import 'insight_feedback_widget.dart';

class ExpandableInsightCard extends StatefulWidget {
  final AIInsight insight;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Function(bool isHelpful)? onFeedback;

  const ExpandableInsightCard({
    Key? key,
    required this.insight,
    this.onAction,
    this.actionLabel,
    this.onFeedback,
  }) : super(key: key);

  @override
  State<ExpandableInsightCard> createState() => _ExpandableInsightCardState();
}

class _ExpandableInsightCardState extends State<ExpandableInsightCard>
    with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: _getCardDecoration(theme),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        child: Column(
          children: [
            // Main card content
            InkWell(
              onTap: _toggleExpanded,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Simplified header
                    Row(
                      children: [
                        // Simple colored dot instead of complex severity indicator
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _getSeverityColor(),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            widget.insight.title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                        Icon(
                          _isExpanded ? Icons.expand_less : Icons.expand_more,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Brief description with better spacing
                    Text(
                      _getBriefDescription(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.3,
                      ),
                    ),

                    // Quick action button (if available and not expanded)
                    if (widget.onAction != null &&
                        widget.actionLabel != null &&
                        !_isExpanded) ...[
                      const SizedBox(height: AppSpacing.md),
                      _buildQuickActionButton(theme),
                    ],
                  ],
                ),
              ),
            ),

            // Expandable detailed content
            SizeTransition(
              sizeFactor: _expandAnimation,
              child: _buildExpandedContent(theme),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _getCardDecoration(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    // Simplified decoration with minimal visual noise
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? colorScheme.surfaceContainer.withValues(alpha: 0.3)
              : colorScheme.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      border: Border.all(
        color: _getSeverityColor().withValues(alpha: 0.15),
        width: 1,
      ),
    );
  }

  String _getBriefDescription() {
    // Show first sentence or first 100 characters
    final description = widget.insight.description;
    final firstSentence = description.split('.').first;

    if (firstSentence.length < 100) {
      return '$firstSentence.';
    }

    if (description.length <= 100) {
      return description;
    }

    return '${description.substring(0, 97)}...';
  }

  Widget _buildQuickActionButton(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: widget.onAction,
        icon: Icon(_getActionIcon(), size: 16),
        label: Text(widget.actionLabel!),
        style: OutlinedButton.styleFrom(
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Detailed description
          if (widget.insight.description.length >
              _getBriefDescription().length) ...[
            Text(
              'Details',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              widget.insight.description,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // Impact analysis
          _buildImpactAnalysis(theme),
          const SizedBox(height: AppSpacing.md),

          // Action buttons row
          Row(
            children: [
              // Main action button
              if (widget.onAction != null && widget.actionLabel != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: widget.onAction,
                    icon: Icon(_getActionIcon(), size: 16),
                    label: Text(widget.actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getSeverityColor().withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: _getSeverityColor(),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
              ],

              // Feedback widget
              if (widget.onFeedback != null)
                InsightFeedbackWidget(
                  onFeedback: widget.onFeedback!,
                  compact: true,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImpactAnalysis(ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: _getSeverityColor().withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: _getSeverityColor().withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(_getImpactIcon(), color: _getSeverityColor(), size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getImpactTitle(),
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: _getSeverityColor(),
                  ),
                ),
                Text(
                  _getImpactDescription(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor() {
    switch (widget.insight.severity.toLowerCase()) {
      case 'high':
        return AppTheme.errorColor;
      case 'medium':
        return AppTheme.warningColor;
      case 'low':
      default:
        return AppTheme.infoColor;
    }
  }

  IconData _getActionIcon() {
    switch (widget.insight.type.toLowerCase()) {
      case 'negative':
        return Icons.trending_down;
      case 'positive':
        return Icons.trending_up;
      default:
        return Icons.insights;
    }
  }

  IconData _getImpactIcon() {
    switch (widget.insight.severity.toLowerCase()) {
      case 'high':
        return Icons.warning_amber;
      case 'medium':
        return Icons.info_outline;
      case 'low':
      default:
        return Icons.lightbulb_outline;
    }
  }

  String _getImpactTitle() {
    switch (widget.insight.severity.toLowerCase()) {
      case 'high':
        return 'Immediate Attention Required';
      case 'medium':
        return 'Consider Reviewing';
      case 'low':
      default:
        return 'Good to Know';
    }
  }

  String _getImpactDescription() {
    switch (widget.insight.severity.toLowerCase()) {
      case 'high':
        return 'This insight suggests an urgent financial matter that may impact your financial health.';
      case 'medium':
        return 'This insight highlights an area where you could optimize your financial habits.';
      case 'low':
      default:
        return 'This insight provides helpful context about your financial patterns.';
    }
  }
}
