import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/contribution_model.dart';
import '../models/group_metadata_model.dart';

class ContributionService {
  final supabase = Supabase.instance.client;
  final uuid = Uuid();
  
  // Record a contribution for a user
  Future<ContributionModel> recordContribution({
    required String groupId,
    required String userId,
    required String month,
    required double amount,
  }) async {
    try {
      final id = uuid.v4();
      final now = DateTime.now();
      
      final contributionData = {
        'id': id,
        'group_id': groupId,
        'user_id': userId,
        'month': month,
        'amount': amount,
        'contribution_date': now.toIso8601String(),
        'is_paid': true,
      };
      
      await supabase.from('contributions').insert(contributionData);
      
      // Also insert into the dynamically created group contributions table
      await supabase.rpc('record_contribution', params: {
        'p_group_id': groupId,
        'p_user_id': userId,
        'p_month': month,
        'p_amount': amount,
      });
      
      // Update the group metadata based on group type
      // First, get the group type
      final groupResponse = await supabase
          .from('groups')
          .select('type')
          .eq('id', groupId)
          .single();
          
      final groupType = (groupResponse as Map<String, dynamic>)['type'] as String;
      
      if (groupType == 'standard') {
        // Update standard group metadata
        final metadataResponse = await supabase
            .from('standard_group_metadata')
            .select()
            .eq('group_id', groupId)
            .single();
            
        final metadata = StandardGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
        final newPoolAmount = metadata.actualPoolAmount + amount;
        
        await supabase
            .from('standard_group_metadata')
            .update({
              'actual_pool_amount': newPoolAmount,
              'updated_at': now.toIso8601String(),
            })
            .eq('group_id', groupId);
      } else if (groupType == 'lottery') {
        // Update lottery group metadata
        final metadataResponse = await supabase
            .from('lottery_group_metadata')
            .select()
            .eq('group_id', groupId)
            .single();
            
        final metadata = LotteryGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
        final newPoolAmount = metadata.actualPoolAmount + amount;
        final newCurrentPoolAmount = metadata.currentPoolAmount + amount;
        
        await supabase
            .from('lottery_group_metadata')
            .update({
              'actual_pool_amount': newPoolAmount,
              'current_pool_amount': newCurrentPoolAmount,
              'updated_at': now.toIso8601String(),
            })
            .eq('group_id', groupId);
      }
      
      return ContributionModel.fromJson(contributionData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get user contributions for a specific month
  Future<ContributionModel?> getUserContributionForMonth({
    required String groupId,
    required String userId,
    required String month,
  }) async {
    try {
      final response = await supabase
          .from('contributions')
          .select()
          .eq('group_id', groupId)
          .eq('user_id', userId)
          .eq('month', month)
          .maybeSingle();
      
      if (response == null) {
        return null;
      }
      
      return ContributionModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  // Get all contributions for a user in a group
  Future<List<ContributionModel>> getUserContributions({
    required String groupId,
    required String userId,
  }) async {
    final response = await supabase
        .from('contributions')
        .select()
        .eq('group_id', groupId)
        .eq('user_id', userId)
        .order('month');
    
    return (response as List).map((contrib) => ContributionModel.fromJson(contrib as Map<String, dynamic>)).toList();
  }
  
  // Calculate contribution deficit for a user
  Future<double> calculateUserDeficit({
    required String groupId,
    required String userId,
  }) async {
    try {
      // Get the group
      final groupResponse = await supabase
          .from('groups')
          .select('savings_goal, created_at')
          .eq('id', groupId)
          .single();
      
      final savingsGoal = (groupResponse as Map<String, dynamic>)['savings_goal'] as double;
      final createdAt = DateTime.parse((groupResponse as Map<String, dynamic>)['created_at'] as String);
      
      // Get all user contributions
      final contributions = await getUserContributions(groupId: groupId, userId: userId);
      
      // Calculate total contributed
      final totalContributed = contributions.fold<double>(0, (sum, contrib) => sum + contrib.amount);
      
      // Calculate how many months have passed since group creation
      final now = DateTime.now();
      final monthsElapsed = (now.year - createdAt.year) * 12 + now.month - createdAt.month;
      
      // Calculate expected contribution
      final expectedContribution = savingsGoal * monthsElapsed;
      
      // Calculate deficit
      final deficit = expectedContribution - totalContributed;
      
      return deficit > 0 ? deficit : 0;
    } catch (e) {
      return 0;
    }
  }
  
  // Get all contributions for a group in a specific month
  Future<List<ContributionModel>> getGroupContributionsForMonth({
    required String groupId,
    required String month,
  }) async {
    final response = await supabase
        .from('contributions')
        .select()
        .eq('group_id', groupId)
        .eq('month', month);
    
    return (response as List).map((contrib) => ContributionModel.fromJson(contrib as Map<String, dynamic>)).toList();
  }
} 