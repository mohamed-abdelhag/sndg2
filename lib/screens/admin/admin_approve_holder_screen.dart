import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminApproveHolderScreen extends StatefulWidget {
  const AdminApproveHolderScreen({Key? key}) : super(key: key);

  @override
  _AdminApproveHolderScreenState createState() => _AdminApproveHolderScreenState();
}

class _AdminApproveHolderScreenState extends State<AdminApproveHolderScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<UserModel> _holderRequests = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHolderRequests();
  }

  Future<void> _loadHolderRequests() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
      
      // First check if the current user is an admin
      final currentUser = await _authService.getCurrentUser();
      if (currentUser == null || currentUser.role != 'admin') {
        setState(() {
          _errorMessage = 'You do not have permission to view this page';
          _isLoading = false;
        });
        return;
      }
      
      print('Current user is admin, loading holder requests...');
      
      try {
        // Get holder requests
        final requests = await _authService.getHolderRequests();
        print('Loaded ${requests.length} holder requests');
        
        setState(() {
          _holderRequests = requests;
          _isLoading = false;
        });
      } catch (e) {
        print('Error in getHolderRequests: $e');
        setState(() {
          _errorMessage = 'Error loading holder requests: ${e.toString()}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('General error in _loadHolderRequests: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _approveHolderRequest(String userId) async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      await _authService.approveHolderRequest(userId);
      
      setState(() {
        _isLoading = false;
      });
      
      await _loadHolderRequests();
      
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
      
      setState(() {
        _isLoading = false;
      });
      
      await _loadHolderRequests();
      
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
        title: const Text('Approve Holder Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHolderRequests,
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
                        onPressed: _loadHolderRequests,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : _holderRequests.isEmpty
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
                          const Text(
                            'No pending holder requests',
                            style: TextStyle(fontSize: 18),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.refresh),
                            label: const Text('Refresh'),
                            onPressed: _loadHolderRequests,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16.0),
                      itemCount: _holderRequests.length,
                      itemBuilder: (context, index) {
                        final user = _holderRequests[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email: ${user.email}',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'User ID: ${user.id}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Created: ${user.createdAt.toLocal().toString().split('.')[0]}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () => _rejectHolderRequest(user.id),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.red,
                                      ),
                                      child: const Text('Reject'),
                                    ),
                                    const SizedBox(width: 16),
                                    ElevatedButton(
                                      onPressed: () => _approveHolderRequest(user.id),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
} 