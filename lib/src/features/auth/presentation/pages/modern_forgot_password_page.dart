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

class ModernForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ModernForgotPasswordPage({super.key, this.initialEmail});

  @override
  State<ModernForgotPasswordPage> createState() =>
      _ModernForgotPasswordPageState();
}

class _ModernForgotPasswordPageState extends State<ModernForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  // Controllers and services
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // State variables
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Set initial email if provided
    if (widget.initialEmail != null) {
      _emailController.text = widget.initialEmail!;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailController.dispose();
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

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _emailSent = true;
        });
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
    if (error.contains('user not found') || error.contains('404')) {
      return 'No account found with this email address.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Failed to send reset email. Please try again.';
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

  void _resendEmail() {
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
    _sendResetEmail();
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
                            IconButton(
                              onPressed: () {
                                try {
                                  if (GoRouter.of(context).canPop()) {
                                    GoRouter.of(context).pop();
                                  } else {
                                    // If there's nothing to pop, navigate to login
                                    GoRouter.of(context).go('/login');
                                  }
                                } catch (e) {
                                  // Fallback: always navigate to login if there's an error
                                  GoRouter.of(context).go('/login');
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back,
                                color: theme.colorScheme.onSurface,
                              ),
                              tooltip: 'Back',
                            ),

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

                        // Header
                        _buildHeader(theme),

                        const SizedBox(height: AppSpacing.huge),

                        // Main content
                        _emailSent
                            ? _buildSuccessCard(theme)
                            : _buildResetForm(theme),

                        const SizedBox(height: AppSpacing.xxl),

                        // Back to login link
                        _buildBackToLoginLink(theme),
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
            _emailSent
                ? Icons.mark_email_read_rounded
                : Icons.lock_reset_rounded,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          _emailSent ? 'Check Your Email' : 'Forgot Password?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _emailSent
              ? 'We\'ve sent password reset instructions to your email'
              : 'Enter your email address and we\'ll send you reset instructions',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildResetForm(ThemeData theme) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Error message
            if (_errorMessage != null) _buildErrorMessage(theme),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              validator: _validateEmail,
              onFieldSubmitted: (_) => _sendResetEmail(),
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email address',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Send reset email button
            ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        _sendResetEmail();
                      },
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Send Reset Instructions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessCard(ThemeData theme) {
    return AppCard(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 48,
              color: AppTheme.successColor,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Text(
            'Email Sent Successfully!',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.successColor,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          Text(
            'We\'ve sent password reset instructions to:',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),

          const SizedBox(height: AppSpacing.xs),

          Text(
            _emailController.text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Check your email and follow the instructions to reset your password. Don\'t forget to check your spam folder if you don\'t see it in your inbox.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppSpacing.xxl),

          // Resend button
          OutlinedButton(
            onPressed: _isLoading ? null : _resendEmail,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : const Text('Resend Email'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StatusCard(
        title: 'Reset Error',
        message: _errorMessage!,
        icon: Icons.error_outline,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildBackToLoginLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Remember your password? ',
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
