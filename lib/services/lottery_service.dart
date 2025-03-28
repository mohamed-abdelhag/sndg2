import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/lottery_winner_model.dart';
import '../models/group_metadata_model.dart';
import 'dart:math';

class LotteryService {
  final supabase = Supabase.instance.client;
  final uuid = Uuid();
  
  // Draw a lottery winner
  Future<LotteryWinnerModel> drawLotteryWinner(String groupId) async {
    try {
      // Verify this is a lottery group
      final groupResponse = await supabase
          .from('groups')
          .select('type')
          .eq('id', groupId)
          .single();
          
      final groupType = (groupResponse as Map<String, dynamic>)['type'] as String;
      
      if (groupType != 'lottery') {
        throw Exception('Lottery draw is only available for lottery groups');
      }
      
      // Get metadata to check if there's a pool to distribute
      final metadataResponse = await supabase
          .from('lottery_group_metadata')
          .select()
          .eq('group_id', groupId)
          .single();
          
      final metadata = LotteryGroupMetadata.fromJson(metadataResponse as Map<String, dynamic>);
      
      if (metadata.currentPoolAmount <= 0) {
        throw Exception('No funds available in the pool for lottery draw');
      }
      
      // Get list of group members who haven't won yet
      final membersResponse = await supabase
          .from('users')
          .select('id')
          .eq('group_id', groupId);
          
      final allMembers = (membersResponse as List).map((m) => (m as Map<String, dynamic>)['id'] as String).toList();
      
      // Get previous winners
      final winnersResponse = await supabase
          .from('lottery_winners')
          .select('user_id')
          .eq('group_id', groupId);
          
      final previousWinners = (winnersResponse as List).map((w) => (w as Map<String, dynamic>)['user_id'] as String).toList();
      
      // Filter out previous winners
      final eligibleMembers = allMembers.where((m) => !previousWinners.contains(m)).toList();
      
      if (eligibleMembers.isEmpty) {
        // If all members have won, reset and start over
        final random = Random();
        final randomIndex = random.nextInt(allMembers.length);
        final winnerUserId = allMembers[randomIndex];
        
        // Record the winner
        final now = DateTime.now();
        final month = '${now.month}-${now.year}';
        
        final winnerId = uuid.v4();
        final winnerData = {
          'id': winnerId,
          'group_id': groupId,
          'user_id': winnerUserId,
          'month': month,
          'amount': metadata.currentPoolAmount,
          'draw_date': now.toIso8601String(),
          'collected': false,
          'collection_date': null,
        };
        
        await supabase.from('lottery_winners').insert(winnerData);
        
        // Update metadata
        await supabase
            .from('lottery_group_metadata')
            .update({
              'current_pool_amount': 0,
              'updated_at': now.toIso8601String(),
              'next_draw_date': _calculateNextDrawDate(now).toIso8601String(),
            })
            .eq('group_id', groupId);
        
        return LotteryWinnerModel.fromJson(winnerData);
      } else {
        // Select a random eligible member
        final random = Random();
        final randomIndex = random.nextInt(eligibleMembers.length);
        final winnerUserId = eligibleMembers[randomIndex];
        
        // Record the winner
        final now = DateTime.now();
        final month = '${now.month}-${now.year}';
        
        final winnerId = uuid.v4();
        final winnerData = {
          'id': winnerId,
          'group_id': groupId,
          'user_id': winnerUserId,
          'month': month,
          'amount': metadata.currentPoolAmount,
          'draw_date': now.toIso8601String(),
          'collected': false,
          'collection_date': null,
        };
        
        await supabase.from('lottery_winners').insert(winnerData);
        
        // Update metadata
        await supabase
            .from('lottery_group_metadata')
            .update({
              'current_pool_amount': 0,
              'updated_at': now.toIso8601String(),
              'next_draw_date': _calculateNextDrawDate(now).toIso8601String(),
            })
            .eq('group_id', groupId);
        
        return LotteryWinnerModel.fromJson(winnerData);
      }
    } catch (e) {
      rethrow;
    }
  }
  
  // Mark lottery winnings as collected
  Future<void> markWinningsCollected(String winnerId) async {
    try {
      final now = DateTime.now();
      
      await supabase
          .from('lottery_winners')
          .update({
            'collected': true,
            'collection_date': now.toIso8601String(),
          })
          .eq('id', winnerId);
    } catch (e) {
      rethrow;
    }
  }
  
  // Get lottery winners for a group
  Future<List<LotteryWinnerModel>> getGroupWinners(String groupId) async {
    final response = await supabase
        .from('lottery_winners')
        .select()
        .eq('group_id', groupId)
        .order('draw_date', ascending: false);
    
    return (response as List).map((w) => LotteryWinnerModel.fromJson(w as Map<String, dynamic>)).toList();
  }
  
  // Check if user has won in current cycle
  Future<bool> hasUserWon(String groupId, String userId) async {
    final response = await supabase
        .from('lottery_winners')
        .select('id')
        .eq('group_id', groupId)
        .eq('user_id', userId);
    
    return (response as List).isNotEmpty;
  }
  
  // Get user's winnings
  Future<List<LotteryWinnerModel>> getUserWinnings(String userId) async {
    final response = await supabase
        .from('lottery_winners')
        .select()
        .eq('user_id', userId)
        .order('draw_date', ascending: false);
    
    return (response as List).map((w) => LotteryWinnerModel.fromJson(w as Map<String, dynamic>)).toList();
  }
  
  // Check if it's time for a draw
  Future<bool> isTimeForDraw(String groupId) async {
    try {
      final metadataResponse = await supabase
          .from('lottery_group_metadata')
          .select('next_draw_date')
          .eq('group_id', groupId)
          .single();
          
      final nextDrawDate = DateTime.parse((metadataResponse as Map<String, dynamic>)['next_draw_date'] as String);
      final now = DateTime.now();
      
      return now.isAfter(nextDrawDate);
    } catch (e) {
      return false;
    }
  }
  
  // Calculate next draw date (last day of next month)
  DateTime _calculateNextDrawDate(DateTime from) {
    final nextMonth = from.month == 12 
        ? DateTime(from.year + 1, 1, 1) 
        : DateTime(from.year, from.month + 1, 1);
    return DateTime(nextMonth.year, nextMonth.month + 1, 0);
  }
} 