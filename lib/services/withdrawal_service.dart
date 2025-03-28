import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/withdrawal_model.dart';
import '../models/group_metadata_model.dart';

class WithdrawalService {
  final SupabaseClient _client;
  final Uuid uuid = Uuid();
  
  WithdrawalService(this._client);
  
  // Request a withdrawal
  Future<WithdrawalModel> requestWithdrawal({
    required String groupId,
    required String userId,
    required double amount,
    required int paybackDuration,
  }) async {
    try {
      // Check if group is standard type
      final groupResponse = await _client
          .from('groups')
          .select('type')
          .eq('id', groupId)
          .single();
          
      final groupType = (groupResponse as Map<String, dynamic>)['type'] as String;
      
      if (groupType != 'standard') {
        throw Exception('Withdrawals are only available for standard savings groups');
      }
      
      // Check if there's enough in the pool
      final metadataResponse = await _client
          .from('standard_group_metadata')
          .select()
          .eq('group_id', groupId)
          .single();
          
      final metadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      
      if (metadata.actualPoolAmount - metadata.currentWithdrawals < amount) {
        throw Exception('Not enough funds available in the pool');
      }
      
      final id = uuid.v4();
      final now = DateTime.now();
      
      // Calculate monthly payback amount
      final paybackAmount = amount / paybackDuration;
      
      final withdrawalData = {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'amount': amount,
        'status': 'pending',
        'request_date': now.toIso8601String(),
        'approval_date': null,
        'payback_duration': paybackDuration,
        'payback_amount': paybackAmount,
      };
      
      await _client.from('withdrawals').insert(withdrawalData);
      
      // Update group metadata to reflect the requested withdrawal
      await _client
          .from('standard_group_metadata')
          .update({
            'current_withdrawals': metadata.currentWithdrawals + amount,
            'updated_at': now.toIso8601String(),
          })
          .eq('group_id', groupId);
      
      return WithdrawalModel.fromJson(withdrawalData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Approve a withdrawal request
  Future<void> approveWithdrawal(String withdrawalId) async {
    try {
      final now = DateTime.now();
      
      // Get the withdrawal data
      final withdrawalResponse = await _client
          .from('withdrawals')
          .select()
          .eq('id', withdrawalId)
          .single();
          
      final withdrawal = WithdrawalModel.fromJson(withdrawalResponse as Map<String, dynamic>);
      
      // Update withdrawal status
      await _client
          .from('withdrawals')
          .update({
            'status': 'approved',
            'approval_date': now.toIso8601String(),
          })
          .eq('id', withdrawalId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Reject a withdrawal request
  Future<void> rejectWithdrawal(String withdrawalId) async {
    try {
      final now = DateTime.now();
      
      // Get the withdrawal data
      final withdrawalResponse = await _client
          .from('withdrawals')
          .select()
          .eq('id', withdrawalId)
          .single();
          
      final withdrawal = WithdrawalModel.fromJson(withdrawalResponse as Map<String, dynamic>);
      
      // Update withdrawal status
      await _client
          .from('withdrawals')
          .update({
            'status': 'rejected',
            'approval_date': now.toIso8601String(),
          })
          .eq('id', withdrawalId);
      
      // Update group metadata to reflect the rejected withdrawal
      // Get current metadata
      final metadataResponse = await _client
          .from('standard_group_metadata')
          .select()
          .eq('group_id', withdrawal.groupId)
          .single();
      
      final metadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      
      // Update metadata
      await _client
          .from('standard_group_metadata')
          .update({
            'current_withdrawals': metadata.currentWithdrawals - withdrawal.amount,
            'updated_at': now.toIso8601String(),
          })
          .eq('group_id', withdrawal.groupId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Mark a withdrawal as cashed (money taken out)
  Future<void> markWithdrawalAsCashed(String withdrawalId) async {
    try {
      final now = DateTime.now();
      
      // Update withdrawal status
      await _client
          .from('withdrawals')
          .update({
            'status': 'cashed',
          })
          .eq('id', withdrawalId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Record a payback for a withdrawal
  Future<void> recordWithdrawalPayback({
    required String withdrawalId,
    required double amount,
  }) async {
    try {
      // Get the withdrawal data
      final withdrawalResponse = await _client
          .from('withdrawals')
          .select()
          .eq('id', withdrawalId)
          .single();
          
      final withdrawal = WithdrawalModel.fromJson(withdrawalResponse as Map<String, dynamic>);
      
      // Create a payback record
      await _client.from('withdrawal_paybacks').insert({
        'id': uuid.v4(),
        'withdrawal_id': withdrawalId,
        'amount': amount,
        'payback_date': DateTime.now().toIso8601String(),
      });
      
      // Get total paid back
      final totalPaidBackResponse = await _client
          .from('withdrawal_paybacks')
          .select('amount')
          .eq('withdrawal_id', withdrawalId);
          
      final totalPaidBack = (totalPaidBackResponse as List)
          .fold<double>(0, (sum, item) => sum + ((item as Map<String, dynamic>)['amount'] as double));
      
      // Update withdrawal status based on payment status
      String newStatus;
      if (totalPaidBack >= withdrawal.amount) {
        newStatus = 'paid back in full';
      } else {
        newStatus = 'being paid back';
      }
      
      await _client
          .from('withdrawals')
          .update({
            'status': newStatus,
          })
          .eq('id', withdrawalId);
      
      // Update group metadata
      if (newStatus == 'paid back in full') {
        // Get current metadata
        final metadataResponse = await _client
            .from('standard_group_metadata')
            .select()
            .eq('group_id', withdrawal.groupId)
            .single();
            
        final metadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
        
        // Update metadata to reflect the completed withdrawal
        await _client
            .from('standard_group_metadata')
            .update({
              'current_withdrawals': metadata.currentWithdrawals - withdrawal.amount,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('group_id', withdrawal.groupId);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Get pending withdrawal requests for a group
  Future<List<WithdrawalModel>> getPendingWithdrawals(String groupId) async {
    final response = await _client
        .from('withdrawals')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'pending');
    
    return (response as List).map((w) => WithdrawalModel.fromJson(w as Map<String, dynamic>)).toList();
  }
  
  // Get approved withdrawals for a group
  Future<List<WithdrawalModel>> getApprovedWithdrawals(String groupId) async {
    final response = await _client
        .from('withdrawals')
        .select()
        .eq('group_id', groupId)
        .eq('status', 'approved');
    
    return (response as List).map((w) => WithdrawalModel.fromJson(w as Map<String, dynamic>)).toList();
  }
  
  // Get active withdrawals for a user (being paid back)
  Future<List<WithdrawalModel>> getUserActiveWithdrawals(String userId) async {
    final response = await _client
        .from('withdrawals')
        .select()
        .eq('user_id', userId)
        .in_('status', ['cashed', 'being paid back']);
    
    return (response as List).map((w) => WithdrawalModel.fromJson(w as Map<String, dynamic>)).toList();
  }
  
  // Get withdrawal history for a user
  Future<List<WithdrawalModel>> getUserWithdrawalHistory(String userId) async {
    final response = await _client
        .from('withdrawals')
        .select()
        .eq('user_id', userId)
        .order('request_date', ascending: false);
    
    return (response as List).map((w) => WithdrawalModel.fromJson(w as Map<String, dynamic>)).toList();
  }
} 