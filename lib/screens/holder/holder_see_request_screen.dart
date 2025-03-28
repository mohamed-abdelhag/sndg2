import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class HolderSeeRequestScreen extends StatefulWidget {
  final String groupId;
  
  const HolderSeeRequestScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderSeeRequestScreenState createState() => _HolderSeeRequestScreenState();
}

class _HolderSeeRequestScreenState extends State<HolderSeeRequestScreen> {
  final AuthService authService = AuthService(Supabase.instance.client);
  bool isLoading = true;
  String? errorMessage;
  List<UserModel> requestingUsers = [];
  
  @override
  void initState() {
    super.initState();
    loadRequests();
  }
  
  Future<void> loadRequests() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch users requesting to join this group
      requestingUsers = await authService.getJoinGroupRequests(widget.groupId);
      
      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  Future<void> approveRequest(String userId) async {
    try {
      await authService.approveJoinGroupRequest(userId, widget.groupId);
      // Refresh the list
      loadRequests();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving request: ${e.toString()}')),
      );
    }
  }

  Future<void> rejectRequest(String userId) async {
    try {
      await authService.rejectJoinGroupRequest(userId);
      // Refresh the list
      loadRequests();
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
        title: const Text('Join Requests'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (requestingUsers.isEmpty) {
      return const Center(
        child: Text('No pending join requests at this time.'),
      );
    }
    
    return ListView.builder(
      itemCount: requestingUsers.length,
      itemBuilder: (context, index) {
        final user = requestingUsers[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            title: Text(user.email),
            subtitle: Text('Requested to join your group'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  onPressed: () => approveRequest(user.id),
                  tooltip: 'Approve',
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  onPressed: () => rejectRequest(user.id),
                  tooltip: 'Reject',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 