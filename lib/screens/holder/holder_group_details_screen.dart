import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/group_metadata_model.dart';

class HolderGroupDetailsScreen extends StatefulWidget {
  final String groupId;
  
  const HolderGroupDetailsScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderGroupDetailsScreenState createState() => _HolderGroupDetailsScreenState();
}

class _HolderGroupDetailsScreenState extends State<HolderGroupDetailsScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  dynamic groupMetadata;
  
  @override
  void initState() {
    super.initState();
    loadGroupDetails();
  }
  
  Future<void> loadGroupDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch group details
      final groupResponse = await client
          .from('groups')
          .select()
          .eq('id', widget.groupId)
          .single();
      
      group = GroupModel.fromJson(groupResponse as Map<String, dynamic>);
      
      // Fetch group metadata based on group type
      if (group?.type == 'standard') {
        final metadataResponse = await client
            .from('standard_group_metadata')
            .select()
            .eq('group_id', widget.groupId)
            .single();
        
        groupMetadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      } else if (group?.type == 'lottery') {
        // TODO: Load lottery group metadata
      }
      
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
        title: const Text('Group Details'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (group == null) {
      return const Center(
        child: Text('Group not found.'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group basic info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Group Name: ${group!.name}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text('Group Type: ${group!.type}'),
                  const SizedBox(height: 8),
                  Text('Group ID: ${group!.id}'),
                  const SizedBox(height: 8),
                  Text('Created At: ${_formatDate(group!.createdAt)}'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Group metadata info
          if (groupMetadata != null && group!.type == 'standard')
            _buildStandardGroupMetadata(),
          
          // TODO: Add lottery group metadata display
        ],
      ),
    );
  }
  
  Widget _buildStandardGroupMetadata() {
    final metadata = groupMetadata as StandardGroupMetadata;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Standard Group Metadata', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            
            ListTile(
              title: const Text('Total Savings Goal'),
              trailing: Text('\$${metadata.totalSavingsGoal.toStringAsFixed(2)}'),
            ),
            
            ListTile(
              title: const Text('Actual Pool Amount'),
              trailing: Text('\$${metadata.actualPoolAmount.toStringAsFixed(2)}'),
            ),
            
            ListTile(
              title: const Text('Current Withdrawals'),
              trailing: Text('\$${metadata.currentWithdrawals.toStringAsFixed(2)}'),
            ),
            
            ListTile(
              title: const Text('Available for Withdrawal'),
              trailing: Text('\$${(metadata.actualPoolAmount - metadata.currentWithdrawals).toStringAsFixed(2)}'),
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
} 