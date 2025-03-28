import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/withdrawal_service.dart';
import '../../models/group_metadata_model.dart';

class UserWithdrawalRequestScreen extends StatefulWidget {
  final String groupId;
  
  const UserWithdrawalRequestScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _UserWithdrawalRequestScreenState createState() => _UserWithdrawalRequestScreenState();
}

class _UserWithdrawalRequestScreenState extends State<UserWithdrawalRequestScreen> {
  final client = Supabase.instance.client;
  final WithdrawalService withdrawalService = WithdrawalService(Supabase.instance.client);
  
  bool isLoading = true;
  String? errorMessage;
  StandardGroupMetadata? groupMetadata;
  
  final TextEditingController amountController = TextEditingController();
  final TextEditingController durationController = TextEditingController(text: '3'); // Default to 3 months
  
  double maxAvailable = 0.0;
  
  @override
  void initState() {
    super.initState();
    loadGroupMetadata();
  }
  
  @override
  void dispose() {
    amountController.dispose();
    durationController.dispose();
    super.dispose();
  }
  
  Future<void> loadGroupMetadata() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch group metadata
      final metadataResponse = await client
          .from('standard_group_metadata')
          .select()
          .eq('group_id', widget.groupId)
          .single();
      
      groupMetadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      maxAvailable = groupMetadata!.actualPoolAmount - groupMetadata!.currentWithdrawals;
      
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
  
  Future<void> submitWithdrawalRequest() async {
    // Validate input
    final amount = double.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    
    if (amount > maxAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Requested amount exceeds available funds')),
      );
      return;
    }
    
    final duration = int.tryParse(durationController.text);
    if (duration == null || duration < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid payback duration')),
      );
      return;
    }
    
    try {
      setState(() {
        isLoading = true;
      });
      
      // Get current user
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Submit withdrawal request
      await withdrawalService.requestWithdrawal(
        groupId: widget.groupId,
        userId: user.id,
        amount: amount,
        paybackDuration: duration,
      );
      
      setState(() {
        isLoading = false;
      });
      
      // Show success message and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal request submitted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Withdrawal'),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : _buildContent(),
    );
  }
  
  Widget _buildContent() {
    if (groupMetadata == null) {
      return const Center(
        child: Text('Group information not available'),
      );
    }
    
    // Calculate monthly payback based on current input
    double monthlyPayback = 0;
    final amount = double.tryParse(amountController.text) ?? 0;
    final duration = int.tryParse(durationController.text) ?? 1;
    if (amount > 0 && duration > 0) {
      monthlyPayback = amount / duration;
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group info card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Withdrawal Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text('Total Pool Amount: \$${groupMetadata!.actualPoolAmount.toStringAsFixed(2)}'),
                  Text('Current Withdrawals: \$${groupMetadata!.currentWithdrawals.toStringAsFixed(2)}'),
                  const Divider(),
                  Text(
                    'Available for Withdrawal: \$${maxAvailable.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Withdrawal request form
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Request Details',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount field
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(
                      labelText: 'Amount to Withdraw',
                      prefixText: '\$',
                      hintText: 'Enter amount',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Duration field
                  TextField(
                    controller: durationController,
                    decoration: const InputDecoration(
                      labelText: 'Payback Duration (Months)',
                      hintText: 'Enter number of months',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Monthly payback info
                  Container(
                    padding: const EdgeInsets.all(8.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Monthly Payback: \$${monthlyPayback.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: amount > 0 ? submitWithdrawalRequest : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              child: const Text(
                'Submit Withdrawal Request',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Disclaimer
          const Text(
            'Note: Withdrawal requests are subject to approval by the group holder. Once approved, you will be able to withdraw the funds and begin the payback process.',
            style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
          ),
        ],
      ),
    );
  }
} 