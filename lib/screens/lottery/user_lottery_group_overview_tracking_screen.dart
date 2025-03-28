import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class UserLotteryGroupOverviewTrackingScreen extends StatefulWidget {
  final String groupId;
  
  const UserLotteryGroupOverviewTrackingScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _UserLotteryGroupOverviewTrackingScreenState createState() => _UserLotteryGroupOverviewTrackingScreenState();
}

class _UserLotteryGroupOverviewTrackingScreenState extends State<UserLotteryGroupOverviewTrackingScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  Map<String, dynamic>? lotteryMetadata;
  List<UserModel> groupMembers = [];
  Map<String, Map<String, dynamic>> contributionsByMonth = {};
  List<Map<String, dynamic>> pastDraws = [];
  
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
      
      // Fetch group members
      final membersResponse = await client
          .from('users')
          .select()
          .eq('group_id', widget.groupId);
      
      groupMembers = (membersResponse as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
      
      // TODO: Fetch lottery metadata and past draws
      
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
        title: const Text('Lottery Group Overview'),
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
          
          // Lottery cycle progress
          _buildLotteryCycleProgress(),
          
          const SizedBox(height: 24),
          
          // Members contribution table
          _buildMembersContributionTable(),
          
          const SizedBox(height: 24),
          
          // Past draws
          _buildPastDrawsSection(),
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
            // TODO: Add jackpot calculation
            Text(
              'Current Jackpot: \$${(group!.savingsGoal * groupMembers.length).toStringAsFixed(2)}',
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
  
  Widget _buildLotteryCycleProgress() {
    // Using placeholder values - to be replaced with actual data
    final totalMembers = groupMembers.length;
    final completedDraws = pastDraws.length;
    final remainingDraws = totalMembers - completedDraws;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lottery Cycle Progress',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            LinearProgressIndicator(
              value: totalMembers > 0 ? completedDraws / totalMembers : 0,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
              minHeight: 20,
            ),
            
            const SizedBox(height: 8),
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Completed: $completedDraws draws'),
                Text('Remaining: $remainingDraws draws'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Note: Each member will win once in a complete cycle.',
              style: TextStyle(fontStyle: FontStyle.italic),
            ),
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
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Won')),
                ],
                rows: List.generate(
                  groupMembers.length,
                  (index) {
                    final member = groupMembers[index];
                    // TODO: Replace with actual contribution data
                    return DataRow(cells: [
                      DataCell(Text(member.email)),
                      // Example values - to be replaced with actual data
                      const DataCell(Text('Paid')),
                      const DataCell(Text('On Track')),
                      const DataCell(Icon(Icons.close, color: Colors.red)),
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
  
  Widget _buildPastDrawsSection() {
    // TODO: Replace with actual past draws data
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Past Draws',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Sample past draws - to be replaced with actual data
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3, // Example count
              itemBuilder: (context, index) {
                return ListTile(
                  leading: CircleAvatar(
                    child: Text('${index + 1}'),
                  ),
                  title: Text('Draw ${index + 1}'),
                  subtitle: Text('${DateTime.now().month - index}/2023'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Winner: user${index + 1}@example.com'),
                      Text('\$${(group!.savingsGoal * groupMembers.length).toStringAsFixed(2)}'),
                    ],
                  ),
                  onTap: () {
                    // Navigate to draw details
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
} 