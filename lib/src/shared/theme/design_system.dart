import 'package:flutter/material.dart';
import 'app_spacing.dart';
import 'app_theme.dart';

/// Design system utility class for consistent UI patterns across the app
class DesignSystem {
  // Prevent instantiation
  DesignSystem._();

  /// Standard glass-morphism container decoration
  ///
  /// This provides the app's signature glass-morphism style with proper
  /// alpha values and consistent border styling.
  static BoxDecoration glassContainer(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  /// High-contrast glass-morphism container for elevated content
  ///
  /// Used for modals, dialogs, and elevated cards that need more prominence.
  static BoxDecoration glassContainerElevated(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }

  /// Subtle glass-morphism for background elements
  ///
  /// Used for background cards and less prominent elements.
  static BoxDecoration glassContainerSubtle(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surface.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.1),
        width: 1,
      ),
    );
  }

  /// Standard glass-morphism with custom border radius
  static BoxDecoration glassContainerWithRadius(
    ThemeData theme,
    double radius,
  ) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        width: 1,
      ),
    );
  }

  /// Premium financial card styling for transactions and insights
  ///
  /// Optimized for financial data display with enhanced readability and trust.
  static BoxDecoration financialCard(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.8)
              : theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
      borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      border: Border.all(
        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.06),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.04),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  /// Premium financial card with enhanced depth for important data
  static BoxDecoration financialCardPremium(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9)
              : theme.colorScheme.surface.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      border: Border.all(
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.primary.withValues(alpha: 0.2)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
        width: 2,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.08),
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

  /// Frosted glass effect for overlays and modals
  static BoxDecoration frostGlass(ThemeData theme) {
    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surface.withValues(alpha: 0.4)
              : theme.colorScheme.surface.withValues(alpha: 0.3),
      borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
      border: Border.all(
        color: theme.colorScheme.outline.withValues(alpha: 0.2),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: theme.colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Success state glass container (for income/gains)
  static BoxDecoration successGlassContainer(ThemeData theme) {
    final successColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFF81C784)
            : const Color(0xFF2E7D32);

    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(
        color: successColor.withValues(alpha: 0.3),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color: successColor.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Error state glass container (for expenses/losses)
  static BoxDecoration errorGlassContainer(ThemeData theme) {
    final errorColor =
        theme.brightness == Brightness.dark
            ? const Color(0xFFEF5350)
            : const Color(0xFFD32F2F);

    return BoxDecoration(
      color:
          theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      border: Border.all(color: errorColor.withValues(alpha: 0.3), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: errorColor.withValues(alpha: 0.1),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}

/// Color extension methods for consistent financial color usage
extension AppColors on ColorScheme {
  /// Success color for income and positive financial indicators
  Color get incomeColor => AppTheme.successColor;

  /// Error color for expenses and negative financial indicators
  Color get expenseColor => AppTheme.errorColor;

  /// Primary action color for main interactive elements
  Color get primaryActionColor => AppTheme.primaryColor;

  /// Warning color for alerts and attention-requiring elements
  Color get warningColor => AppTheme.warningColor;

  /// Info color for informational elements
  Color get infoColor => AppTheme.infoColor;

  /// Neutral color for secondary text and icons
  Color get neutralColor => onSurfaceVariant.withValues(alpha: 0.6);
}

/// Enhanced typography extension for financial applications
extension AppTypography on TextTheme {
  /// Large financial amounts (dashboard totals, balance displays)
  TextStyle get financialAmountLarge => displayMedium!.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: -1.5,
    height: 1.1,
    fontFeatures: [const FontFeature.tabularFigures()], // Monospaced numbers
  );

  /// Standard financial amounts (transaction amounts, card values)
  TextStyle get financialAmount => headlineMedium!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.8,
    height: 1.2,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Medium financial amounts (list items, summary cards)
  TextStyle get financialAmountMedium => headlineSmall!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Small financial amounts (transaction details, subcategories)
  TextStyle get financialAmountSmall => titleLarge!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: -0.3,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Currency labels and financial descriptors
  TextStyle get financialLabel => labelLarge!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    textBaseline: TextBaseline.alphabetic,
  );

  /// Percentage changes and financial metrics
  TextStyle get financialMetric => titleMedium!.copyWith(
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Section headers in financial contexts
  TextStyle get financialSectionHeader => titleLarge!.copyWith(
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.3,
  );

  /// Card titles for financial cards
  TextStyle get financialCardTitle =>
      titleMedium!.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.1);

  /// Financial data tables and detailed information
  TextStyle get financialData => bodyLarge!.copyWith(
    fontWeight: FontWeight.w500,
    fontFeatures: [const FontFeature.tabularFigures()],
  );

  /// Supplementary financial information
  TextStyle get financialSecondary => bodyMedium!.copyWith(
    fontWeight: FontWeight.w400,
    color: bodyMedium!.color?.withValues(alpha: 0.8),
  );

  /// Financial captions and metadata
  TextStyle get financialCaption => bodySmall!.copyWith(
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: bodySmall!.color?.withValues(alpha: 0.7),
  );

  // Legacy support - maintaining backward compatibility
  TextStyle get sectionHeader => financialSectionHeader;
  TextStyle get cardTitle => financialCardTitle;
  TextStyle get subtitleSecondary => financialSecondary;
}

/// Spacing extension methods for consistent layout
extension AppLayoutSpacing on EdgeInsets {
  /// Standard card padding
  static const EdgeInsets cardPadding = EdgeInsets.all(AppSpacing.cardPadding);

  /// Screen padding for main pages
  static const EdgeInsets screenPadding = EdgeInsets.all(
    AppSpacing.screenPadding,
  );

  /// Form field spacing
  static const EdgeInsets formSpacing = EdgeInsets.symmetric(
    vertical: AppSpacing.sm,
  );

  /// Button padding
  static const EdgeInsets buttonPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.xl,
    vertical: AppSpacing.md,
  );

  /// List item padding
  static const EdgeInsets listItemPadding = EdgeInsets.symmetric(
    horizontal: AppSpacing.lg,
    vertical: AppSpacing.md,
  );
}
