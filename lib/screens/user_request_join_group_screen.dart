import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../models/user_model.dart';

class UserRequestJoinGroupScreen extends StatefulWidget {
  const UserRequestJoinGroupScreen({Key? key}) : super(key: key);

  @override
  _UserRequestJoinGroupScreenState createState() => _UserRequestJoinGroupScreenState();
}

class _UserRequestJoinGroupScreenState extends State<UserRequestJoinGroupScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  
  final _formKey = GlobalKey<FormState>();
  final _groupCodeController = TextEditingController();
  
  bool _isLoading = false;
  UserModel? _currentUser;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _groupCodeController.dispose();
    super.dispose();
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

  Future<void> _submitJoinRequest() async {
    if (_currentUser == null) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verify the group code exists
      final groupId = await _groupService.getGroupIdByCode(_groupCodeController.text.trim());
      
      if (groupId != null) {
        // Submit the join request
        await _authService.requestJoinGroup(_currentUser!.id, groupId);
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Join request submitted successfully!')),
        );
        
        // Navigate back to landing page
        Navigator.pushReplacementNamed(context, '/landing');
      } else {
        setState(() {
          _errorMessage = 'Invalid group code. Please check and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error submitting request: ${e.toString()}';
      });
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
        title: const Text('Join a Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
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
                        'Join an Existing Group',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Enter the group code provided by the group holder:',
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _groupCodeController,
                        decoration: const InputDecoration(
                          labelText: 'Group Code',
                          hintText: 'Enter the 6-digit group code',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.groups),
                        ),
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a group code';
                          }
                          if (value.length != 6) {
                            return 'Group code must be 6 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.characters,
                      ),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                            ),
                          ),
                        ),
                      if (_currentUser?.requestedJoinGroup == true)
                        const Padding(
                          padding: EdgeInsets.only(top: 16.0),
                          child: Text(
                            'You have already requested to join a group. Please wait for approval.',
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
              if (_currentUser?.requestedJoinGroup != true)
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitJoinRequest,
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
                      : const Text('Submit Join Request'),
                ),
              if (_currentUser?.requestedJoinGroup == true)
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/landing');
                  },
                  child: const Text('Back to Home'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
