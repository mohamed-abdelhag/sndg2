import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class UserRequestHolderScreen extends StatefulWidget {
  const UserRequestHolderScreen({Key? key}) : super(key: key);

  @override
  _UserRequestHolderScreenState createState() => _UserRequestHolderScreenState();
}

class _UserRequestHolderScreenState extends State<UserRequestHolderScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      setState(() {
        _currentUser = user;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: ${e.toString()}')),
      );
    }
  }

  Future<void> _submitHolderRequest() async {
    if (_currentUser == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _authService.requestHolder(_currentUser!.id);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holder request submitted successfully!')),
      );
      
      // Navigate back to landing page
      Navigator.pushReplacementNamed(context, '/landing');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting request: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Become a Group Holder'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Request to Become a Group Holder',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'As a group holder, you will be responsible for:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const ListTile(
                      leading: Icon(Icons.people),
                      title: Text('Creating and managing savings groups'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.approval),
                      title: Text('Reviewing and approving member join requests'),
                    ),
                    const ListTile(
                      leading: Icon(Icons.money),
                      title: Text('Managing finances and contribution tracking'),
                    ),
                    if (_currentUser?.requestedHolder == true)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          'Your request to become a holder has been submitted and is pending approval.',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_currentUser?.requestedHolder != true) 
              ElevatedButton(
                onPressed: _isLoading ? null : _submitHolderRequest,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: _isLoading 
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Submitting Request...'),
                        ],
                      )
                    : const Text('Submit Request'),
              ),
            if (_currentUser?.requestedHolder == true)
              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/landing');
                },
                child: const Text('Back to Home'),
              ),
          ],
        ),
      ),
    );
  }
}
