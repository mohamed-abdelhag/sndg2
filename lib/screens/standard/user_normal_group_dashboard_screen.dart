import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/group_metadata_model.dart';
import '../../models/user_model.dart';

class UserNormalGroupDashboardScreen extends StatefulWidget {
  final String groupId;
  
  const UserNormalGroupDashboardScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _UserNormalGroupDashboardScreenState createState() => _UserNormalGroupDashboardScreenState();
}

class _UserNormalGroupDashboardScreenState extends State<UserNormalGroupDashboardScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  StandardGroupMetadata? groupMetadata;
  UserModel? currentUser;
  Map<String, dynamic>? userContributions;
  
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
      final user = client.auth.currentUser;
      if (user != null) {
        final userData = await client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        currentUser = UserModel.fromJson(userData as Map<String, dynamic>);
      }
      
      // Fetch group details
      final groupResponse = await client
          .from('groups')
          .select()
          .eq('id', widget.groupId)
          .single();
      
      group = GroupModel.fromJson(groupResponse as Map<String, dynamic>);
      
      // Fetch group metadata
      final metadataResponse = await client
          .from('standard_group_metadata')
          .select()
          .eq('group_id', widget.groupId)
          .single();
      
      groupMetadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      
      // TODO: Fetch user contributions
      
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
        title: Text(group?.name ?? 'Group Dashboard'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(
            context,
            '/user_withdrawal_request',
            arguments: widget.groupId,
          );
        },
        child: const Icon(Icons.monetization_on),
        tooltip: 'Request Withdrawal',
      ),
    );
  }
  
  Widget _buildContent() {
    if (group == null || groupMetadata == null) {
      return const Center(
        child: Text('Group information not available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    group!.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text('Group Type: Standard Savings'),
                  Text('Monthly Target: \$${group!.savingsGoal.toStringAsFixed(2)}'),
                  Text('Current Pool: \$${groupMetadata!.actualPoolAmount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: groupMetadata!.actualPoolAmount / groupMetadata!.totalSavingsGoal,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Progress: ${((groupMetadata!.actualPoolAmount / groupMetadata!.totalSavingsGoal) * 100).toStringAsFixed(1)}% of goal',
                    style: const TextStyle(fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                icon: const Icon(Icons.show_chart),
                label: const Text('Track Progress'),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/user_group_overview_tracking',
                    arguments: widget.groupId,
                  );
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.payments),
                label: const Text('Record Payment'),
                onPressed: () {
                  // TODO: Implement payment recording
                  _showRecordPaymentDialog();
                },
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Your contributions section
          Text(
            'Your Contributions',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          
          // TODO: Replace with actual contribution data
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ListTile(
                    title: const Text('This Month'),
                    trailing: const Text('\$0.00'), // Replace with actual data
                    subtitle: const Text('Not paid yet'), // Replace with status
                  ),
                  ListTile(
                    title: const Text('Total Contributed'),
                    trailing: const Text('\$0.00'), // Replace with actual data
                    subtitle: const Text('Over all time'),
                  ),
                  ListTile(
                    title: const Text('Status'),
                    trailing: const Text('On Track'), // Replace with status
                    subtitle: const Text('No missed payments'),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Recent activity section (placeholder)
          Text(
            'Recent Activity',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          _buildRecentActivityList(),
        ],
      ),
    );
  }
  
  Widget _buildRecentActivityList() {
    // TODO: Replace with actual activity data
    return Card(
      child: ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 3, // Example count
        itemBuilder: (context, index) {
          return const ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.green,
              child: Icon(Icons.attach_money, color: Colors.white),
            ),
            title: Text('Monthly Contribution'),
            subtitle: Text('May 2023'),
            trailing: Text('\$100.00'),
          );
        },
      ),
    );
  }
  
  void _showRecordPaymentDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Record Payment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Record your monthly contribution:'),
            const SizedBox(height: 16),
            Text('Amount: \$${group?.savingsGoal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            const Text('Confirm that you have made this payment to the group.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Record the payment
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment recorded successfully')),
              );
            },
            child: const Text('Confirm Payment'),
          ),
        ],
      ),
    );
  }
} 