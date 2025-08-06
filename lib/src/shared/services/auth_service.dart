import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_money/src/shared/services/login_attempt_service.dart';
import 'package:apex_money/src/shared/config/api_config.dart';

class AuthService {
  String get baseUrl => ApiConfig.apiBaseUrl;

  Future<Map<String, dynamic>> login(String email, String password) async {
    // Check if user is locked out
    if (await LoginAttemptService.isLockedOut()) {
      final int remainingTime =
          await LoginAttemptService.getRemainingLockoutTime();
      throw Exception(
        'Account temporarily locked. Try again in $remainingTime minutes.',
      );
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (kDebugMode) {
        print('Login response status: ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'] as String?;
        if (accessToken != null) {
          final prefs = await SharedPreferences.getInstance();

          // Check if this is a different user logging in
          final previousToken = prefs.getString('access_token');
          final isDifferentUser =
              previousToken != null && previousToken != accessToken;

          await prefs.setString('access_token', accessToken);

          // Store user email as user ID (since user model has no 'id' field)
          final userId =
              data['user']?['email']?.toString() ?? // Primary: user.email
              data['email']?.toString(); // Fallback: direct email
          if (userId != null) {
            await prefs.setString('user_id', userId);
            if (kDebugMode) {
              print('Stored user_id: $userId');
            }
          } else {
            if (kDebugMode) {
              print('No user ID found in login response: $data');
            }
          }

          // Clear user-specific data if a different user is logging in
          if (isDifferentUser) {
            if (kDebugMode) {
              print('Different user detected, clearing cached data');
            }
            await clearUserData();
          }

          // Record successful login (clears any failed attempts)
          await LoginAttemptService.recordSuccessfulLogin(email);

          return data;
        } else {
          // Record failed attempt
          await LoginAttemptService.recordFailedAttempt(email);
          throw Exception('Access token is missing in the response.');
        }
      } else {
        // Record failed attempt for invalid credentials
        await LoginAttemptService.recordFailedAttempt(email);
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      // If it's not a lockout exception, record the failed attempt
      if (!e.toString().contains('Account temporarily locked')) {
        await LoginAttemptService.recordFailedAttempt(email);
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> register(
    String name,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    if (kDebugMode) {
      print('Registration response status: ${response.statusCode}');
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      // Clear any previous user's data and login preferences after successful registration
      await clearUserData();
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to register: ${response.body}');
    }
  }

  Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    // Clear user-specific data while preserving auth and app preferences
    await prefs.remove('stored_goals');
    await prefs.remove('cached_transactions');
    await prefs.remove('user_profile_cache');
    // Clear login form preferences to prevent showing previous user's data
    await prefs.remove('email');
    await prefs.remove('keepSignedIn');
    // Add any other user-specific keys here
    if (kDebugMode) {
      print('Cleared user-specific cached data and login preferences');
    }
  }

  Future<void> logout() async {
    await clearUserData(); // Clear user-specific data first
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('user_id');
    // Clear remember me preferences on explicit logout
    await prefs.setBool('keepSignedIn', false);
    await prefs.remove('email');
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token') != null;
  }

  Future<bool> validateToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      return false;
    }

    final response = await http.get(
      Uri.parse('$baseUrl/validate-token'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>> fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null) {
      throw Exception('No access token found');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/me'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch user profile: ${response.body}');
    }
  }

  /// Get current user information from local storage
  Future<Map<String, dynamic>?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id'); // This is the user's email

    if (userId == null) {
      return null;
    }

    try {
      // Try to get full profile from the server
      final profile = await fetchUserProfile();
      return profile;
    } catch (e) {
      // Fallback to minimal local data if server request fails
      return {
        'email': userId,
        'name': 'User', // Default name - could be enhanced to store locally
      };
    }
  }

  /// Get current user email (which serves as user ID)
  Future<String?> getCurrentUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to send password reset email: ${response.body}');
    }
  }

  // Debug method to help troubleshoot login issues
  Future<Map<String, dynamic>> debugLoginStatus(String email) async {
    try {
      // Check lockout status
      final isLocked = await LoginAttemptService.isLockedOut();
      final remainingTime = await LoginAttemptService.getRemainingLockoutTime();

      // Test basic connectivity using login endpoint with invalid data
      // This should return 422 (validation error) if server is working
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': 'test@connectivity.check',
          'password': 'test',
        }),
      );

      // Server is reachable if we get any HTTP response (even error responses)
      final serverReachable =
          response.statusCode >= 200 && response.statusCode < 600;

      return {
        'isLockedOut': isLocked,
        'remainingLockoutMinutes': remainingTime,
        'serverReachable': serverReachable,
        'serverResponse': response.statusCode,
        'serverMessage':
            response.statusCode == 422
                ? 'Server working (validation error as expected)'
                : 'Unexpected response',
      };
    } catch (e) {
      return {
        'isLockedOut': false,
        'remainingLockoutMinutes': 0,
        'serverReachable': false,
        'serverResponse': 0,
        'error': e.toString(),
      };
    }
  }

  // Method to clear lockout (for debugging)
  Future<void> clearLockout() async {
    await LoginAttemptService.clearAllAttempts();
  }

  // Test login without lockout penalties (for debugging)
  Future<Map<String, dynamic>> testLoginCredentials(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'email': email, 'password': password}),
      );

      return {
        'statusCode': response.statusCode,
        'success': response.statusCode == 200,
        'responseBody': response.body,
        'message':
            response.statusCode == 200
                ? 'Login successful!'
                : response.statusCode == 422
                ? 'Invalid credentials'
                : 'Server error: ${response.statusCode}',
      };
    } catch (e) {
      return {
        'statusCode': 0,
        'success': false,
        'responseBody': '',
        'message': 'Network error: ${e.toString()}',
        'error': e.toString(),
      };
    }
  }
}
