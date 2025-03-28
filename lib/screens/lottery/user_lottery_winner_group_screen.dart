import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';

class UserLotteryWinnerGroupScreen extends StatefulWidget {
  final String groupId;
  final String winnerId;
  //skjadgsakjd
  const UserLotteryWinnerGroupScreen({
    Key? key, 
    required this.groupId,
    required this.winnerId,
  }) : super(key: key);

  @override
  _UserLotteryWinnerGroupScreenState createState() => _UserLotteryWinnerGroupScreenState();
}

class _UserLotteryWinnerGroupScreenState extends State<UserLotteryWinnerGroupScreen> {
  final client = Supabase.instance.client;
  bool isLoading = true;
  String? errorMessage;
  GroupModel? group;
  UserModel? winner;
  Map<String, dynamic>? drawDetails;
  
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
      
      // Fetch winner details
      final winnerResponse = await client
          .from('users')
          .select()
          .eq('id', widget.winnerId)
          .single();
      
      winner = UserModel.fromJson(winnerResponse as Map<String, dynamic>);
      
      // TODO: Fetch draw details
      
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
        title: const Text('Lottery Winner Details'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (group == null || winner == null) {
      return const Center(
        child: Text('Information not available'),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Winner card
          _buildWinnerCard(),
          
          const SizedBox(height: 24),
          
          // Draw details card
          _buildDrawDetailsCard(),
          
          const SizedBox(height: 24),
          
          // Payment confirmation section
          _buildPaymentConfirmationSection(),
        ],
      ),
    );
  }
  
  Widget _buildWinnerCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.emoji_events,
              size: 56,
              color: Colors.amber,
            ),
            const SizedBox(height: 16),
            Text(
              'Winner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              winner!.email,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TODO: Add draw number and date information
            const Text('Draw #3 - May 2023'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'Prize: \$${(group!.savingsGoal * 10).toStringAsFixed(2)}', // Replace with actual value
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDrawDetailsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Draw Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Total Participants'),
              trailing: const Text('10'), // Replace with actual value
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Individual Contribution'),
              trailing: Text('\$${group!.savingsGoal.toStringAsFixed(2)}'),
            ),
            
            const Divider(),
            
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Draw Date'),
              trailing: const Text('15 May 2023'), // Replace with actual value
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildPaymentConfirmationSection() {
    // Example - this would be based on whether the current user is the winner or not,
    // and whether the payment has been made
    final bool isCurrentUserWinner = false; // Replace with actual logic
    final bool paymentConfirmed = false; // Replace with actual logic
    
    if (isCurrentUserWinner) {
      return Card(
        color: Colors.green[50],
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Congratulations!',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'You are the winner of this draw. The prize will be transferred to you shortly.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              
              // Payment status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: paymentConfirmed ? Colors.green[100] : Colors.amber[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      paymentConfirmed ? Icons.check_circle : Icons.pending,
                      color: paymentConfirmed ? Colors.green : Colors.amber[800],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      paymentConfirmed ? 'Payment Received' : 'Payment Pending',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: paymentConfirmed ? Colors.green : Colors.amber[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // If the current user is not the winner
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payment Status',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Icon(
                  paymentConfirmed ? Icons.check_circle : Icons.pending,
                  color: paymentConfirmed ? Colors.green : Colors.amber,
                ),
                title: Text(
                  paymentConfirmed 
                      ? 'Payment to Winner Complete' 
                      : 'Payment to Winner Pending',
                ),
                subtitle: Text(
                  paymentConfirmed
                      ? 'Prize has been transferred on ${DateTime.now().toString().substring(0, 10)}'
                      : 'The holder will coordinate the prize transfer',
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
} 