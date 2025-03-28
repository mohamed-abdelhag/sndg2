import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/withdrawal_service.dart';
import '../../models/withdrawal_model.dart';

class HolderManageWithdrawalScreen extends StatefulWidget {
  final String groupId;
  
  const HolderManageWithdrawalScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderManageWithdrawalScreenState createState() => _HolderManageWithdrawalScreenState();
}

class _HolderManageWithdrawalScreenState extends State<HolderManageWithdrawalScreen> with SingleTickerProviderStateMixin {
  final WithdrawalService withdrawalService = WithdrawalService(Supabase.instance.client);
  bool isLoading = true;
  String? errorMessage;
  List<WithdrawalModel> pendingWithdrawals = [];
  List<WithdrawalModel> approvedWithdrawals = [];
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    loadWithdrawals();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> loadWithdrawals() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch pending withdrawals
      pendingWithdrawals = await withdrawalService.getPendingWithdrawals(widget.groupId);
      
      // Fetch approved withdrawals
      approvedWithdrawals = await withdrawalService.getApprovedWithdrawals(widget.groupId);
      
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

  Future<void> approveWithdrawal(String withdrawalId) async {
    try {
      await withdrawalService.approveWithdrawal(withdrawalId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal approved')),
      );
      loadWithdrawals(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> rejectWithdrawal(String withdrawalId) async {
    try {
      await withdrawalService.rejectWithdrawal(withdrawalId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal rejected')),
      );
      loadWithdrawals(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  Future<void> markAsCashed(String withdrawalId) async {
    try {
      await withdrawalService.markWithdrawalAsCashed(withdrawalId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Withdrawal marked as cashed')),
      );
      loadWithdrawals(); // Refresh the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Withdrawals'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
          ],
        ),
      ),
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(child: Text('Error: $errorMessage'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildPendingWithdrawals(),
                    _buildApprovedWithdrawals(),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: loadWithdrawals,
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh',
      ),
    );
  }
  
  Widget _buildPendingWithdrawals() {
    if (pendingWithdrawals.isEmpty) {
      return const Center(
        child: Text('No pending withdrawal requests'),
      );
    }
    
    return ListView.builder(
      itemCount: pendingWithdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = pendingWithdrawals[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: \$${withdrawal.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('User ID: ${withdrawal.userId}'),
                Text('Request Date: ${withdrawal.requestDate.toString().substring(0, 10)}'),
                Text('Payback Duration: ${withdrawal.paybackDuration} months'),
                Text('Monthly Payback: \$${withdrawal.paybackAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () => approveWithdrawal(withdrawal.id),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => rejectWithdrawal(withdrawal.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildApprovedWithdrawals() {
    if (approvedWithdrawals.isEmpty) {
      return const Center(
        child: Text('No approved withdrawals'),
      );
    }
    
    return ListView.builder(
      itemCount: approvedWithdrawals.length,
      itemBuilder: (context, index) {
        final withdrawal = approvedWithdrawals[index];
        
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Amount: \$${withdrawal.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text('User ID: ${withdrawal.userId}'),
                Text('Request Date: ${withdrawal.requestDate.toString().substring(0, 10)}'),
                Text('Approval Date: ${withdrawal.approvalDate?.toString().substring(0, 10) ?? 'N/A'}'),
                Text('Payback Duration: ${withdrawal.paybackDuration} months'),
                Text('Monthly Payback: \$${withdrawal.paybackAmount.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.monetization_on),
                  label: const Text('Mark as Cashed'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                  ),
                  onPressed: () => markAsCashed(withdrawal.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
} 