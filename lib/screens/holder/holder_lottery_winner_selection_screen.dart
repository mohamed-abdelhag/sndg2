import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../models/user_model.dart';

class HolderLotteryWinnerSelectionScreen extends StatefulWidget {
  final String groupId;
  
  const HolderLotteryWinnerSelectionScreen({Key? key, required this.groupId}) : super(key: key);

  @override
  _HolderLotteryWinnerSelectionScreenState createState() => _HolderLotteryWinnerSelectionScreenState();
}

class _HolderLotteryWinnerSelectionScreenState extends State<HolderLotteryWinnerSelectionScreen> {
  final client = Supabase.instance.client;
  final uuid = Uuid();
  bool isLoading = true;
  String? errorMessage;
  List<UserModel> groupMembers = [];
  UserModel? selectedWinner;
  bool selectionInProgress = false;
  
  @override
  void initState() {
    super.initState();
    loadGroupMembers();
  }
  
  Future<void> loadGroupMembers() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
      
      // Fetch members of this group
      final response = await client
          .from('users')
          .select()
          .eq('group_id', widget.groupId);
      
      groupMembers = (response as List)
          .map((user) => UserModel.fromJson(user as Map<String, dynamic>))
          .toList();
      
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

  Future<void> selectWinner() async {
    if (groupMembers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No members to select from')),
      );
      return;
    }
    
    setState(() {
      selectionInProgress = true;
    });
    
    // Simulate selection animation
    for (int i = 0; i < 15; i++) {
      final randomIndex = DateTime.now().millisecondsSinceEpoch % groupMembers.length;
      setState(() {
        selectedWinner = groupMembers[randomIndex];
      });
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    // Final selection
    final finalIndex = DateTime.now().millisecondsSinceEpoch % groupMembers.length;
    setState(() {
      selectedWinner = groupMembers[finalIndex];
      selectionInProgress = false;
    });
    
    // TODO: Save the winner to the database
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lottery Winner Selection'),
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Lottery Winner Selection',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Group ID: ${widget.groupId}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Total Members: ${groupMembers.length}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Winner display area
          Card(
            color: Colors.amber[100],
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
              child: Column(
                children: [
                  Text(
                    'Selected Winner',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  selectedWinner != null
                      ? Text(
                          selectedWinner!.email,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      : const Text(
                          'No winner selected yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Selection button
          ElevatedButton.icon(
            icon: const Icon(Icons.casino),
            label: selectionInProgress
                ? const Text('Selecting...')
                : const Text('Select Winner'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              backgroundColor: Colors.green,
            ),
            onPressed: selectionInProgress ? null : selectWinner,
          ),
          
          const SizedBox(height: 16),
          
          // Confirm selection button (only show when winner is selected)
          if (selectedWinner != null && !selectionInProgress)
            ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text('Confirm Winner'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                backgroundColor: Colors.blue,
              ),
              onPressed: () {
                // TODO: Confirm winner in database
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }
} 