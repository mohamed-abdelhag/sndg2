import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/group_service.dart';
import '../../models/user_model.dart';

class HolderCreateScreen extends StatefulWidget {
  @override
  _HolderCreateScreenState createState() => _HolderCreateScreenState();
}

class _HolderCreateScreenState extends State<HolderCreateScreen> {
  final AuthService _authService = AuthService();
  final GroupService _groupService = GroupService();
  
  final _formKey = GlobalKey<FormState>();
  
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isCreatingGroup = false;
  
  String _groupName = '';
  String _groupType = 'standard';
  double _savingsGoal = 0.0;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    try {
      final user = await _authService.getCurrentUser();
      
      setState(() {
        _currentUser = user;
        _isLoading = false;
      });
      
      if (user == null || user.role != 'holder') {
        // Navigate back if not a holder
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Only holders can create groups')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user: ${e.toString()}')),
      );
    }
  }
  
  Future<void> _createGroup() async {
    if (_formKey.currentState?.validate() != true || _currentUser == null) {
      return;
    }
    
    _formKey.currentState?.save();
    
    try {
      setState(() {
        _isCreatingGroup = true;
      });
      
      await _groupService.createGroup(
        name: _groupName,
        type: _groupType,
        savingsGoal: _savingsGoal,
        holderId: _currentUser!.id,
      );
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Group created successfully')),
      );
      
      // Navigate back to holder dashboard
      Navigator.pushReplacementNamed(context, '/holder_dashboard');
    } catch (e) {
      setState(() {
        _isCreatingGroup = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating group: ${e.toString()}')),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Create Group')),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Group'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Create a New Savings Group',
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Group Name',
                  hintText: 'Enter a name for your group',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  return null;
                },
                onSaved: (value) {
                  _groupName = value?.trim() ?? '';
                },
                enabled: !_isCreatingGroup,
              ),
              SizedBox(height: 16),
              Text('Group Type', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              _buildGroupTypeSelector(),
              SizedBox(height: 16),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Monthly Savings Goal (\$)',
                  hintText: 'Enter the amount each member should save monthly',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a savings goal';
                  }
                  
                  final goal = double.tryParse(value);
                  if (goal == null || goal <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  
                  return null;
                },
                onSaved: (value) {
                  _savingsGoal = double.tryParse(value ?? '0') ?? 0.0;
                },
                enabled: !_isCreatingGroup,
              ),
              SizedBox(height: 24),
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _groupType == 'standard' ? Colors.blue.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _groupType == 'standard' ? Colors.blue : Colors.orange,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _groupType == 'standard' ? 'Standard Group Info' : 'Lottery Group Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _groupType == 'standard' ? Colors.blue : Colors.orange,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _groupType == 'standard'
                          ? 'In a standard group, members can request to withdraw money and pay it back over time.'
                          : 'In a lottery group, contributions are pooled and one member wins the pool each month.',
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isCreatingGroup ? null : _createGroup,
                child: _isCreatingGroup
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text('Creating Group...'),
                        ],
                      )
                    : Text('Create Group'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildGroupTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: _isCreatingGroup ? null : () {
              setState(() {
                _groupType = 'standard';
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _groupType == 'standard' ? Colors.blue : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.savings,
                    color: _groupType == 'standard' ? Colors.white : Colors.grey.shade700,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Standard',
                    style: TextStyle(
                      color: _groupType == 'standard' ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: GestureDetector(
            onTap: _isCreatingGroup ? null : () {
              setState(() {
                _groupType = 'lottery';
              });
            },
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: _groupType == 'lottery' ? Colors.orange : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.emoji_events,
                    color: _groupType == 'lottery' ? Colors.white : Colors.grey.shade700,
                    size: 32,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Lottery',
                    style: TextStyle(
                      color: _groupType == 'lottery' ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
} 