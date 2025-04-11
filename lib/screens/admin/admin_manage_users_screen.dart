import 'package:flutter/material.dart';
import '../../services/auth_service_v2.dart';
import '../../models/user_model.dart';

class AdminManageUsersScreen extends StatefulWidget {
  const AdminManageUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminManageUsersScreenState createState() => _AdminManageUsersScreenState();
}

class _AdminManageUsersScreenState extends State<AdminManageUsersScreen> {
  final AuthServiceV2 _authService = AuthServiceV2();
  bool _isLoading = true;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  String? _errorMessage;
  
  // Filter options
  String _filterRole = 'all';
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // First check if the current user is an admin
      final currentUser = await _authService.getCurrentUser();
      print('Current user: ${currentUser?.email}, role: ${currentUser?.role}');
      
      if (currentUser == null || currentUser.role != 'admin') {
        setState(() {
          _errorMessage = 'You do not have permission to view this page';
          _isLoading = false;
        });
        return;
      }
      
      print('Current user is admin, loading all users...');
      
      try {
        final users = await _authService.getAllUsers();
        print('Loaded ${users.length} users');
        
        setState(() {
          _allUsers = users;
          _applyFilters();
          _isLoading = false;
        });
      } catch (e) {
        print('Error in getAllUsers: $e');
        setState(() {
          _errorMessage = 'Error loading users: ${e.toString()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('General error in _loadUsers: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }
  
  void _applyFilters() {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        // Apply role filter
        if (_filterRole != 'all' && user.role != _filterRole) {
          return false;
        }
        
        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          return user.email.toLowerCase().contains(_searchQuery.toLowerCase());
        }
        
        return true;
      }).toList();
      
      // Sort by email for consistency
      _filteredUsers.sort((a, b) => a.email.compareTo(b.email));
    });
  }
  
  Future<void> _approveHolderRequest(String userId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _authService.approveHolderRequest(userId);
      
      await _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User approved as holder successfully')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving holder: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _rejectHolderRequest(String userId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _authService.rejectHolderRequest(userId);
      
      await _loadUsers();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Holder request rejected')),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_errorMessage'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadUsers,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _buildFilterBar(),
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? Center(
                              child: Text(
                                _allUsers.isEmpty
                                    ? 'No users found'
                                    : 'No users match your filters',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                return _buildUserCard(_filteredUsers[index]);
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
  
  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search by email',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
                _applyFilters();
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Filter by role: '),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _filterRole,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filterRole = newValue;
                      _applyFilters();
                    });
                  }
                },
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('All Users')),
                  DropdownMenuItem(value: 'normal', child: Text('Normal Users')),
                  DropdownMenuItem(value: 'holder', child: Text('Holders')),
                  DropdownMenuItem(value: 'admin', child: Text('Admins')),
                ],
              ),
              const Spacer(),
              Chip(
                label: Text('${_filteredUsers.length} users'),
                backgroundColor: Colors.blue.shade100,
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserCard(UserModel user) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(user.email),
        subtitle: Text('Role: ${user.role}'),
        leading: _getUserIcon(user),
        trailing: user.requestedHolder
            ? Chip(
                label: const Text('Holder Request'),
                backgroundColor: Colors.amber.shade100,
              )
            : null,
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('User ID: ${user.id}'),
                const SizedBox(height: 8),
                Text('Created: ${user.createdAt.toLocal().toString().split('.')[0]}'),
                const SizedBox(height: 8),
                Text('Group ID: ${user.groupId ?? 'Not in a group'}'),
                const SizedBox(height: 8),
                
                // Status indicators
                if (user.requestedHolder) ...[
                  const Divider(),
                  const Text(
                    'User has requested to become a holder',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => _rejectHolderRequest(user.id),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Reject Request'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => _approveHolderRequest(user.id),
                        child: const Text('Approve as Holder'),
                      ),
                    ],
                  ),
                ],
                
                if (user.requestedJoinGroup) ...[
                  const Divider(),
                  Text(
                    'User has requested to join a group: ${user.requestedGroupId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _getUserIcon(UserModel user) {
    if (user.role == 'admin') {
      return const CircleAvatar(
        backgroundColor: Colors.red,
        child: Icon(Icons.admin_panel_settings, color: Colors.white),
      );
    } else if (user.role == 'holder') {
      return const CircleAvatar(
        backgroundColor: Colors.green,
        child: Icon(Icons.person_2, color: Colors.white),
      );
    } else {
      return const CircleAvatar(
        backgroundColor: Colors.blue,
        child: Icon(Icons.person, color: Colors.white),
      );
    }
  }
} 