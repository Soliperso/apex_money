import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordPage({super.key, this.initialEmail});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _emailSent = false;

  // Animation controller for logo pulsing effect
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _loadEmail();
  }

  Future<void> _loadEmail() async {
    String emailToUse = widget.initialEmail ?? '';

    // If no email provided via parameter, try to load from preferences
    if (emailToUse.isEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        emailToUse = prefs.getString('email') ?? '';
      } catch (e) {
        // Continue with empty email if preferences loading fails
      }
    }

    if (mounted) {
      setState(() {
        _emailController.text = emailToUse;
      });
    }
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
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService().sendPasswordResetEmail(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _emailSent = true;
        });
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset email sent successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset email: ${_getFriendlyErrorMessage(error.toString())}',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
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
    if (error.contains('not found') || error.contains('404')) {
      return 'Email address not found';
    } else if (error.contains('Network')) {
      return 'Network error. Please check your connection';
    }
    return 'Please try again';
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
              Color(0xFFE3F2FD), // Very light blue
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
                    minHeight: constraints.maxHeight - 32,
                  ),
                  child: IntrinsicHeight(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Back Button
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
                                  child: Icon(
                                    _emailSent
                                        ? Icons.mark_email_read
                                        : Icons.lock_reset,
                                    size: 60,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _emailSent
                                ? 'Check Your Email'
                                : 'Forgot Password?',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _emailSent
                                ? 'We\'ve sent a password reset link to your email'
                                : 'Enter your email to receive a reset link',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),

                          if (!_emailSent) ...[
                            // Reset Password Card
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    // Email Field
                                    TextFormField(
                                      controller: _emailController,
                                      keyboardType:
                                          TextInputType.emailAddress,
                                      textInputAction: TextInputAction.done,
                                      autofillHints: const [
                                        AutofillHints.email,
                                      ],
                                      validator: _validateEmail,
                                      onFieldSubmitted:
                                          (_) => _sendResetEmail(),
                                      decoration: InputDecoration(
                                        labelText: 'Email Address',
                                        hintText:
                                            'Enter your email address',
                                        prefixIcon: const Icon(
                                          Icons.email_outlined,
                                        ),
                                        fillColor: Colors.grey.shade50,
                                        filled: true,
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: Colors.grey.shade300,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.blueAccent,
                                            width: 2,
                                          ),
                                        ),
                                        errorBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          borderSide: const BorderSide(
                                            color: Colors.red,
                                            width: 2,
                                          ),
                                        ),
                                        focusedErrorBorder:
                                            OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: const BorderSide(
                                                color: Colors.red,
                                                width: 2,
                                              ),
                                            ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),

                                    // Send Reset Email Button
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed:
                                            _isLoading ? null : _sendResetEmail,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
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
                                                        AlwaysStoppedAnimation<
                                                          Color
                                                        >(Colors.white),
                                                  ),
                                                )
                                                : const Text(
                                                  'Send Reset Link',
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
                          ] else ...[
                            // Email Sent Confirmation
                            Card(
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 60,
                                      color: Colors.green.shade600,
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Reset link sent!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Check your email and follow the instructions to reset your password.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      child: OutlinedButton(
                                        onPressed: () {
                                          setState(() {
                                            _emailSent = false;
                                          });
                                        },
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.blueAccent,
                                          side: const BorderSide(
                                            color: Colors.blueAccent,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                        ),
                                        child: const Text('Resend Email'),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Back to Login - single line below card
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text(
                                "Remember your password? ",
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
              );
            },
          ),
        ),
      ),
    );
  }
}
