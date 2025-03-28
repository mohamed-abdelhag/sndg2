import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class UserLotteryGroupDashboardScreen extends StatefulWidget {
  final String groupId;
  
  const UserLotteryGroupDashboardScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _UserLotteryGroupDashboardScreenState createState() => _UserLotteryGroupDashboardScreenState();
}

class _UserLotteryGroupDashboardScreenState extends State<UserLotteryGroupDashboardScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  Map<String, dynamic>? lotteryMetadata;
  UserModel? currentUser;
  List<UserModel> groupMembers = [];
  UserModel? currentWinner;
  DateTime? nextDrawDate;
  
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
      
      // Fetch group members
      final membersResponse = await client
          .from('users')
          .select()
          .eq('group_id', widget.groupId);
      
      groupMembers = (membersResponse as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
      
      // TODO: Fetch lottery metadata and winner info
      
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
        title: Text(group?.name ?? 'Lottery Group Dashboard'),
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
          
          // Current status section
          _buildCurrentStatusCard(),
          
          const SizedBox(height: 24),
          
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
                    '/user_lottery_group_overview_tracking',
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
          
          // Past winners section
          _buildPastWinnersSection(),
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
            Text('Group Type: Lottery'),
            Text('Members: ${groupMembers.length}'),
            Text('Monthly Contribution: \$${group!.savingsGoal.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            // TODO: Add estimated jackpot calculation
            Text(
              'Estimated Jackpot: \$${(group!.savingsGoal * groupMembers.length).toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCurrentStatusCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Draw Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Next draw date
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Next Draw'),
              subtitle: Text(nextDrawDate != null 
                  ? '${nextDrawDate!.day}/${nextDrawDate!.month}/${nextDrawDate!.year}'
                  : 'To be determined'),
            ),
            
            // Current winner
            ListTile(
              leading: const Icon(Icons.emoji_events),
              title: const Text('Current Winner'),
              subtitle: Text(currentWinner?.email ?? 'No winner selected yet'),
            ),
            
            // Your status
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Your Status'),
              subtitle: const Text('Waiting for draw'), // To be replaced with actual status
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPastWinnersSection() {
    // TODO: Replace with actual past winners data
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past Winners',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Sample past winners - to be replaced with actual data
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Example count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text('user${index + 1}@example.com'),
                  subtitle: Text('Draw ${index + 1}'),
                  trailing: Text('\$${(group!.savingsGoal * groupMembers.length).toStringAsFixed(2)}'),
                  onTap: () {
                    // Navigate to winner details
                    Navigator.pushNamed(
                      context,
                      '/user_lottery_winner_group',
                      arguments: {
                        'groupId': widget.groupId,
                        'winnerId': 'sample-winner-id-${index + 1}', // To be replaced with actual ID
                      },
                    );
                  },
                );
              },
            ),
          ],
        ),
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