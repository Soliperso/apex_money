/// Centralized route constants for consistent navigation throughout the app
class Routes {
  // Private constructor to prevent instantiation
  Routes._();

  // Authentication routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String profile = '/profile';

  // Main app routes
  static const String dashboard = '/dashboard';
  static const String transactions = '/transactions';
  static const String createTransaction = '/create-transaction';
  static const String goals = '/goals';
  static const String createGoal = '/create-goal';
  // GROUPS FUNCTIONALITY COMMENTED OUT
  // static const String groups = '/groups';
  static const String aiInsights = '/ai-insights';
  static const String notifications = '/notifications';

  // GROUPS SUB-ROUTES COMMENTED OUT
  // static String groupDetail(String groupId) => '/groups/$groupId';
  // static String createBill(String groupId) => '/groups/$groupId/create-bill';
  // static String groupBills(String groupId) => '/groups/$groupId/bills';
  // static String billDetail(String groupId, String billId) => '/groups/$groupId/bills/$billId';
  // static String groupActivity(String groupId) => '/groups/$groupId/activity';

  /// Validates if a route exists in the app router
  static bool isValidRoute(String route) {
    const validRoutes = [
      splash,
      onboarding,
      login,
      register,
      forgotPassword,
      profile,
      dashboard,
      transactions,
      createTransaction,
      goals,
      createGoal,
      // groups, // COMMENTED OUT
      aiInsights,
      notifications,
    ];

    // Check direct routes
    if (validRoutes.contains(route)) return true;

    // GROUPS ROUTE VALIDATION COMMENTED OUT
    // if (route.startsWith('/groups/')) {
    //   final segments = route.split('/');
    //   if (segments.length == 3) return true; // /groups/{groupId}
    //   if (segments.length == 4 && segments[3] == 'create-bill') return true;
    //   if (segments.length == 4 && segments[3] == 'bills') return true;
    //   if (segments.length == 4 && segments[3] == 'activity') return true;
    //   if (segments.length == 5 && segments[3] == 'bills') return true; // /groups/{groupId}/bills/{billId}
    // }

    return false;
  }

  /// Gets a user-friendly label for a route
  static String getRouteLabel(String route) {
    switch (route) {
      case dashboard:
        return 'Dashboard';
      case transactions:
        return 'Transactions';
      case createTransaction:
        return 'Add Transaction';
      case goals:
        return 'Goals';
      case createGoal:
        return 'Create Goal';
      // case groups: // COMMENTED OUT
      //   return 'Groups';
      case aiInsights:
        return 'AI Insights';
      case notifications:
        return 'Notifications';
      case profile:
        return 'Profile';
      default:
        // GROUPS LABEL COMMENTED OUT
        // if (route.startsWith('/groups/')) {
        //   return 'Groups';
        // }
        return 'Unknown';
    }
  }
}
