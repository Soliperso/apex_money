import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../shared/services/auth_service.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/theme_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/app_card.dart';

enum PasswordStrength { none, weak, medium, strong, veryStrong }

class ModernRegisterPage extends StatefulWidget {
  const ModernRegisterPage({super.key});

  @override
  State<ModernRegisterPage> createState() => _ModernRegisterPageState();
}

class _ModernRegisterPageState extends State<ModernRegisterPage>
    with SingleTickerProviderStateMixin {
  // Controllers and services
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _passwordController.addListener(_onPasswordChanged);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: AppDuration.medium,
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
    });
  }

  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;

    // Return strength based on score
    if (score < 2) return PasswordStrength.weak;
    if (score < 4) return PasswordStrength.medium;
    if (score < 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Color _getPasswordStrengthColor() {
    switch (_passwordStrength) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return AppTheme.errorColor;
      case PasswordStrength.medium:
        return AppTheme.warningColor;
      case PasswordStrength.strong:
        return AppTheme.infoColor;
      case PasswordStrength.veryStrong:
        return AppTheme.successColor;
    }
  }

  String _getPasswordStrengthText() {
    switch (_passwordStrength) {
      case PasswordStrength.none:
        return '';
      case PasswordStrength.weak:
        return 'Weak';
      case PasswordStrength.medium:
        return 'Medium';
      case PasswordStrength.strong:
        return 'Strong';
      case PasswordStrength.veryStrong:
        return 'Very Strong';
    }
  }

  double _getPasswordStrengthProgress() {
    switch (_passwordStrength) {
      case PasswordStrength.none:
        return 0.0;
      case PasswordStrength.weak:
        return 0.2;
      case PasswordStrength.medium:
        return 0.4;
      case PasswordStrength.strong:
        return 0.7;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions to continue.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        _nameController.text.trim(),
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (mounted) {
        HapticFeedback.lightImpact();
        _showSuccessMessage('Account created successfully! Please sign in.');
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e.toString());
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('email already exists') || error.contains('409')) {
      return 'An account with this email already exists. Please sign in instead.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Registration failed. Please try again.';
  }

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Please enter your full name';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }

    final formattedEmail = value.toLowerCase().trim();
    if (formattedEmail != value) {
      _emailController.text = formattedEmail;
      _emailController.selection = TextSelection.fromPosition(
        TextPosition(offset: formattedEmail.length),
      );
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(formattedEmail)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (_passwordStrength == PasswordStrength.weak) {
      return 'Please choose a stronger password';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.successColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside input fields
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: AppGradientBackground(
          child: SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          (AppSpacing.screenPadding * 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Theme toggle and back button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (GoRouter.of(context).canPop())
                              IconButton(
                                onPressed: () {
                                  try {
                                    if (GoRouter.of(context).canPop()) {
                                      GoRouter.of(context).pop();
                                    } else {
                                      GoRouter.of(context).go('/login');
                                    }
                                  } catch (e) {
                                    GoRouter.of(context).go('/login');
                                  }
                                },
                                icon: Icon(
                                  Icons.arrow_back,
                                  color: theme.colorScheme.onSurface,
                                ),
                                tooltip: 'Back',
                              )
                            else
                              const SizedBox(width: 48),

                            IconButton(
                              onPressed: themeProvider.toggleTheme,
                              icon: Icon(
                                themeProvider.themeModeIcon,
                                color: theme.colorScheme.onSurface,
                              ),
                              tooltip:
                                  'Switch to ${themeProvider.isDarkMode ? 'light' : 'dark'} mode',
                            ),
                          ],
                        ),

                        const SizedBox(height: AppSpacing.lg),

                        // App Logo and Title
                        _buildHeader(theme),

                        const SizedBox(height: AppSpacing.huge),

                        // Registration Form
                        _buildRegistrationForm(theme),

                        const SizedBox(height: AppSpacing.xxl),

                        // Sign in link
                        _buildSignInLink(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            Icons.person_add_rounded,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Create Account',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Join Apex Money to manage your finances',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRegistrationForm(ThemeData theme) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_errorMessage != null) _buildErrorMessage(theme),

            // Full Name field
            TextFormField(
              controller: _nameController,
              textInputAction: TextInputAction.next,
              validator: _validateName,
              autofillHints: const [AutofillHints.name],
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your full name',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              validator: _validatePassword,
              autofillHints: const [AutofillHints.newPassword],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Create a strong password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),

            // Password strength indicator
            if (_passwordController.text.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _buildPasswordStrengthIndicator(theme),
            ],

            const SizedBox(height: AppSpacing.lg),

            // Confirm Password field
            TextFormField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              validator: _validateConfirmPassword,
              onFieldSubmitted: (_) => _register(),
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                hintText: 'Re-enter your password',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureConfirmPassword = !_obscureConfirmPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Terms and conditions
            CheckboxListTile(
              value: _acceptTerms,
              onChanged: (value) {
                setState(() {
                  _acceptTerms = value ?? false;
                });
              },
              title: Text.rich(
                TextSpan(
                  text: 'I agree to the ',
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: 'Terms of Service',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const TextSpan(text: ' and '),
                    TextSpan(
                      text: 'Privacy Policy',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Register button
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        _register();
                      },
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordStrengthIndicator(ThemeData theme) {
    final color = _getPasswordStrengthColor();
    final progress = _getPasswordStrengthProgress();
    final text = _getPasswordStrengthText();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password Strength', style: theme.textTheme.bodySmall),
            Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
        ),
      ],
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StatusCard(
        title: 'Registration Error',
        message: _errorMessage!,
        icon: Icons.error_outline,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildSignInLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => GoRouter.of(context).go('/login'),
          child: const Text('Sign in'),
        ),
      ],
    );
  }
}
