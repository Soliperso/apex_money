import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';
import 'package:apex_money/src/shared/services/user_profile_notifier.dart';
import 'package:apex_money/src/shared/utils/avatar_utils.dart';
import 'package:apex_money/src/shared/widgets/app_gradient_background.dart';
import 'package:apex_money/src/shared/theme/app_spacing.dart';
import 'package:apex_money/src/shared/theme/theme_provider.dart';
import 'package:apex_money/src/shared/theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  // Settings state variables
  bool _notificationsEnabled = true;
  bool _biometricEnabled = false;
  String _selectedCurrency = 'USD';

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
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

        // Auto-logout if authentication failed
        if (error.toString().contains('No access token found') ||
            error.toString().contains('unauthorized') ||
            error.toString().contains('401')) {
          _performAutoLogout();
        }
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
            backgroundColor: AppTheme.successColor,
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
                  await _performLogout();
                },
                child: const Text(
                  'Logout',
                  style: TextStyle(color: AppTheme.errorColor),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _performLogout() async {
    await _authService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (context.mounted) {
      GoRouter.of(context).go('/login');
    }
  }

  Future<void> _performAutoLogout() async {
    // Show a brief message before auto-logout
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session expired. Redirecting to login...'),
        backgroundColor: AppTheme.errorColor,
        duration: Duration(seconds: 2),
      ),
    );

    // Delay for user to see the message
    await Future.delayed(const Duration(seconds: 2));
    await _performLogout();
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('network') || error.contains('connection')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('unauthorized') || error.contains('401')) {
      return 'Session expired. Please login again.';
    } else if (error.contains('No access token found')) {
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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: AppGradientBackground(
        child: CustomScrollView(
          slivers: [
            // Modern App Bar matching dashboard
            _buildSliverAppBar(theme, themeProvider),
            SliverToBoxAdapter(
              child:
                  _isLoading
                      ? Container(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.primary,
                            ),
                          ),
                        ),
                      )
                      : Padding(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              // Profile Picture Section
                              Center(
                                child: Stack(
                                  children: [
                                    AvatarUtils.buildAvatar(
                                      context: context,
                                      userName: _nameController.text,
                                      profilePicture: _profilePicture,
                                      radius: 50,
                                      fontSize: 30,
                                      style: AvatarStyle.standard,
                                      showBorder: false,
                                      enableAnimation: false,
                                      onTap: () {
                                        if (_isEditing) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Image picker feature coming soon!',
                                              ),
                                              backgroundColor:
                                                  AppTheme.primaryColor,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                    if (_isEditing)
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: theme.colorScheme.primary,
                                            shape: BoxShape.circle,
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
                                                  backgroundColor:
                                                      AppTheme.primaryColor,
                                                ),
                                              );
                                            },
                                            icon: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.xl),

                              // Profile Form Card
                              Container(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                decoration: BoxDecoration(
                                  color:
                                      theme.brightness == Brightness.dark
                                          ? theme.colorScheme.surfaceContainer
                                              .withValues(alpha: 0.6)
                                          : theme.colorScheme.surface
                                              .withValues(alpha: 0.5),
                                  borderRadius: BorderRadius.circular(
                                    AppSpacing.radiusMd,
                                  ),
                                  border: Border.all(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Section Header
                                    Text(
                                      'Profile Information',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Error Message
                                    if (_errorMessage != null)
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        margin: const EdgeInsets.only(
                                          bottom: 16,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme
                                              .colorScheme
                                              .errorContainer
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: theme.colorScheme.error
                                                .withValues(alpha: 0.3),
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
                                                  color:
                                                      theme.colorScheme.error,
                                                  fontWeight: FontWeight.w500,
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
                                      decoration: InputDecoration(
                                        labelText: 'Full Name',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.auto,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.outline
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
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
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        floatingLabelBehavior:
                                            FloatingLabelBehavior.auto,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.outline
                                                .withValues(alpha: 0.5),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                            width: 2,
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
                                        decoration: InputDecoration(
                                          labelText: 'New Password (optional)',
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                    !_obscurePassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                        decoration: InputDecoration(
                                          labelText: 'Confirm New Password',
                                          floatingLabelBehavior:
                                              FloatingLabelBehavior.auto,
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _obscureConfirmPassword
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                      .visibility_off_outlined,
                                            ),
                                            onPressed: () {
                                              setState(() {
                                                _obscureConfirmPassword =
                                                    !_obscureConfirmPassword;
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.outline
                                                  .withValues(alpha: 0.5),
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
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
                                            child: OutlinedButton(
                                              onPressed:
                                                  _isSaving
                                                      ? null
                                                      : () {
                                                        setState(() {
                                                          _isEditing = false;
                                                          _passwordController
                                                              .clear();
                                                          _confirmPasswordController
                                                              .clear();
                                                        });
                                                      },
                                              style: OutlinedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Cancel'),
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed:
                                                  _isSaving
                                                      ? null
                                                      : _saveProfile,
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child:
                                                  _isSaving
                                                      ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                      : const Text(
                                                        'Save Changes',
                                                      ),
                                            ),
                                          ),
                                        ] else ...[
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () {
                                                setState(() {
                                                  _isEditing = true;
                                                });
                                              },
                                              style: ElevatedButton.styleFrom(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 16,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('Edit Profile'),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Settings Section
                              _buildSettingsSection(),
                            ],
                          ),
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ThemeProvider themeProvider) {
    final appBarColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.primary.withValues(alpha: 0.95);

    final titleColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : Colors.white;

    final iconColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9);

    return SliverAppBar(
      floating: false,
      pinned: true,
      expandedHeight: 56,
      backgroundColor: appBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: theme.colorScheme.shadow,
      forceElevated: false,
      systemOverlayStyle:
          theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(
            bottom: BorderSide(
              color:
                  theme.brightness == Brightness.dark
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
        color: iconColor,
        tooltip: 'Back to Dashboard',
      ),
      title: Text(
        'Profile',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      actions: [
        // Theme toggle
        IconButton(
          onPressed: themeProvider.toggleTheme,
          icon: Icon(themeProvider.themeModeIcon),
          tooltip: 'Switch theme',
          color: iconColor,
        ),

        // Logout button
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.md,
            left: AppSpacing.xs,
          ),
          child: IconButton(
            onPressed: _logout,
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            color: iconColor,
          ),
        ),
      ],
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

  // Settings section
  Widget _buildSettingsSection() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),

          // Dark Mode Toggle
          _buildSimpleToggle(
            'Dark Mode',
            'Switch app theme',
            Icons.dark_mode_outlined,
            themeProvider.themeMode == ThemeMode.dark,
            (value) => themeProvider.toggleTheme(),
          ),

          // Notifications Toggle
          _buildSimpleToggle(
            'Notifications',
            'Receive app notifications',
            Icons.notifications_outlined,
            _notificationsEnabled,
            (value) => setState(() => _notificationsEnabled = value),
          ),

          // Currency Selection
          _buildSimpleDropdown(
            'Currency',
            'Default currency',
            Icons.attach_money,
            _selectedCurrency,
            ['USD', 'EUR', 'GBP', 'CAD', 'AUD'],
            (value) => setState(() => _selectedCurrency = value),
          ),

          // Biometric Authentication
          _buildSimpleToggle(
            'Biometric Authentication',
            'Use fingerprint or face unlock',
            Icons.fingerprint,
            _biometricEnabled,
            (value) => setState(() => _biometricEnabled = value),
          ),

          const Divider(height: 32),

          // Action buttons
          _buildSimpleAction(
            'Change Password',
            'Update your password',
            Icons.lock_outlined,
            () => _showChangePasswordDialog(),
          ),

          _buildSimpleAction(
            'Delete Account',
            'Permanently delete account',
            Icons.delete_forever_outlined,
            () => _showDeleteAccountDialog(),
            isDestructive: true,
          ),
        ],
      ),
    );
  }

  // Simple toggle tile
  Widget _buildSimpleToggle(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 20,
            child: Transform.scale(
              scale: 0.8,
              child: Switch.adaptive(
                value: value,
                onChanged: onChanged,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Simple dropdown tile
  Widget _buildSimpleDropdown(
    String title,
    String subtitle,
    IconData icon,
    String value,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 22, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: value,
            underline: const SizedBox.shrink(),
            items:
                options
                    .map(
                      (option) =>
                          DropdownMenuItem(value: option, child: Text(option)),
                    )
                    .toList(),
            onChanged:
                (newValue) => newValue != null ? onChanged(newValue) : null,
          ),
        ],
      ),
    );
  }

  // Simple action tile
  Widget _buildSimpleAction(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color:
                  isDestructive
                      ? theme.colorScheme.error
                      : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color:
                          isDestructive
                              ? theme.colorScheme.error
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for actions
  void _showComingSoonSnackbar(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: AppTheme.primaryColor,
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

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Delete Account',
              style: TextStyle(color: AppTheme.errorColor),
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
                  backgroundColor: AppTheme.errorColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }
}
