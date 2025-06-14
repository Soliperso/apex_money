import 'package:flutter/material.dart';
import 'package:apex_money/src/shared/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _profilePicture; // Placeholder for future use

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final userProfile = await AuthService().fetchUserProfile();
      print('Fetched user profile: $userProfile'); // Debugging log

      setState(() {
        _nameController.text = userProfile['name'] ?? '';
        _emailController.text = userProfile['email'] ?? '';
        // _profilePicture = userProfile['profilePicture']; // Uncomment if profile picture is added in the future
      });
    } catch (error) {
      print('Error fetching user profile: $error'); // Debugging log
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load profile: $error')));
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
              GestureDetector(
                onTap: () {
                  // Add functionality to upload a profile picture
                },
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage:
                      _profilePicture != null
                          ? NetworkImage(_profilePicture!)
                          : null,
                  child:
                      _profilePicture == null
                          ? const Icon(Icons.camera_alt, size: 50)
                          : null,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Add functionality to save changes
                  },
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
