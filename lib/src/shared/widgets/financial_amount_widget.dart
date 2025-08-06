import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../theme/app_theme.dart';

/// Premium financial amount display widget with semantic colors and formatting
class FinancialAmountWidget extends StatelessWidget {
  final double amount;
  final String currency;
  final FinancialAmountSize size;
  final FinancialAmountType type;
  final bool showPrefix;
  final TextAlign textAlign;
  final int decimalPlaces;

  const FinancialAmountWidget({
    super.key,
    required this.amount,
    this.currency = '\$',
    this.size = FinancialAmountSize.medium,
    this.type = FinancialAmountType.neutral,
    this.showPrefix = true,
    this.textAlign = TextAlign.start,
    this.decimalPlaces = 2,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color amountColor;
    String prefix = '';

    switch (type) {
      case FinancialAmountType.income:
        amountColor = AppTheme.successColor;
        prefix = showPrefix ? '+' : '';
        break;
      case FinancialAmountType.expense:
        amountColor = AppTheme.errorColor;
        prefix = showPrefix ? '-' : '';
        break;
      case FinancialAmountType.neutral:
        amountColor = colorScheme.onSurface;
        break;
      case FinancialAmountType.savings:
        amountColor = AppTheme.savingsColor;
        prefix = showPrefix ? '+' : '';
        break;
      case FinancialAmountType.investment:
        amountColor = AppTheme.investmentColor;
        break;
    }

    TextStyle textStyle;
    switch (size) {
      case FinancialAmountSize.large:
        textStyle = theme.textTheme.financialAmountLarge;
        break;
      case FinancialAmountSize.medium:
        textStyle = theme.textTheme.financialAmount;
        break;
      case FinancialAmountSize.small:
        textStyle = theme.textTheme.financialAmountMedium;
        break;
      case FinancialAmountSize.extraSmall:
        textStyle = theme.textTheme.financialAmountSmall;
        break;
    }

    final formattedAmount = amount.abs().toStringAsFixed(decimalPlaces);

    return Text(
      '$prefix$currency$formattedAmount',
      style: textStyle.copyWith(color: amountColor),
      textAlign: textAlign,
      semanticsLabel: _buildSemanticLabel(),
    );
  }

  String _buildSemanticLabel() {
    final absAmount = amount.abs().toStringAsFixed(decimalPlaces);
    final typeDescription =
        type == FinancialAmountType.income
            ? 'income'
            : type == FinancialAmountType.expense
            ? 'expense'
            : 'amount';

    return '$typeDescription $currency$absAmount';
  }
}

/// Financial amount display sizes
enum FinancialAmountSize {
  large, // Dashboard totals, main balance displays
  medium, // Transaction amounts, card values
  small, // List items, summary cards
  extraSmall, // Transaction details, subcategories
}

/// Financial amount semantic types for color coding
enum FinancialAmountType {
  income, // Positive financial flow (green)
  expense, // Negative financial flow (red)
  neutral, // Neutral amounts (default color)
  savings, // Savings/goals (purple)
  investment, // Investment amounts (emerald)
}

/// Premium financial card widget with glass-morphism styling
class FinancialCard extends StatelessWidget {
  final Widget child;
  final FinancialCardType type;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final double? width;
  final double? height;

  const FinancialCard({
    super.key,
    required this.child,
    this.type = FinancialCardType.standard,
    this.padding,
    this.onTap,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    BoxDecoration decoration;
    switch (type) {
      case FinancialCardType.standard:
        decoration = DesignSystem.financialCard(theme);
        break;
      case FinancialCardType.premium:
        decoration = DesignSystem.financialCardPremium(theme);
        break;
      case FinancialCardType.success:
        decoration = DesignSystem.successGlassContainer(theme);
        break;
      case FinancialCardType.error:
        decoration = DesignSystem.errorGlassContainer(theme);
        break;
      case FinancialCardType.glass:
        decoration = DesignSystem.glassContainer(theme);
        break;
    }

    Widget cardWidget = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: decoration,
      child: child,
    );

    if (onTap != null) {
      cardWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          type == FinancialCardType.premium ? 20 : 16,
        ),
        child: cardWidget,
      );
    }

    return cardWidget;
  }
}

/// Financial card styling types
enum FinancialCardType {
  standard, // Standard financial card with enhanced styling
  premium, // Premium card with extra depth and borders
  success, // Success state card (income/gains)
  error, // Error state card (expenses/losses)
  glass, // Standard glass-morphism container
}

/// Financial metric badge for displaying percentages and changes
class FinancialMetricBadge extends StatelessWidget {
  final double value;
  final String suffix;
  final FinancialMetricType type;
  final bool showTrend;

  const FinancialMetricBadge({
    super.key,
    required this.value,
    this.suffix = '%',
    this.type = FinancialMetricType.neutral,
    this.showTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color backgroundColor;
    Color textColor;
    IconData? trendIcon;

    if (value > 0) {
      backgroundColor =
          Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFE8F5E8)
              : const Color(0xFF1B5E20);
      textColor = AppTheme.successColor;
      trendIcon = showTrend ? Icons.trending_up : null;
    } else if (value < 0) {
      backgroundColor =
          Theme.of(context).brightness == Brightness.light
              ? const Color(0xFFFFEBEE)
              : const Color(0xFFB71C1C);
      textColor = AppTheme.errorColor;
      trendIcon = showTrend ? Icons.trending_down : null;
    } else {
      backgroundColor = colorScheme.surfaceVariant;
      textColor = AppTheme.neutralColor;
      trendIcon = null;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trendIcon != null) ...[
            Icon(trendIcon, size: 12, color: textColor),
            const SizedBox(width: 2),
          ],
          Text(
            '${value.abs().toStringAsFixed(1)}$suffix',
            style: theme.textTheme.financialMetric.copyWith(
              color: textColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Financial metric types for semantic styling
enum FinancialMetricType {
  positive, // Positive trend (green)
  negative, // Negative trend (red)
  neutral, // Neutral trend (gray)
}
