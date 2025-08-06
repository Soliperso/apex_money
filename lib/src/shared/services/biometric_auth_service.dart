import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricAuthService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static final LocalAuthentication _localAuth = LocalAuthentication();

  // Keys for secure storage
  static const String _biometricEnabledKey = 'biometric_enabled';
  static const String _userEmailKey = 'user_email_biometric';
  static const String _biometricTokenKey = 'biometric_auth_token';

  /// Check if biometric authentication is available on device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();

      if (!isAvailable || !isDeviceSupported) {
        return false;
      }

      final List<BiometricType> availableBiometrics =
          await _localAuth.getAvailableBiometrics();

      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get available biometric types for display
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  /// Check if user has enabled biometric authentication
  static Future<bool> isBiometricEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_biometricEnabledKey) ?? false;
  }

  /// Enable biometric authentication for user
  static Future<bool> enableBiometricAuth(
    String email,
    String authToken,
  ) async {
    try {
      final bool isAuthenticated = await _authenticateWithBiometric(
        reason: 'Enable biometric authentication for secure login',
      );

      if (isAuthenticated) {
        await _secureStorage.write(key: _userEmailKey, value: email);
        await _secureStorage.write(key: _biometricTokenKey, value: authToken);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_biometricEnabledKey, true);

        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Disable biometric authentication
  static Future<void> disableBiometricAuth() async {
    await _secureStorage.delete(key: _userEmailKey);
    await _secureStorage.delete(key: _biometricTokenKey);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
  }

  /// Authenticate with biometric and return stored credentials
  static Future<Map<String, String>?> authenticateWithBiometric() async {
    try {
      final bool isEnabled = await isBiometricEnabled();
      if (!isEnabled) return null;

      final bool isAuthenticated = await _authenticateWithBiometric(
        reason: 'Authenticate to access your account',
      );

      if (isAuthenticated) {
        final String? email = await _secureStorage.read(key: _userEmailKey);
        final String? token = await _secureStorage.read(
          key: _biometricTokenKey,
        );

        if (email != null && token != null) {
          return {'email': email, 'token': token};
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Private method to handle biometric authentication
  static Future<bool> _authenticateWithBiometric({
    required String reason,
  }) async {
    try {
      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: false, // Don't stick to auth after app goes to background
          biometricOnly: false, // Allow fallback to passcode if needed
          useErrorDialogs: true, // Show system error dialogs
          sensitiveTransaction: false, // This is not a payment
        ),
      );

      return isAuthenticated;
    } catch (e) {
      return false;
    }
  }

  /// Get biometric type name for display
  static String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.fingerprint:
        return 'Fingerprint';
      case BiometricType.iris:
        return 'Iris';
      case BiometricType.strong:
        return 'Biometric';
      case BiometricType.weak:
        return 'Biometric';
    }
  }
}
