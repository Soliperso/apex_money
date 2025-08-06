import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';
import 'financial_amount_display.dart';

/// A premium card for displaying financial insights with enhanced visual hierarchy
class FinancialInsightCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Widget content;
  final List<Widget>? actions;
  final VoidCallback? onTap;
  final FinancialInsightCardType type;
  final bool isPremium;

  const FinancialInsightCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.iconColor,
    required this.content,
    this.actions,
    this.onTap,
    this.type = FinancialInsightCardType.neutral,
    this.isPremium = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine colors based on type
    Color primaryColor;
    Color containerColor;
    switch (type) {
      case FinancialInsightCardType.positive:
        primaryColor = colorScheme.incomeColor;
        containerColor = colorScheme.incomeContainer;
        break;
      case FinancialInsightCardType.negative:
        primaryColor = colorScheme.expenseColor;
        containerColor = colorScheme.expenseContainer;
        break;
      case FinancialInsightCardType.warning:
        primaryColor = colorScheme.warning;
        containerColor = colorScheme.warningContainer;
        break;
      case FinancialInsightCardType.info:
        primaryColor = colorScheme.primary;
        containerColor = colorScheme.primaryContainer;
        break;
      case FinancialInsightCardType.neutral:
      default:
        primaryColor = colorScheme.onSurface;
        containerColor = colorScheme.surfaceContainer;
        break;
    }

    final effectiveIconColor = iconColor ?? primaryColor;

    Widget cardContent = Container(
      decoration:
          isPremium
              ? DesignSystem.financialCardPremium(theme)
              : DesignSystem.financialCard(theme),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: containerColor,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(icon, color: effectiveIconColor, size: 24),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.financialCardTitle),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: theme.textTheme.financialSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
                if (actions != null && actions!.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  ...actions!,
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            // Content
            content,
          ],
        ),
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            isPremium ? AppSpacing.radiusXl : AppSpacing.radiusLg,
          ),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }
}

/// Specialized insight card for displaying financial metrics with comparison
class FinancialMetricCard extends StatelessWidget {
  final String title;
  final double currentValue;
  final double? previousValue;
  final String? currencyCode;
  final String? period;
  final IconData icon;
  final FinancialAmountType amountType;
  final bool showChange;
  final VoidCallback? onTap;

  const FinancialMetricCard({
    super.key,
    required this.title,
    required this.currentValue,
    this.previousValue,
    this.currencyCode = 'USD',
    this.period,
    required this.icon,
    this.amountType = FinancialAmountType.neutral,
    this.showChange = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasComparison = previousValue != null && showChange;

    return FinancialInsightCard(
      title: title,
      subtitle: period,
      icon: icon,
      onTap: onTap,
      type: _getCardTypeFromAmountType(amountType),
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FinancialAmountDisplay(
            amount: currentValue,
            currencyCode: currencyCode,
            type: amountType,
            size: FinancialAmountSize.large,
            showSign: false,
          ),
          if (hasComparison) ...[
            const SizedBox(height: AppSpacing.sm),
            FinancialChangeDisplay(
              currentAmount: currentValue,
              previousAmount: previousValue!,
              currencyCode: currencyCode,
              size: FinancialAmountSize.small,
              label: 'vs. previous period',
            ),
          ],
        ],
      ),
    );
  }

  FinancialInsightCardType _getCardTypeFromAmountType(
    FinancialAmountType type,
  ) {
    switch (type) {
      case FinancialAmountType.income:
      case FinancialAmountType.savings:
      case FinancialAmountType.investment:
        return FinancialInsightCardType.positive;
      case FinancialAmountType.expense:
        return FinancialInsightCardType.negative;
      case FinancialAmountType.auto:
        return currentValue >= 0
            ? FinancialInsightCardType.positive
            : FinancialInsightCardType.negative;
      case FinancialAmountType.neutral:
      default:
        return FinancialInsightCardType.neutral;
    }
  }
}

/// A card for displaying financial goals progress
class FinancialGoalCard extends StatelessWidget {
  final String goalName;
  final double targetAmount;
  final double currentAmount;
  final String? currencyCode;
  final DateTime? deadline;
  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onQuickAdd;

  const FinancialGoalCard({
    super.key,
    required this.goalName,
    required this.targetAmount,
    required this.currentAmount,
    this.currencyCode = 'USD',
    this.deadline,
    this.icon = Icons.savings_outlined,
    this.onTap,
    this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final progress =
        targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;
    final remainingAmount = targetAmount - currentAmount;

    // Calculate deadline status
    String? deadlineText;
    Color? deadlineColor;
    if (deadline != null) {
      final now = DateTime.now();
      final daysRemaining = deadline!.difference(now).inDays;

      if (daysRemaining < 0) {
        deadlineText = 'Overdue';
        deadlineColor = colorScheme.expenseColor;
      } else if (daysRemaining == 0) {
        deadlineText = 'Due today';
        deadlineColor = colorScheme.warning;
      } else if (daysRemaining <= 7) {
        deadlineText = '$daysRemaining days left';
        deadlineColor = colorScheme.warning;
      } else {
        deadlineText = '$daysRemaining days left';
        deadlineColor = colorScheme.onSurfaceVariant;
      }
    }

    return FinancialInsightCard(
      title: goalName,
      subtitle: deadlineText,
      icon: icon,
      iconColor: colorScheme.savingsColor,
      onTap: onTap,
      type: FinancialInsightCardType.info,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        FinancialAmountDisplay(
                          amount: currentAmount,
                          currencyCode: currencyCode,
                          type: FinancialAmountType.savings,
                          size: FinancialAmountSize.medium,
                          showSign: false,
                        ),
                        Text(
                          '${(progress * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.financialMetric.copyWith(
                            color: colorScheme.savingsColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    // Progress bar
                    Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          AppSpacing.radiusXs,
                        ),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: progress,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.savingsColor,
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXs,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (remainingAmount > 0)
                          Text(
                            'Remaining: ${CurrencyFormatter.format(remainingAmount, currencyCode: currencyCode)}',
                            style: theme.textTheme.financialCaption,
                          )
                        else
                          Text(
                            'Goal achieved!',
                            style: theme.textTheme.financialCaption.copyWith(
                              color: colorScheme.incomeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        if (deadlineText != null)
                          Text(
                            deadlineText,
                            style: theme.textTheme.financialCaption.copyWith(
                              color: deadlineColor,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      actions:
          onQuickAdd != null
              ? [
                IconButton(
                  onPressed: onQuickAdd,
                  icon: const Icon(Icons.add_circle_outline),
                  tooltip: 'Quick add to goal',
                ),
              ]
              : null,
    );
  }
}

/// Types for financial insight cards
enum FinancialInsightCardType {
  positive, // Green border/accent for good news
  negative, // Red border/accent for concerning info
  warning, // Amber border/accent for alerts
  info, // Blue border/accent for information
  neutral, // Default styling
}
