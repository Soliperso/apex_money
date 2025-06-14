import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchEmailFromBackend();
  }

  Future<void> _fetchEmailFromBackend() async {
    try {
      final userProfile = await AuthService().fetchUserProfile();
      setState(() {
        _emailController.text = userProfile['email'] ?? '';
      });
    } catch (error) {
      print('Error fetching email: $error');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load email: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    GoRouter.of(context).go('/login');
                  },
                  child: const Text('Reset Password'),
                ),
              ),
              TextButton(
                onPressed: () {
                  GoRouter.of(context).go('/login');
                },
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
