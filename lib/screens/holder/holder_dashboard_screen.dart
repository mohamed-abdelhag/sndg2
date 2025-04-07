import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../models/user_model.dart';
import '../../models/group_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HolderDashboardScreen extends StatefulWidget {
  @override
  _HolderDashboardScreenState createState() => _HolderDashboardScreenState();
}

class _HolderDashboardScreenState extends State<HolderDashboardScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  
  UserModel? _currentUser;
  List<GroupModel> _groups = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserAndGroups();
  }

  Future<void> _loadUserAndGroups() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final user = await _authService.getCurrentUser();
      
      if (user != null) {
        final groups = await _groupService.getGroupsByHolder(user.id);
        
        setState(() {
          _currentUser = user;
          _groups = groups;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        
        // Navigate to login if no user found
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading data: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Holder Dashboard')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_currentUser == null || _currentUser!.role != 'holder') {
      return Scaffold(
        appBar: AppBar(title: Text('Access Denied')),
        body: Center(child: Text('You do not have holder privileges.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Holder Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUserAndGroups,
          ),
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () async {
              await _authService.logout();
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome, Group Holder!',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    SizedBox(height: 8),
                    Text('Email: ${_currentUser!.email}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Your Groups',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Expanded(
              child: _groups.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('You don\'t have any groups yet.'),
                          SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(context, '/holder_create');
                            },
                            icon: Icon(Icons.add),
                            label: Text('Create Group'),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: _groups.length,
                      itemBuilder: (context, index) {
                        final group = _groups[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, '/holder_manage_group', arguments: group.id);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          group.name,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                      ),
                                      _buildGroupTypeChip(group.type),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text('Goal: ${group.savingsGoal} \$ monthly'),
                                  SizedBox(height: 4),
                                  Text('Code: ${group.groupCode}'),
                                  SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/holder_see_request', arguments: group.id);
                                        },
                                        icon: Icon(Icons.group_add, size: 18),
                                        label: Text('Join Requests'),
                                      ),
                                      SizedBox(width: 8),
                                      TextButton.icon(
                                        onPressed: () {
                                          Navigator.pushNamed(context, '/holder_manage_members', arguments: group.id);
                                        },
                                        icon: Icon(Icons.people, size: 18),
                                        label: Text('Members'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/holder_create');
        },
        child: Icon(Icons.add),
        tooltip: 'Create New Group',
      ),
    );
  }

  Widget _buildGroupTypeChip(String type) {
    final isStandard = type == 'standard';
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isStandard ? Colors.blue.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isStandard ? Colors.blue : Colors.orange,
        ),
      ),
      child: Text(
        isStandard ? 'Standard' : 'Lottery',
        style: TextStyle(
          color: isStandard ? Colors.blue : Colors.orange,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }
} 