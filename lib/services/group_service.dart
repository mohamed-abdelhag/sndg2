import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/group_model.dart';
import '../models/group_metadata_model.dart';

class GroupService {
  final supabase = Supabase.instance.client;
  final uuid = Uuid();
  
  // Create a new group
  Future<GroupModel> createGroup({
    required String name,
    required String type,
    required double savingsGoal,
    required String holderId,
  }) async {
    try {
      // Generate a unique group ID
      final groupId = uuid.v4();
      
      // Generate a 6-character group code
      final groupCode = uuid.v4().substring(0, 6).toUpperCase();
      
      final now = DateTime.now().toIso8601String();
      
      // Create group in database
      final groupData = {
        'id': groupId,
        'name': name,
        'type': type,
        'savings_goal': savingsGoal,
        'holder_id': holderId,
        'created_at': now,
        'updated_at': now,
        'group_code': groupCode,
      };
      
      await supabase.from('groups').insert(groupData);
      
      // Create the metadata table based on group type
      if (type == 'standard') {
        await supabase.from('standard_group_metadata').insert({
          'group_id': groupId,
          'total_savings_goal': savingsGoal,
          'actual_pool_amount': 0,
          'holder_id': holderId,
          'current_withdrawals': 0,
          'created_at': now,
          'updated_at': now,
        });
      } else if (type == 'lottery') {
        // Set next draw date to the last day of next month
        final nextMonth = DateTime.now().month == 12 
            ? DateTime(DateTime.now().year + 1, 1, 1) 
            : DateTime(DateTime.now().year, DateTime.now().month + 1, 1);
        final lastDayOfNextMonth = DateTime(nextMonth.year, nextMonth.month + 1, 0);
        
        await supabase.from('lottery_group_metadata').insert({
          'group_id': groupId,
          'total_savings_goal': savingsGoal,
          'actual_pool_amount': 0,
          'holder_id': holderId,
          'next_draw_date': lastDayOfNextMonth.toIso8601String(),
          'current_pool_amount': 0,
          'created_at': now,
          'updated_at': now,
        });
      }
      
      // Execute SQL to create a dynamic table for group contributions
      final tableName = 'contributions_${groupId}';
      
      // We'll use RPC (Remote Procedure Call) to execute the SQL
      // The create_group_table function must be defined in Supabase
      await supabase.rpc('create_group_table', params: {
        'table_name': tableName,
        'group_id': groupId,
      });
      
      // Update the user to assign them to the group
      await supabase
          .from('users')
          .update({
            'group_id': groupId,
            'updated_at': now,
          })
          .eq('id', holderId);
      
      return GroupModel.fromJson(groupData);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get group by ID
  Future<GroupModel?> getGroupById(String groupId) async {
    try {
      final response = await supabase
          .from('groups')
          .select()
          .eq('id', groupId)
          .single();
      
      return GroupModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  // Get group by code
  Future<GroupModel?> getGroupByCode(String groupCode) async {
    try {
      final response = await supabase
          .from('groups')
          .select()
          .eq('group_code', groupCode)
          .single();
      
      return GroupModel.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  // Get group metadata (standard)
  Future<StandardGroupMetadata?> getStandardGroupMetadata(String groupId) async {
    try {
      final response = await supabase
          .from('standard_group_metadata')
          .select()
          .eq('group_id', groupId)
          .single();
      
      return StandardGroupMetadata.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  // Get group metadata (lottery)
  Future<LotteryGroupMetadata?> getLotteryGroupMetadata(String groupId) async {
    try {
      final response = await supabase
          .from('lottery_group_metadata')
          .select()
          .eq('group_id', groupId)
          .single();
      
      return LotteryGroupMetadata.fromJson(response as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }
  
  // Update group
  Future<void> updateGroup(GroupModel group) async {
    await supabase
        .from('groups')
        .update({
          'name': group.name,
          'savings_goal': group.savingsGoal,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', group.id);
  }
  
  // Update standard group metadata
  Future<void> updateStandardGroupMetadata(StandardGroupMetadata metadata) async {
    await supabase
        .from('standard_group_metadata')
        .update({
          'total_savings_goal': metadata.totalSavingsGoal,
          'actual_pool_amount': metadata.actualPoolAmount,
          'current_withdrawals': metadata.currentWithdrawals,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('group_id', metadata.groupId);
  }
  
  // Update lottery group metadata
  Future<void> updateLotteryGroupMetadata(LotteryGroupMetadata metadata) async {
    await supabase
        .from('lottery_group_metadata')
        .update({
          'total_savings_goal': metadata.totalSavingsGoal,
          'actual_pool_amount': metadata.actualPoolAmount,
          'next_draw_date': metadata.nextDrawDate.toIso8601String(),
          'current_pool_amount': metadata.currentPoolAmount,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('group_id', metadata.groupId);
  }
  
  // Get groups by holder
  Future<List<GroupModel>> getGroupsByHolder(String holderId) async {
    final response = await supabase
        .from('groups')
        .select()
        .eq('holder_id', holderId);
    
    return (response as List).map((group) => GroupModel.fromJson(group as Map<String, dynamic>)).toList();
  }
  
  // Get group ID by code
  Future<String?> getGroupIdByCode(String groupCode) async {
    try {
      final response = await supabase
          .from('groups')
          .select('id')
          .eq('group_code', groupCode)
          .single();
      
      return (response as Map<String, dynamic>)['id'] as String;
    } catch (e) {
      return null;
    }
  }
} 