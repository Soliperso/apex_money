import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/main_navigation_wrapper.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/design_system.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../shared/models/ai_insight_model.dart';
import '../widgets/expandable_insight_card.dart';
import '../widgets/actionable_insight_card.dart';
import '../widgets/smart_recommendation_card.dart';
import '../widgets/insight_feedback_widget.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({Key? key}) : super(key: key);

  @override
  _AIInsightsPageState createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  final TransactionService _transactionService = TransactionService();
  final GoalService _goalService = GoalService();
  AIService? _aiService;

  // Cancel token for ongoing requests
  bool _isDisposed = false;

  // Data state
  List<Transaction> _transactions = [];
  Map<String, dynamic>? _goalStats;
  bool _isLoading = true;
  String? _error;

  // AI-generated data
  List<AIInsight> _aiInsights = [];
  List<AIRecommendation> _aiRecommendations = [];
  String? _spendingPrediction;
  bool _isLoadingAI = false;
  String? _aiError;

  // Analytics data
  double _thisMonthSpending = 0.0;
  double _lastMonthSpending = 0.0;
  double _avgDailySpending = 0.0;
  String _topSpendingCategory = 'N/A';
  double _categoryPercentage = 0.0;

  // UI state
  bool _isDetailedAnalyticsExpanded = false;
  bool _showAllInsights = false;
  bool _showAllRecommendations = false;

  // Time filtering
  String _selectedTimeFilter = '30D';
  static const List<String> _timeFilterOptions = ['7D', '30D', '90D', '1Y'];
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  @override
  void initState() {
    super.initState();
    _initializeAIService();
    _loadInsightData();
  }

  void _initializeAIService() {
    try {
      _aiService = AIService();
    } catch (e) {
      print('Warning: AI Service initialization failed: $e');
      _aiService = null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MainNavigationWrapper(
      currentIndex: 3, // Updated from 4 to 3 since groups tab was removed
      child: AppGradientBackground(
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
                    Icons.filter_list,
                    color: isDark ? colorScheme.onSurface : Colors.white,
                  ),
                  onPressed: _showTimeFilterDialog,
                  tooltip: 'Filter Time Period',
                ),
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    color: isDark ? colorScheme.onSurface : Colors.white,
                  ),
                  onPressed: _loadAIInsights,
                  tooltip: 'Refresh AI Insights',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Time filter indicator
                    _buildTimeFilterIndicator(),
                    const SizedBox(height: 16),

                    // 1. Financial Health Score - Simplified overview
                    _buildFinancialHealthScore(),
                    const SizedBox(height: AppSpacing.md),

                    // 2. Priority Insights - Compact cards with progressive disclosure
                    _buildPriorityInsights(),
                    const SizedBox(height: AppSpacing.md),

                    // 3. Smart Recommendations - Simplified actionable items
                    _buildSmartRecommendations(),
                    const SizedBox(height: AppSpacing.md),

                    // 4. Detailed Analytics - Expandable section (less prominent)
                    _buildDetailedAnalytics(),
                    const SizedBox(height: 80), // Reduced space for bottom nav
                  ],
                ),
              ),
            ),
          ],
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
          colors:
              isDark
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
                Text(
                  'AI Financial Insights',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Powered by advanced analytics to help you make smarter financial decisions',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(
                      context,
                    ).colorScheme.onPrimary.withValues(alpha: 0.9),
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
              color: Theme.of(
                context,
              ).colorScheme.onPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              Icons.psychology,
              size: 32,
              color: Theme.of(context).colorScheme.onPrimary,
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
      decoration: DesignSystem.glassContainer(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Spending Analysis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
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
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
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

  Widget _buildLegacyInsights() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        decoration: BoxDecoration(
          color:
              theme.brightness == Brightness.dark
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
      decoration: DesignSystem.glassContainer(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Basic Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
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
        'icon': null,
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
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (insight['icon'] != null) ...[
            Icon(insight['icon'], color: insight['color'], size: 20),
            const SizedBox(width: 12),
          ],
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
                // Navigate to relevant sections based on action
                final action = insight['action'] as String;
                if (action.toLowerCase().contains('transaction')) {
                  context.go('/transactions');
                } else if (action.toLowerCase().contains('goal')) {
                  context.go('/goals');
                } else if (action.toLowerCase().contains('budget')) {
                  context.go('/transactions');
                } else {
                  // Show more detailed insight
                  _showInsightDetails(context, insight);
                }
              },
              child: Text(insight['action'], style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _loadInsightData() async {
    if (_isDisposed || !mounted) return;

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

      // Check if widget is still mounted after async operations
      if (_isDisposed || !mounted) return;

      final transactions = futures[0] as List<Transaction>;
      final goalStats = futures[1] as Map<String, dynamic>;

      // Calculate analytics
      _calculateSpendingAnalytics(transactions);

      setState(() {
        _transactions = transactions;
        _goalStats = goalStats;
        _isLoading = false;
      });

      // Load AI insights after data is loaded (always load, even if no transactions)
      _loadAIInsights();
    } catch (e) {
      // Check if widget is still mounted before calling setState
      if (_isDisposed || !mounted) return;

      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _calculateSpendingAnalytics(List<Transaction> transactions) {
    final now = DateTime.now();
    _updateFilterDates();

    // Filter transactions by selected time period
    final filteredTransactions = _filterTransactionsByTime(transactions);

    // Filter expenses (negative amounts or expense type)
    final expenses =
        filteredTransactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // Calculate periods based on filter
    final periodDuration = _getPeriodDuration();
    final currentPeriodStart = _filterStartDate!;
    final previousPeriodStart = currentPeriodStart.subtract(periodDuration);
    final currentPeriodEnd = _filterEndDate!;
    final previousPeriodEnd = currentPeriodStart;

    // Current period spending
    _thisMonthSpending = expenses
        .where(
          (t) =>
              t.date.isAfter(currentPeriodStart) &&
              t.date.isBefore(currentPeriodEnd),
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Previous period spending
    _lastMonthSpending = expenses
        .where(
          (t) =>
              t.date.isAfter(previousPeriodStart) &&
              t.date.isBefore(previousPeriodEnd),
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    // Average daily spending (current period)
    final daysInPeriod = currentPeriodEnd.difference(currentPeriodStart).inDays;
    _avgDailySpending =
        daysInPeriod > 0 ? _thisMonthSpending / daysInPeriod : 0.0;

    // Top spending category (current period)
    final categoryTotals = <String, double>{};
    for (final expense in expenses.where(
      (t) =>
          t.date.isAfter(currentPeriodStart) &&
          t.date.isBefore(currentPeriodEnd),
    )) {
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
    if (changeValue > 0) {
      return _getThemeColor('error'); // Increased spending = bad
    }
    if (changeValue < 0) {
      return _getThemeColor('success'); // Decreased spending = good
    }
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

  /// Load AI insights from the backend
  Future<void> _loadAIInsights() async {
    if (_isDisposed || !mounted) return;

    if (kDebugMode) {
      debugPrint(
        'AIInsightsPage: Loading AI insights... Transactions count: ${_transactions.length}',
      );
    }

    // Check if AI service is available
    if (_aiService == null) {
      if (kDebugMode) {
        debugPrint(
          'AIInsightsPage: AI Service not available, loading demo insights...',
        );
      }
      _loadDemoInsights();
      return;
    }

    if (_transactions.isEmpty) {
      if (kDebugMode) {
        debugPrint(
          'AIInsightsPage: No transactions available, loading demo insights...',
        );
      }
      _loadDemoInsights();
      return;
    }

    if (_isDisposed || !mounted) return;
    setState(() {
      _isLoadingAI = true;
      _aiError = null;
    });

    try {
      if (kDebugMode) {
        debugPrint(
          'AIInsightsPage: Generating AI insights for ${_transactions.length} transactions...',
        );
      }

      // Run AI analysis tasks in parallel
      final futures = await Future.wait([
        _aiService!.generateInsights(_transactions),
        _aiService!.generateRecommendations(_transactions, _goalStats),
        _aiService!.generateSpendingPredictions(_transactions),
      ]);

      // Check if widget is still mounted after async operations
      if (_isDisposed || !mounted) return;

      final insightResponse = futures[0] as AIInsightResponse;
      final recommendations = futures[1] as List<AIRecommendation>;
      final prediction = futures[2] as String;

      if (kDebugMode) {
        debugPrint('AIInsightsPage: AI insights generated successfully!');
        debugPrint(
          'AIInsightsPage: Insights: ${insightResponse.insights.length}',
        );
        debugPrint(
          'AIInsightsPage: Recommendations: ${recommendations.length}',
        );
      }

      setState(() {
        _aiInsights = insightResponse.insights;
        _aiRecommendations = recommendations;
        _spendingPrediction = prediction;
        _isLoadingAI = false;
      });
    } catch (e) {
      if (kDebugMode) {
        debugPrint('AIInsightsPage: Error loading AI insights: $e');
      }

      // Check if widget is still mounted before calling setState
      if (_isDisposed || !mounted) return;

      setState(() {
        _aiError = e.toString();
        _isLoadingAI = false;
      });
    }
  }

  /// Load demo insights when no transactions are available
  void _loadDemoInsights() {
    if (_isDisposed || !mounted) return;

    if (_aiService == null) {
      // AI Service not available - show setup message
      setState(() {
        _aiInsights = [
          AIInsight(
            title: 'AI Features Not Configured',
            description:
                'Add your OpenAI API key to the .env file to enable AI-powered insights and recommendations.',
            type: 'neutral',
            severity: 'medium',
          ),
        ];
        _aiRecommendations = [
          AIRecommendation(
            title: 'Configure OpenAI API Key',
            description:
                'Add OPENAI_API_KEY to your .env file to unlock AI-powered financial insights.',
            action: 'Add API key to .env file',
            potentialSavings: 'Unlock AI features',
            priority: 'high',
          ),
          AIRecommendation(
            title: 'Start Tracking Expenses',
            description:
                'Begin by adding your daily expenses to get basic financial insights.',
            action: 'Add your first transaction',
            potentialSavings: 'Better tracking',
            priority: 'medium',
          ),
        ];
        _spendingPrediction =
            'Configure OpenAI API key to get AI-powered spending predictions based on your habits.';
        _isLoadingAI = false;
      });
    } else {
      // AI Service available but no transactions
      setState(() {
        _aiInsights = [
          AIInsight(
            title: 'Welcome to AI Insights',
            description:
                'Add some transactions to get personalized AI-powered financial insights and recommendations.',
            type: 'neutral',
            severity: 'low',
          ),
        ];
        _aiRecommendations = [
          AIRecommendation(
            title: 'Start Tracking Expenses',
            description:
                'Begin by adding your daily expenses to get personalized financial insights.',
            action: 'Add your first transaction',
            potentialSavings: 'Varies',
            priority: 'high',
          ),
          AIRecommendation(
            title: 'Set Financial Goals',
            description:
                'Create savings goals to better track your financial progress.',
            action: 'Create a savings goal',
            potentialSavings: 'Builds wealth',
            priority: 'medium',
          ),
        ];
        _spendingPrediction =
            'Start adding transactions to get AI-powered spending predictions based on your habits.';
        _isLoadingAI = false;
      });
    }
  }

  /// Build AI-powered insights list
  Widget _buildAIInsightsList() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DesignSystem.glassContainer(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Insights',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (_isLoadingAI)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_aiError != null) ...[
            _buildErrorCard(_aiError!),
          ] else if (_aiInsights.isEmpty && !_isLoadingAI) ...[
            _buildEmptyAICard(),
          ] else ...[
            ..._aiInsights.map((insight) => _buildAIInsightTile(insight)),
          ],
        ],
      ),
    );
  }

  /// Build AI insight tile
  Widget _buildAIInsightTile(AIInsight insight) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getInsightColor() {
      switch (insight.type) {
        case 'positive':
          return _getThemeColor('success');
        case 'negative':
          return _getThemeColor('error');
        default:
          return _getThemeColor('info');
      }
    }

    IconData getInsightIcon() {
      switch (insight.type) {
        case 'positive':
          return Icons.trending_up;
        case 'negative':
          return Icons.trending_down;
        default:
          return Icons.info_outline;
      }
    }

    final color = getInsightColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(getInsightIcon(), color: color, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  insight.description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              insight.severity.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build spending prediction card
  Widget _buildSpendingPrediction() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DesignSystem.glassContainer(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Prediction',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_spendingPrediction != null) ...[
            Text(
              _spendingPrediction!,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ] else if (_isLoadingAI) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            Text(
              'No prediction available. Add more transactions for better predictions.',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Build AI recommendations
  Widget _buildAIRecommendations() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: DesignSystem.glassContainer(theme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
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
          if (_aiRecommendations.isNotEmpty) ...[
            ..._aiRecommendations.map((rec) => _buildAIRecommendationTile(rec)),
          ] else if (_isLoadingAI) ...[
            const Center(child: CircularProgressIndicator()),
          ] else ...[
            _buildEmptyRecommendationCard(),
          ],
        ],
      ),
    );
  }

  /// Build AI recommendation tile
  Widget _buildAIRecommendationTile(AIRecommendation recommendation) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getPriorityColor() {
      switch (recommendation.priority) {
        case 'high':
          return _getThemeColor('error');
        case 'medium':
          return _getThemeColor('warning');
        default:
          return _getThemeColor('info');
      }
    }

    final color = getPriorityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                child: Icon(Icons.lightbulb_outline, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      recommendation.description,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.priority.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: _getThemeColor('success'),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Action: ${recommendation.action}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.savings_outlined,
                color: _getThemeColor('success'),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'Potential Savings: ${recommendation.potentialSavings}',
                style: TextStyle(
                  color: _getThemeColor('success'),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build error card
  Widget _buildErrorCard(String error) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getThemeColor('error').withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getThemeColor('error').withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: _getThemeColor('error'), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Analysis Error',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  'Unable to generate AI insights. Please try again later.',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _loadAIInsights,
            child: Text('Retry', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  /// Build empty AI card
  Widget _buildEmptyAICard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.psychology_outlined,
            color: colorScheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No AI insights available',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add more transactions to generate AI insights',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build empty recommendation card
  Widget _buildEmptyRecommendationCard() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(
            Icons.lightbulb_outline,
            color: colorScheme.onSurfaceVariant,
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'No recommendations available',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Keep tracking your expenses to get personalized recommendations',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Build Financial Health Score - Simplified overview
  Widget _buildFinancialHealthScore() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Calculate financial health score (0-100)
    int healthScore = _calculateFinancialHealthScore();
    String healthStatus = _getHealthStatus(healthScore);
    Color healthColor = _getHealthColor(healthScore);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.4)
                : colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: healthColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          // Simplified icon indicator
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: healthColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.health_and_safety, color: healthColor, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Financial Health',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  healthStatus,
                  style: TextStyle(
                    fontSize: 12,
                    color: healthColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Score display
          Column(
            children: [
              Text(
                '$healthScore',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: healthColor,
                ),
              ),
              Text(
                '/100',
                style: TextStyle(
                  fontSize: 10,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Priority Insights - Top 3 most important
  Widget _buildPriorityInsights() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Get priority insights with smart filtering
    List<AIInsight> priorityInsights = _getPriorityInsights();
    List<AIInsight> displayInsights =
        _showAllInsights ? priorityInsights : priorityInsights.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with simplified design
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.insights,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Key Insights',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_isLoadingAI) ...[
                const Spacer(),
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Simplified insight cards
        if (displayInsights.isEmpty && !_isLoadingAI) ...[
          _buildEmptyPriorityInsights(),
        ] else ...[
          ...displayInsights.map(
            (insight) => _buildCompactInsightCard(insight),
          ),

          // Show more/less button if there are more insights
          if (priorityInsights.length > 2)
            _buildShowMoreInsightsButton(priorityInsights.length),
        ],
      ],
    );
  }

  /// Build Smart Recommendations with action buttons
  Widget _buildSmartRecommendations() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Smart filtering for recommendations
    List<AIRecommendation> filteredRecommendations =
        _aiRecommendations.where((rec) {
          // Filter out very generic recommendations
          final title = rec.title.toLowerCase();
          final description = rec.description.toLowerCase();

          // Skip generic recommendations
          if (title.contains('general') || title.contains('basic')) {
            return false;
          }

          // Skip recommendations with very short descriptions
          if (description.length < 40) {
            return false;
          }

          return true;
        }).toList();

    // Sort by priority and relevance
    filteredRecommendations.sort((a, b) {
      // Primary sort: priority
      int priorityCompare = _getPriorityOrder(
        b.priority,
      ).compareTo(_getPriorityOrder(a.priority));
      if (priorityCompare != 0) return priorityCompare;

      // Secondary sort: relevance
      int aRelevance = _calculateRecommendationRelevance(a);
      int bRelevance = _calculateRecommendationRelevance(b);
      return bRelevance.compareTo(aRelevance);
    });

    List<AIRecommendation> displayRecommendations =
        _showAllRecommendations
            ? filteredRecommendations
            : filteredRecommendations.take(2).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Simplified section header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.tips_and_updates,
                  color: colorScheme.secondary,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Recommendations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),

        // Simplified recommendation cards
        if (displayRecommendations.isEmpty && !_isLoadingAI) ...[
          _buildEmptyRecommendations(),
        ] else if (_isLoadingAI) ...[
          _buildLoadingRecommendations(),
        ] else ...[
          ...displayRecommendations.map(
            (recommendation) => _buildCompactRecommendationCard(recommendation),
          ),

          // Show more/less button if there are more recommendations
          if (filteredRecommendations.length > 2)
            _buildShowMoreRecommendationsButton(filteredRecommendations.length),
        ],
      ],
    );
  }

  /// Build Detailed Analytics - Expandable section
  Widget _buildDetailedAnalytics() {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.2)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _isDetailedAnalyticsExpanded = !_isDetailedAnalyticsExpanded;
              });
            },
            borderRadius: BorderRadius.circular(6),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: colorScheme.primary,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    _isDetailedAnalyticsExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          if (_isDetailedAnalyticsExpanded) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildSpendingTrendChart(),
            const SizedBox(height: AppSpacing.sm),
            _buildCategoryBreakdownChart(),
            const SizedBox(height: AppSpacing.sm),
            _buildSpendingOverview(),
            const SizedBox(height: AppSpacing.sm),
            _buildSpendingPrediction(),
          ],
        ],
      ),
    );
  }

  // Helper methods for Financial Health Score
  int _calculateFinancialHealthScore() {
    int score = 50; // Base score

    // Factor 1: Spending trend (30 points)
    if (_lastMonthSpending > 0) {
      double changePercent = _calculateMonthlyChangeValue();
      if (changePercent < -10)
        score += 30; // Much less spending
      else if (changePercent < 0)
        score += 20; // Less spending
      else if (changePercent < 10)
        score += 10; // Similar spending
      else
        score -= 20; // Much more spending
    }

    // Factor 2: Goal progress (25 points)
    if (_goalStats != null) {
      double progress = _goalStats!['overallProgress'] ?? 0.0;
      score += (progress * 25).round();
    }

    // Factor 3: Spending distribution (25 points)
    if (_categoryPercentage < 50)
      score += 25; // Good diversification
    else if (_categoryPercentage < 70)
      score += 15; // Okay diversification
    else
      score += 5; // Poor diversification

    // Factor 4: Transaction count (20 points) - More tracking = better
    if (_transactions.length > 20)
      score += 20;
    else if (_transactions.length > 10)
      score += 15;
    else if (_transactions.length > 5)
      score += 10;
    else
      score += 5;

    return score.clamp(0, 100);
  }

  String _getHealthStatus(int score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Good';
    if (score >= 50) return 'Fair';
    if (score >= 35) return 'Needs Attention';
    return 'Poor';
  }

  Color _getHealthColor(int score) {
    if (score >= 80) return _getThemeColor('success');
    if (score >= 65) return _getThemeColor('primary');
    if (score >= 50) return _getThemeColor('warning');
    return _getThemeColor('error');
  }

  List<AIInsight> _getPriorityInsights() {
    // Filter and sort insights by relevance and severity
    List<AIInsight> filteredInsights =
        _aiInsights.where((insight) {
          // Filter out generic or low-value insights
          final title = insight.title.toLowerCase();
          final description = insight.description.toLowerCase();

          // Skip overly generic insights
          if (title.contains('general') ||
              title.contains('basic') ||
              title.contains('simple')) {
            return false;
          }

          // Skip very short descriptions (likely not meaningful)
          if (description.length < 30) {
            return false;
          }

          return true;
        }).toList();

    // Sort by severity, type, and relevance
    filteredInsights.sort((a, b) {
      // Primary sort: severity
      int severityCompare = _getSeverityOrder(
        b.severity,
      ).compareTo(_getSeverityOrder(a.severity));
      if (severityCompare != 0) return severityCompare;

      // Secondary sort: prioritize actionable negative insights
      if (a.type == 'negative' && b.type != 'negative') return -1;
      if (b.type == 'negative' && a.type != 'negative') return 1;

      // Tertiary sort: prioritize insights with specific financial terms
      int aRelevance = _calculateInsightRelevance(a);
      int bRelevance = _calculateInsightRelevance(b);
      return bRelevance.compareTo(aRelevance);
    });

    return filteredInsights;
  }

  /// Calculate insight relevance score based on content
  int _calculateInsightRelevance(AIInsight insight) {
    int score = 0;
    final content = '${insight.title} ${insight.description}'.toLowerCase();

    // Higher score for specific financial terms
    if (content.contains('spending') || content.contains('expense')) score += 3;
    if (content.contains('budget') || content.contains('limit')) score += 3;
    if (content.contains('goal') || content.contains('saving')) score += 2;
    if (content.contains('category') || content.contains('pattern')) score += 2;
    if (content.contains('increase') || content.contains('decrease'))
      score += 2;
    if (content.contains('alert') || content.contains('warning')) score += 1;

    // Higher score for actionable content
    if (content.contains('reduce') || content.contains('optimize')) score += 2;
    if (content.contains('consider') || content.contains('should')) score += 1;

    return score;
  }

  int _getSeverityOrder(String severity) {
    switch (severity) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Get priority order for recommendations
  int _getPriorityOrder(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }

  /// Calculate recommendation relevance score
  int _calculateRecommendationRelevance(AIRecommendation recommendation) {
    int score = 0;
    final content =
        '${recommendation.title} ${recommendation.description} ${recommendation.action}'
            .toLowerCase();

    // Higher score for actionable recommendations
    if (content.contains('save') || content.contains('reduce')) score += 3;
    if (content.contains('budget') || content.contains('limit')) score += 3;
    if (content.contains('goal') || content.contains('target')) score += 2;
    if (content.contains('category') || content.contains('spending'))
      score += 2;
    if (content.contains('optimize') || content.contains('improve')) score += 2;
    if (content.contains('track') || content.contains('monitor')) score += 1;

    // Higher score for specific financial amounts
    if (content.contains('\$') || content.contains('percent')) score += 1;

    // Higher score for time-sensitive recommendations
    if (content.contains('now') || content.contains('today')) score += 1;
    if (content.contains('this month') || content.contains('weekly'))
      score += 1;

    return score;
  }

  Widget _buildPriorityInsightTile(AIInsight insight) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getInsightColor() {
      switch (insight.type) {
        case 'positive':
          return _getThemeColor('success');
        case 'negative':
          return _getThemeColor('error');
        default:
          return _getThemeColor('info');
      }
    }

    IconData getInsightIcon() {
      switch (insight.type) {
        case 'positive':
          return Icons.trending_up_rounded;
        case 'negative':
          return Icons.trending_down_rounded;
        default:
          return Icons.info_outline_rounded;
      }
    }

    final color = getInsightColor();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(
                  context,
                ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(getInsightIcon(), color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.description,
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              insight.severity.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartRecommendationTile(AIRecommendation recommendation) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color getPriorityColor() {
      switch (recommendation.priority) {
        case 'high':
          return _getThemeColor('error');
        case 'medium':
          return _getThemeColor('warning');
        default:
          return _getThemeColor('info');
      }
    }

    final color = getPriorityColor();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.lightbulb_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  recommendation.priority.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            recommendation.description,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.savings_outlined,
                          color: _getThemeColor('success'),
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          recommendation.potentialSavings,
                          style: TextStyle(
                            color: _getThemeColor('success'),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => _handleRecommendationAction(recommendation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Take Action',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyPriorityInsights() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(Icons.insights, color: colorScheme.onSurfaceVariant, size: 24),
          const SizedBox(height: 6),
          Text(
            'Analyzing your data...',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Add more transactions for insights',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecommendations() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(
            Icons.tips_and_updates,
            color: colorScheme.onSurfaceVariant,
            size: 24,
          ),
          const SizedBox(height: 6),
          Text(
            'No recommendations yet',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Keep tracking expenses for recommendations',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingRecommendations() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Generating recommendations...',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  /// Show time filter bottom sheet
  void _showTimeFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final colorScheme = Theme.of(context).colorScheme;
        final isDark = Theme.of(context).brightness == Brightness.dark;

        return Container(
          decoration: BoxDecoration(
            color:
                isDark
                    ? colorScheme.surface
                    : colorScheme.surfaceContainerHighest,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Select Time Period',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 16),

              // Filter options
              ..._timeFilterOptions.map((filter) {
                final isSelected = filter == _selectedTimeFilter;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      Navigator.of(context).pop();
                      _updateTimeFilter(filter);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? colorScheme.primary.withValues(alpha: 0.1)
                                : colorScheme.surfaceContainer.withValues(
                                  alpha: 0.3,
                                ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isSelected
                                  ? colorScheme.primary.withValues(alpha: 0.3)
                                  : colorScheme.outlineVariant.withValues(
                                    alpha: 0.2,
                                  ),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? colorScheme.primary.withValues(
                                        alpha: 0.2,
                                      )
                                      : colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _getFilterIcon(filter),
                              size: 16,
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getFilterDisplayName(filter),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isSelected
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _getFilterDescription(filter),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),

              // Safe area padding
              SizedBox(height: MediaQuery.of(context).padding.bottom),
            ],
          ),
        );
      },
    );
  }

  /// Update time filter and refresh data
  void _updateTimeFilter(String newFilter) {
    setState(() {
      _selectedTimeFilter = newFilter;
    });
    _loadInsightData(); // Refresh all data with new filter
  }

  /// Update filter dates based on selected time filter
  void _updateFilterDates() {
    final now = DateTime.now();
    switch (_selectedTimeFilter) {
      case '7D':
        _filterStartDate = now.subtract(Duration(days: 7));
        _filterEndDate = now;
        break;
      case '30D':
        _filterStartDate = now.subtract(Duration(days: 30));
        _filterEndDate = now;
        break;
      case '90D':
        _filterStartDate = now.subtract(Duration(days: 90));
        _filterEndDate = now;
        break;
      case '1Y':
        _filterStartDate = now.subtract(Duration(days: 365));
        _filterEndDate = now;
        break;
      default:
        _filterStartDate = now.subtract(Duration(days: 30));
        _filterEndDate = now;
    }
  }

  /// Filter transactions by current time filter
  List<Transaction> _filterTransactionsByTime(List<Transaction> transactions) {
    if (_filterStartDate == null || _filterEndDate == null) {
      _updateFilterDates();
    }

    return transactions.where((transaction) {
      return transaction.date.isAfter(_filterStartDate!) &&
          transaction.date.isBefore(_filterEndDate!);
    }).toList();
  }

  /// Get period duration for calculations
  Duration _getPeriodDuration() {
    switch (_selectedTimeFilter) {
      case '7D':
        return Duration(days: 7);
      case '30D':
        return Duration(days: 30);
      case '90D':
        return Duration(days: 90);
      case '1Y':
        return Duration(days: 365);
      default:
        return Duration(days: 30);
    }
  }

  /// Get display name for filter option
  String _getFilterDisplayName(String filter) {
    switch (filter) {
      case '7D':
        return 'Last 7 Days';
      case '30D':
        return 'Last 30 Days';
      case '90D':
        return 'Last 3 Months';
      case '1Y':
        return 'Last Year';
      default:
        return filter;
    }
  }

  /// Get description for filter option
  String _getFilterDescription(String filter) {
    final now = DateTime.now();
    DateTime startDate;

    switch (filter) {
      case '7D':
        startDate = now.subtract(Duration(days: 7));
        break;
      case '30D':
        startDate = now.subtract(Duration(days: 30));
        break;
      case '90D':
        startDate = now.subtract(Duration(days: 90));
        break;
      case '1Y':
        startDate = now.subtract(Duration(days: 365));
        break;
      default:
        startDate = now.subtract(Duration(days: 30));
    }

    return '${startDate.day}/${startDate.month} - ${now.day}/${now.month}';
  }

  /// Build time filter indicator
  Widget _buildTimeFilterIndicator() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: _showTimeFilterDialog,
        borderRadius: BorderRadius.circular(20),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.access_time, size: 16, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              _getFilterDisplayName(_selectedTimeFilter),
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down,
              size: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  /// Build interactive spending trend chart
  Widget _buildSpendingTrendChart() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark
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
          Row(
            children: [
              Icon(Icons.trending_up, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _buildLineChart()),
        ],
      ),
    );
  }

  /// Build category breakdown pie chart
  Widget _buildCategoryBreakdownChart() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            isDark
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
          Row(
            children: [
              Icon(Icons.pie_chart, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: _buildPieChart()),
        ],
      ),
    );
  }

  /// Build line chart for spending trends
  Widget _buildLineChart() {
    final chartData = _generateChartData();
    final colorScheme = Theme.of(context).colorScheme;

    if (chartData.isEmpty) {
      return Center(
        child: Text(
          'No data available for selected period',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: null,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value.toInt() >= 0 && value.toInt() < chartData.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      chartData[value.toInt()]['label'],
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  );
                }
                return Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (double value, TitleMeta meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        minX: 0,
        maxX: (chartData.length - 1).toDouble(),
        minY: 0,
        maxY:
            chartData.isNotEmpty
                ? chartData
                        .map((d) => d['amount'] as double)
                        .reduce((a, b) => a > b ? a : b) *
                    1.2
                : 100,
        lineBarsData: [
          LineChartBarData(
            spots:
                chartData.asMap().entries.map((entry) {
                  return FlSpot(
                    entry.key.toDouble(),
                    entry.value['amount'] as double,
                  );
                }).toList(),
            isCurved: true,
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: colorScheme.primary,
                  strokeWidth: 2,
                  strokeColor: colorScheme.surface,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary.withValues(alpha: 0.3),
                  colorScheme.primary.withValues(alpha: 0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
              return touchedBarSpots.map((barSpot) {
                final index = barSpot.x.toInt();
                if (index >= 0 && index < chartData.length) {
                  return LineTooltipItem(
                    '${chartData[index]['label']}\n\$${barSpot.y.toStringAsFixed(0)}',
                    TextStyle(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  );
                }
                return null;
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  /// Build pie chart for category breakdown
  Widget _buildPieChart() {
    final categoryData = _generateCategoryChartData();
    final colorScheme = Theme.of(context).colorScheme;

    if (categoryData.isEmpty) {
      return Center(
        child: Text(
          'No category data available',
          style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          flex: 2,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  // Handle touch interactions if needed
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections:
                  categoryData.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value;
                    final color = _getCategoryColor(index);

                    return PieChartSectionData(
                      color: color,
                      value: data['amount'] as double,
                      title: '${data['percentage'].toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:
                categoryData.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final color = _getCategoryColor(index);

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['category'] as String,
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  /// Generate data for spending trend chart
  List<Map<String, dynamic>> _generateChartData() {
    final filteredTransactions = _filterTransactionsByTime(_transactions);
    final expenses =
        filteredTransactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    if (expenses.isEmpty) return [];

    // Group by time period based on filter
    final chartData = <Map<String, dynamic>>[];
    final now = DateTime.now();

    switch (_selectedTimeFilter) {
      case '7D':
        // Daily data for last 7 days
        for (int i = 6; i >= 0; i--) {
          final date = now.subtract(Duration(days: i));
          final dayExpenses =
              expenses
                  .where(
                    (t) =>
                        t.date.year == date.year &&
                        t.date.month == date.month &&
                        t.date.day == date.day,
                  )
                  .toList();

          final total = dayExpenses.fold(0.0, (sum, t) => sum + t.amount.abs());
          chartData.add({
            'label': '${date.day}/${date.month}',
            'amount': total,
            'date': date,
          });
        }
        break;

      case '30D':
        // Weekly data for last 30 days
        for (int i = 3; i >= 0; i--) {
          final weekStart = now.subtract(Duration(days: (i * 7) + 6));
          final weekEnd = now.subtract(Duration(days: i * 7));

          final weekExpenses =
              expenses
                  .where(
                    (t) =>
                        t.date.isAfter(weekStart) &&
                        t.date.isBefore(weekEnd.add(Duration(days: 1))),
                  )
                  .toList();

          final total = weekExpenses.fold(
            0.0,
            (sum, t) => sum + t.amount.abs(),
          );
          chartData.add({
            'label': 'W${4 - i}',
            'amount': total,
            'date': weekStart,
          });
        }
        break;

      case '90D':
      case '1Y':
        // Monthly data
        final monthsToShow = _selectedTimeFilter == '90D' ? 3 : 12;
        for (int i = monthsToShow - 1; i >= 0; i--) {
          final monthDate = DateTime(now.year, now.month - i);
          final monthExpenses =
              expenses
                  .where(
                    (t) =>
                        t.date.year == monthDate.year &&
                        t.date.month == monthDate.month,
                  )
                  .toList();

          final total = monthExpenses.fold(
            0.0,
            (sum, t) => sum + t.amount.abs(),
          );
          chartData.add({
            'label': _getMonthAbbr(monthDate.month),
            'amount': total,
            'date': monthDate,
          });
        }
        break;
    }

    return chartData;
  }

  /// Generate data for category pie chart
  List<Map<String, dynamic>> _generateCategoryChartData() {
    final filteredTransactions = _filterTransactionsByTime(_transactions);
    final expenses =
        filteredTransactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    if (expenses.isEmpty) return [];

    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount.abs();
    }

    final totalSpending = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    if (totalSpending == 0) return [];

    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    // Take top 5 categories and group the rest as "Others"
    final chartData = <Map<String, dynamic>>[];
    final topCategories = sortedCategories.take(5).toList();

    for (final entry in topCategories) {
      final percentage = (entry.value / totalSpending) * 100;
      chartData.add({
        'category': entry.key,
        'amount': entry.value,
        'percentage': percentage,
      });
    }

    if (sortedCategories.length > 5) {
      final othersTotal = sortedCategories
          .skip(5)
          .fold(0.0, (sum, entry) => sum + entry.value);
      final othersPercentage = (othersTotal / totalSpending) * 100;
      chartData.add({
        'category': 'Others',
        'amount': othersTotal,
        'percentage': othersPercentage,
      });
    }

    return chartData;
  }

  /// Get color for category at index
  Color _getCategoryColor(int index) {
    final colors = [
      const Color(0xFF6366F1), // Primary
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFF10B981), // Green
      const Color(0xFFF59E0B), // Amber
      const Color(0xFFEF4444), // Red
    ];
    return colors[index % colors.length];
  }

  /// Get month abbreviation
  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  /// Get icon for time filter option
  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case '7D':
        return Icons.view_week;
      case '30D':
        return Icons.calendar_month;
      case '90D':
        return Icons.calendar_view_month;
      case '1Y':
        return Icons.calendar_today;
      default:
        return Icons.access_time;
    }
  }

  /// Handle recommendation action button press
  void _handleRecommendationAction(AIRecommendation recommendation) {
    // Analyze the recommendation to determine the appropriate action
    final action = recommendation.action.toLowerCase();
    final title = recommendation.title.toLowerCase();
    final description = recommendation.description.toLowerCase();

    // Show action options dialog
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildActionBottomSheet(recommendation),
    );
  }

  /// Build action bottom sheet with contextual options
  Widget _buildActionBottomSheet(AIRecommendation recommendation) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Determine primary action based on recommendation content
    final actionType = _determineActionType(recommendation);

    return Container(
      decoration: BoxDecoration(
        color:
            isDark ? colorScheme.surface : colorScheme.surfaceContainerHighest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle indicator
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            'Take Action: ${recommendation.title}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            recommendation.description,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),

          // Action buttons based on recommendation type
          ...actionType.actions
              .map((action) => _buildActionButton(action))
              .toList(),

          const SizedBox(height: 12),

          // Cancel button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
          ),

          // Safe area padding
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  /// Build individual action button
  Widget _buildActionButton(RecommendationAction action) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.of(context).pop();
          action.onPressed();
        },
        icon: Icon(action.icon, size: 20),
        label: Text(action.label),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              action.isPrimary
                  ? colorScheme.primary
                  : colorScheme.surfaceContainer,
          foregroundColor:
              action.isPrimary ? Colors.white : colorScheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  /// Determine action type based on recommendation content
  RecommendationActionType _determineActionType(
    AIRecommendation recommendation,
  ) {
    final content =
        '${recommendation.title} ${recommendation.description} ${recommendation.action}'
            .toLowerCase();

    // Budget-related recommendations
    if (content.contains('budget') ||
        content.contains('spending') ||
        content.contains('reduce')) {
      return RecommendationActionType(
        type: 'budget',
        actions: [
          RecommendationAction(
            label: 'Create Budget Plan',
            icon: Icons.account_balance_wallet,
            isPrimary: true,
            onPressed: () => _navigateToCreateBudget(),
          ),
          RecommendationAction(
            label: 'View Transactions',
            icon: Icons.list_alt,
            isPrimary: false,
            onPressed: () => _navigateToTransactions(),
          ),
          RecommendationAction(
            label: 'Set Spending Alert',
            icon: Icons.notification_add,
            isPrimary: false,
            onPressed: () => _showSpendingAlertDialog(),
          ),
        ],
      );
    }

    // Goal-related recommendations
    if (content.contains('goal') ||
        content.contains('saving') ||
        content.contains('save')) {
      return RecommendationActionType(
        type: 'goal',
        actions: [
          RecommendationAction(
            label: 'Create Savings Goal',
            icon: Icons.savings,
            isPrimary: true,
            onPressed: () => _navigateToCreateGoal(),
          ),
          RecommendationAction(
            label: 'View Goals',
            icon: Icons.flag,
            isPrimary: false,
            onPressed: () => _navigateToGoals(),
          ),
          RecommendationAction(
            label: 'Add Money to Goal',
            icon: Icons.add_circle,
            isPrimary: false,
            onPressed: () => _showAddToGoalDialog(),
          ),
        ],
      );
    }

    // Category-specific recommendations
    if (content.contains('category') ||
        content.contains('food') ||
        content.contains('entertainment')) {
      return RecommendationActionType(
        type: 'category',
        actions: [
          RecommendationAction(
            label: 'View Category Details',
            icon: Icons.category,
            isPrimary: true,
            onPressed: () => _navigateToTransactions(),
          ),
          RecommendationAction(
            label: 'Set Category Limit',
            icon: Icons.block,
            isPrimary: false,
            onPressed: () => _showCategoryLimitDialog(),
          ),
          RecommendationAction(
            label: 'Add Transaction',
            icon: Icons.add,
            isPrimary: false,
            onPressed: () => _navigateToAddTransaction(),
          ),
        ],
      );
    }

    // Default generic actions
    return RecommendationActionType(
      type: 'general',
      actions: [
        RecommendationAction(
          label: 'View Transactions',
          icon: Icons.list_alt,
          isPrimary: true,
          onPressed: () => _navigateToTransactions(),
        ),
        RecommendationAction(
          label: 'Add Transaction',
          icon: Icons.add,
          isPrimary: false,
          onPressed: () => _navigateToAddTransaction(),
        ),
        RecommendationAction(
          label: 'Create Goal',
          icon: Icons.flag,
          isPrimary: false,
          onPressed: () => _navigateToCreateGoal(),
        ),
      ],
    );
  }

  /// Navigation methods
  void _navigateToTransactions() {
    context.go('/transactions');
  }

  void _navigateToCreateGoal() {
    context.go('/goals');
  }

  void _navigateToGoals() {
    context.go('/goals');
  }

  void _navigateToCreateBudget() {
    // Navigate to budget creation or show budget setup dialog
    _showBudgetSetupDialog();
  }

  void _navigateToAddTransaction() {
    context.go('/create-transaction');
  }

  /// Dialog methods for specific actions
  void _showSpendingAlertDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Set Spending Alert'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up spending alerts to get notified when you exceed your budget.',
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Alert Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Spending alert set successfully!')),
                  );
                },
                child: Text('Set Alert'),
              ),
            ],
          ),
    );
  }

  void _showAddToGoalDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Add Money to Goal'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Add money to your existing savings goals.'),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Amount (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/goals');
                },
                child: Text('Go to Goals'),
              ),
            ],
          ),
    );
  }

  void _showCategoryLimitDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Set Category Limit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Set a spending limit for this category.'),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Monthly Limit (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category limit set successfully!')),
                  );
                },
                child: Text('Set Limit'),
              ),
            ],
          ),
    );
  }

  void _showBudgetSetupDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Create Budget Plan'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Set up a monthly budget based on your spending patterns.',
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Monthly Budget (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Budget plan created successfully!'),
                    ),
                  );
                },
                child: Text('Create Budget'),
              ),
            ],
          ),
    );
  }

  void _showInsightDetails(BuildContext context, Map<String, dynamic> insight) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(insight['title'] ?? 'Insight Details'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight['description'] ?? 'No additional details available.',
                ),
                if (insight['recommendation'] != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Recommendation:',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(insight['recommendation']),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              if (insight['action'] != null)
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Handle specific actions based on the insight
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Action noted! Check the relevant section for next steps.',
                        ),
                      ),
                    );
                  },
                  child: Text(insight['action']),
                ),
            ],
          ),
    );
  }

  // Enhanced widget helper methods
  void _handleInsightFeedback(AIInsight insight, bool isHelpful) {
    // Log feedback for personalization (could be sent to analytics)
    print(
      'Insight feedback: ${insight.title} - ${isHelpful ? 'helpful' : 'not helpful'}',
    );

    // Show user confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thanks for your feedback!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String? _getInsightActionLabel(AIInsight insight) {
    final titleLower = insight.title.toLowerCase();
    final descriptionLower = insight.description.toLowerCase();

    if (titleLower.contains('spending') ||
        descriptionLower.contains('spending')) {
      return 'View Transactions';
    } else if (titleLower.contains('goal') ||
        descriptionLower.contains('goal')) {
      return 'View Goals';
    } else if (titleLower.contains('budget') ||
        descriptionLower.contains('budget')) {
      return 'Set Budget';
    } else if (titleLower.contains('category') ||
        descriptionLower.contains('category')) {
      return 'Filter Category';
    }

    return 'Learn More';
  }

  void _handleInsightAction(AIInsight insight) {
    final titleLower = insight.title.toLowerCase();
    final descriptionLower = insight.description.toLowerCase();

    try {
      if (titleLower.contains('spending') ||
          descriptionLower.contains('spending')) {
        context.go('/transactions');
      } else if (titleLower.contains('goal') ||
          descriptionLower.contains('goal')) {
        context.go('/goals');
      } else if (titleLower.contains('budget') ||
          descriptionLower.contains('budget')) {
        // For now, navigate to transactions as we don't have a budget page
        context.go('/transactions');
      } else {
        // Default action - go to dashboard
        context.go('/dashboard');
      }
    } catch (e) {
      // Fallback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Opening related feature...'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _handleRecommendationFeedback(
    AIRecommendation recommendation,
    bool isHelpful,
  ) {
    // Log feedback for AI improvement
    print(
      'Recommendation feedback: ${recommendation.title} - ${isHelpful ? 'helpful' : 'not helpful'}',
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thanks for rating this recommendation!'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _handleRecommendationComplete(AIRecommendation recommendation) {
    // Mark recommendation as completed
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Great job completing: ${recommendation.title}'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            // Handle undo logic if needed
          },
        ),
      ),
    );
  }

  /// Build compact insight card with progressive disclosure
  Widget _buildCompactInsightCard(AIInsight insight) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.4)
                : colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: _getInsightAccentColor(insight).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Simple severity indicator
          Container(
            width: 4,
            height: 32,
            decoration: BoxDecoration(
              color: _getInsightAccentColor(insight),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _getTruncatedDescription(insight.description, 80),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Action button
          TextButton(
            onPressed: () => _showInsightDialog(insight),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'View',
              style: TextStyle(
                fontSize: 12,
                color: _getInsightAccentColor(insight),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build compact recommendation card
  Widget _buildCompactRecommendationCard(AIRecommendation recommendation) {
    final colorScheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.4)
                : colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: _getRecommendationAccentColor(
            recommendation,
          ).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Priority indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getRecommendationAccentColor(
                    recommendation,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  recommendation.priority.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getRecommendationAccentColor(recommendation),
                  ),
                ),
              ),
              const Spacer(),

              // Action button
              TextButton(
                onPressed: () => _showRecommendationDialog(recommendation),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Act',
                  style: TextStyle(
                    fontSize: 12,
                    color: _getRecommendationAccentColor(recommendation),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),

          Text(
            recommendation.title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            _getTruncatedDescription(recommendation.description, 90),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Build show more insights button
  Widget _buildShowMoreInsightsButton(int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showAllInsights = !_showAllInsights;
          });
        },
        icon: Icon(
          _showAllInsights ? Icons.expand_less : Icons.expand_more,
          size: 16,
        ),
        label: Text(
          _showAllInsights ? 'Show Less' : 'View All ($totalCount)',
          style: TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.primary,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  /// Build show more recommendations button
  Widget _buildShowMoreRecommendationsButton(int totalCount) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () {
          setState(() {
            _showAllRecommendations = !_showAllRecommendations;
          });
        },
        icon: Icon(
          _showAllRecommendations ? Icons.expand_less : Icons.expand_more,
          size: 16,
        ),
        label: Text(
          _showAllRecommendations ? 'Show Less' : 'View All ($totalCount)',
          style: TextStyle(fontSize: 12),
        ),
        style: TextButton.styleFrom(
          foregroundColor: colorScheme.secondary,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
      ),
    );
  }

  /// Helper methods for the new design
  String _getTruncatedDescription(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength).trim()}...';
  }

  Color _getInsightAccentColor(AIInsight insight) {
    switch (insight.severity.toLowerCase()) {
      case 'high':
        return _getThemeColor('error');
      case 'medium':
        return _getThemeColor('warning');
      default:
        return _getThemeColor('info');
    }
  }

  Color _getRecommendationAccentColor(AIRecommendation recommendation) {
    switch (recommendation.priority.toLowerCase()) {
      case 'high':
        return _getThemeColor('error');
      case 'medium':
        return _getThemeColor('warning');
      default:
        return _getThemeColor('info');
    }
  }

  /// Show detailed insight in a dialog
  void _showInsightDialog(AIInsight insight) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getInsightIcon(insight),
                  color: _getInsightAccentColor(insight),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getInsightAccentColor(
                      insight,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${insight.severity.toUpperCase()} PRIORITY',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: _getInsightAccentColor(insight),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(insight.description, style: TextStyle(height: 1.4)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleInsightAction(insight);
                },
                child: Text(_getInsightActionLabel(insight) ?? 'Take Action'),
              ),
            ],
          ),
    );
  }

  /// Show detailed recommendation in a dialog
  void _showRecommendationDialog(AIRecommendation recommendation) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: _getRecommendationAccentColor(recommendation),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getRecommendationAccentColor(
                          recommendation,
                        ).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${recommendation.priority.toUpperCase()} PRIORITY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: _getRecommendationAccentColor(recommendation),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.savings,
                      size: 14,
                      color: _getThemeColor('success'),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      recommendation.potentialSavings,
                      style: TextStyle(
                        fontSize: 12,
                        color: _getThemeColor('success'),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(recommendation.description, style: TextStyle(height: 1.4)),
                const SizedBox(height: 8),
                Text(
                  'Suggested Action: ${recommendation.action}',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _handleRecommendationAction(recommendation);
                },
                child: Text('Take Action'),
              ),
            ],
          ),
    );
  }

  IconData _getInsightIcon(AIInsight insight) {
    switch (insight.type.toLowerCase()) {
      case 'positive':
        return Icons.trending_up;
      case 'negative':
        return Icons.trending_down;
      default:
        return Icons.info_outline;
    }
  }
}

/// Helper classes for recommendation actions
class RecommendationActionType {
  final String type;
  final List<RecommendationAction> actions;

  RecommendationActionType({required this.type, required this.actions});
}

class RecommendationAction {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onPressed;

  RecommendationAction({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onPressed,
  });
}
