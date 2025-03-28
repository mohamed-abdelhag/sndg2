import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AdminSeeUsersScreen extends StatefulWidget {
  @override
  _AdminSeeUsersScreenState createState() => _AdminSeeUsersScreenState();
}

class _AdminSeeUsersScreenState extends State<AdminSeeUsersScreen> {
  final supabase = Supabase.instance.client;
  List<UserModel> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final response = await supabase.from('users').select().order('created_at');
      
      List<UserModel> loadedUsers = (response as List)
          .map((userData) => UserModel.fromJson(userData as Map<String, dynamic>))
          .toList();

      setState(() {
        _users = loadedUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'holder':
        return 'Group Holder';
      case 'normal':
        return 'Regular User';
      default:
        return role;
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return Colors.purple;
      case 'holder':
        return Colors.blue;
      case 'normal':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('All Users'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadUsers,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Error: $_error'),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadUsers,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : _users.isEmpty
                  ? Center(child: Text('No users found'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        user.email,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getRoleColor(user.role).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: _getRoleColor(user.role),
                                        ),
                                      ),
                                      child: Text(
                                        _getRoleDisplayName(user.role),
                                        style: TextStyle(
                                          color: _getRoleColor(user.role),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('ID: ${user.id}'),
                                SizedBox(height: 4),
                                Text(
                                  'Created: ${user.createdAt.toLocal().toString().split('.')[0]}',
                                ),
                                if (user.groupId != null) ...[
                                  SizedBox(height: 4),
                                  Text('Group ID: ${user.groupId}'),
                                ],
                                if (user.requestedHolder) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.pending, color: Colors.orange, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Requested to become a holder',
                                        style: TextStyle(
                                          color: Colors.orange,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                if (user.requestedJoinGroup) ...[
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Icon(Icons.pending, color: Colors.blue, size: 16),
                                      SizedBox(width: 4),
                                      Text(
                                        'Requested to join a group',
                                        style: TextStyle(
                                          color: Colors.blue,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 