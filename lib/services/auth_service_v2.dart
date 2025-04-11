import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class AuthServiceV2 {
  final SupabaseClient _client;
  
  AuthServiceV2([SupabaseClient? client]) : _client = client ?? Supabase.instance.client;

  // Check if user is admin based on email
  bool isAdmin(String email) {
    return email.endsWith('@sandoog') || email.contains('@sandoog.');
  }

  // Login user
  Future<UserModel?> login(String email, String password) async {
    try {
      print('Attempting login for: $email');
      
      // Login with Supabase Auth
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
      
      // Admin users get special handling to ensure they always work
      final isAdminUser = isAdmin(email);
      
      // Get the user profile from database using RPC to avoid RLS issues
      try {
        final userData = await _client.rpc('get_user_profile', params: {
          'user_id': user.id,
        });
        
        if (userData == null) {
          print('User profile not found for ID: ${user.id}');
          
          // For admin users, create the profile if it doesn't exist
          if (isAdminUser) {
            print('Creating admin user profile');
            await _client.rpc('create_user_profile', params: {
              'user_id': user.id,
              'user_email': email,
              'user_role': 'admin',
            });
            
            final now = DateTime.now();
            return UserModel(
              id: user.id,
              email: email,
              role: 'admin',
              createdAt: now,
              updatedAt: now,
              requestedHolder: false,
              requestedJoinGroup: false,
            );
          }
          
          // For regular users, create a basic profile
          print('Creating user profile for regular user');
          await _client.rpc('create_user_profile', params: {
            'user_id': user.id,
            'user_email': email,
            'user_role': 'normal',
          });
          
          final now = DateTime.now();
          return UserModel(
            id: user.id,
            email: email,
            role: 'normal',
            createdAt: now,
            updatedAt: now,
            requestedHolder: false,
            requestedJoinGroup: false,
          );
        }
        
        print('Found user profile: ${userData['email']}');
        return UserModel.fromJson(userData);
      } catch (e) {
        print('Error getting user profile: $e');
        
        // Attempt fallback by creating a basic user model
        final now = DateTime.now();
        return UserModel(
          id: user.id,
          email: email,
          role: isAdminUser ? 'admin' : 'normal',
          createdAt: now,
          updatedAt: now,
          requestedHolder: false,
          requestedJoinGroup: false,
        );
      }
    } catch (e) {
      print('Login error: $e');
      throw 'Login failed. Please check your email and password.';
    }
  }

  // Register new user
  Future<UserModel?> signup(String email, String password) async {
    try {
      print('Attempting signup for: $email');
      
      // Create auth user with email confirmation
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: null, // Use default redirect URL
      );
      
      final user = response.user;
      if (user == null) {
        print('Auth signup failed - user is null');
        return null;
      }
      
      print('Auth signup successful for user: ${user.id}');
      
      // Create user profile using RPC to avoid permissions issues
      try {
        await _client.rpc('create_user_profile', params: {
          'user_id': user.id,
          'user_email': email,
          'user_role': isAdmin(email) ? 'admin' : 'normal',
        });
        
        final now = DateTime.now();
        return UserModel(
          id: user.id,
          email: email,
          role: isAdmin(email) ? 'admin' : 'normal',
          createdAt: now,
          updatedAt: now,
          requestedHolder: false,
          requestedJoinGroup: false,
        );
      } catch (e) {
        print('Error creating user profile: $e');
        
        // Special case for admin users - continue anyway
        if (isAdmin(email)) {
          final now = DateTime.now();
          return UserModel(
            id: user.id,
            email: email,
            role: 'admin',
            createdAt: now,
            updatedAt: now,
            requestedHolder: false,
            requestedJoinGroup: false,
          );
        }
        
        throw 'Failed to create user account. Please try again.';
      }
    } catch (e) {
      print('Signup error: $e');
      throw e.toString();
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
    
    // Admin gets special handling
    final isAdminUser = isAdmin(email);
    
    try {
      // Get user profile via RPC to avoid permission issues
      final userData = await _client.rpc('get_user_profile', params: {
        'user_id': user.id,
      });
      
      if (userData == null) {
        print('User profile not found');
        
        // Create profile if it doesn't exist
        print('Creating user profile for ${isAdminUser ? "admin" : "regular"} user');
        await _client.rpc('create_user_profile', params: {
          'user_id': user.id,
          'user_email': email,
          'user_role': isAdminUser ? 'admin' : 'normal',
        });
        
        final now = DateTime.now();
        return UserModel(
          id: user.id,
          email: email,
          role: isAdminUser ? 'admin' : 'normal',
          createdAt: now,
          updatedAt: now,
          requestedHolder: false,
          requestedJoinGroup: false,
        );
      }
      
      print('Found user profile: ${userData['email']}');
      return UserModel.fromJson(userData);
    } catch (e) {
      print('Error getting user profile: $e');
      
      // Fallback to basic user model
      print('Fallback: returning basic user model');
      final now = DateTime.now();
      return UserModel(
        id: user.id,
        email: email,
        role: isAdminUser ? 'admin' : 'normal',
        createdAt: now,
        updatedAt: now,
        requestedHolder: false,
        requestedJoinGroup: false,
      );
    }
  }
  
  // Request to become a holder
  Future<void> requestHolder(String userId) async {
    await _client.rpc('request_holder_status', params: {
      'user_id': userId,
    });
  }
  
  // Approve holder request (admin only)
  Future<void> approveHolderRequest(String userId) async {
    await _client.rpc('approve_holder_request', params: {
      'target_user_id': userId,
    });
  }
  
  // Reject holder request (admin only)
  Future<void> rejectHolderRequest(String userId) async {
    await _client.rpc('reject_holder_request', params: {
      'target_user_id': userId,
    });
  }
  
  // Get all users with holder requests (admin only)
  Future<List<UserModel>> getHolderRequests() async {
    try {
      print('Fetching holder requests...');
      
      final response = await _client.rpc('get_holder_requests');
      
      print('Holder requests response: $response');
      
      if (response == null) {
        return [];
      }
      
      return (response as List).map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      print('Error loading holder requests: $e');
      throw e;
    }
  }
  
  // Get all users (admin only)
  Future<List<UserModel>> getAllUsers() async {
    try {
      print('Fetching all users...');
      
      final response = await _client.rpc('get_all_users');
      
      print('All users response: $response');
      
      if (response == null) {
        return [];
      }
      
      return (response as List).map((user) => UserModel.fromJson(user)).toList();
    } catch (e) {
      print('Error loading users: $e');
      throw e;
    }
  }

  // Resend confirmation email
  Future<void> resendConfirmationEmail(String email) async {
    try {
      await _client.auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      print('Error resending confirmation email: $e');
      throw 'Failed to resend confirmation email. Please try again.';
    }
  }
  
  // Check if email is confirmed 
  Future<bool> isEmailConfirmed() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return false;
      }
      
      // Refresh session to get latest metadata
      await _client.auth.refreshSession();
      
      // Check if user's metadata includes email_confirmed_at
      final updatedUser = _client.auth.currentUser;
      return updatedUser?.userMetadata?['email_confirmed_at'] != null;
    } catch (e) {
      print('Error checking email confirmation: $e');
      return false;
    }
  }
}
