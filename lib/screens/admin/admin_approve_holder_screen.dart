import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class AdminApproveHolderScreen extends StatefulWidget {
  @override
  _AdminApproveHolderScreenState createState() => _AdminApproveHolderScreenState();
}

class _AdminApproveHolderScreenState extends State<AdminApproveHolderScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  List<UserModel> _holderRequests = [];

  @override
  void initState() {
    super.initState();
    _loadHolderRequests();
  }

  Future<void> _loadHolderRequests() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final requests = await _authService.getHolderRequests();
      
      setState(() {
        _holderRequests = requests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading holder requests: ${e.toString()}')),
      );
    }
  }

  Future<void> _approveHolderRequest(String userId) async {
    try {
      await _authService.approveHolderRequest(userId);
      await _loadHolderRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User approved as holder successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving holder: ${e.toString()}')),
      );
    }
  }

  Future<void> _rejectHolderRequest(String userId) async {
    try {
      await _authService.rejectHolderRequest(userId);
      await _loadHolderRequests();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Holder request rejected')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting request: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Approve Holder Requests'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _holderRequests.isEmpty
              ? Center(child: Text('No pending holder requests'))
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
                            SizedBox(height: 8),
                            Text(
                              'User ID: ${user.id}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Created: ${user.createdAt.toLocal().toString().split('.')[0]}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _rejectHolderRequest(user.id),
                                  child: Text('Reject'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.red,
                                  ),
                                ),
                                SizedBox(width: 16),
                                ElevatedButton(
                                  onPressed: () => _approveHolderRequest(user.id),
                                  child: Text('Approve'),
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