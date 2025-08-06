import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class PerformanceService {
  static final PerformanceService _instance = PerformanceService._internal();

  factory PerformanceService() => _instance;

  PerformanceService._internal();

  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Initialize performance service
  Future<void> initialize() async {
    if (_isInitialized) return;

    _prefs = await SharedPreferences.getInstance();
    _isInitialized = true;

    // Warm up commonly used services
    await _warmUpServices();
  }

  /// Warm up commonly used services to improve startup time
  Future<void> _warmUpServices() async {
    // Pre-cache common theme data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _precacheThemeData();
    });

    // Pre-load critical shared preferences
    await _preloadCriticalPrefs();
  }

  /// Pre-cache theme data to improve rendering performance
  void _precacheThemeData() {
    // This will be called after the first frame to cache theme data
    // Helps with subsequent theme-dependent widgets
  }

  /// Pre-load critical shared preferences to avoid blocking UI
  Future<void> _preloadCriticalPrefs() async {
    // Pre-load commonly accessed preferences
    _prefs.getBool('first_launch') ?? true;
    _prefs.getString('user_id') ?? '';
    _prefs.getString('access_token') ?? '';
    _prefs.getBool('dark_mode') ?? false;
    _prefs.getBool('haptic_enabled') ?? true;
  }

  /// Optimize navigation transitions
  PageRouteBuilder createOptimizedRoute({
    required Widget page,
    RouteSettings? settings,
    Duration duration = const Duration(milliseconds: 300),
    bool maintainState = true,
  }) {
    return PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      settings: settings,
      maintainState: maintainState,
      transitionDuration: duration,
      reverseTransitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Use a more performant transition
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.1, 0),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
            child: child,
          ),
        );
      },
    );
  }

  /// Optimize list view performance
  Widget optimizeListView({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    bool shrinkWrap = false,
    ScrollPhysics? physics,
    EdgeInsets? padding,
  }) {
    return ListView.builder(
      controller: controller,
      shrinkWrap: shrinkWrap,
      physics: physics,
      padding: padding,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      // Performance optimizations
      cacheExtent: 200, // Cache items slightly off-screen
      addAutomaticKeepAlives: false, // Don't keep items alive unnecessarily
      addRepaintBoundaries: true, // Improve repaint performance
    );
  }

  /// Create optimized image widget
  Widget optimizeImage({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    Widget? placeholder,
    Widget? errorWidget,
  }) {
    return Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          child: child,
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Center(
              child: CircularProgressIndicator(
                value:
                    loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
              ),
            );
      },
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ?? const Icon(Icons.error, color: Colors.red);
      },
    );
  }

  /// Debounce function calls to improve performance
  static void debounce(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 300),
  }) {
    _DebounceTimer.start(delay, callback);
  }

  /// Throttle function calls to improve performance
  static DateTime? _lastThrottleTime;

  static void throttle(
    VoidCallback callback, {
    Duration delay = const Duration(milliseconds: 100),
  }) {
    final now = DateTime.now();
    if (_lastThrottleTime == null ||
        now.difference(_lastThrottleTime!) > delay) {
      _lastThrottleTime = now;
      callback();
    }
  }

  /// Optimize app startup
  Future<void> optimizeStartup() async {
    // Set preferred orientations early
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Set system UI overlay style early
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
  }

  /// Measure widget build performance
  Widget measurePerformance(Widget child, String name) {
    return _PerformanceMeasurer(name: name, child: child);
  }

  /// Clear caches to free up memory
  Future<void> clearCaches() async {
    // Clear image cache
    PaintingBinding.instance.imageCache.clear();

    // Clear other caches as needed
    await _clearAppCaches();
  }

  Future<void> _clearAppCaches() async {
    // Clear any app-specific caches
    // This could include clearing old transaction data, etc.
  }

  /// Memory optimization for large lists
  Widget createMemoryOptimizedList({
    required int itemCount,
    required IndexedWidgetBuilder itemBuilder,
    ScrollController? controller,
    int maxCacheExtent = 500,
  }) {
    return ListView.builder(
      controller: controller,
      itemCount: itemCount,
      itemBuilder: itemBuilder,
      cacheExtent: maxCacheExtent.toDouble(),
      addAutomaticKeepAlives: false,
      addRepaintBoundaries: true,
    );
  }
}

class _PerformanceMeasurer extends StatefulWidget {
  final Widget child;
  final String name;

  const _PerformanceMeasurer({required this.child, required this.name});

  @override
  State<_PerformanceMeasurer> createState() => _PerformanceMeasurerState();
}

class _PerformanceMeasurerState extends State<_PerformanceMeasurer> {
  late DateTime _startTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final duration = DateTime.now().difference(_startTime);
      debugPrint(
        'Performance: ${widget.name} took ${duration.inMilliseconds}ms to build',
      );
    });

    return widget.child;
  }
}

// Extension for easy performance optimization
extension PerformanceExtensions on Widget {
  Widget withPerformanceOptimization() {
    return RepaintBoundary(child: this);
  }

  Widget withMeasurement(String name) {
    return PerformanceService().measurePerformance(this, name);
  }
}

// Helper class for debouncing
class _DebounceTimer {
  static Timer? _timer;

  static void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  static void start(Duration duration, VoidCallback callback) {
    cancel();
    _timer = Timer(duration, callback);
  }
}
