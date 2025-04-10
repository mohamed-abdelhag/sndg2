import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../models/user_model.dart';
import '../models/group_model.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  _LandingScreenState createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  
  bool _isLoading = true;
  UserModel? _currentUser;
  GroupModel? _userGroup;
  
  @override
  void initState() {
    super.initState();
    _checkUserStatusAndRedirect();
  }
  
  Future<void> _checkUserStatusAndRedirect() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get current user
      final user = await _authService.getCurrentUser();
      
      if (user == null) {
        // No user, redirect to login
        Navigator.pushReplacementNamed(context, '/');
        return;
      }
      
      setState(() {
        _currentUser = user;
      });
      
      // Check user role and status
      if (user.role == 'admin') {
        // Admin goes to admin dashboard
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
        return;
      } else if (user.role == 'holder') {
        // Check if holder has a group
        final holderGroups = await _groupService.getGroupsByHolder(user.id);
        
        if (holderGroups.isNotEmpty) {
          // Holder has at least one group, go to holder dashboard
          Navigator.pushReplacementNamed(context, '/holder_dashboard');
        } else {
          // Holder has no groups, go to create group
          Navigator.pushReplacementNamed(context, '/holder_create');
        }
        return;
      } else if (user.groupId != null) {
        // User is in a group, get group details to determine type
        final group = await _groupService.getGroupById(user.groupId!);
        
        if (group != null) {
          setState(() {
            _userGroup = group;
          });
          
          // Check group type and redirect accordingly
          if (group.type == 'standard') {
            Navigator.pushReplacementNamed(
              context, 
              '/user_normal_group_dashboard',
              arguments: group.id,
            );
          } else if (group.type == 'lottery') {
            Navigator.pushReplacementNamed(
              context, 
              '/user_lottery_group_dashboard',
              arguments: group.id,
            );
          }
          return;
        }
      }
      
      // If we reach here, user is a normal user without a group
      // or with an unknown group - show the landing page
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking user status: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Sandoog App')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sandoog App'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Color(0xFF307351), // Primary color from the directory
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to Sandoog',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Group Savings Made Simple',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              
              // Status-based UI
              _buildStatusBasedUI(),
              
              const SizedBox(height: 32),
              
              // About section
              const Text(
                'Sandoog helps you save money with your community through group savings and lending.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildStatusBasedUI() {
    // Handle different user states
    if (_currentUser == null) {
      return const SizedBox.shrink();
    }
    
    if (_currentUser!.requestedHolder) {
      return _buildRequestedHolderStatus();
    } else if (_currentUser!.requestedJoinGroup) {
      return _buildRequestedJoinGroupStatus();
    } else {
      return _buildDefaultOptions();
    }
  }
  
  Widget _buildRequestedHolderStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_top,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your request to become a holder is pending approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'An administrator will review your request soon.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _checkUserStatusAndRedirect,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRequestedJoinGroupStatus() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Icon(
              Icons.hourglass_top,
              size: 48,
              color: Colors.blue,
            ),
            const SizedBox(height: 16),
            const Text(
              'Your request to join a group is pending approval',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'The group holder will review your request soon.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _checkUserStatusAndRedirect,
              child: const Text('Refresh Status'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefaultOptions() {
    return Column(
      children: [
        const Text(
          'What would you like to do?',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          icon: const Icon(Icons.group_add),
          label: const Text('Join a Group'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(240, 48),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/user_request_join_group');
          },
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text('Become a Group Holder'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(240, 48),
          ),
          onPressed: () {
            Navigator.pushNamed(context, '/user_request_holder');
          },
        ),
      ],
    );
  }
} 