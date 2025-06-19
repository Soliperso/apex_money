import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A reusable gradient background widget that adapts to theme
class AppGradientBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  final List<double>? stops;

  const AppGradientBackground({
    super.key,
    required this.child,
    this.colors,
    this.begin = Alignment.topCenter,
    this.end = Alignment.bottomCenter,
    this.stops,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Default gradient colors based on theme
    final defaultColors = colors ?? 
      (isDark ? AppTheme.darkSurfaceGradient : [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.8),
        theme.colorScheme.surface,
      ]);
    
    // Default stops based on the number of colors
    final defaultStops = stops ?? _generateDefaultStops(defaultColors.length);
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: defaultColors,
          stops: defaultStops,
        ),
      ),
      child: child,
    );
  }
  
  List<double> _generateDefaultStops(int colorCount) {
    if (colorCount <= 1) return [0.0];
    if (colorCount == 2) return [0.0, 1.0];
    if (colorCount == 3) return [0.0, 0.3, 1.0];
    if (colorCount == 4) return [0.0, 0.3, 0.7, 1.0];
    
    // For more colors, distribute evenly
    return List.generate(colorCount, (index) => index / (colorCount - 1));
  }
}

/// A subtle surface gradient for cards and containers
class AppSurfaceGradient extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;

  const AppSurfaceGradient({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainer,
              ]
            : [
                theme.colorScheme.surface,
                theme.colorScheme.surfaceContainerHighest,
              ],
          stops: const [0.0, 1.0],
        ),
        borderRadius: borderRadius,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}