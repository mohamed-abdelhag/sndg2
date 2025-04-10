import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_logo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService authService = AuthService();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    
    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter both email and password';
      });
      return;
    }
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      print('Login attempt for: $email');
      final user = await authService.login(email, password);
      
      if (!mounted) return;
      
      if (user != null) {
        print('Login successful, user role: ${user.role}');
        // Route based on user role
        if (user.role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else if (user.role == 'holder') {
          Navigator.pushReplacementNamed(context, '/holder_dashboard');
        } else if (user.groupId != null) {
          Navigator.pushReplacementNamed(context, '/user_normal_group_dashboard', 
            arguments: user.groupId);
        } else {
          Navigator.pushReplacementNamed(context, '/landing');
        }
      } else {
        print('Login failed - null user returned');
        setState(() {
          _errorMessage = 'Invalid email or password. Please try again.';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Login error caught: $e');
      String errorMsg = 'Login failed';
      
      if (e.toString().contains('Invalid login credentials')) {
        errorMsg = 'Incorrect email or password';
      } else if (e.toString().contains('not found')) {
        errorMsg = 'Account not found. Please sign up first.';
      } else if (e.toString().contains('User account not found')) {
        errorMsg = 'Account not found. Please sign up first.';
      } else if (e.toString().contains('network')) {
        errorMsg = 'Network error. Please check your connection.';
      } else {
        errorMsg = 'Login error: ${e.toString()}';
      }
      
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const AppLogo(size: 100),
                const SizedBox(height: 32),
                const Text(
                  'SANDOOG',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Group Savings Management',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                  obscureText: true,
                  textInputAction: TextInputAction.done,
                  enabled: !_isLoading,
                  onSubmitted: (_) => _login(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('LOGIN'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushNamed(context, '/signup');
                        },
                  child: const Text('Don\'t have an account? Sign Up'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 