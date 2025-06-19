import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class LoginAttemptService {
  static const String _attemptsKey = 'login_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _lastAttemptEmailKey = 'last_attempt_email';

  // Security configuration
  static const int maxAttempts = 5;
  static const int lockoutDurationMinutes = 15;
  static const int attemptWindowMinutes = 60; // Reset attempts after 1 hour

  /// Check if user is currently locked out
  static Future<bool> isLockedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lockoutTime = prefs.getInt(_lockoutTimeKey);

    if (lockoutTime == null) return false;

    final DateTime lockoutDateTime = DateTime.fromMillisecondsSinceEpoch(
      lockoutTime,
    );
    final DateTime now = DateTime.now();

    if (now.difference(lockoutDateTime).inMinutes >= lockoutDurationMinutes) {
      // Lockout period has expired, clear the lockout
      await _clearLockout();
      return false;
    }

    return true;
  }

  /// Get remaining lockout time in minutes
  static Future<int> getRemainingLockoutTime() async {
    final prefs = await SharedPreferences.getInstance();
    final int? lockoutTime = prefs.getInt(_lockoutTimeKey);

    if (lockoutTime == null) return 0;

    final DateTime lockoutDateTime = DateTime.fromMillisecondsSinceEpoch(
      lockoutTime,
    );
    final DateTime now = DateTime.now();
    final int elapsedMinutes = now.difference(lockoutDateTime).inMinutes;

    return (lockoutDurationMinutes - elapsedMinutes).clamp(
      0,
      lockoutDurationMinutes,
    );
  }

  /// Record a failed login attempt
  static Future<void> recordFailedAttempt(String email) async {
    if (await isLockedOut()) return;

    final prefs = await SharedPreferences.getInstance();
    final String emailHash = _hashEmail(email);

    // Get current attempts data
    final String? attemptsJson = prefs.getString(_attemptsKey);
    Map<String, dynamic> attemptsData = {};

    if (attemptsJson != null) {
      try {
        attemptsData = jsonDecode(attemptsJson);
      } catch (e) {
        attemptsData = {};
      }
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final String currentEmailKey = 'email_$emailHash';

    // Initialize or update attempts for this email
    Map<String, dynamic> emailAttempts =
        attemptsData[currentEmailKey] ?? {'count': 0, 'timestamps': <int>[]};

    // Remove old attempts outside the window
    List<int> timestamps = List<int>.from(emailAttempts['timestamps'] ?? []);
    timestamps.removeWhere((timestamp) {
      final DateTime attemptTime = DateTime.fromMillisecondsSinceEpoch(
        timestamp,
      );
      return DateTime.now().difference(attemptTime).inMinutes >
          attemptWindowMinutes;
    });

    // Add current attempt
    timestamps.add(now);
    emailAttempts['count'] = timestamps.length;
    emailAttempts['timestamps'] = timestamps;

    // Update attempts data
    attemptsData[currentEmailKey] = emailAttempts;

    // Save updated data
    await prefs.setString(_attemptsKey, jsonEncode(attemptsData));
    await prefs.setString(_lastAttemptEmailKey, emailHash);

    // Check if we need to lock out the user
    if (timestamps.length >= maxAttempts) {
      await _lockoutUser();
    }
  }

  /// Record a successful login (clears attempts for this email)
  static Future<void> recordSuccessfulLogin(String email) async {
    final prefs = await SharedPreferences.getInstance();
    final String emailHash = _hashEmail(email);

    // Clear attempts for this email
    final String? attemptsJson = prefs.getString(_attemptsKey);
    if (attemptsJson != null) {
      try {
        Map<String, dynamic> attemptsData = jsonDecode(attemptsJson);
        attemptsData.remove('email_$emailHash');
        await prefs.setString(_attemptsKey, jsonEncode(attemptsData));
      } catch (e) {
        // If there's an error, just clear all attempts
        await prefs.remove(_attemptsKey);
      }
    }

    // Clear lockout if exists
    await _clearLockout();
  }

  /// Get remaining attempts before lockout for specific email
  static Future<int> getRemainingAttempts(String email) async {
    if (await isLockedOut()) return 0;

    final prefs = await SharedPreferences.getInstance();
    final String emailHash = _hashEmail(email);
    final String? attemptsJson = prefs.getString(_attemptsKey);

    if (attemptsJson == null) return maxAttempts;

    try {
      final Map<String, dynamic> attemptsData = jsonDecode(attemptsJson);
      final Map<String, dynamic>? emailAttempts =
          attemptsData['email_$emailHash'];

      if (emailAttempts == null) return maxAttempts;

      final int currentAttempts = emailAttempts['count'] ?? 0;
      return (maxAttempts - currentAttempts).clamp(0, maxAttempts);
    } catch (e) {
      return maxAttempts;
    }
  }

  /// Clear all login attempts (admin function)
  static Future<void> clearAllAttempts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockoutTimeKey);
    await prefs.remove(_lastAttemptEmailKey);
  }

  /// Private: Lock out the user
  static Future<void> _lockoutUser() async {
    final prefs = await SharedPreferences.getInstance();
    final int lockoutTime = DateTime.now().millisecondsSinceEpoch;
    await prefs.setInt(_lockoutTimeKey, lockoutTime);
  }

  /// Private: Clear lockout
  static Future<void> _clearLockout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lockoutTimeKey);
  }

  /// Private: Hash email for privacy
  static String _hashEmail(String email) {
    final bytes = utf8.encode(email.toLowerCase().trim());
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
}
