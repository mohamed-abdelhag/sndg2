import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/user_model.dart';

class HolderManageMembersScreen extends StatefulWidget {
  final String groupId;
  
  const HolderManageMembersScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderManageMembersScreenState createState() => _HolderManageMembersScreenState();
}

class _HolderManageMembersScreenState extends State<HolderManageMembersScreen> {
  final AuthService authService = AuthService(Supabase.instance.client);
  bool isLoading = true;
  String? errorMessage;
  List<UserModel> groupMembers = [];
  
  @override
  void initState() {
    super.initState();
    loadMembers();
  }
  
  Future<void> loadMembers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch members of this group
      groupMembers = await authService.getGroupMembers(widget.groupId);
      
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

  Future<void> removeMember(String userId) async {
    try {
      await authService.removeUserFromGroup(userId);
      // Refresh the list
      loadMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Member removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing member: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Members'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (groupMembers.isEmpty) {
      return const Center(
        child: Text('No members in this group yet.'),
      );
    }
    
    return ListView.builder(
      itemCount: groupMembers.length,
      itemBuilder: (context, index) {
        final member = groupMembers[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: ListTile(
            leading: CircleAvatar(
              child: Text(member.email.substring(0, 1).toUpperCase()),
            ),
            title: Text(member.email),
            subtitle: Text('Role: ${member.role}'),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showRemoveConfirmation(member),
              tooltip: 'Remove from group',
            ),
          ),
        );
      },
    );
  }
  
  void _showRemoveConfirmation(UserModel member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Member'),
        content: Text('Are you sure you want to remove ${member.email} from the group?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              removeMember(member.id);
            },
            child: const Text('Remove'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
  }
} 