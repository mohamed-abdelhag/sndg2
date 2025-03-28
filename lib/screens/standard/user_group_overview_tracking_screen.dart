import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/group_metadata_model.dart';
import '../../models/user_model.dart';

class UserGroupOverviewTrackingScreen extends StatefulWidget {
  final String groupId;
  
  const UserGroupOverviewTrackingScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _UserGroupOverviewTrackingScreenState createState() => _UserGroupOverviewTrackingScreenState();
}

class _UserGroupOverviewTrackingScreenState extends State<UserGroupOverviewTrackingScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  StandardGroupMetadata? groupMetadata;
  List<UserModel> groupMembers = [];
  Map<String, Map<String, dynamic>> contributionsByMonth = {};
  
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
      
      // Fetch group members
      final membersResponse = await client
          .from('users')
          .select()
          .eq('group_id', widget.groupId);
      
      groupMembers = (membersResponse as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
      
      // TODO: Fetch contributions by month
      
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
        title: const Text('Group Overview'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
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
          _buildGroupSummaryCard(),
          
          const SizedBox(height: 24),
          
          // Progress chart
          _buildProgressSection(),
          
          const SizedBox(height: 24),
          
          // Members contribution table
          _buildMembersContributionTable(),
        ],
      ),
    );
  }
  
  Widget _buildGroupSummaryCard() {
    return Card(
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
            Text('Total Members: ${groupMembers.length}'),
            Text('Monthly Target: \$${group!.savingsGoal.toStringAsFixed(2)}'),
            Text('Total Savings Goal: \$${groupMetadata!.totalSavingsGoal.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Pool', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${groupMetadata!.actualPoolAmount.toStringAsFixed(2)}'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Withdrawals', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${groupMetadata!.currentWithdrawals.toStringAsFixed(2)}'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Available Funds', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('\$${(groupMetadata!.actualPoolAmount - groupMetadata!.currentWithdrawals).toStringAsFixed(2)}'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildProgressSection() {
    final progress = groupMetadata!.actualPoolAmount / groupMetadata!.totalSavingsGoal;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Savings Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
              minHeight: 20,
            ),
            const SizedBox(height: 8),
            Text(
              '${(progress * 100).toStringAsFixed(1)}% of goal (\$${groupMetadata!.actualPoolAmount.toStringAsFixed(2)} of \$${groupMetadata!.totalSavingsGoal.toStringAsFixed(2)})',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            // TODO: Add monthly contribution chart here
          ],
        ),
      ),
    );
  }
  
  Widget _buildMembersContributionTable() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Members Contribution Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Member')),
                  DataColumn(label: Text('This Month')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Status')),
                ],
                rows: List.generate(
                  groupMembers.length,
                  (index) {
                    final member = groupMembers[index];
                    // TODO: Replace with actual contribution data
                    return DataRow(cells: [
                      DataCell(Text(member.email)),
                      const DataCell(Text('\$0.00')), // This month contribution
                      const DataCell(Text('\$0.00')), // Total contribution
                      const DataCell(Text('On Track')), // Status
                    ]);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 