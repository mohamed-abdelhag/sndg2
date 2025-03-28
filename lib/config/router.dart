import 'package:flutter/material.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/signup_screen.dart';
import '../screens/landing_screen.dart';
import '../screens/admin/admin_dashboard_screen.dart';
import '../screens/admin/admin_approve_holder_screen.dart';
import '../screens/admin/admin_see_users_screen.dart';
import '../screens/holder/holder_dashboard_screen.dart';
import '../screens/holder/holder_create_screen.dart';
// These screens will be created:
import '../screens/holder/holder_manage_group_screen.dart';
import '../screens/holder/holder_see_request_screen.dart';
import '../screens/holder/holder_manage_members_screen.dart';
import '../screens/holder/holder_group_details_screen.dart';
import '../screens/holder/holder_lottery_winner_selection_screen.dart';
import '../screens/holder/holder_manage_withdrawal_screen.dart';
import '../screens/standard/user_normal_group_dashboard_screen.dart';
import '../screens/standard/user_group_overview_tracking_screen.dart';
import '../screens/standard/user_withdrawal_request_screen.dart';
import '../screens/lottery/user_lottery_group_dashboard_screen.dart';
import '../screens/lottery/user_lottery_group_overview_tracking_screen.dart';
import '../screens/lottery/user_lottery_winner_group_screen.dart';

class AppRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => LoginScreen());
      case '/signup':
        return MaterialPageRoute(builder: (_) => SignupScreen());
      case '/landing':
        return MaterialPageRoute(builder: (_) => LandingScreen());
        
      // Admin Routes
      case '/admin_dashboard':
        return MaterialPageRoute(builder: (_) => AdminDashboardScreen());
      case '/admin_approve_holder':
        return MaterialPageRoute(builder: (_) => AdminApproveHolderScreen());
      case '/admin_see_users':
        return MaterialPageRoute(builder: (_) => AdminSeeUsersScreen());
        
      // Holder Routes
      case '/holder_dashboard':
        return MaterialPageRoute(builder: (_) => HolderDashboardScreen());
      case '/holder_create':
        return MaterialPageRoute(builder: (_) => HolderCreateScreen());
      
      // Routes for screens that will be implemented 
      case '/holder_manage_group':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderManageGroupScreen(groupId: args));
        }
        return _errorRoute();
      case '/holder_see_request':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderSeeRequestScreen(groupId: args));
        }
        return _errorRoute();
      case '/holder_manage_members':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderManageMembersScreen(groupId: args));
        }
        return _errorRoute();
      case '/holder_group_details':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderGroupDetailsScreen(groupId: args));
        }
        return _errorRoute();
      case '/holder_lottery_winner_selection':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderLotteryWinnerSelectionScreen(groupId: args));
        }
        return _errorRoute();
      case '/holder_manage_withdrawal':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => HolderManageWithdrawalScreen(groupId: args));
        }
        return _errorRoute();
        
      // Standard Group User Routes
      case '/user_normal_group_dashboard':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => UserNormalGroupDashboardScreen(groupId: args));
        }
        return _errorRoute();
      case '/user_group_overview_tracking':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => UserGroupOverviewTrackingScreen(groupId: args));
        }
        return _errorRoute();
      case '/user_withdrawal_request':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => UserWithdrawalRequestScreen(groupId: args));
        }
        return _errorRoute();
        
      // Lottery Group User Routes
      case '/user_lottery_group_dashboard':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => UserLotteryGroupDashboardScreen(groupId: args));
        }
        return _errorRoute();
      case '/user_lottery_group_overview_tracking':
        if (args is String) {
          return MaterialPageRoute(builder: (_) => UserLotteryGroupOverviewTrackingScreen(groupId: args));
        }
        return _errorRoute();
      case '/user_lottery_winner_group':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => UserLotteryWinnerGroupScreen(
              groupId: args['groupId']!,
              winnerId: args['winnerId']!,
            ),
          );
        }
        return _errorRoute();
        
      default:
        return _errorRoute();
    }
  }
  
  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found'),
        ),
      );
    });
  }
} 