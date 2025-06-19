import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';
import 'package:apex_money/src/shared/services/biometric_auth_service.dart';
import 'package:apex_money/src/shared/services/login_attempt_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _keepSignedIn = false;
  bool _obscurePassword = true;
  bool _isSettingUpBiometric = false;

  // Enhanced security and UX features
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  List<BiometricType> _availableBiometrics = [];
  bool _isLockedOut = false;
  int _remainingLockoutTime = 0;
  int _remainingAttempts = 5;
  List<String> _emailSuggestions = [];

  // Animation controller for logo pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAnimation();
    _initializeAuth();
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start the pulsing animation and repeat it
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeAuth() async {
    _loadPreferences();
    await _checkBiometricAvailability();
    await _checkLockoutStatus();
    await _checkBiometricLogin();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Reset biometric setup flag if the app was backgrounded
      // This can happen if Face ID was interrupted
      if (_isSettingUpBiometric) {
        print('🔐 App resumed, resetting biometric setup flag');
        _resetBiometricSetup();
      }
    }
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final bool available = await BiometricAuthService.isBiometricAvailable();
      final bool enabled = await BiometricAuthService.isBiometricEnabled();
      final List<BiometricType> biometrics =
          await BiometricAuthService.getAvailableBiometrics();

      if (mounted) {
        setState(() {
          _isBiometricAvailable = available;
          _isBiometricEnabled = enabled;
          _availableBiometrics = biometrics;
        });
      }
    } catch (e) {
      // Biometric not available, continue with normal flow
    }
  }

  Future<void> _checkLockoutStatus() async {
    try {
      final bool isLockedOut = await LoginAttemptService.isLockedOut();
      if (isLockedOut) {
        final int remainingTime =
            await LoginAttemptService.getRemainingLockoutTime();
        if (mounted) {
          setState(() {
            _isLockedOut = true;
            _remainingLockoutTime = remainingTime;
          });
          _startLockoutTimer();
        }
      } else {
        // Update remaining attempts for current email
        await _updateRemainingAttempts();
      }
    } catch (e) {
      // Handle error silently
    }
  }

  Future<void> _updateRemainingAttempts() async {
    if (_emailController.text.isNotEmpty) {
      final int attempts = await LoginAttemptService.getRemainingAttempts(
        _emailController.text,
      );
      if (mounted) {
        setState(() {
          _remainingAttempts = attempts;
        });
      }
    }
  }

  void _startLockoutTimer() {
    if (_remainingLockoutTime > 0) {
      Future.delayed(const Duration(minutes: 1), () async {
        if (mounted) {
          final bool stillLockedOut = await LoginAttemptService.isLockedOut();
          if (stillLockedOut) {
            final int newRemainingTime =
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

  Future<void> _checkBiometricLogin() async {
    if (_isBiometricAvailable && _isBiometricEnabled && !_isLockedOut) {
      try {
        final Map<String, String>? credentials =
            await BiometricAuthService.authenticateWithBiometric();
        if (credentials != null && mounted) {
          // Auto-login with biometric authentication
          _performBiometricLogin(credentials);
        }
      } catch (e) {
        // Biometric authentication failed or was cancelled, continue with normal flow
      }
    }
  }

  Future<void> _performBiometricLogin(Map<String, String> credentials) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use stored token for quick authentication
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', credentials['token']!);

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.fingerprint, color: Colors.white),
                SizedBox(width: 8),
                Text('Biometric login successful!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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

  void _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _keepSignedIn = prefs.getBool('keepSignedIn') ?? false;
      _emailController.text = prefs.getString('email') ?? '';
    });
  }

  void _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('keepSignedIn', _keepSignedIn);
    if (_keepSignedIn) {
      // Only save email if remember me is checked
      await prefs.setString('email', _emailController.text);
    } else {
      // If remember me is unchecked, clear stored email and token
      await prefs.remove('email');
      await prefs.remove('access_token');
    }
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    // Check lockout status before attempting login
    if (await LoginAttemptService.isLockedOut()) {
      final int remainingTime =
          await LoginAttemptService.getRemainingLockoutTime();
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

      if (_keepSignedIn) {
        _savePreferences();
      } else {
        // If remember me is unchecked, don't save credentials
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('keepSignedIn', false);
        await prefs.remove('email');
        // Note: we don't remove access_token here as it's needed for the current session
      }

      // Enable biometric auth if available and user hasn't set it up yet
      if (_isBiometricAvailable && !_isBiometricEnabled && mounted) {
        _showBiometricSetupDialog(loginResult['access_token']);
      }

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login successful!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
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

  void _showBiometricSetupDialog(String authToken) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final String biometricName =
            _availableBiometrics.isNotEmpty
                ? BiometricAuthService.getBiometricTypeName(
                  _availableBiometrics.first,
                )
                : 'Biometric';

        return AlertDialog(
          title: Row(
            children: [
              Icon(_getBiometricIcon(), color: Colors.blueAccent),
              const SizedBox(width: 8),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Enable'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setupBiometricAuth(String authToken) async {
    try {
      final bool success = await BiometricAuthService.enableBiometricAuth(
        _emailController.text.trim(),
        authToken,
      );

      if (success && mounted) {
        setState(() {
          _isBiometricEnabled = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to enable biometric authentication'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _showEnableBiometricDialog() async {
    if (!_isBiometricAvailable) return;

    final biometricName =
        _availableBiometrics.isNotEmpty
            ? BiometricAuthService.getBiometricTypeName(
              _availableBiometrics.first,
            )
            : 'biometric authentication';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: [
                Icon(_getBiometricIcon(), color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Text(
                  'Enable $biometricName',
                  style: const TextStyle(fontSize: 18),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Login securely and quickly using your $biometricName instead of typing your password every time.',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.security,
                        color: Colors.green.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Your credentials are stored securely on this device only',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Maybe Later'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _enableBiometricAuth();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                ),
                child: Text('Enable $biometricName'),
              ),
            ],
          ),
    );
  }

  Future<void> _enableBiometricAuth() async {
    // Prevent multiple simultaneous biometric setup attempts
    if (_isSettingUpBiometric) {
      print('🔐 Biometric setup already in progress, ignoring request');
      // Auto-reset after 2 seconds in case it's stuck
      Future.delayed(const Duration(seconds: 2), () {
        if (_isSettingUpBiometric) {
          print('🔐 Auto-resetting stuck biometric setup');
          _resetBiometricSetup();
        }
      });
      return;
    }

    try {
      setState(() {
        _isSettingUpBiometric = true;
      });

      // User needs to login first to enable biometric auth
      if (_emailController.text.trim().isEmpty ||
          _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter your email and password first'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      // First, authenticate with email/password
      print('🔐 Attempting login for biometric setup...');
      final loginResult = await _authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      print(
        '🔐 Login successful, token: ${loginResult['access_token']?.substring(0, 20)}...',
      );

      // Then enable biometric auth with the token
      print('🔐 Attempting to enable biometric auth...');

      // Update UI to show Face ID is being set up
      if (mounted) {
        setState(() {
          _isLoading = false; // Allow UI interaction
        });

        // Show a loading dialog specifically for Face ID setup
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => AlertDialog(
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.face_retouching_natural,
                      size: 48,
                      color: Colors.blue.shade600,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Setting up Face ID',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Please authenticate with Face ID to enable secure login',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ),
              ),
        );
      }

      final success = await BiometricAuthService.enableBiometricAuth(
        _emailController.text.trim(),
        loginResult['access_token'],
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('🔐 Biometric auth setup timed out');
          return false;
        },
      );

      // Close the Face ID setup dialog
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      print('🔐 Biometric enable result: $success');

      if (success && mounted) {
        // Update state to show biometric button
        setState(() {
          _isBiometricEnabled = true;
        });

        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(_getBiometricIcon(), color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  '${_availableBiometrics.isNotEmpty ? BiometricAuthService.getBiometricTypeName(_availableBiometrics.first) : 'Biometric'} login enabled!',
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Navigate to dashboard
        GoRouter.of(context).go('/dashboard');
      }
    } catch (e) {
      print('🔐 Error enabling biometric auth: $e');
      if (mounted) {
        String errorMessage = 'Failed to enable biometric login';

        if (e.toString().contains('UserCancel') ||
            e.toString().contains('cancelled')) {
          errorMessage = 'Face ID setup was cancelled';
        } else if (e.toString().contains('NotAvailable')) {
          errorMessage = 'Face ID is not available on this device';
        } else if (e.toString().contains('NotEnrolled')) {
          errorMessage = 'Please set up Face ID in device settings first';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Face ID setup timed out';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSettingUpBiometric = false;
        });
      }
    }
  }

  void _resetBiometricSetup() {
    if (mounted) {
      setState(() {
        _isSettingUpBiometric = false;
        _isLoading = false;
      });
      print('🔐 Biometric setup state reset');

      // Close any open dialogs
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    }
  }

  IconData _getBiometricIcon() {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return Icons.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return Icons.fingerprint;
    }
    return Icons.security;
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

    // Auto-format email to lowercase
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

    // Update remaining attempts when email changes
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


  // Email suggestion methods
  List<String> _getEmailSuggestions(String email) {
    if (email.isEmpty || !email.contains('@')) return [];

    final parts = email.split('@');
    if (parts.length != 2) return [];

    final username = parts[0];
    final domain = parts[1].toLowerCase();

    const popularDomains = [
      'gmail.com',
      'yahoo.com',
      'hotmail.com',
      'outlook.com',
      'icloud.com',
      'aol.com',
    ];

    // Find similar domains
    List<String> suggestions = [];
    for (String popularDomain in popularDomains) {
      if (popularDomain.contains(domain) ||
          domain.contains(
            popularDomain.substring(0, popularDomain.length ~/ 2),
          )) {
        suggestions.add('$username@$popularDomain');
      }
    }

    // If no similar domains found and domain is incomplete, suggest all popular ones
    if (suggestions.isEmpty && domain.length < 4) {
      suggestions = popularDomains.map((d) => '$username@$d').take(3).toList();
    }

    return suggestions.take(3).toList();
  }

  void _selectEmailSuggestion(String suggestion) {
    _emailController.text = suggestion;
    _emailController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    setState(() {
      _emailSuggestions = [];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1976D2), // Deep blue
              Color(0xFF2196F3), // Bright blue
              Color(0xFF64B5F6), // Medium blue
              Color(0xFFE3F2FD), // Very light blue (instead of white)
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight:
                        constraints.maxHeight -
                        32, // Account for reduced padding
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Back Button (if coming from other screens)
                          if (GoRouter.of(context).canPop())
                            Align(
                              alignment: Alignment.topLeft,
                              child: IconButton(
                                onPressed: () {
                                  GoRouter.of(context).pop();
                                },
                                icon: const Icon(
                                  Icons.arrow_back,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                            ),

                          // App Logo/Title with pulsing animation
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        spreadRadius: 2,
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.account_balance_wallet,
                                    size: 60,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Welcome Back',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Sign in to your account',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Login Card
                          Card(
                            elevation: 4,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Column(
                                children: [
                                  // Security warnings for lockout
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child:
                                        _isLockedOut
                                            ? Container(
                                              key: const ValueKey('lockout'),
                                              padding: const EdgeInsets.all(12),
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.orange.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.orange.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.lock_clock,
                                                    color:
                                                        Colors.orange.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Account temporarily locked for security. Time remaining: $_remainingLockoutTime minutes.',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .orange
                                                                .shade700,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),

                                  // Remaining attempts warning
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child:
                                        (!_isLockedOut &&
                                                _remainingAttempts <= 3 &&
                                                _remainingAttempts > 0)
                                            ? Container(
                                              key: const ValueKey('warning'),
                                              padding: const EdgeInsets.all(12),
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.amber.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.amber.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.warning_amber,
                                                    color:
                                                        Colors.amber.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      'Warning: $_remainingAttempts attempt${_remainingAttempts == 1 ? '' : 's'} remaining before account lockout.',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .amber
                                                                .shade700,
                                                        fontSize: 14,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),

                                  // Error Message
                                  AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 300),
                                    child:
                                        _errorMessage != null
                                            ? Container(
                                              key: ValueKey(_errorMessage),
                                              padding: const EdgeInsets.all(12),
                                              margin: const EdgeInsets.only(
                                                bottom: 16,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.red.shade200,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    color: Colors.red.shade700,
                                                    size: 20,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Expanded(
                                                    child: Text(
                                                      _errorMessage!,
                                                      style: TextStyle(
                                                        color:
                                                            Colors.red.shade700,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                            : const SizedBox.shrink(),
                                  ),

                                  // Email Field
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _validateEmail,
                                    onChanged: (value) {
                                      setState(() {
                                        _emailSuggestions =
                                            _getEmailSuggestions(value);
                                      });
                                    },
                                    autofillHints: const [AutofillHints.email],
                                    enabled: !_isLockedOut,
                                    decoration: InputDecoration(
                                      labelText: 'Email',
                                      hintText: 'Enter your email',
                                      prefixIcon: const Icon(
                                        Icons.email_outlined,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Email Suggestions
                                  if (_emailSuggestions.isNotEmpty)
                                    AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          border: Border.all(
                                            color: Colors.grey.shade200,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Padding(
                                              padding:
                                                  const EdgeInsets.fromLTRB(
                                                    12,
                                                    8,
                                                    12,
                                                    4,
                                                  ),
                                              child: Text(
                                                'Did you mean?',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey.shade600,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            ..._emailSuggestions
                                                .map(
                                                  (suggestion) => InkWell(
                                                    onTap:
                                                        () =>
                                                            _selectEmailSuggestion(
                                                              suggestion,
                                                            ),
                                                    child: Container(
                                                      width: double.infinity,
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 8,
                                                          ),
                                                      child: Row(
                                                        children: [
                                                          Icon(
                                                            Icons
                                                                .email_outlined,
                                                            size: 16,
                                                            color:
                                                                Colors
                                                                    .grey
                                                                    .shade600,
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          Expanded(
                                                            child: Text(
                                                              suggestion,
                                                              style: const TextStyle(
                                                                fontSize: 14,
                                                                color:
                                                                    Colors
                                                                        .blueAccent,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ],
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  // Password Field
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    validator: _validatePassword,
                                    onFieldSubmitted: (_) => _login(),
                                    autofillHints: const [
                                      AutofillHints.password,
                                    ],
                                    enabled: !_isLockedOut,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      hintText: 'Enter your password',
                                      prefixIcon: const Icon(
                                        Icons.lock_outlined,
                                      ),
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_outlined
                                              : Icons.visibility_off_outlined,
                                        ),
                                        onPressed: () {
                                          setState(() {
                                            _obscurePassword =
                                                !_obscurePassword;
                                          });
                                        },
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                          color: Colors.blueAccent,
                                          width: 2,
                                        ),
                                      ),
                                      disabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Keep signed in & Forgot password
                                  Row(
                                    children: [
                                      // Remember me checkbox
                                      Expanded(
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Checkbox(
                                              value: _keepSignedIn,
                                              onChanged: (value) {
                                                setState(() {
                                                  _keepSignedIn =
                                                      value ?? false;
                                                });
                                                // Immediately save preference change
                                                _savePreferences();
                                              },
                                              activeColor: Colors.blueAccent,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            const Flexible(
                                              child: Text(
                                                'Remember me',
                                                style: TextStyle(fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      // Forgot password link
                                      Flexible(
                                        child: TextButton(
                                          onPressed: () {
                                            final email =
                                                _emailController.text.trim();
                                            if (email.isNotEmpty) {
                                              GoRouter.of(context).go(
                                                '/forgot-password?email=${Uri.encodeComponent(email)}',
                                              );
                                            } else {
                                              GoRouter.of(
                                                context,
                                              ).go('/forgot-password');
                                            }
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 8,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize:
                                                MaterialTapTargetSize
                                                    .shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Forgot Password?',
                                            style: TextStyle(
                                              color: Colors.blueAccent,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),

                                  // Biometric Login Button (if available and enabled)
                                  if (_isBiometricAvailable &&
                                      _isBiometricEnabled &&
                                      !_isLockedOut)
                                    Column(
                                      children: [
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: OutlinedButton.icon(
                                            onPressed: _checkBiometricLogin,
                                            icon: Icon(_getBiometricIcon()),
                                            label: Text(
                                              'Login with ${_availableBiometrics.isNotEmpty ? BiometricAuthService.getBiometricTypeName(_availableBiometrics.first) : 'Biometric'}',
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            style: OutlinedButton.styleFrom(
                                              side: const BorderSide(
                                                color: Colors.blueAccent,
                                                width: 2,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16,
                                                  ),
                                              child: Text(
                                                'or',
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Divider(
                                                color: Colors.grey.shade300,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                      ],
                                    ),

                                  // Enable Biometric Button (if available but not enabled)
                                  if (_isBiometricAvailable &&
                                      !_isBiometricEnabled &&
                                      !_isLockedOut)
                                    Column(
                                      children: [
                                        Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.blue.shade50,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Colors.blue.shade200,
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                _getBiometricIcon(),
                                                color: Colors.blue.shade600,
                                                size: 24,
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      'Quick Login Available',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade800,
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Enable ${_availableBiometrics.isNotEmpty ? BiometricAuthService.getBiometricTypeName(_availableBiometrics.first) : 'biometric'} for secure, one-tap login',
                                                      style: TextStyle(
                                                        color:
                                                            Colors
                                                                .blue
                                                                .shade600,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              SizedBox(
                                                child: TextButton(
                                                  onPressed:
                                                      _isSettingUpBiometric
                                                          ? null // Disable button when setup is in progress
                                                          : _showEnableBiometricDialog,
                                                  style: TextButton.styleFrom(
                                                    backgroundColor:
                                                        _isSettingUpBiometric
                                                            ? Colors
                                                                .grey
                                                                .shade400
                                                            : Colors
                                                                .blue
                                                                .shade600,
                                                    foregroundColor:
                                                        Colors.white,
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 8,
                                                        ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                  ),
                                                  child:
                                                      _isSettingUpBiometric
                                                          ? const SizedBox(
                                                            width: 16,
                                                            height: 16,
                                                            child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor:
                                                                  AlwaysStoppedAnimation<
                                                                    Color
                                                                  >(
                                                                    Colors
                                                                        .white,
                                                                  ),
                                                            ),
                                                          )
                                                          : const Icon(
                                                            Icons
                                                                .face_retouching_natural,
                                                            size: 16,
                                                          ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Login Button
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed:
                                          (_isLoading || _isLockedOut)
                                              ? null
                                              : () {
                                                HapticFeedback.lightImpact();
                                                _login();
                                              },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            _isLockedOut
                                                ? Colors.grey.shade400
                                                : Colors.blueAccent,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        elevation: _isLoading ? 0 : 2,
                                        shadowColor: Colors.blueAccent
                                            .withOpacity(0.3),
                                      ),
                                      child: AnimatedSwitcher(
                                        duration: const Duration(
                                          milliseconds: 200,
                                        ),
                                        child:
                                            _isLoading
                                                ? const SizedBox(
                                                  key: ValueKey('loading'),
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                                : Row(
                                                  key: ValueKey(
                                                    'text-${_isLockedOut ? 'locked' : 'normal'}',
                                                  ),
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    if (_isLockedOut) ...[
                                                      const Icon(
                                                        Icons.lock_clock,
                                                        size: 18,
                                                      ),
                                                      const SizedBox(width: 8),
                                                    ],
                                                    Text(
                                                      _isLockedOut
                                                          ? 'Account Locked ($_remainingLockoutTime min)'
                                                          : 'Sign In',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign up link - single line below card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  GoRouter.of(context).go('/register');
                                },
                                child: const Text(
                                  'Sign up',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    decoration: TextDecoration.underline,
                                    decorationColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_isLockedOut) ...[
                            const SizedBox(height: 12),
                            Card(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 20,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Text(
                                      'Account Locked',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.red,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Remaining time: $_remainingLockoutTime minutes',
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
