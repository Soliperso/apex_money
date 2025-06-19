import 'package:flutter/material.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';
import 'package:apex_money/src/shared/services/user_profile_notifier.dart';
import 'package:apex_money/src/shared/utils/avatar_utils.dart';
import 'package:apex_money/src/shared/widgets/app_gradient_background.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Achievement model
class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final DateTime? unlockedDate;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    this.unlockedDate,
  });
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();
  final UserProfileNotifier _profileNotifier = UserProfileNotifier();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isEditing = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _profilePicture;
  String? _errorMessage;

  // Modern UI state variables
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  bool _analyticsEnabled = true;
  bool _darkModeEnabled = false;
  String _selectedCurrency = 'USD';
  String _selectedLanguage = 'English';

  // Expandable sections state
  bool _isSecurityExpanded = false;
  bool _isPreferencesExpanded = false;
  bool _isPrivacyExpanded = false;

  // Achievement data
  List<Achievement> _achievements = [];

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _loadAchievements();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use the profile notifier to fetch and broadcast the user profile
      await _profileNotifier.fetchUserProfile();
      final userProfile = _profileNotifier.currentProfile;

      if (mounted && userProfile != null) {
        setState(() {
          _nameController.text = userProfile['name'] ?? '';
          _emailController.text = userProfile['email'] ?? '';
          _profilePicture = userProfile['profile_picture'];
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(error.toString());
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      // In a real app, this would call an API to update profile
      await Future.delayed(const Duration(seconds: 2)); // Simulate API call

      // Create a profile update data map
      final updatedProfile = {
        'name': _nameController.text,
        'email': _emailController.text,
        'profile_picture': _profilePicture,
      };

      // Update through the notifier to broadcast changes
      await _profileNotifier.updateUserProfile(updatedProfile);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isEditing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(error.toString());
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Logout'),
            content: const Text('Are you sure you want to logout?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _authService.logout();
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    GoRouter.of(context).go('/login');
                  }
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('unauthorized') || error.contains('401')) {
      return 'Session expired. Please login again.';
    }
    return 'Something went wrong. Please try again.';
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (!_isEditing || value == null || value.isEmpty) {
      return null; // Password is optional when not editing
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (!_isEditing || _passwordController.text.isEmpty) {
      return null;
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.onSurface
                : Colors.white,
          ),
        ),
        backgroundColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.primary.withValues(alpha: 0.95),
        foregroundColor: theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.surface.withValues(alpha: 0.95)
                : theme.colorScheme.primary.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: theme.brightness == Brightness.dark
                    ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => GoRouter.of(context).go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.onSurfaceVariant
              : Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            color: theme.brightness == Brightness.dark
                ? theme.colorScheme.onSurfaceVariant
                : Colors.white,
          ),
        ],
      ),
      body: AppGradientBackground(
        child:
            _isLoading
                ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                )
                : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Profile Picture Section
                        Stack(
                          children: [
                            AvatarUtils.buildAvatar(
                              userName: _nameController.text,
                              profilePicture: _profilePicture,
                              radius: 60,
                              fontSize: 36,
                              style: AvatarStyle.premium,
                              status: StatusIndicator.verified,
                              showBorder: true,
                              borderColor: Colors.white,
                              borderWidth: 4,
                              enableAnimation: true,
                              onTap: () {
                                if (_isEditing) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Image picker feature coming soon!',
                                      ),
                                      backgroundColor: Colors.blueAccent,
                                    ),
                                  );
                                }
                              },
                            ),
                            if (_isEditing)
                              Positioned(
                                bottom: 5,
                                left: 5,
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF6366F1),
                                        Color(0xFF8B5CF6),
                                      ],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6366F1,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: IconButton(
                                    onPressed: () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Image picker feature coming soon!',
                                          ),
                                          backgroundColor: Colors.blueAccent,
                                        ),
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 40),

                        // Profile Form Card
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(28),
                            color: theme.colorScheme.surface,
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                spreadRadius: 0,
                                blurRadius: 32,
                                offset: const Offset(0, 16),
                              ),
                              BoxShadow(
                                color: theme.colorScheme.shadow.withValues(alpha: 0.08),
                                spreadRadius: 0,
                                blurRadius: 64,
                                offset: const Offset(0, 32),
                              ),
                              if (theme.brightness == Brightness.light)
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  spreadRadius: 1,
                                  blurRadius: 0,
                                  offset: const Offset(0, -1),
                                ),
                            ],
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              children: [
                                // Profile Completion Progress
                                _buildProfileCompletion(),
                                const SizedBox(height: 16),

                                // Achievement Badges
                                _buildAchievementBadges(),
                                const SizedBox(height: 12),

                                // Error Message
                                if (_errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: theme.colorScheme.error.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: theme.colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: theme.colorScheme.onErrorContainer,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Name Field
                                TextFormField(
                                  controller: _nameController,
                                  enabled: _isEditing,
                                  validator: _validateName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Full Name',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.person_outline_rounded,
                                        color: theme.colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: _isEditing
                                        ? theme.colorScheme.surface
                                        : theme.colorScheme.surfaceContainer,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2.5,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),

                                // Email Field
                                TextFormField(
                                  controller: _emailController,
                                  enabled: _isEditing,
                                  validator: _validateEmail,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email Address',
                                    labelStyle: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    prefixIcon: Container(
                                      margin: const EdgeInsets.all(8),
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.email_outlined,
                                        color: theme.colorScheme.primary,
                                        size: 16,
                                      ),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 14,
                                    ),
                                    filled: true,
                                    fillColor: _isEditing
                                        ? theme.colorScheme.surface
                                        : theme.colorScheme.surfaceContainer,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide.none,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline,
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2.5,
                                      ),
                                    ),
                                    disabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                  ),
                                ),

                                // Password Fields (only when editing)
                                if (_isEditing) ...[
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    validator: _validatePassword,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'New Password (optional)',
                                      labelStyle: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surfaceContainer,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _confirmPasswordController,
                                    obscureText: _obscureConfirmPassword,
                                    validator: _validateConfirmPassword,
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurface,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Confirm New Password',
                                      labelStyle: TextStyle(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      prefixIcon: Icon(
                                        Icons.lock_outline,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscureConfirmPassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscureConfirmPassword =
                                                !_obscureConfirmPassword;
                                          });
                                        },
                                      ),
                                      filled: true,
                                      fillColor: theme.colorScheme.surfaceContainer,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.outline,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: theme.colorScheme.primary,
                                          width: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 20),

                                // Action Buttons
                                Row(
                                  children: [
                                    if (_isEditing) ...[
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            color: theme.colorScheme.surfaceContainer,
                                            border: Border.all(
                                              color: theme.colorScheme.outline,
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                                                spreadRadius: 0,
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: OutlinedButton(
                                            onPressed: _isSaving
                                                ? null
                                                : () {
                                                  setState(() {
                                                    _isEditing = false;
                                                    _passwordController.clear();
                                                    _confirmPasswordController.clear();
                                                  });
                                                },
                                            style: OutlinedButton.styleFrom(
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                              side: BorderSide.none,
                                              elevation: 0,
                                            ),
                                            child: Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurfaceVariant,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            color: theme.colorScheme.primary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                spreadRadius: 0,
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: _isSaving ? null : _saveProfile,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: _isSaving
                                                ? SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(
                                                      theme.colorScheme.onPrimary,
                                                    ),
                                                  ),
                                                )
                                                : Text(
                                                  'Save Changes',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: theme.colorScheme.onPrimary,
                                                  ),
                                                ),
                                          ),
                                        ),
                                      ),
                                    ] else ...[
                                      Expanded(
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            color: theme.colorScheme.primary,
                                            boxShadow: [
                                              BoxShadow(
                                                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                                spreadRadius: 0,
                                                blurRadius: 12,
                                                offset: const Offset(0, 6),
                                              ),
                                            ],
                                          ),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = true;
                                              });
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.transparent,
                                              shadowColor: Colors.transparent,
                                              padding: const EdgeInsets.symmetric(vertical: 18),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: Text(
                                              'Edit Profile',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onPrimary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // App Settings Section
                        _buildExpandableSection(
                          'App Settings',
                          Icons.settings_outlined,
                          _isPreferencesExpanded,
                          () => setState(
                            () =>
                                _isPreferencesExpanded =
                                    !_isPreferencesExpanded,
                          ),
                          [
                            _buildToggleTile(
                              'Dark Mode',
                              'Switch to dark theme',
                              Icons.dark_mode_outlined,
                              _darkModeEnabled,
                              (value) =>
                                  setState(() => _darkModeEnabled = value),
                            ),
                            _buildToggleTile(
                              'Push Notifications',
                              'Receive app notifications',
                              Icons.notifications_outlined,
                              _notificationsEnabled,
                              (value) =>
                                  setState(() => _notificationsEnabled = value),
                            ),
                            _buildDropdownTile(
                              'Currency',
                              'Default currency for transactions',
                              Icons.attach_money,
                              _selectedCurrency,
                              ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
                              (value) =>
                                  setState(() => _selectedCurrency = value),
                            ),
                            _buildDropdownTile(
                              'Language',
                              'App display language',
                              Icons.language,
                              _selectedLanguage,
                              ['English', 'Spanish', 'French', 'German'],
                              (value) =>
                                  setState(() => _selectedLanguage = value),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Security Settings Section
                        _buildExpandableSection(
                          'Security & Privacy',
                          Icons.security_outlined,
                          _isSecurityExpanded,
                          () => setState(
                            () => _isSecurityExpanded = !_isSecurityExpanded,
                          ),
                          [
                            _buildToggleTile(
                              'Biometric Authentication',
                              'Use fingerprint or face unlock',
                              Icons.fingerprint,
                              _biometricEnabled,
                              (value) =>
                                  setState(() => _biometricEnabled = value),
                              customIconColor: Colors.lightBlue,
                            ),
                            _buildToggleTile(
                              'Analytics',
                              'Help improve the app with usage data',
                              Icons.analytics_outlined,
                              _analyticsEnabled,
                              (value) =>
                                  setState(() => _analyticsEnabled = value),
                            ),
                            _buildActionTile(
                              'Change Password',
                              'Update your account password',
                              Icons.lock_outlined,
                              () => _showChangePasswordDialog(),
                            ),
                            _buildActionTile(
                              'Two-Factor Authentication',
                              'Add extra security to your account',
                              Icons.verified_user_outlined,
                              () => _showComingSoonSnackbar('2FA setup'),
                            ),
                          ],
                        ),

                        const SizedBox(height: 6),

                        // Data & Privacy Section
                        _buildExpandableSection(
                          'Data & Privacy',
                          Icons.privacy_tip_outlined,
                          _isPrivacyExpanded,
                          () => setState(
                            () => _isPrivacyExpanded = !_isPrivacyExpanded,
                          ),
                          [
                            _buildActionTile(
                              'Export Data',
                              'Download your financial data',
                              Icons.download_outlined,
                              () => _exportUserData(),
                            ),
                            _buildActionTile(
                              'Privacy Policy',
                              'View our privacy policy',
                              Icons.policy_outlined,
                              () => _showComingSoonSnackbar('Privacy policy'),
                            ),
                            _buildActionTile(
                              'Terms of Service',
                              'Read terms and conditions',
                              Icons.description_outlined,
                              () => _showComingSoonSnackbar('Terms of service'),
                            ),
                            _buildActionTile(
                              'Delete Account',
                              'Permanently delete your account',
                              Icons.delete_forever_outlined,
                              () => _showDeleteAccountDialog(),
                              isDestructive: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Profile completion calculation
  Widget _buildProfileCompletion() {
    final theme = Theme.of(context);
    int completedFields = 0;
    int totalFields = 4;

    if (_nameController.text.isNotEmpty) completedFields++;
    if (_emailController.text.isNotEmpty) completedFields++;
    if (_profilePicture != null) completedFields++;
    if (_biometricEnabled || _notificationsEnabled) completedFields++;

    double completionPercentage = completedFields / totalFields;

    // Determine colors based on completion and theme
    Color progressColor;
    String statusText;

    if (completionPercentage == 1.0) {
      progressColor = theme.brightness == Brightness.dark 
          ? const Color(0xFF81C784) 
          : const Color(0xFF4CAF50);
      statusText = 'Complete!';
    } else if (completionPercentage >= 0.75) {
      progressColor = theme.colorScheme.primary;
      statusText = 'Almost there';
    } else if (completionPercentage >= 0.5) {
      progressColor = theme.brightness == Brightness.dark 
          ? const Color(0xFF26C6DA) 
          : const Color(0xFF00BCD4);
      statusText = 'Good progress';
    } else {
      progressColor = theme.brightness == Brightness.dark 
          ? const Color(0xFF9575CD) 
          : const Color(0xFF9C27B0);
      statusText = 'Getting started';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: progressColor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: progressColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: progressColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${(completionPercentage * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black26,
                      offset: Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Enhanced progress bar
        Container(
          height: 12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.surfaceContainer,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                blurRadius: 4,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Stack(
              children: [
                // Background track
                Container(
                  width: double.infinity,
                  height: 12,
                  color: theme.colorScheme.surfaceContainerHighest,
                ),

                // Progress fill
                if (completionPercentage > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: completionPercentage,
                    child: Container(
                      height: 12,
                      decoration: BoxDecoration(
                        color: progressColor,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: progressColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            spreadRadius: 0,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Highlight effect on progress bar
                if (completionPercentage > 0)
                  FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: completionPercentage,
                    child: Container(
                      height: 6,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.3),
                            Colors.white.withValues(alpha: 0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        // Progress milestones
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildProgressMilestone('Basic Info', completedFields >= 2, theme),
            _buildProgressMilestone('Profile Photo', _profilePicture != null, theme),
            _buildProgressMilestone(
              'Security',
              _biometricEnabled || _notificationsEnabled,
              theme,
            ),
            _buildProgressMilestone('Complete', completionPercentage == 1.0, theme),
          ],
        ),
      ],
    );
  }

  // Build progress milestone indicator
  Widget _buildProgressMilestone(String label, bool isCompleted, ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isCompleted 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            shape: BoxShape.circle,
            boxShadow: isCompleted
                ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 4,
                    spreadRadius: 0,
                    offset: const Offset(0, 1),
                  ),
                ]
                : null,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isCompleted 
                ? theme.colorScheme.onSurface 
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  // Modern expandable section builder
  Widget _buildExpandableSection(
    String title,
    IconData icon,
    bool isExpanded,
    VoidCallback onToggle,
    List<Widget> children,
  ) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.08),
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.05),
            spreadRadius: 0,
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          blurRadius: 8,
                          spreadRadius: 0,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Icon(
                      icon,
                      color: theme.colorScheme.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child:
                isExpanded
                    ? Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        bottom: 16,
                      ),
                      child: Column(children: children),
                    )
                    : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  // Modern toggle tile
  Widget _buildToggleTile(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged, {
    Color? customBackgroundColor,
    Color? customIconColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: customBackgroundColor ?? theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: value
                ? (customIconColor?.withValues(alpha: 0.1) ?? 
                   theme.colorScheme.primary.withValues(alpha: 0.1))
                : theme.colorScheme.outline.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: value
                ? (customIconColor ?? theme.colorScheme.primary)
                : theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        trailing: Transform.scale(
          scale: 0.8,
          child: Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: theme.colorScheme.primary,
          ),
        ),
      ),
    );
  }

  // Modern dropdown tile
  Widget _buildDropdownTile(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 11,
          ),
        ),
        trailing: DropdownButton<String>(
          value: value,
          underline: const SizedBox.shrink(),
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: theme.colorScheme.surface,
          items: options
              .map(
                (option) => DropdownMenuItem(
                  value: option,
                  child: Text(
                    option,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (newValue) => newValue != null ? onChanged(newValue) : null,
        ),
      ),
    );
  }

  // Modern action tile
  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDestructive
                ? theme.colorScheme.error.withValues(alpha: 0.1)
                : theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive 
                ? theme.colorScheme.error 
                : theme.colorScheme.primary,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: isDestructive 
                ? theme.colorScheme.error 
                : theme.colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: theme.colorScheme.onSurfaceVariant,
            fontSize: 13,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        onTap: onTap,
      ),
    );
  }

  // Helper methods for actions
  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Change Password'),
            content: const Text(
              'Password change functionality will be available soon.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _exportUserData() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Export Data'),
            content: const Text(
              'Your data export will be prepared and sent to your email address. This may take a few minutes.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showComingSoonSnackbar('Data export');
                },
                child: const Text('Export'),
              ),
            ],
          ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: Colors.red),
            ),
            content: const Text(
              'Are you sure you want to permanently delete your account? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showComingSoonSnackbar('Account deletion');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  // Load financial statistics

  // Load achievements
  void _loadAchievements() {
    // Simulate achievement logic
    setState(() {
      _achievements = [
        Achievement(
          id: 'first_transaction',
          title: 'First Steps',
          description: 'Added your first transaction',
          icon: Icons.star,
          color: const Color(0xFF64B5F6), // Light Blue
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        ),
        Achievement(
          id: 'goal_setter',
          title: 'Goal Setter',
          description: 'Created your first financial goal',
          icon: Icons.flag,
          color: const Color(0xFF26C6DA), // Cyan
          isUnlocked: true,
          unlockedDate: DateTime.now(),
        ),
        Achievement(
          id: 'saver',
          title: 'Smart Saver',
          description: 'Achieved positive savings rate',
          icon: Icons.savings,
          color: const Color(0xFF81C784), // Light Green
          isUnlocked: false,
          unlockedDate: DateTime.now(),
        ),
        Achievement(
          id: 'tracker',
          title: 'Expense Tracker',
          description: 'Logged 10+ transactions',
          icon: Icons.trending_up,
          color: const Color(0xFF9575CD), // Light Purple
          isUnlocked: false,
          unlockedDate: DateTime.now(),
        ),
      ];
    });
  }

  // Build achievement badges
  Widget _buildAchievementBadges() {
    final theme = Theme.of(context);
    final unlockedAchievements =
        _achievements.where((a) => a.isUnlocked).toList();

    if (unlockedAchievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 16),
            const SizedBox(width: 6),
            Text(
              'Achievements (${unlockedAchievements.length}/${_achievements.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 95,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: _buildAchievementBadge(achievement),
              );
            },
          ),
        ),
      ],
    );
  }

  // Build individual achievement badge
  Widget _buildAchievementBadge(Achievement achievement) {
    return _AnimatedAchievementBadge(
      achievement: achievement,
      onTap: () => _showAchievementDetails(achievement),
    );
  }

  // Show achievement details
  void _showAchievementDetails(Achievement achievement) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  achievement.icon,
                  color:
                      achievement.isUnlocked ? achievement.color : Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    achievement.title,
                    style: TextStyle(
                      color:
                          achievement.isUnlocked
                              ? achievement.color
                              : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(achievement.description),
                if (achievement.isUnlocked) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'Achievement Unlocked!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Keep going to unlock!',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }
}

/// Enhanced animated achievement badge with premium styling
class _AnimatedAchievementBadge extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback onTap;

  const _AnimatedAchievementBadge({
    required this.achievement,
    required this.onTap,
  });

  @override
  State<_AnimatedAchievementBadge> createState() =>
      _AnimatedAchievementBadgeState();
}

class _AnimatedAchievementBadgeState extends State<_AnimatedAchievementBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _glowAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> _getGradientColors() {
    if (!widget.achievement.isUnlocked) {
      return [Colors.grey.shade300, Colors.grey.shade400];
    }

    // Create gradient based on achievement color
    final baseColor = widget.achievement.color;
    return [baseColor.withValues(alpha: 0.8), baseColor.withValues(alpha: 0.6)];
  }

  @override
  Widget build(BuildContext context) {
    final gradientColors = _getGradientColors();

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: 80,
              height: 85,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  // Primary shadow
                  BoxShadow(
                    color:
                        widget.achievement.isUnlocked
                            ? widget.achievement.color.withValues(
                              alpha: 0.3 * _glowAnimation.value,
                            )
                            : Colors.grey.withValues(alpha: 0.2),
                    blurRadius: 12 * _glowAnimation.value,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                  // Secondary depth shadow
                  BoxShadow(
                    color:
                        widget.achievement.isUnlocked
                            ? widget.achievement.color.withValues(
                              alpha: 0.1 * _glowAnimation.value,
                            )
                            : Colors.grey.withValues(alpha: 0.1),
                    blurRadius: 20 * _glowAnimation.value,
                    spreadRadius: -2,
                    offset: const Offset(0, 8),
                  ),
                  // Inner highlight
                  if (widget.achievement.isUnlocked)
                    BoxShadow(
                      color: Colors.white.withValues(alpha: 0.2),
                      blurRadius: 1,
                      spreadRadius: 1,
                      offset: const Offset(0, -1),
                    ),
                ],
                border: Border.all(
                  color:
                      widget.achievement.isUnlocked
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient:
                      widget.achievement.isUnlocked
                          ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.1),
                              Colors.transparent,
                            ],
                          )
                          : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Achievement Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color:
                            widget.achievement.isUnlocked
                                ? Colors.white.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.achievement.icon,
                        size: 20,
                        color:
                            widget.achievement.isUnlocked
                                ? Colors.white
                                : Colors.grey.shade600,
                        shadows:
                            widget.achievement.isUnlocked
                                ? [
                                  Shadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    offset: const Offset(0, 1),
                                    blurRadius: 2,
                                  ),
                                ]
                                : null,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Achievement Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        widget.achievement.title,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color:
                              widget.achievement.isUnlocked
                                  ? Colors.white
                                  : Colors.grey.shade600,
                          letterSpacing: 0.2,
                          shadows:
                              widget.achievement.isUnlocked
                                  ? [
                                    Shadow(
                                      color: Colors.black.withValues(
                                        alpha: 0.4,
                                      ),
                                      offset: const Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ]
                                  : null,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // Unlocked indicator
                    if (widget.achievement.isUnlocked)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 2,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
