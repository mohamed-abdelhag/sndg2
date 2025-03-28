 import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/auth_service.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class HolderManageGroupScreen extends StatefulWidget {
  final String groupId;
  
  const HolderManageGroupScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderManageGroupScreenState createState() => _HolderManageGroupScreenState();
}

class _HolderManageGroupScreenState extends State<HolderManageGroupScreen> {
  final AuthService authService = AuthService(Supabase.instance.client);
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  UserModel? currentUser;
  
  @override
  void initState() {
    super.initState();
    loadData();
  }
  
  Future<void> loadData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch current user
      currentUser = await authService.getCurrentUser();
      
      // TODO: Fetch group data
      
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Group'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group information section
          Text('Group ID: ${widget.groupId}', style: Theme.of(context).textTheme.headline6),
          const SizedBox(height: 20),
          
          // Action buttons
          ElevatedButton.icon(
            icon: const Icon(Icons.people),
            label: const Text('Manage Members'),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/holder_manage_members',
                arguments: widget.groupId,
              );
            },
          ),
          
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.list_alt),
            label: const Text('View Requests'),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/holder_see_request',
                arguments: widget.groupId,
              );
            },
          ),
          
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.info),
            label: const Text('Group Details'),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/holder_group_details',
                arguments: widget.groupId,
              );
            },
          ),
          
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.monetization_on),
            label: const Text('Manage Withdrawals'),
            onPressed: () {
              Navigator.pushNamed(
                context, 
                '/holder_manage_withdrawal',
                arguments: widget.groupId,
              );
            },
          ),
          
          // Add more buttons based on group type
          // TODO: Add conditional buttons based on group type
        ],
      ),
    );
  }
}