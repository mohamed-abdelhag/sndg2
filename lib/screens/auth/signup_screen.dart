import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';

class SignupScreen extends StatelessWidget {
  final AuthService authService = AuthService(Supabase.instance.client);
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
              ElevatedButton(
                onPressed: () async {
                  String email = emailController.text; // Get email from input
                  String password = passwordController.text; // Get password from input
                  await authService.signup(email, password);
                  // Navigate to landing page after signup
                  Navigator.pushReplacementNamed(context, '/landing');
                },
                child: const Text('Sign Up'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/'); // Navigate to Login
                },
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 