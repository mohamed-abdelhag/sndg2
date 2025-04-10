import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';

class AuthService {
  final SupabaseClient _client;
  
  AuthService([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  // Check if user is admin based on email
  bool isAdmin(String email) {
    return email.endsWith('@sandoog');
  }

  // Helper method to ensure a user exists in the database
  Future<UserModel> _ensureUserInDatabase(User authUser, String email) async {
    try {
      // Try to get the user from the database
      final userData = await _client
          .from('users')
          .select()
          .eq('id', authUser.id)
          .single();
      
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      // If the user doesn't exist in the database, create them
      final role = isAdmin(email) ? 'admin' : 'normal';
      
      // Create user in database
      final now = DateTime.now().toIso8601String();
      final newUserData = {
        'id': authUser.id,
        'email': email,
        'role': role,
        'created_at': now,
        'updated_at': now,
        'requested_holder': false,
        'requested_join_group': false,
      };
      
      try {
        // Try to insert directly
        await _client.from('users').insert(newUserData);
      } catch (insertError) {
        print('Failed to insert user via client: $insertError');
        
        // If that fails, try using RPC
        try {
          await _client.rpc('create_user_record', params: {
            'user_id': authUser.id,
            'user_email': email,
            'user_role': role
          });
        } catch (rpcError) {
          print('Failed to create user via RPC: $rpcError');
          // Last resort - continue anyway and return a UserModel
        }
      }
      
      return UserModel.fromJson(newUserData);
    }
  }

  // Login user
  Future<UserModel?> login(String email, String password) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        // Use our helper method to ensure the user exists in the database
        try {
          return await _ensureUserInDatabase(user, email);
        } catch (e) {
          print('Error ensuring user exists: $e');
          throw 'Login failed: Unable to retrieve or create user profile.';
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Register new user
  Future<UserModel?> signup(String email, String password) async {
    try {
      // First, create the auth user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user != null) {
        try {
          // Try to ensure the user exists in the database
          return await _ensureUserInDatabase(user, email);
        } catch (e) {
          print('Warning: User created in auth but failed to create in database: $e');
          // Return a temporary UserModel anyway - the user will be created when they login
          final role = isAdmin(email) ? 'admin' : 'normal';
          final now = DateTime.now().toIso8601String();
          final userData = {
            'id': user.id,
            'email': email,
            'role': role,
            'created_at': now,
            'updated_at': now,
            'requested_holder': false,
            'requested_join_group': false,
          };
          
          return UserModel.fromJson(userData);
        }
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  // Log out
  Future<void> logout() async {
    await _client.auth.signOut();
  }
  
  // Get current user
  Future<UserModel?> getCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        return UserModel.fromJson(userData as Map<String, dynamic>);
      } catch (e) {
        // User might be authenticated but not in the users table (edge case)
        return null;
      }
    }
    return null;
  }
  
  // Request to become a holder
  Future<void> requestHolder(String userId) async {
    await _client
        .from('users')
        .update({'requested_holder': true, 'updated_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  }
  
  // Approve holder request
  Future<void> approveHolderRequest(String userId) async {
    await _client
        .from('users')
        .update({
          'role': 'holder',
          'requested_holder': false,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }
  
  // Reject holder request
  Future<void> rejectHolderRequest(String userId) async {
    await _client
        .from('users')
        .update({
          'requested_holder': false,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }
  
  // Request to join a group
  Future<void> requestJoinGroup(String userId, String groupId) async {
    await _client
        .from('users')
        .update({
          'requested_join_group': true,
          'requested_group_id': groupId,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }
  
  // Approve join group request
  Future<void> approveJoinGroupRequest(String userId, String groupId) async {
    await _client
        .from('users')
        .update({
          'group_id': groupId,
          'requested_join_group': false,
          'requested_group_id': null,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }
  
  // Reject join group request
  Future<void> rejectJoinGroupRequest(String userId) async {
    await _client
        .from('users')
        .update({
          'requested_join_group': false,
          'requested_group_id': null,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }
  
  // Get all users with holder requests
  Future<List<UserModel>> getHolderRequests() async {
    try {
      print('Fetching holder requests from Supabase...');
      // Use service role for admin operations to bypass RLS
      final response = await _client
          .from('users')
          .select()
          .eq('requested_holder', true);
          
      return (response as List).map((user) => UserModel.fromJson(user as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading holder requests: $e');
      throw e;
    }
  }
  
  // Get all users with join group requests for a specific group
  Future<List<UserModel>> getJoinGroupRequests(String groupId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('requested_join_group', true)
        .eq('requested_group_id', groupId);
        
    return (response as List).map((user) => UserModel.fromJson(user as Map<String, dynamic>)).toList();
  }
  
  // Get all users in a group
  Future<List<UserModel>> getGroupMembers(String groupId) async {
    final response = await _client
        .from('users')
        .select()
        .eq('group_id', groupId);
        
    return (response as List).map((user) => UserModel.fromJson(user as Map<String, dynamic>)).toList();
  }
  
  // Remove user from group
  Future<void> removeUserFromGroup(String userId) async {
    await _client
        .from('users')
        .update({
          'group_id': null,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', userId);
  }

  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      print('Fetching users from Supabase...');
      // Use service role for admin operations to bypass RLS
      final response = await _client
          .from('users')
          .select();
          
      return (response as List).map((user) => UserModel.fromJson(user as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading users: $e');
      throw e;
    }
  }
} 