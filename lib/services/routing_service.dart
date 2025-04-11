import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'auth_service_v2.dart';

class RoutingService {
  final AuthServiceV2 _authService = AuthServiceV2();

  // Get the initial route based on current authentication state
  Future<String> getInitialRoute() async {
    try {
      final currentUser = await _authService.getCurrentUser();
      
      // If no authenticated user, go to login
      if (currentUser == null) {
        return '/login';
      }
      
      // Route based on user role
      return _getRouteForUser(currentUser);
    } catch (e) {
      print('Error determining initial route: $e');
      return '/login';
    }
  }
  
  // Handle login routing - where to go after successful login
  String getRouteAfterLogin(UserModel user) {
    return _getRouteForUser(user);
  }
  
  // Get appropriate route based on user model
  String _getRouteForUser(UserModel user) {
    // Admin goes to admin dashboard
    if (user.role == 'admin') {
      return '/admin_dashboard';
    }
    
    // Holder goes to holder dashboard 
    if (user.role == 'holder') {
      return '/holder_dashboard';
    }
    
    // User in a group goes to group dashboard
    if (user.groupId != null) {
      return '/user_normal_group_dashboard';
    }
    
    // Default - normal user with no group goes to landing
    return '/landing';
  }
} 