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
      print('Attempting login for: $email');
      
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) {
        print('Auth failed - user is null');
        return null;
      }
      
      print('Auth successful for user: ${user.id}');
      
      // For admin users, create a direct model
      if (isAdmin(email)) {
        print('Admin user detected, creating admin model');
        final now = DateTime.now().toIso8601String();
        try {
          // Try to insert admin if it doesn't exist (will fail silently if exists)
          await _client.from('users').upsert({
            'id': user.id,
            'email': email,
            'role': 'admin',
            'created_at': now,
            'updated_at': now,
            'requested_holder': false,
            'requested_join_group': false,
          }, onConflict: 'id');
        } catch (e) {
          print('Admin upsert error (non-critical): $e');
        }
        
        // Return admin model regardless of DB success
        return UserModel.fromJson({
          'id': user.id,
          'email': email,
          'role': 'admin',
          'created_at': now,
          'updated_at': now,
          'requested_holder': false,
          'requested_join_group': false,
        });
      }
      
      // For non-admins, try to get from database
      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        print('Found user in database: ${userData['email']}');
        return UserModel.fromJson(userData as Map<String, dynamic>);
      } catch (e) {
        print('User not found in database: $e');
        throw 'User account not found in the system. Please sign up first.';
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Register new user
  Future<UserModel?> signup(String email, String password) async {
    try {
      print('Attempting signup for: $email');
      
      // First, create the auth user
      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );
      
      final user = response.user;
      if (user == null) {
        print('Auth signup failed - user is null');
        return null;
      }
      
      print('Auth signup successful for user: ${user.id}');
      
      // Determine the role
      final role = isAdmin(email) ? 'admin' : 'normal';
      print('Assigned role: $role');
      
      // Create user data
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
      
      // Try to insert the user into the database
      try {
        print('Inserting user into database');
        await _client.from('users').insert(userData);
        print('User successfully inserted into database');
      } catch (insertError) {
        print('Error inserting user into database: $insertError');
        // If we failed to insert but the user is an admin, we can still return a model
        if (!isAdmin(email)) {
          throw 'Failed to create user profile in database';
        }
      }
      
      // Return the user model
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Signup error: $e');
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
    if (user == null) {
      print('No current auth user');
      return null;
    }
    
    print('Current auth user found: ${user.id}');
    final email = user.email;
    
    // Special handling for admin users
    if (email != null && isAdmin(email)) {
      print('Admin user detected by email domain');
      
      // Check if admin exists in DB first
      try {
        final userData = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        print('Admin found in database');
        return UserModel.fromJson(userData as Map<String, dynamic>);
      } catch (e) {
        // Admin not in DB, create model without DB dependency
        print('Admin not in database, creating model');
        final now = DateTime.now().toIso8601String();
        return UserModel.fromJson({
          'id': user.id,
          'email': email,
          'role': 'admin',
          'created_at': now,
          'updated_at': now,
          'requested_holder': false,
          'requested_join_group': false,
        });
      }
    }
    
    // Regular user - must exist in database
    try {
      final userData = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      print('Regular user found in database');
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      print('Error getting user from database: $e');
      return null;
    }
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
      print('Fetching holder requests using RPC function...');
      
      final client = Supabase.instance.client;
      
      // Use the security_definer function to bypass RLS
      final response = await client.rpc('get_holder_requests');
      
      print('Holder requests response: $response');
      
      if (response == null) {
        return [];
      }
      
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
      print('Fetching all users using RPC function...');
      
      final client = Supabase.instance.client;
      
      // Use the security_definer function to bypass RLS
      final response = await client.rpc('get_all_users');
      
      print('All users response: $response');
      
      if (response == null) {
        return [];
      }
      
      return (response as List).map((user) => UserModel.fromJson(user as Map<String, dynamic>)).toList();
    } catch (e) {
      print('Error loading users: $e');
      throw e;
    }
  }
} 