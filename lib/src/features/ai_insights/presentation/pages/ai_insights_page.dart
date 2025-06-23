import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({Key? key}) : super(key: key);

  @override
  _AIInsightsPageState createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  final TransactionService _transactionService = TransactionService();
  final GoalService _goalService = GoalService();

  // Data state
  List<Transaction> _transactions = [];
  Map<String, dynamic>? _goalStats;
  bool _isLoading = true;
  String? _error;

  // Analytics data
  double _thisMonthSpending = 0.0;
  double _lastMonthSpending = 0.0;
  double _avgDailySpending = 0.0;
  String _topSpendingCategory = 'N/A';
  double _categoryPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInsightData();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: AppGradientBackground(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: false,
              pinned: true,
              expandedHeight: 56,
              backgroundColor:
                  isDark ? colorScheme.surface : colorScheme.primary,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              forceElevated: false,
              title: Text(
                'AI Insights',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? colorScheme.onSurface : Colors.white,
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(
                    Icons.dashboard,
                    color: isDark ? colorScheme.onSurface : Colors.white,
                  ),
                  onPressed: () {
                    GoRouter.of(context).go('/dashboard');
                  },
                  tooltip: 'Go to Dashboard',
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? colorScheme.onSurface : Colors.white,
                  ),
                  onPressed: () {
                    _refreshInsights();
                  },
                  tooltip: 'Refresh Insights',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildSpendingOverview(),
                    const SizedBox(height: 20),
                    _buildInsightsList(),
                    const SizedBox(height: 20),
                    _buildRecommendations(),
                    const SizedBox(height: 100), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 4,
            selectedItemColor: colorScheme.primary,
            unselectedItemColor: colorScheme.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
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
                  GoRouter.of(context).go('/dashboard');
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
                  // Already on AI insights page
                  break;
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        gradient: LinearGradient(
          colors: isDark 
            ? [
                const Color(0xFF1A1B23),
                const Color(0xFF2D1B69),
                const Color(0xFF4527A0),
              ]
            : [
                colorScheme.primary,
                const Color(0xFF6366F1),
                const Color(0xFF8B5CF6),
              ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const [0.0, 0.5, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: -2,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'AI Financial Insights',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Powered by advanced analytics to help you make smarter financial decisions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.psychology,
              size: 32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingOverview() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with icon - matching other screens style
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.analytics_rounded,
                  size: 18,
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Spending Analysis',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'This Month',
                  _isLoading
                      ? '...'
                      : '\$${_thisMonthSpending.toStringAsFixed(0)}',
                  _isLoading ? '...' : _calculateMonthlyChange(),
                  _getChangeColor(_calculateMonthlyChangeValue()),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Last Month',
                  _isLoading
                      ? '...'
                      : '\$${_lastMonthSpending.toStringAsFixed(0)}',
                  _isLoading
                      ? '...'
                      : '${_lastMonthSpending > 0 ? "Base" : "N/A"}',
                  _getThemeColor('success'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Avg Daily',
                  _isLoading
                      ? '...'
                      : '\$${_avgDailySpending.toStringAsFixed(0)}',
                  _isLoading ? '...' : 'Current',
                  _getThemeColor('warning'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Top Category',
                  _isLoading ? '...' : _topSpendingCategory,
                  _isLoading
                      ? '...'
                      : '${_categoryPercentage.toStringAsFixed(0)}%',
                  _getThemeColor('info'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    String change,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark
                ? color.withValues(alpha: 0.1)
                : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color:
                  isDark
                      ? colorScheme.onSurfaceVariant
                      : color.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: isDark ? color : color.withValues(alpha: 0.9),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            change,
            style: TextStyle(
              color: isDark ? color : color.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightsList() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final insights = _generateDynamicInsights();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with icon - matching other screens style
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.lightbulb_rounded,
                  size: 18,
                  color: colorScheme.onSecondaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Smart Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insights.map((insight) => _buildInsightTile(insight)).toList(),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _generateDynamicInsights() {
    List<Map<String, dynamic>> insights = [];

    // Spending analysis insight
    if (_thisMonthSpending > 0 && _lastMonthSpending > 0) {
      final changePercent = _calculateMonthlyChangeValue();
      if (changePercent.abs() > 10) {
        insights.add({
          'title':
              changePercent > 0
                  ? 'Spending Increase Detected'
                  : 'Great Spending Control!',
          'description':
              'You spent ${changePercent.abs().toStringAsFixed(0)}% ${changePercent > 0 ? 'more' : 'less'} this month vs last month',
          'icon': changePercent > 0 ? Icons.trending_up : Icons.trending_down,
          'color':
              changePercent > 0
                  ? _getThemeColor('error')
                  : _getThemeColor('success'),
          'action': null,
        });
      }
    }

    // Goal progress insight
    if (_goalStats != null) {
      final totalGoals = _goalStats!['totalGoals'] ?? 0;
      final completedGoals = _goalStats!['completedGoals'] ?? 0;
      final overallProgress = _goalStats!['overallProgress'] ?? 0.0;

      if (totalGoals > 0) {
        if (completedGoals > 0) {
          insights.add({
            'title': 'Goal Achievement!',
            'description': '$completedGoals out of $totalGoals goals completed',
            'icon': Icons.emoji_events,
            'color': _getThemeColor('success'),
            'action': 'View Goals',
          });
        } else if (overallProgress > 0.7) {
          insights.add({
            'title': 'Goal Progress Looking Great!',
            'description':
                '${(overallProgress * 100).toStringAsFixed(0)}% overall progress towards your goals',
            'icon': Icons.savings,
            'color': _getThemeColor('primary'),
            'action': 'View Goals',
          });
        } else if (overallProgress < 0.3) {
          insights.add({
            'title': 'Time to Boost Your Goals',
            'description':
                'Only ${(overallProgress * 100).toStringAsFixed(0)}% progress. Consider increasing savings',
            'icon': Icons.flag,
            'color': _getThemeColor('warning'),
            'action': 'View Goals',
          });
        }
      }
    }

    // Top category insight
    if (_topSpendingCategory != 'N/A' && _categoryPercentage > 30) {
      insights.add({
        'title': 'Category Alert',
        'description':
            '${_categoryPercentage.toStringAsFixed(0)}% of spending is on $_topSpendingCategory',
        'icon': Icons.pie_chart,
        'color': _getThemeColor('info'),
        'action': 'View Details',
      });
    }

    // Daily spending insight
    if (_avgDailySpending > 100) {
      insights.add({
        'title': 'Daily Spending Alert',
        'description':
            'Average daily spending is \$${_avgDailySpending.toStringAsFixed(0)}',
        'icon': Icons.calendar_today,
        'color': _getThemeColor('warning'),
        'action': null,
      });
    }

    // If no insights, show a default one
    if (insights.isEmpty) {
      insights.add({
        'title': 'Financial Health Check',
        'description':
            'Your spending patterns look stable. Keep tracking for better insights!',
        'icon': Icons.health_and_safety,
        'color': _getThemeColor('success'),
        'action': null,
      });
    }

    return insights;
  }

  Widget _buildInsightTile(Map<String, dynamic> insight) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark
                ? insight['color'].withValues(alpha: 0.1)
                : insight['color'].withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color:
              isDark
                  ? insight['color'].withValues(alpha: 0.3)
                  : insight['color'].withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(insight['icon'], color: insight['color'], size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['title'],
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  insight['description'],
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (insight['action'] != null)
            TextButton(
              onPressed: () {
                // TODO: Implement action
              },
              child: Text(insight['action']),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header with icon - matching other screens style
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.recommend_rounded,
                  size: 18,
                  color: colorScheme.onTertiaryContainer,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Recommendations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRecommendationCard(
            'Save on Subscriptions',
            'Cancel unused streaming services to save \$45/month',
            Icons.subscriptions,
            _getThemeColor('primary'),
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Budget Alert',
            'Set a food budget of \$400 to reduce dining expenses',
            Icons.restaurant,
            _getThemeColor('warning'),
          ),
          const SizedBox(height: 12),
          _buildRecommendationCard(
            'Investment Opportunity',
            'You have \$500 surplus - consider investing',
            Icons.trending_up,
            _getThemeColor('success'),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }

  Future<void> _loadInsightData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load data in parallel
      final futures = await Future.wait([
        _transactionService.fetchTransactions(),
        _goalService.getGoalStatistics(),
      ]);

      final transactions = futures[0] as List<Transaction>;
      final goalStats = futures[1] as Map<String, dynamic>;

      // Calculate analytics
      _calculateSpendingAnalytics(transactions);

      setState(() {
        _transactions = transactions;
        _goalStats = goalStats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateSpendingAnalytics(List<Transaction> transactions) {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);

    // Filter expenses (negative amounts or expense type)
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // This month spending
    _thisMonthSpending = expenses
        .where((t) => t.date.isAfter(currentMonth))
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Last month spending
    _lastMonthSpending = expenses
        .where(
          (t) => t.date.isAfter(lastMonth) && t.date.isBefore(currentMonth),
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Average daily spending (this month)
    final daysInMonth = now.day;
    _avgDailySpending =
        daysInMonth > 0 ? _thisMonthSpending / daysInMonth : 0.0;

    // Top spending category
    final categoryTotals = <String, double>{};
    for (final expense in expenses.where((t) => t.date.isAfter(currentMonth))) {
      final category = expense.category;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0.0) + expense.amount.abs();
    }

    if (categoryTotals.isNotEmpty) {
      final topEntry = categoryTotals.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      _topSpendingCategory = topEntry.key;
      _categoryPercentage =
          _thisMonthSpending > 0
              ? (topEntry.value / _thisMonthSpending) * 100
              : 0.0;
    }
  }

  void _refreshInsights() {
    _loadInsightData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Insights refreshed successfully!'),
        backgroundColor: _getThemeColor('success'),
      ),
    );
  }

  String _calculateMonthlyChange() {
    if (_lastMonthSpending == 0) return 'N/A';
    final change =
        ((_thisMonthSpending - _lastMonthSpending) / _lastMonthSpending) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(0)}%';
  }

  double _calculateMonthlyChangeValue() {
    if (_lastMonthSpending == 0) return 0.0;
    return ((_thisMonthSpending - _lastMonthSpending) / _lastMonthSpending) *
        100;
  }

  Color _getChangeColor(double changeValue) {
    if (changeValue > 0)
      return _getThemeColor('error'); // Increased spending = bad
    if (changeValue < 0)
      return _getThemeColor('success'); // Decreased spending = good
    return _getThemeColor('neutral'); // No change
  }

  /// Get theme-aware colors that work well in both light and dark modes
  Color _getThemeColor(String colorType) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (colorType) {
      case 'primary':
        return colorScheme.primary;
      case 'success':
        return isDark ? const Color(0xFF4CAF50) : const Color(0xFF2E7D32);
      case 'error':
        return isDark ? const Color(0xFFFF5252) : const Color(0xFFD32F2F);
      case 'warning':
        return isDark ? const Color(0xFFFF9800) : const Color(0xFFE65100);
      case 'info':
        return isDark ? const Color(0xFF9C27B0) : const Color(0xFF7B1FA2);
      case 'accent':
        return isDark ? const Color(0xFFFFB300) : const Color(0xFFF57C00);
      case 'neutral':
        return colorScheme.onSurfaceVariant;
      default:
        return colorScheme.primary;
    }
  }
}
