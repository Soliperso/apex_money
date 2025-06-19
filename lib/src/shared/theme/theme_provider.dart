import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  ThemeMode _themeMode = ThemeMode.system;
  
  ThemeMode get themeMode => _themeMode;
  
  bool get isDarkMode {
    switch (_themeMode) {
      case ThemeMode.dark:
        return true;
      case ThemeMode.light:
        return false;
      case ThemeMode.system:
        return WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark;
    }
  }
  
  /// Initialize theme from saved preferences
  Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey);
      
      if (themeIndex != null) {
        _themeMode = ThemeMode.values[themeIndex];
        notifyListeners();
      }
    } catch (e) {
      // If loading fails, use system default
      _themeMode = ThemeMode.system;
    }
  }
  
  /// Set theme mode and save to preferences
  Future<void> setThemeMode(ThemeMode themeMode) async {
    if (_themeMode == themeMode) return;
    
    _themeMode = themeMode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeKey, themeMode.index);
    } catch (e) {
      // Handle error silently
      debugPrint('Failed to save theme preference: $e');
    }
  }
  
  /// Toggle between light and dark mode (ignores system)
  Future<void> toggleTheme() async {
    final newTheme = _themeMode == ThemeMode.dark 
      ? ThemeMode.light 
      : ThemeMode.dark;
    await setThemeMode(newTheme);
  }
  
  /// Set to system theme
  Future<void> setSystemTheme() async {
    await setThemeMode(ThemeMode.system);
  }
  
  /// Get current brightness based on theme mode
  Brightness getCurrentBrightness(BuildContext context) {
    switch (_themeMode) {
      case ThemeMode.dark:
        return Brightness.dark;
      case ThemeMode.light:
        return Brightness.light;
      case ThemeMode.system:
        return MediaQuery.of(context).platformBrightness;
    }
  }
  
  /// Get theme mode display name
  String get themeModeDisplayName {
    switch (_themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
  
  /// Get theme mode icon
  IconData get themeModeIcon {
    switch (_themeMode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }
}