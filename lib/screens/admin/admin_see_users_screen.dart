import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/user_model.dart';

class AdminSeeUsersScreen extends StatefulWidget {
  const AdminSeeUsersScreen({Key? key}) : super(key: key);

  @override
  _AdminSeeUsersScreenState createState() => _AdminSeeUsersScreenState();
}

class _AdminSeeUsersScreenState extends State<AdminSeeUsersScreen> {
  final client = Supabase.instance.client;
  List<UserModel> _allUsers = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoading = true;
  String? _error;
  
  // Filtering
  final TextEditingController _searchController = TextEditingController();
  String _selectedRole = 'all';
  final List<String> _roleOptions = ['all', 'normal', 'holder', 'admin'];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }
  
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      print('Fetching users from Supabase...');
      final response = await client.from('users').select().order('created_at');
      print('Response from Supabase: ${response.length} users found');
      
      List<UserModel> loadedUsers = (response as List)
          .map((userData) => UserModel.fromJson(userData as Map<String, dynamic>))
          .toList();

      setState(() {
        _allUsers = loadedUsers;
        _applyFilters(); // Apply initial filters
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading users: ${e.toString()}');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
  
  void _applyFilters() {
    List<UserModel> result = List.from(_allUsers);
    
    // Apply role filter
    if (_selectedRole != 'all') {
      result = result.where((user) => user.role == _selectedRole).toList();
    }
    
    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase().trim();
    if (searchQuery.isNotEmpty) {
      result = result.where((user) => 
        user.email.toLowerCase().contains(searchQuery)
      ).toList();
    }
    
    setState(() {
      _filteredUsers = result;
    });
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
        title: const Text('All Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and filter section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by email',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _applyFilters();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _applyFilters(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Filter by role:'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _selectedRole,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        items: _roleOptions.map((String role) {
                          return DropdownMenuItem<String>(
                            value: role,
                            child: Text(role == 'all' ? 'All Roles' : _getRoleDisplayName(role)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              _selectedRole = newValue;
                              _applyFilters();
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Total: ${_filteredUsers.length} users' + 
                  (_selectedRole != 'all' ? ' (Filtered)' : ''),
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
          
          // Users list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Error: $_error'),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadUsers,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _filteredUsers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.person_off,
                                  size: 64,
                                  color: Colors.grey,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _searchController.text.isNotEmpty || _selectedRole != 'all'
                                      ? 'No users match your filters'
                                      : 'No users found',
                                  style: const TextStyle(fontSize: 18),
                                ),
                                if (_searchController.text.isNotEmpty || _selectedRole != 'all')
                                  TextButton(
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() {
                                        _selectedRole = 'all';
                                        _applyFilters();
                                      });
                                    },
                                    child: const Text('Clear Filters'),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = _filteredUsers[index];
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
                                            padding: const EdgeInsets.symmetric(
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
                                      const SizedBox(height: 8),
                                      Text('ID: ${user.id}'),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Created: ${user.createdAt.toLocal().toString().split('.')[0]}',
                                      ),
                                      if (user.groupId != null) ...[
                                        const SizedBox(height: 4),
                                        Text('Group ID: ${user.groupId}'),
                                      ],
                                      if (user.requestedHolder) ...[
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.pending, color: Colors.orange, size: 16),
                                            const SizedBox(width: 4),
                                            const Text(
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
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Icon(Icons.pending, color: Colors.blue, size: 16),
                                            const SizedBox(width: 4),
                                            const Text(
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
          ),
        ],
      ),
    );
  }
} 