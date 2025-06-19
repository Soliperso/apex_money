import 'dart:async';
import 'package:apex_money/src/shared/services/auth_service.dart';

class UserProfileNotifier {
  static final UserProfileNotifier _instance = UserProfileNotifier._internal();
  final AuthService _authService = AuthService();

  // Stream controller for profile updates
  final _profileController = StreamController<Map<String, dynamic>>.broadcast();

  // Getter for the stream
  Stream<Map<String, dynamic>> get profileStream => _profileController.stream;

  // Cache the current profile
  Map<String, dynamic>? _currentProfile;
  Map<String, dynamic>? get currentProfile => _currentProfile;

  // Singleton constructor
  factory UserProfileNotifier() {
    return _instance;
  }

  UserProfileNotifier._internal();

  // Fetch and broadcast user profile
  Future<void> fetchUserProfile() async {
    try {
      final userProfile = await _authService.fetchUserProfile();
      _currentProfile = userProfile;
      _profileController.add(userProfile);
    } catch (e) {
      // Add error handling if needed
      print('Error fetching user profile: $e');
    }
  }

  // Method to update profile data and notify listeners
  Future<bool> updateUserProfile(Map<String, dynamic> updatedData) async {
    try {
      // In a real app, this would call the API to update the profile
      // For now, we'll just update our local cache and notify
      if (_currentProfile != null) {
        _currentProfile!.addAll(updatedData);
        _profileController.add(_currentProfile!);
      } else {
        await fetchUserProfile(); // Fetch if not already cached
      }
      return true;
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // Clean up resources
  void dispose() {
    _profileController.close();
  }
}
