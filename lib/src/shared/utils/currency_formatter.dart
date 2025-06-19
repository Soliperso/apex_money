import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Default US Dollar formatter
  static final NumberFormat _usdFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 2,
  );

  // Compact formatter for large numbers (e.g., $1.2K, $1.5M)
  static final NumberFormat _compactFormatter = NumberFormat.compactCurrency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 1,
  );

  // Simple formatter without decimal places
  static final NumberFormat _wholeFormatter = NumberFormat.currency(
    locale: 'en_US',
    symbol: '\$',
    decimalDigits: 0,
  );

  /// Format currency with full precision (e.g., $1,234.56)
  static String format(double amount) {
    return _usdFormatter.format(amount);
  }

  /// Format currency without decimal places (e.g., $1,235)
  static String formatWhole(double amount) {
    return _wholeFormatter.format(amount);
  }

  /// Format currency in compact form for large numbers (e.g., $1.2K, $1.5M)
  static String formatCompact(double amount) {
    final absAmount = amount.abs();
    
    if (absAmount >= 1000000) {
      return _compactFormatter.format(amount);
    } else if (absAmount >= 1000) {
      return _compactFormatter.format(amount);
    } else {
      return formatWhole(amount);
    }
  }

  /// Format currency for display in cards and summaries
  /// Uses compact format for large numbers, whole numbers for smaller amounts
  static String formatForDisplay(double amount) {
    final absAmount = amount.abs();
    
    if (absAmount >= 1000000) {
      return formatCompact(amount);
    } else if (absAmount >= 10000) {
      return formatCompact(amount);
    } else {
      return formatWhole(amount);
    }
  }

  /// Format currency with appropriate precision based on amount
  /// Small amounts show cents, larger amounts are rounded
  static String formatSmart(double amount) {
    final absAmount = amount.abs();
    
    if (absAmount >= 1000) {
      return formatWhole(amount);
    } else {
      return format(amount);
    }
  }

  /// Format percentage (e.g., 15.5%)
  static String formatPercentage(double percentage) {
    return '${percentage.toStringAsFixed(1)}%';
  }

  /// Format currency with plus/minus sign for gains/losses
  static String formatWithSign(double amount) {
    final formatted = formatSmart(amount.abs());
    if (amount > 0) {
      return '+$formatted';
    } else if (amount < 0) {
      return '-$formatted';
    } else {
      return formatted;
    }
  }
}