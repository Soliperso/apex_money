import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';
import 'package:go_router/go_router.dart';

enum PasswordStrength { none, weak, medium, strong, veryStrong }

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  String? _errorMessage;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptTerms = false;
  PasswordStrength _passwordStrength = PasswordStrength.none;
  List<String> _emailSuggestions = [];

  // Animation controller for logo pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _passwordController.addListener(_onPasswordChanged);
    _emailController.addListener(_onEmailChanged);
  }

  void _initializeAnimation() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onPasswordChanged() {
    setState(() {
      _passwordStrength = _calculatePasswordStrength(_passwordController.text);
    });
  }

  void _onEmailChanged() {
    final suggestions = _getEmailSuggestions(_emailController.text);
    setState(() {
      _emailSuggestions = suggestions;
    });
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptTerms) {
      setState(() {
        _errorMessage = 'Please accept the terms and conditions';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        GoRouter.of(context).go('/login');
      }
    } catch (e) {
      if (mounted) {
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
      return 'This email is already registered. Please use a different email.';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    return 'Registration failed. Please try again.';
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
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 8) {
      return 'Password must be at least 8 characters';
    }
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)').hasMatch(value)) {
      return 'Password must contain uppercase, lowercase, and numbers';
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

  // Password strength calculation
  PasswordStrength _calculatePasswordStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;

    int score = 0;

    // Length check
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character variety checks
    if (password.contains(RegExp(r'[a-z]'))) score++; // lowercase
    if (password.contains(RegExp(r'[A-Z]'))) score++; // uppercase
    if (password.contains(RegExp(r'[0-9]'))) score++; // numbers
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
      score++; // special chars

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  Color _getPasswordStrengthColor(PasswordStrength strength) {
    switch (strength) {
      case PasswordStrength.none:
        return Colors.grey;
      case PasswordStrength.weak:
        return Colors.red;
      case PasswordStrength.medium:
        return Colors.orange;
      case PasswordStrength.strong:
        return Colors.lightGreen;
      case PasswordStrength.veryStrong:
        return Colors.green;
    }
  }

  String _getPasswordStrengthText(PasswordStrength strength) {
    switch (strength) {
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
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
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
                              Icons.person_add,
                              size: 60,
                              color: Colors.blueAccent,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign up to get started',
                      style: TextStyle(fontSize: 16, color: Colors.white70),
                    ),
                    const SizedBox(height: 40),

                    // Register Card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            // Error Message
                            if (_errorMessage != null)
                              Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
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
                                          color: Colors.red.shade700,
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
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.name],
                              validator: _validateName,
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                hintText: 'Enter your full name',
                                prefixIcon: const Icon(Icons.person_outlined),
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
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Email Field with suggestions
                            Column(
                              children: [
                                TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [AutofillHints.email],
                                  validator: _validateEmail,
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
                                  ),
                                ),
                                // Email suggestions
                                if (_emailSuggestions.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.blue.shade200,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Did you mean:',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.blue,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 8,
                                          children:
                                              _emailSuggestions.map((
                                                suggestion,
                                              ) {
                                                return GestureDetector(
                                                  onTap:
                                                      () =>
                                                          _selectEmailSuggestion(
                                                            suggestion,
                                                          ),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 8,
                                                          vertical: 4,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color:
                                                          Colors.blue.shade100,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            12,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      suggestion,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                );
                                              }).toList(),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Password Field with strength indicator
                            Column(
                              children: [
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.next,
                                  autofillHints: const [
                                    AutofillHints.newPassword,
                                  ],
                                  validator: _validatePassword,
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
                                        HapticFeedback.lightImpact();
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
                                  ),
                                ),
                                // Password strength indicator
                                if (_passwordController.text.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    child: Column(
                                      children: [
                                        // Strength bar
                                        Row(
                                          children: [
                                            Expanded(
                                              child: LinearProgressIndicator(
                                                value:
                                                    _passwordStrength ==
                                                            PasswordStrength
                                                                .none
                                                        ? 0.0
                                                        : (_passwordStrength
                                                                .index /
                                                            4.0),
                                                backgroundColor:
                                                    Colors.grey.shade300,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      _getPasswordStrengthColor(
                                                        _passwordStrength,
                                                      ),
                                                    ),
                                                minHeight: 4,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              _getPasswordStrengthText(
                                                _passwordStrength,
                                              ),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    _getPasswordStrengthColor(
                                                      _passwordStrength,
                                                    ),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        // Strength requirements
                                        Align(
                                          alignment: Alignment.centerLeft,
                                          child: Text(
                                            'Use 8+ characters with uppercase, lowercase, numbers & symbols',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.newPassword],
                              validator: _validateConfirmPassword,
                              onFieldSubmitted: (_) => _register(),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Confirm your password',
                                prefixIcon: const Icon(Icons.lock_outlined),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _obscureConfirmPassword =
                                          !_obscureConfirmPassword;
                                    });
                                    HapticFeedback.lightImpact();
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
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Terms and Conditions
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                  activeColor: Colors.blueAccent,
                                ),
                                Expanded(
                                  child: RichText(
                                    text: const TextSpan(
                                      text: 'I agree to the ',
                                      style: TextStyle(
                                        color: Colors.black87,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        TextSpan(
                                          text: 'Terms & Conditions',
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        TextSpan(text: ' and '),
                                        TextSpan(
                                          text: 'Privacy Policy',
                                          style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                ),
                                child:
                                    _isLoading
                                        ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                          ),
                                        )
                                        : const Text(
                                          'Create Account',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Sign in link - single line below card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          "Already have an account? ",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            GoRouter.of(context).go('/login');
                          },
                          child: const Text(
                            'Sign In',
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
