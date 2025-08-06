/// Consistent spacing values throughout the app
class AppSpacing {
  // Prevent instantiation
  AppSpacing._();

  // Base spacing unit (4dp)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double xxxl = 32.0;
  static const double huge = 48.0;
  static const double massive = 64.0;

  // Semantic spacing
  static const double cardPadding = lg;
  static const double screenPadding = lg;
  static const double sectionSpacing = xxl;
  static const double listItemSpacing = sm;
  static const double buttonPadding = md;

  // Radius values
  static const double radiusXs = 4.0;
  static const double radiusSm = 8.0;
  static const double radiusMd = 12.0;
  static const double radiusLg = 16.0;
  static const double radiusXl = 20.0;
  static const double radiusXxl = 24.0;

  // Semantic radius
  static const double cardRadius = radiusLg;
  static const double buttonRadius = radiusMd;
  static const double inputRadius = radiusMd;
  static const double bottomSheetRadius = radiusXl;
  static const double dialogRadius = radiusXl;
}

/// Consistent elevation values
class AppElevation {
  AppElevation._();

  static const double none = 0.0;
  static const double low = 1.0;
  static const double medium = 3.0;
  static const double high = 6.0;
  static const double highest = 12.0;

  // Semantic elevations
  static const double card = low;
  static const double button =
      none; // Material 3 uses filled buttons without elevation
  static const double fab = high;
  static const double bottomSheet = medium;
  static const double dialog = highest;
  static const double appBar = none;
}

/// Animation duration constants
class AppDuration {
  AppDuration._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 250);
  static const Duration slow = Duration(milliseconds: 350);
  static const Duration verySlow = Duration(milliseconds: 500);

  // Semantic durations
  static const Duration buttonAnimation = fast;
  static const Duration pageTransition = medium;
  static const Duration modalAnimation = medium;
  static const Duration loadingAnimation = slow;
}
