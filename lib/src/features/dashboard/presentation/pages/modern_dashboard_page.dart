import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';

import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../data/services/dashboard_sync_service.dart';
import '../../../../shared/utils/avatar_utils.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/services/user_profile_notifier.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/theme_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

class ModernDashboardPage extends StatefulWidget {
  const ModernDashboardPage({super.key});

  @override
  State<ModernDashboardPage> createState() => _ModernDashboardPageState();
}

class _ModernDashboardPageState extends State<ModernDashboardPage>
    with AutomaticKeepAliveClientMixin {
  // Services
  final TransactionService _transactionService = TransactionService();
  final GoalService _goalService = GoalService();
  final DashboardSyncService _syncService = DashboardSyncService();
  final UserProfileNotifier _profileNotifier = UserProfileNotifier();

  // State variables
  List<Transaction> _recentTransactions = [];
  bool _isLoading = true;
  String? _error;

  // User profile data
  String _userName = '';
  String? _userProfilePicture;

  // Financial summary data
  double _totalIncome = 0.0;
  double _totalExpenses = 0.0;
  double _savings = 0.0;

  // Previous month data for percentage calculation
  double _previousIncome = 0.0;
  double _previousExpenses = 0.0;

  // Goals summary data
  int _totalGoals = 0;
  double _totalSavedAmount = 0.0;
  double _totalTargetAmount = 0.0;

  // Category breakdown data for charts
  Map<String, double> _categoryBreakdown = {};

  @override
  void initState() {
    super.initState();
    // Add a small delay to ensure token is stored
    Future.delayed(const Duration(milliseconds: 500), () {
      _loadData();
      _profileNotifier.fetchUserProfile();
    });

    // Register this dashboard instance for sync updates
    _syncService.setRefreshCallback(_loadData);

    // Listen to profile changes
    _profileNotifier.profileStream.listen((userProfile) {
      if (mounted) {
        setState(() {
          _userName = userProfile['name'] ?? '';
          _userProfilePicture = userProfile['profile_picture'];
        });
      }
    });
  }

  @override
  void dispose() {
    _syncService.clearRefreshCallback();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadTransactions(), _loadUserProfile()]);
  }

  Future<void> _loadTransactions() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load transactions and goals in parallel
      final futures = await Future.wait([
        _transactionService.fetchTransactions(),
        _loadGoalStatistics(),
      ]);

      final transactions = futures[0] as List<Transaction>;

      // Calculate financial summary
      double income = 0.0;
      double expenses = 0.0;
      double prevIncome = 0.0;
      double prevExpenses = 0.0;

      final now = DateTime.now();
      final currentMonthStart = DateTime(now.year, now.month, 1);
      final previousMonthStart = DateTime(now.year, now.month - 1, 1);

      // Collect current month transactions and calculate category breakdown
      final currentMonthTransactions = <Transaction>[];
      final categoryTotals = <String, double>{};

      for (final transaction in transactions) {
        final transactionDate = transaction.date;
        final isCurrentMonth =
            transactionDate.isAfter(currentMonthStart) ||
            transactionDate.isAtSameMomentAs(currentMonthStart);
        final isPreviousMonth =
            transactionDate.isAfter(previousMonthStart) &&
            transactionDate.isBefore(currentMonthStart);

        if (isCurrentMonth) {
          currentMonthTransactions.add(transaction);

          // Calculate category breakdown for expenses only
          if (transaction.type.toLowerCase() == 'expense' ||
              transaction.amount < 0) {
            final category = transaction.category;
            final amount = transaction.amount.abs();
            categoryTotals[category] =
                (categoryTotals[category] ?? 0.0) + amount;
          }
        }

        // Handle amounts properly
        if (transaction.type.toLowerCase() == 'income' ||
            transaction.amount > 0) {
          if (isCurrentMonth) {
            income += transaction.amount.abs();
          }
          if (isPreviousMonth) {
            prevIncome += transaction.amount.abs();
          }
        } else {
          if (isCurrentMonth) {
            expenses += transaction.amount.abs();
          }
          if (isPreviousMonth) {
            prevExpenses += transaction.amount.abs();
          }
        }
      }

      setState(() {
        // Sort transactions by date in descending order (most recent first)
        transactions.sort((a, b) => b.date.compareTo(a.date));
        _recentTransactions = transactions.take(3).toList();
        _totalIncome = income;
        _totalExpenses = expenses;
        _previousIncome = prevIncome;
        _previousExpenses = prevExpenses;
        _savings = income - expenses;
        _categoryBreakdown = categoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        _recentTransactions = [];
        _totalIncome = 0.0;
        _totalExpenses = 0.0;
        _savings = 0.0;
        _totalGoals = 0;
        _totalSavedAmount = 0.0;
        _totalTargetAmount = 0.0;
      });
    }
  }

  Future<void> _loadGoalStatistics() async {
    try {
      final stats = await _goalService.getGoalStatistics();
      _totalGoals = stats['totalGoals'] ?? 0;
      _totalSavedAmount = stats['totalSavedAmount'] ?? 0.0;
      _totalTargetAmount = stats['totalTargetAmount'] ?? 0.0;
    } catch (e) {
      debugPrint('Error loading goal statistics: $e');
      _totalGoals = 0;
      _totalSavedAmount = 0.0;
      _totalTargetAmount = 0.0;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      await _profileNotifier.fetchUserProfile();
    } catch (e) {
      debugPrint('Error loading user profile: $e');
      setState(() {
        _userName = '';
        _userProfilePicture = null;
      });
    }
  }

  String get _firstName {
    if (_userName.isEmpty) return '';
    return _userName.split(' ').first;
  }

  IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drinks':
      case 'restaurant':
      case 'dining':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
      case 'car':
        return Icons.directions_car;
      case 'shopping':
      case 'retail':
        return Icons.shopping_bag;
      case 'entertainment':
      case 'movies':
        return Icons.movie;
      case 'utilities':
      case 'bills':
        return Icons.receipt;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'salary':
      case 'income':
      case 'work':
        return Icons.work;
      case 'investment':
        return Icons.trending_up;
      case 'coffee':
        return Icons.local_cafe;
      case 'groceries':
      case 'grocery':
        return Icons.local_grocery_store;
      case 'gas':
      case 'fuel':
        return Icons.local_gas_station;
      case 'education':
        return Icons.school;
      case 'gym':
      case 'fitness':
        return Icons.fitness_center;
      default:
        return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: AppGradientBackground(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              _buildSliverAppBar(theme, themeProvider),

              // Dashboard Content
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Welcome Section
                    _buildWelcomeSection(theme),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // Financial Summary Cards
                    _buildFinancialSummary(theme),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // Quick Actions
                    _buildQuickActions(theme),

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // Recent Transactions
                    _buildRecentTransactions(theme),

                    if (_categoryBreakdown.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.sectionSpacing),
                      _buildSpendingBreakdown(theme),
                    ],

                    const SizedBox(height: AppSpacing.sectionSpacing),

                    // AI Insights
                    _buildSmartInsights(theme),

                    const SizedBox(
                      height: AppSpacing.massive,
                    ), // Extra space for bottom navigation
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // Modern Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(theme),

      // Modern FAB
      floatingActionButton: _buildFloatingActionButton(theme),
      floatingActionButtonLocation:
          const _CustomCenterFloatingActionButtonLocation(),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ThemeProvider themeProvider) {
    final appBarColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.surface.withValues(alpha: 0.95)
            : theme.colorScheme.primary.withValues(alpha: 0.95);

    final titleColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : Colors.white;

    final iconColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9);

    return SliverAppBar(
      floating: false,
      pinned: true,
      expandedHeight: 56,
      backgroundColor: appBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: theme.colorScheme.shadow,
      forceElevated: false,
      systemOverlayStyle:
          theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.light,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          color: appBarColor,
          border: Border(
            bottom: BorderSide(
              color:
                  theme.brightness == Brightness.dark
                      ? theme.colorScheme.outlineVariant.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.2),
              width: 0.5,
            ),
          ),
        ),
      ),
      title: Text(
        'Dashboard',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      actions: [
        // Theme toggle
        IconButton(
          onPressed: themeProvider.toggleTheme,
          icon: Icon(themeProvider.themeModeIcon),
          tooltip: 'Switch theme',
          color: iconColor,
        ),

        // Profile
        Padding(
          padding: const EdgeInsets.only(
            right: AppSpacing.md,
            left: AppSpacing.xs,
          ),
          child: IconButton(
            onPressed: () => GoRouter.of(context).go('/profile'),
            icon: AvatarUtils.buildAvatar(
              context: context,
              userName: _userName,
              profilePicture: _userProfilePicture,
              radius: 16,
              fontSize: 14,
              style: AvatarStyle.standard,
            ),
            tooltip: 'Profile',
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(ThemeData theme) {
    final now = DateTime.now();
    final timeOfDay =
        now.hour < 12
            ? 'Morning'
            : now.hour < 17
            ? 'Afternoon'
            : 'Evening';

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Section Header with icon - matching other screens style
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.waving_hand,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              // Clean Welcome Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _firstName.isNotEmpty
                          ? 'Good $timeOfDay,\n$_firstName!'
                          : 'Good $timeOfDay!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Ready to manage your finances today?',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // Simple Balance Indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Balance',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  CurrencyFormatter.formatForDisplay(_savings),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color:
                        _savings >= 0
                            ? AppTheme.successColor
                            : AppTheme.errorColor,
                  ),
                ),
              ],
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialSummary(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with icon
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Overview',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/ai-insights'),
                child: Text(
                  'View Details',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Clean Financial Cards Grid
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              // Section Header with icon - matching other screens style
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.analytics_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Financial Overview',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // First row: Income and Expenses
              Row(
                children: [
                  Expanded(
                    child: _buildCleanFinancialCard(
                      theme,
                      'Income',
                      _totalIncome,
                      Icons.trending_up_rounded,
                      AppTheme.successColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: _buildCleanFinancialCard(
                      theme,
                      'Expenses',
                      _totalExpenses,
                      Icons.trending_down_rounded,
                      AppTheme.errorColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Second row: Balance and Goals
              Row(
                children: [
                  Expanded(
                    child: _buildCleanFinancialCard(
                      theme,
                      'Balance',
                      _savings,
                      Icons.account_balance_wallet_rounded,
                      _savings >= 0
                          ? AppTheme.successColor
                          : AppTheme.errorColor,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),

                  Expanded(
                    child: GestureDetector(
                      onTap: () => GoRouter.of(context).go('/goals'),
                      child: _buildGoalsCard(theme),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCleanFinancialCard(
    ThemeData theme,
    String title,
    double value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Amount with better formatting
          Text(
            CurrencyFormatter.formatForDisplay(value),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Trend indicator based on card type
          _buildTrendIndicator(theme, title),
        ],
      ),
    );
  }

  Widget _buildTrendIndicator(ThemeData theme, String cardType) {
    String trendText = '';
    IconData trendIcon = Icons.remove_rounded;
    Color trendColor = theme.colorScheme.onSurfaceVariant;

    switch (cardType.toLowerCase()) {
      case 'income':
        final change =
            _previousIncome > 0
                ? ((_totalIncome - _previousIncome) / _previousIncome * 100)
                : 0.0;
        trendText =
            change > 0
                ? '+${CurrencyFormatter.formatPercentage(change)} vs last month'
                : change < 0
                ? '${CurrencyFormatter.formatPercentage(change)} vs last month'
                : 'No change';
        trendIcon =
            change > 0
                ? Icons.trending_up_rounded
                : change < 0
                ? Icons.trending_down_rounded
                : Icons.remove_rounded;
        trendColor =
            change > 0
                ? AppTheme.successColor
                : change < 0
                ? AppTheme.errorColor
                : theme.colorScheme.onSurfaceVariant;
        break;

      case 'expenses':
        final change =
            _previousExpenses > 0
                ? ((_totalExpenses - _previousExpenses) /
                    _previousExpenses *
                    100)
                : 0.0;
        trendText =
            change > 0
                ? '+${CurrencyFormatter.formatPercentage(change)} vs last month'
                : change < 0
                ? '${CurrencyFormatter.formatPercentage(change)} vs last month'
                : 'No change';
        trendIcon =
            change > 0
                ? Icons.trending_up_rounded
                : change < 0
                ? Icons.trending_down_rounded
                : Icons.remove_rounded;
        // For expenses, up is bad (red) and down is good (green)
        trendColor =
            change > 0
                ? AppTheme.errorColor
                : change < 0
                ? AppTheme.successColor
                : theme.colorScheme.onSurfaceVariant;
        break;

      case 'balance':
        if (_savings >= 0) {
          trendText = 'Positive balance';
          trendIcon = Icons.trending_up_rounded;
          trendColor = AppTheme.successColor;
        } else {
          trendText = 'Needs attention';
          trendIcon = Icons.trending_down_rounded;
          trendColor = AppTheme.errorColor;
        }
        break;

      case 'goals':
        if (_totalGoals > 0) {
          final goalProgress =
              _totalTargetAmount > 0
                  ? _totalSavedAmount / _totalTargetAmount
                  : 0.0;
          if (goalProgress >= 0.5) {
            trendText =
                '${CurrencyFormatter.formatPercentage(goalProgress * 100)} completed';
            trendIcon = Icons.trending_up_rounded;
            trendColor = AppTheme.successColor;
          } else if (goalProgress > 0) {
            trendText =
                '${CurrencyFormatter.formatPercentage(goalProgress * 100)} progress';
            trendIcon = Icons.trending_up_rounded;
            trendColor = AppTheme.warningColor;
          } else {
            trendText = 'Just getting started';
            trendIcon = Icons.flag_rounded;
            trendColor = AppTheme.warningColor;
          }
        } else {
          trendText = 'Set your first goal';
          trendIcon = Icons.add_rounded;
          trendColor = AppTheme.warningColor;
        }
        break;

      default:
        trendText = 'This month';
        break;
    }

    return Row(
      children: [
        Icon(trendIcon, size: 14, color: trendColor),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: Text(
            trendText,
            style: theme.textTheme.labelSmall?.copyWith(
              color: trendColor,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildGoalsCard(ThemeData theme) {
    final color = AppTheme.warningColor;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.08),
            color.withValues(alpha: 0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(Icons.flag_rounded, size: 16, color: color),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Goals',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Goals count or amount - matching other cards format
          Text(
            _totalGoals > 0
                ? '$_totalGoals ${_totalGoals == 1 ? 'Goal' : 'Goals'}'
                : CurrencyFormatter.formatForDisplay(_totalSavedAmount),
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // Trend indicator - matching other cards
          _buildTrendIndicator(theme, 'Goals'),
        ],
      ),
    );
  }

  Widget _buildQuickActions(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.bolt_rounded,
                  size: 18,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Quick Actions',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Enhanced Action Grid
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.dark 
                  ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                  : theme.colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildEnhancedQuickAction(
                    theme,
                    'Expense',
                    Icons.remove_circle_outline,
                    AppTheme.errorColor,
                    () => GoRouter.of(context).go('/create-transaction'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildEnhancedQuickAction(
                    theme,
                    'Income',
                    Icons.add_circle_outline,
                    AppTheme.successColor,
                    () => GoRouter.of(context).go('/create-transaction'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildEnhancedQuickAction(
                    theme,
                    'Goals',
                    Icons.flag_outlined,
                    AppTheme.warningColor,
                    () => GoRouter.of(context).go('/goals'),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildEnhancedQuickAction(
                    theme,
                    'Insights',
                    Icons.lightbulb_outline,
                    AppTheme.infoColor,
                    () => GoRouter.of(context).go('/ai-insights'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedQuickAction(
    ThemeData theme,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      child: Container(
        height: 70,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with icon - matching other sections
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(
                      Icons.receipt_long_rounded,
                      size: 18,
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Recent Transactions',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => GoRouter.of(context).go('/transactions'),
                child: Text(
                  'View All',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Full-width Transaction Card - matching financial summary styling exactly
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child:
              _isLoading
                  ? _buildTransactionSkeletonContent(theme)
                  : _error != null
                  ? _buildErrorWidgetContent(theme)
                  : _recentTransactions.isEmpty
                  ? _buildEmptyTransactionsWidgetContent(theme)
                  : _buildTransactionListContent(theme),
        ),
      ],
    );
  }

  Widget _buildTransactionSkeletonContent(ThemeData theme) {
    return Column(
      children: List.generate(
        3,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: index < 2 ? AppSpacing.md : 0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      width: 120,
                      height: 12,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.05,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionListContent(ThemeData theme) {
    if (_recentTransactions.isEmpty) return const SizedBox.shrink();

    return Column(
      children:
          _recentTransactions
              .asMap()
              .entries
              .map(
                (entry) => Padding(
                  padding: EdgeInsets.only(
                    bottom:
                        entry.key < _recentTransactions.length - 1
                            ? AppSpacing.md
                            : 0,
                  ),
                  child: _buildSimpleTransactionTile(theme, entry.value),
                ),
              )
              .toList(),
    );
  }

  Widget _buildSimpleTransactionTile(ThemeData theme, Transaction transaction) {
    final isIncome =
        transaction.type.toLowerCase() == 'income' || transaction.amount > 0;
    final color = isIncome ? AppTheme.successColor : AppTheme.errorColor;

    return Row(
      children: [
        // Category icon
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Icon(
            _getTransactionIcon(transaction.category),
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: AppSpacing.md),

        // Transaction description
        Expanded(
          child: Text(
            transaction.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),

        // Amount
        Text(
          CurrencyFormatter.formatWithSign(transaction.amount),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidgetContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 48,
          color: theme.colorScheme.error,
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Unable to load transactions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        ElevatedButton(onPressed: _loadData, child: const Text('Retry')),
      ],
    );
  }

  Widget _buildEmptyTransactionsWidgetContent(ThemeData theme) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.receipt_long_outlined,
          size: 48,
          color: Colors.grey.withValues(alpha: 0.4),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No transactions yet',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Start by adding your first transaction',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingBreakdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                Icons.pie_chart_rounded,
                size: 18,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Spending Breakdown',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(height: 200, child: _buildCategoryPieChart(theme)),
              const SizedBox(height: AppSpacing.lg),
              _buildCategoryLegend(theme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryPieChart(ThemeData theme) {
    if (_categoryBreakdown.isEmpty) {
      return Center(
        child: Text(
          'No expense data available',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    final colors = [
      AppTheme.errorColor,
      AppTheme.infoColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final sections =
        _categoryBreakdown.entries.map((entry) {
          final index = _categoryBreakdown.keys.toList().indexOf(entry.key);
          final percentage = (entry.value / _totalExpenses) * 100;
          return PieChartSectionData(
            color: colors[index % colors.length],
            value: entry.value,
            title: '${percentage.toStringAsFixed(1)}%',
            radius: 60,
            titleStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          );
        }).toList();

    return PieChart(
      PieChartData(sections: sections, centerSpaceRadius: 40, sectionsSpace: 2),
    );
  }

  Widget _buildCategoryLegend(ThemeData theme) {
    if (_categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final colors = [
      AppTheme.errorColor,
      AppTheme.infoColor,
      AppTheme.successColor,
      AppTheme.warningColor,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children:
          _categoryBreakdown.entries.map((entry) {
            final index = _categoryBreakdown.keys.toList().indexOf(entry.key);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: colors[index % colors.length],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  '${entry.key}: ${CurrencyFormatter.formatWhole(entry.value)}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            );
          }).toList(),
    );
  }

  Widget _buildSmartInsights(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header with icon - matching other sections
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Financial Insights',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Powered by intelligent analysis',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Refresh insights button
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                _loadData(); // Refresh insights
              },
              icon: Icon(
                Icons.refresh_rounded,
                color: theme.colorScheme.primary,
              ),
              tooltip: 'Refresh insights',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Enhanced insights container
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: theme.brightness == Brightness.dark 
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(children: _buildEnhancedInsightsList(theme)),
        ),
      ],
    );
  }

  List<Widget> _buildEnhancedInsightsList(ThemeData theme) {
    if (_categoryBreakdown.isEmpty || _recentTransactions.isEmpty) {
      return [_buildWelcomeInsight(theme)];
    }

    final insights = <Widget>[];

    // Show only 2-3 most relevant insights

    // 1. Savings performance (most important)
    if (_totalIncome > 0) {
      insights.add(_buildSimpleSavingsInsight(theme));
    }

    // 2. Top spending category
    if (_categoryBreakdown.isNotEmpty) {
      insights.add(_buildSimpleCategoryInsight(theme));
    }

    // 3. One smart tip
    insights.add(_buildSimpleRecommendation(theme));

    // Add separators between insights
    final separatedInsights = <Widget>[];
    for (int i = 0; i < insights.length; i++) {
      separatedInsights.add(insights[i]);
      if (i < insights.length - 1) {
        separatedInsights.add(_buildInsightSeparator(theme));
      }
    }

    return separatedInsights;
  }

  Widget _buildWelcomeInsight(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(
            Icons.insights_rounded,
            size: 48,
            color: Colors.grey.withValues(alpha: 0.4),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No insights yet',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.grey.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Add transactions to see AI insights',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleSavingsInsight(ThemeData theme) {
    final savingsRate = (_savings / _totalIncome * 100);

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (savingsRate >= 20) {
      color = AppTheme.successColor;
      icon = Icons.savings_rounded;
      title = 'Great savings!';
      subtitle =
          '${CurrencyFormatter.formatPercentage(savingsRate)} saved this month';
    } else if (savingsRate >= 10) {
      color = AppTheme.infoColor;
      icon = Icons.trending_up_rounded;
      title = 'Good progress';
      subtitle =
          '${CurrencyFormatter.formatPercentage(savingsRate)} saved, aim for 20%';
    } else if (savingsRate > 0) {
      color = AppTheme.warningColor;
      icon = Icons.lightbulb_outline_rounded;
      title = 'Room to improve';
      subtitle =
          'Only ${CurrencyFormatter.formatPercentage(savingsRate)} saved this month';
    } else {
      color = AppTheme.errorColor;
      icon = Icons.warning_rounded;
      title = 'Budget alert';
      subtitle = 'Spending more than earning';
    }

    return _buildSimpleInsightTile(theme, title, subtitle, icon, color);
  }

  Widget _buildSimpleCategoryInsight(ThemeData theme) {
    final topCategory = _categoryBreakdown.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final percentage = (topCategory.value / _totalExpenses * 100);

    Color color;
    IconData icon;
    String title;
    String subtitle;

    if (percentage > 40) {
      color = AppTheme.warningColor;
      icon = Icons.pie_chart_rounded;
      title = 'Top spending category';
      subtitle =
          '${topCategory.key} - ${CurrencyFormatter.formatPercentage(percentage)} of expenses';
    } else {
      color = AppTheme.infoColor;
      icon = Icons.donut_small_rounded;
      title = 'Balanced spending';
      subtitle =
          '${topCategory.key} leads at ${CurrencyFormatter.formatPercentage(percentage)}';
    }

    return _buildSimpleInsightTile(theme, title, subtitle, icon, color);
  }

  Widget _buildSimpleRecommendation(ThemeData theme) {
    String title;
    String subtitle;
    IconData icon;
    Color color;

    // Generate one simple tip
    if (_totalIncome > 0 && (_savings / _totalIncome) < 0.1) {
      title = 'Quick tip';
      subtitle = 'Try saving 10% of your income';
      icon = Icons.lightbulb_outline_rounded;
      color = AppTheme.warningColor;
    } else if (_totalGoals == 0) {
      title = 'Get started';
      subtitle = 'Set your first financial goal';
      icon = Icons.flag_outlined;
      color = AppTheme.infoColor;
    } else if (_categoryBreakdown.isNotEmpty) {
      final topCategory = _categoryBreakdown.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      if ((topCategory.value / _totalExpenses) > 0.4) {
        title = 'Budget tip';
        subtitle = 'Set a limit for ${topCategory.key} spending';
        icon = Icons.adjust_rounded;
        color = AppTheme.warningColor;
      } else {
        title = 'Keep it up!';
        subtitle = 'Your spending looks balanced';
        icon = Icons.check_circle_outline;
        color = AppTheme.successColor;
      }
    } else {
      title = 'AI Tip';
      subtitle = 'Track expenses for better insights';
      icon = Icons.auto_awesome_rounded;
      color = AppTheme.infoColor;
    }

    return _buildSimpleInsightTile(theme, title, subtitle, icon, color);
  }

  Widget _buildSimpleInsightTile(
    ThemeData theme,
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightSeparator(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      height: 1,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.transparent,
            theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 0,
          backgroundColor: Colors.transparent,
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_rounded),
              label: 'Transactions',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag_rounded),
              label: 'Goals',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_rounded),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded),
              label: 'AI Insights',
            ),
          ],
          onTap: (index) {
            switch (index) {
              case 0:
                // Already on dashboard
                break;
              case 1:
                GoRouter.of(context).go('/transactions');
                break;
              case 2:
                GoRouter.of(context).go('/goals');
                break;
              case 3:
                GoRouter.of(context).go('/groups');
                break;
              case 4:
                GoRouter.of(context).go('/ai-insights');
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () => GoRouter.of(context).go('/create-transaction'),
      tooltip: 'Add Transaction',
      child: const Icon(Icons.receipt_long),
    );
  }

  @override
  bool get wantKeepAlive => true;
}

/// Custom FloatingActionButtonLocation that positions the FAB slightly above center docked
class _CustomCenterFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _CustomCenterFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the center docked position
    final Offset centerDocked = FloatingActionButtonLocation.centerDocked
        .getOffset(scaffoldGeometry);

    // Move it up by 16 pixels to clear the bottom navigation
    return Offset(centerDocked.dx, centerDocked.dy - 16);
  }
}
