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
      
      // We'll keep it simple - try to get the user from the database first
      try {
        print('Trying to get user profile from database');
        final userData = await _client
            .from('users')
            .select()
            .eq('id', user.id)
            .single();
        
        print('Found user in database: ${userData['email']}');
        return UserModel.fromJson(userData as Map<String, dynamic>);
      } catch (e) {
        print('User lookup failed, trying to create: $e');
        
        // If not found, create the user record
        final role = isAdmin(email) ? 'admin' : 'normal';
        final now = DateTime.now().toIso8601String();
        final newUserData = {
          'id': user.id,
          'email': email,
          'role': role,
          'created_at': now,
          'updated_at': now,
          'requested_holder': false,
          'requested_join_group': false,
        };
        
        try {
          await _client.from('users').insert(newUserData);
          print('Created new user in database');
          return UserModel.fromJson(newUserData);
        } catch (insertError) {
          print('Failed to insert user: $insertError');
          
          // For admin users, we can create a temporary model
          if (isAdmin(email)) {
            print('Creating admin model for non-DB user');
            return UserModel.fromJson(newUserData);
          }
          
          // For regular users, must exist in DB
          throw 'User account could not be created. Please contact support.';
        }
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
      
      // Determine the role based on email domain
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
      
      // Insert user with retries
      for (int i = 0; i < 3; i++) {
        try {
          print('Attempt ${i+1} to insert user into database');
          await _client.from('users').insert(userData);
          print('User successfully inserted into database');
          return UserModel.fromJson(userData);
        } catch (insertError) {
          print('Insert error on attempt ${i+1}: $insertError');
          
          // If last attempt, or admin
          if (i == 2 || isAdmin(email)) {
            if (isAdmin(email)) {
              print('Admin user, returning model without DB insertion');
              return UserModel.fromJson(userData);
            } else {
              print('All insert attempts failed for regular user');
              throw 'Failed to create user after multiple attempts';
            }
          }
          
          // Wait before retrying
          await Future.delayed(Duration(milliseconds: 500));
        }
      }
      
      // Should never reach here, but return null just in case
      return null;
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
    if (email == null) {
      print('Auth user has no email');
      return null;
    }
    
    try {
      // Try to get from database first
      print('Trying to get user from database');
      final userData = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .single();
      
      print('Found user in database: ${userData['email']}');
      return UserModel.fromJson(userData as Map<String, dynamic>);
    } catch (e) {
      print('Could not find user in database: $e');
      
      // Create the user if not found
      if (isAdmin(email)) {
        print('Creating admin user model');
        final now = DateTime.now().toIso8601String();
        final adminData = {
          'id': user.id,
          'email': email,
          'role': 'admin',
          'created_at': now,
          'updated_at': now,
          'requested_holder': false,
          'requested_join_group': false,
        };
        
        try {
          // Try to create the user
          await _client.from('users').insert(adminData);
          print('Admin user created in database');
        } catch (insertError) {
          print('Failed to create admin user: $insertError');
          // Continue anyway for admin
        }
        
        return UserModel.fromJson(adminData);
      }
      
      // If we get here, a non-admin user was not found
      print('Regular user not found, cannot create model');
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
      print('Fetching holder requests via admin function...');
      
      // Use the more reliable admin function
      final response = await _client.rpc('admin_get_holder_requests');
      
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
      print('Fetching all users via admin function...');
      
      // Use the more reliable admin function
      final response = await _client.rpc('admin_get_all_users');
      
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