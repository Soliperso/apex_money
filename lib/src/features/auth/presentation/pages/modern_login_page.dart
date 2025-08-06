import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../shared/services/auth_service.dart';
import '../../../../shared/services/biometric_auth_service.dart';
import '../../../../shared/services/login_attempt_service.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/theme_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/app_card.dart';

class ModernLoginPage extends StatefulWidget {
  const ModernLoginPage({super.key});

  @override
  State<ModernLoginPage> createState() => _ModernLoginPageState();
}

class _ModernLoginPageState extends State<ModernLoginPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // Controllers and services
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  // State variables
  bool _isLoading = false;
  String? _errorMessage;
  bool _keepSignedIn = false;
  bool _obscurePassword = true;
  bool _isSettingUpBiometric = false;

  // Biometric state
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];

  // Security state
  bool _isLockedOut = false;
  int _remainingLockoutTime = 0;
  int _remainingAttempts = 5;

  // Email suggestions (not used in this simplified version)
  // List<String> _emailSuggestions = [];

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Force dismiss keyboard if it's stuck from previous screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusManager.instance.primaryFocus?.unfocus();
      SystemChannels.textInput.invokeMethod('TextInput.hide');
    });

    _initializeAnimations();
    _initializeAuth();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
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

  Future<void> _initializeAuth() async {
    await Future.wait([
      _loadPreferences(),
      _checkBiometricAvailability(),
      _checkLockoutStatus(),
    ]);

    if (_isBiometricAvailable && _isBiometricEnabled && !_isLockedOut) {
      _attemptBiometricLogin();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _keepSignedIn = prefs.getBool('keepSignedIn') ?? false;
          _emailController.text = prefs.getString('email') ?? '';
        });
      }
    } catch (e) {
      debugPrint('Failed to load preferences: $e');
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final available = await BiometricAuthService.isBiometricAvailable();
      final enabled = await BiometricAuthService.isBiometricEnabled();
      final biometrics = await BiometricAuthService.getAvailableBiometrics();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = available;
          _isBiometricEnabled = enabled;
          _availableBiometrics = biometrics;
        });
      }
    } catch (e) {
      debugPrint('Biometric check failed: $e');
    }
  }

  Future<void> _checkLockoutStatus() async {
    try {
      final isLockedOut = await LoginAttemptService.isLockedOut();
      if (isLockedOut) {
        final remainingTime =
            await LoginAttemptService.getRemainingLockoutTime();
        if (mounted) {
          setState(() {
            _isLockedOut = true;
            _remainingLockoutTime = remainingTime;
          });
          _startLockoutTimer();
        }
      } else {
        await _updateRemainingAttempts();
      }
    } catch (e) {
      debugPrint('Lockout check failed: $e');
    }
  }

  Future<void> _updateRemainingAttempts() async {
    if (_emailController.text.isNotEmpty) {
      try {
        final attempts = await LoginAttemptService.getRemainingAttempts(
          _emailController.text,
        );
        if (mounted) {
          setState(() {
            _remainingAttempts = attempts;
          });
        }
      } catch (e) {
        debugPrint('Failed to update remaining attempts: $e');
      }
    }
  }

  void _startLockoutTimer() {
    if (_remainingLockoutTime > 0) {
      Future.delayed(const Duration(minutes: 1), () async {
        if (mounted) {
          final stillLockedOut = await LoginAttemptService.isLockedOut();
          if (stillLockedOut) {
            final newRemainingTime =
                await LoginAttemptService.getRemainingLockoutTime();
            setState(() {
              _remainingLockoutTime = newRemainingTime;
            });
            if (newRemainingTime > 0) {
              _startLockoutTimer();
            } else {
              setState(() {
                _isLockedOut = false;
              });
            }
          } else {
            setState(() {
              _isLockedOut = false;
              _remainingLockoutTime = 0;
            });
          }
        }
      });
    }
  }

  Future<void> _attemptBiometricLogin() async {
    try {
      final credentials =
          await BiometricAuthService.authenticateWithBiometric();
      if (credentials != null && mounted) {
        await _performBiometricLogin(credentials);
      }
    } catch (e) {
      debugPrint('Biometric login attempt failed: $e');
    }
  }

  Future<void> _performBiometricLogin(Map<String, String> credentials) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', credentials['token']!);

      if (mounted) {
        HapticFeedback.lightImpact();
        _showSuccessMessage('Biometric login successful!');
        GoRouter.of(context).go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Biometric login failed. Please use email and password.';
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    if (await LoginAttemptService.isLockedOut()) {
      final remainingTime = await LoginAttemptService.getRemainingLockoutTime();
      setState(() {
        _errorMessage =
            'Account temporarily locked. Try again in $remainingTime minutes.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final loginResult = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      await _savePreferences();

      if (_isBiometricAvailable && !_isBiometricEnabled && mounted) {
        _showBiometricSetupDialog(loginResult['access_token']);
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        _showSuccessMessage('Login successful!');
        GoRouter.of(context).go('/dashboard');
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.mediumImpact();
        await _updateRemainingAttempts();
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

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('keepSignedIn', _keepSignedIn);
      if (_keepSignedIn) {
        await prefs.setString('email', _emailController.text);
      } else {
        await prefs.remove('email');
        await prefs.remove('access_token');
      }
    } catch (e) {
      debugPrint('Failed to save preferences: $e');
    }
  }

  void _showBiometricSetupDialog(String authToken) {
    final theme = Theme.of(context);
    final biometricName =
        _availableBiometrics.isNotEmpty
            ? BiometricAuthService.getBiometricTypeName(
              _availableBiometrics.first,
            )
            : 'Biometric';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(_getBiometricIcon(), color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Enable $biometricName Login?'),
              ],
            ),
            content: Text(
              'Would you like to enable $biometricName authentication for faster and more secure login?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not Now'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _setupBiometricAuth(authToken);
                },
                child: const Text('Enable'),
              ),
            ],
          ),
    );
  }

  Future<void> _setupBiometricAuth(String authToken) async {
    setState(() {
      _isSettingUpBiometric = true;
    });

    try {
      final success = await BiometricAuthService.enableBiometricAuth(
        _emailController.text.trim(),
        authToken,
      );

      if (success && mounted) {
        setState(() {
          _isBiometricEnabled = true;
        });
        _showSuccessMessage('Biometric authentication enabled!');
      }
    } catch (e) {
      if (mounted) {
        _showErrorMessage('Failed to enable biometric authentication');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSettingUpBiometric = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Invalid credentials') || error.contains('401')) {
      return 'Invalid email or password. Please try again.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Login failed. Please try again.';
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

    _updateRemainingAttempts();
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
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
                        // Theme toggle button
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            onPressed: themeProvider.toggleTheme,
                            icon: Icon(
                              themeProvider.themeModeIcon,
                              color: theme.colorScheme.onSurface,
                            ),
                            tooltip:
                                'Switch to ${themeProvider.isDarkMode ? 'light' : 'dark'} mode',
                          ),
                        ),

                        const SizedBox(height: AppSpacing.xxl),

                        // App Logo and Title
                        _buildHeader(theme),

                        const SizedBox(height: AppSpacing.huge),

                        // Login Form
                        _buildLoginForm(theme),

                        const SizedBox(height: AppSpacing.xxl),

                        // Sign up link
                        _buildSignUpLink(theme),
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
            Icons.account_balance_wallet_rounded,
            size: 48,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Welcome Back',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Sign in to your account',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(ThemeData theme) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Security warnings
            if (_isLockedOut) _buildLockoutWarning(theme),
            if (!_isLockedOut &&
                _remainingAttempts <= 3 &&
                _remainingAttempts > 0)
              _buildAttemptsWarning(theme),
            if (_errorMessage != null) _buildErrorMessage(theme),

            // Email field
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: _validateEmail,
              enabled: !_isLockedOut,
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
              textInputAction: TextInputAction.done,
              validator: _validatePassword,
              onFieldSubmitted: (_) => _login(),
              enabled: !_isLockedOut,
              autofillHints: const [AutofillHints.password],
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
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

            const SizedBox(height: AppSpacing.lg),

            // Remember me & Forgot password
            Row(
              children: [
                Expanded(
                  child: CheckboxListTile(
                    value: _keepSignedIn,
                    onChanged: (value) {
                      setState(() {
                        _keepSignedIn = value ?? false;
                      });
                    },
                    title: const Text('Remember me'),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    final email = _emailController.text.trim();
                    if (email.isNotEmpty) {
                      GoRouter.of(context).go(
                        '/forgot-password?email=${Uri.encodeComponent(email)}',
                      );
                    } else {
                      GoRouter.of(context).go('/forgot-password');
                    }
                  },
                  child: const Text('Forgot Password?'),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.xxl),

            // Biometric login (if available and enabled)
            if (_isBiometricAvailable &&
                _isBiometricEnabled &&
                !_isLockedOut) ...[
              OutlinedButton.icon(
                onPressed: _attemptBiometricLogin,
                icon: Icon(_getBiometricIcon()),
                label: Text(
                  'Login with ${_availableBiometrics.isNotEmpty ? BiometricAuthService.getBiometricTypeName(_availableBiometrics.first) : 'Biometric'}',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      'or',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(child: Divider(color: theme.colorScheme.outline)),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
            ],

            // Biometric setup prompt (if available but not enabled)
            if (_isBiometricAvailable && !_isBiometricEnabled && !_isLockedOut)
              StatusCard(
                title: 'Quick Login Available',
                message:
                    'Enable ${_availableBiometrics.isNotEmpty ? BiometricAuthService.getBiometricTypeName(_availableBiometrics.first) : 'biometric'} for secure, one-tap login',
                icon: _getBiometricIcon(),
                color: AppTheme.infoColor,
                action: IconButton(
                  onPressed:
                      _isSettingUpBiometric
                          ? null
                          : () async {
                            if (_emailController.text.trim().isEmpty ||
                                _passwordController.text.isEmpty) {
                              _showErrorMessage(
                                'Please enter your email and password first',
                              );
                              return;
                            }

                            setState(() => _isLoading = true);
                            try {
                              final loginResult = await _authService.login(
                                _emailController.text.trim(),
                                _passwordController.text,
                              );
                              await _setupBiometricAuth(
                                loginResult['access_token'],
                              );
                            } catch (e) {
                              _showErrorMessage(
                                'Please check your credentials and try again',
                              );
                            } finally {
                              setState(() => _isLoading = false);
                            }
                          },
                  icon:
                      _isSettingUpBiometric
                          ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                          : Icon(_getBiometricIcon()),
                ),
              ),

            if (_isBiometricAvailable && !_isBiometricEnabled && !_isLockedOut)
              const SizedBox(height: AppSpacing.lg),

            // Login button
            ElevatedButton(
              onPressed:
                  (_isLoading || _isLockedOut)
                      ? null
                      : () {
                        HapticFeedback.lightImpact();
                        _login();
                      },
              child:
                  _isLoading
                      ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : Text(
                        _isLockedOut
                            ? 'Account Locked ($_remainingLockoutTime min)'
                            : 'Sign In',
                      ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockoutWarning(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StatusCard(
        title: 'Account Temporarily Locked',
        message: 'Time remaining: $_remainingLockoutTime minutes.',
        icon: Icons.lock_clock,
        color: AppTheme.warningColor,
      ),
    );
  }

  Widget _buildAttemptsWarning(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StatusCard(
        title: 'Warning',
        message:
            '$_remainingAttempts attempt${_remainingAttempts == 1 ? '' : 's'} remaining before account lockout.',
        icon: Icons.warning_amber,
        color: AppTheme.warningColor,
      ),
    );
  }

  Widget _buildErrorMessage(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: StatusCard(
        title: 'Login Error',
        message: _errorMessage!,
        icon: Icons.error_outline,
        color: theme.colorScheme.error,
      ),
    );
  }

  Widget _buildSignUpLink(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        TextButton(
          onPressed: () => GoRouter.of(context).go('/register'),
          child: const Text('Sign up'),
        ),
      ],
    );
  }
}
