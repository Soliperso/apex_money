import 'package:flutter/material.dart';
import '../theme/design_system.dart';
import '../theme/app_spacing.dart';
import '../utils/currency_formatter.dart';

/// A premium financial amount display widget with semantic colors and accessibility
class FinancialAmountDisplay extends StatelessWidget {
  final double amount;
  final String? currencyCode;
  final FinancialAmountSize size;
  final FinancialAmountType type;
  final bool showSign;
  final bool showCurrency;
  final Color? customColor;
  final String? label;
  final CrossAxisAlignment alignment;

  const FinancialAmountDisplay({
    super.key,
    required this.amount,
    this.currencyCode = 'USD',
    this.size = FinancialAmountSize.medium,
    this.type = FinancialAmountType.neutral,
    this.showSign = true,
    this.showCurrency = true,
    this.customColor,
    this.label,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Determine display color based on type and amount
    Color amountColor;
    if (customColor != null) {
      amountColor = customColor!;
    } else {
      switch (type) {
        case FinancialAmountType.income:
          amountColor = colorScheme.incomeColor;
          break;
        case FinancialAmountType.expense:
          amountColor = colorScheme.expenseColor;
          break;
        case FinancialAmountType.savings:
          amountColor = colorScheme.savingsColor;
          break;
        case FinancialAmountType.investment:
          amountColor = colorScheme.investmentColor;
          break;
        case FinancialAmountType.auto:
          amountColor =
              amount >= 0 ? colorScheme.incomeColor : colorScheme.expenseColor;
          break;
        case FinancialAmountType.neutral:
        default:
          amountColor = colorScheme.onSurface;
          break;
      }
    }

    // Get appropriate text style based on size
    TextStyle baseStyle;
    switch (size) {
      case FinancialAmountSize.large:
        baseStyle = theme.textTheme.financialAmountLarge;
        break;
      case FinancialAmountSize.medium:
        baseStyle = theme.textTheme.financialAmount;
        break;
      case FinancialAmountSize.small:
        baseStyle = theme.textTheme.financialAmountMedium;
        break;
      case FinancialAmountSize.tiny:
        baseStyle = theme.textTheme.financialAmountSmall;
        break;
    }

    final amountStyle = baseStyle.copyWith(color: amountColor);
    final labelStyle = theme.textTheme.financialLabel.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    // Format the amount
    final formattedAmount = CurrencyFormatter.format(
      amount.abs(),
      currencyCode: showCurrency ? currencyCode : null,
      showSymbol: showCurrency,
    );

    // Build sign prefix
    String signPrefix = '';
    if (showSign && amount != 0) {
      signPrefix = amount >= 0 ? '+' : '-';
    }

    final displayText = '$signPrefix$formattedAmount';

    // Accessibility label
    final accessibilityLabel = _buildAccessibilityLabel(
      amount: amount,
      type: type,
      currencyCode: currencyCode ?? 'USD',
      label: label,
    );

    return Semantics(
      label: accessibilityLabel,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: alignment,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(label!, style: labelStyle),
            SizedBox(
              height:
                  size == FinancialAmountSize.large
                      ? AppSpacing.sm
                      : AppSpacing.xs,
            ),
          ],
          Text(
            displayText,
            style: amountStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  String _buildAccessibilityLabel({
    required double amount,
    required FinancialAmountType type,
    required String currencyCode,
    String? label,
  }) {
    final buffer = StringBuffer();

    if (label != null) {
      buffer.write('$label: ');
    }

    // Add context based on type
    switch (type) {
      case FinancialAmountType.income:
        buffer.write('Income of ');
        break;
      case FinancialAmountType.expense:
        buffer.write('Expense of ');
        break;
      case FinancialAmountType.savings:
        buffer.write('Savings of ');
        break;
      case FinancialAmountType.investment:
        buffer.write('Investment of ');
        break;
      case FinancialAmountType.auto:
        if (amount >= 0) {
          buffer.write('Positive amount of ');
        } else {
          buffer.write('Negative amount of ');
        }
        break;
      case FinancialAmountType.neutral:
        buffer.write('Amount of ');
        break;
    }

    // Add formatted amount
    final formattedAmount = CurrencyFormatter.format(
      amount.abs(),
      currencyCode: currencyCode,
      showSymbol: true,
    );
    buffer.write(formattedAmount);

    return buffer.toString();
  }
}

/// Size variants for financial amount displays
enum FinancialAmountSize {
  large, // Dashboard totals, main balance
  medium, // Card amounts, transaction amounts
  small, // List item amounts, secondary amounts
  tiny, // Metadata, subcategory amounts
}

/// Semantic types for financial amounts
enum FinancialAmountType {
  income, // Green color for income/positive
  expense, // Red color for expenses/negative
  savings, // Purple color for savings/goals
  investment, // Emerald color for investments
  neutral, // Default surface color
  auto, // Automatically choose income/expense based on amount sign
}

/// A specialized widget for displaying financial changes/deltas
class FinancialChangeDisplay extends StatelessWidget {
  final double currentAmount;
  final double previousAmount;
  final String? currencyCode;
  final FinancialAmountSize size;
  final bool showPercentage;
  final String? label;

  const FinancialChangeDisplay({
    super.key,
    required this.currentAmount,
    required this.previousAmount,
    this.currencyCode = 'USD',
    this.size = FinancialAmountSize.small,
    this.showPercentage = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final change = currentAmount - previousAmount;
    final isPositive = change >= 0;
    final percentChange =
        previousAmount != 0 ? (change / previousAmount.abs()) * 100 : 0.0;

    // Determine color and icon
    final color =
        isPositive ? colorScheme.incomeColor : colorScheme.expenseColor;
    final icon =
        isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded;

    // Format display text
    final formattedChange = CurrencyFormatter.format(
      change.abs(),
      currencyCode: currencyCode,
      showSymbol: true,
    );

    final percentText =
        showPercentage ? ' (${percentChange.abs().toStringAsFixed(1)}%)' : '';

    final displayText = '${isPositive ? '+' : '-'}$formattedChange$percentText';

    // Get text style
    TextStyle textStyle;
    switch (size) {
      case FinancialAmountSize.large:
        textStyle = theme.textTheme.financialAmountMedium;
        break;
      case FinancialAmountSize.medium:
        textStyle = theme.textTheme.financialAmountSmall;
        break;
      case FinancialAmountSize.small:
        textStyle = theme.textTheme.financialMetric;
        break;
      case FinancialAmountSize.tiny:
        textStyle = theme.textTheme.financialCaption;
        break;
    }

    final iconSize =
        size == FinancialAmountSize.large
            ? 20.0
            : size == FinancialAmountSize.medium
            ? 18.0
            : size == FinancialAmountSize.small
            ? 16.0
            : 14.0;

    return Semantics(
      label: _buildChangeAccessibilityLabel(
        change: change,
        percentChange: percentChange,
        currencyCode: currencyCode ?? 'USD',
        label: label,
      ),
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null) ...[
            Text(
              label!,
              style: theme.textTheme.financialLabel.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
          ],
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: iconSize),
              const SizedBox(width: AppSpacing.xs),
              Text(displayText, style: textStyle.copyWith(color: color)),
            ],
          ),
        ],
      ),
    );
  }

  String _buildChangeAccessibilityLabel({
    required double change,
    required double percentChange,
    required String currencyCode,
    String? label,
  }) {
    final buffer = StringBuffer();

    if (label != null) {
      buffer.write('$label: ');
    }

    if (change >= 0) {
      buffer.write('Increased by ');
    } else {
      buffer.write('Decreased by ');
    }

    final formattedChange = CurrencyFormatter.format(
      change.abs(),
      currencyCode: currencyCode,
      showSymbol: true,
    );

    buffer.write('$formattedChange, ');
    buffer.write('${percentChange.abs().toStringAsFixed(1)} percent');

    return buffer.toString();
  }
}
