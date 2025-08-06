import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../shared/widgets/main_navigation_wrapper.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/app_settings_menu.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/services/ai_service.dart';
import '../../../../shared/models/ai_insight_model.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../../models/transaction.dart';
import '../widgets/expandable_insight_card.dart';
import '../widgets/smart_recommendation_card.dart';

class AIInsightsPage extends StatefulWidget {
  const AIInsightsPage({Key? key}) : super(key: key);

  @override
  State<AIInsightsPage> createState() => _AIInsightsPageState();
}

class _AIInsightsPageState extends State<AIInsightsPage> {
  // Core state
  bool _isLoadingAI = false;
  bool _isLoadingTransactions = false;
  String _aiError = '';
  
  // Data
  List<Transaction> _transactions = [];
  List<AIInsight> _aiInsights = [];
  List<AIRecommendation> _aiRecommendations = [];
  String _spendingPrediction = '';
  
  // AI Service
  AIService? _aiService;
  
  // Analytics
  double _financialHealthScore = 0.0;
  double _thisMonthSpending = 0.0;
  double _lastMonthSpending = 0.0;
  String _topSpendingCategory = 'Food';
  String _selectedTimeFrame = '30D';
  List<FlSpot> _spendingTrendData = [];
  
  // Cache
  DateTime? _lastAIUpdate;
  static const Duration _aiCacheValidDuration = Duration(hours: 4);
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _initializeAIService();
    _loadTransactions();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _initializeAIService() {
    try {
      _aiService = AIService();
    } catch (e) {
      if (kDebugMode) {
        print('AI Service initialization failed: $e');
      }
      setState(() {
        _aiError = 'AI features unavailable';
      });
    }
  }

  Future<void> _loadTransactions() async {
    if (_isDisposed) return;
    
    setState(() {
      _isLoadingTransactions = true;
    });

    try {
      final transactions = await TransactionService().getAllTransactions();
      if (!_isDisposed) {
        setState(() {
          _transactions = transactions;
          _calculateBasicAnalytics(transactions);
          _generateSpendingTrendData(transactions);
          _isLoadingTransactions = false;
        });
        
        // Load AI insights if available
        if (_shouldRefreshAI()) {
          _loadAIInsights();
        }
      }
    } catch (e) {
      if (!_isDisposed) {
        setState(() {
          _isLoadingTransactions = false;
        });
      }
    }
  }

  bool _shouldRefreshAI() {
    if (_aiService == null) return false;
    if (_lastAIUpdate == null) return true;
    return DateTime.now().difference(_lastAIUpdate!) > _aiCacheValidDuration;
  }

  Future<void> _loadAIInsights() async {
    if (_isDisposed || _aiService == null || _transactions.isEmpty) return;
    
    setState(() {
      _isLoadingAI = true;
      _aiError = '';
    });

    try {
      // Get goal stats for context
      final goalStats = await _getGoalStats();
      
      // Generate AI insights
      final aiResponse = await _aiService!.generateInsights(_transactions);
      final recommendations = await _aiService!.generateRecommendations(_transactions, goalStats);
      final prediction = await _aiService!.generateSpendingPredictions(_transactions);
      
      if (!_isDisposed) {
        setState(() {
          _aiInsights = aiResponse.insights;
          _aiRecommendations = recommendations;
          _spendingPrediction = prediction;
          _lastAIUpdate = DateTime.now();
          _isLoadingAI = false;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI insights generation failed: $e');
      }
      if (!_isDisposed) {
        setState(() {
          _aiError = 'Failed to generate AI insights';
          _isLoadingAI = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>?> _getGoalStats() async {
    try {
      final goals = await GoalService().getAllGoals();
      if (goals.isEmpty) return null;
      
      final completedGoals = goals.where((g) => g.currentAmount >= g.targetAmount).length;
      final totalProgress = goals.fold(0.0, (sum, g) => sum + (g.currentAmount / g.targetAmount)) / goals.length;
      
      return {
        'totalGoals': goals.length,
        'completedGoals': completedGoals,
        'overallProgress': totalProgress.clamp(0.0, 1.0),
      };
    } catch (e) {
      return null;
    }
  }

  void _calculateBasicAnalytics(List<Transaction> transactions) {
    final now = DateTime.now();
    final thisMonth = DateTime(now.year, now.month);
    final lastMonth = DateTime(now.year, now.month - 1);
    
    final expenses = transactions.where((t) => 
      t.type.toLowerCase() == 'expense' || t.amount < 0
    ).toList();
    
    _thisMonthSpending = expenses
      .where((t) => t.date.isAfter(thisMonth))
      .fold(0.0, (sum, t) => sum + t.amount.abs());
    
    _lastMonthSpending = expenses
      .where((t) => t.date.isAfter(lastMonth) && t.date.isBefore(thisMonth))
      .fold(0.0, (sum, t) => sum + t.amount.abs());
    
    // Calculate financial health score
    _financialHealthScore = _calculateFinancialHealthScore(expenses);
    
    // Find top spending category
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] = 
        (categoryTotals[expense.category] ?? 0.0) + expense.amount.abs();
    }
    
    if (categoryTotals.isNotEmpty) {
      _topSpendingCategory = categoryTotals.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    }
  }

  double _calculateFinancialHealthScore(List<Transaction> expenses) {
    if (expenses.isEmpty) return 75.0;
    
    // Base score
    double score = 100.0;
    
    // Spending consistency (lower variance = higher score)
    if (expenses.length >= 7) {
      final dailyAmounts = <double>[];
      final lastWeek = DateTime.now().subtract(const Duration(days: 7));
      
      for (int i = 0; i < 7; i++) {
        final day = lastWeek.add(Duration(days: i));
        final dayAmount = expenses
          .where((t) => 
            t.date.year == day.year && 
            t.date.month == day.month && 
            t.date.day == day.day
          )
          .fold(0.0, (sum, t) => sum + t.amount.abs());
        dailyAmounts.add(dayAmount);
      }
      
      if (dailyAmounts.isNotEmpty) {
        final mean = dailyAmounts.reduce((a, b) => a + b) / dailyAmounts.length;
        final variance = dailyAmounts
          .map((x) => (x - mean) * (x - mean))
          .reduce((a, b) => a + b) / dailyAmounts.length;
        
        // Lower variance = better score
        final consistencyScore = (100 - (variance / mean * 100).clamp(0, 50));
        score = (score + consistencyScore) / 2;
      }
    }
    
    return score.clamp(0.0, 100.0);
  }

  void _generateSpendingTrendData(List<Transaction> transactions) {
    final expenses = transactions.where((t) => 
      t.type.toLowerCase() == 'expense' || t.amount < 0
    ).toList();
    
    final last7Days = <FlSpot>[];
    final now = DateTime.now();
    
    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayAmount = expenses
        .where((t) => 
          t.date.year == day.year && 
          t.date.month == day.month && 
          t.date.day == day.day
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());
      
      last7Days.add(FlSpot((6 - i).toDouble(), dayAmount));
    }
    
    _spendingTrendData = last7Days;
  }

  void _refreshInsights() {
    _lastAIUpdate = null; // Force refresh
    _loadTransactions();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MainNavigationWrapper(
      currentIndex: 3, // FIXED: Correct index for AI Insights
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: false,
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
                Icons.filter_alt_outlined,
                color: isDark ? colorScheme.onSurface : Colors.white,
              ),
              onPressed: () => _showTimeFilterDialog(),
              tooltip: 'Filter Time Range',
            ),
            IconButton(
              icon: Icon(
                Icons.refresh,
                color: isDark ? colorScheme.onSurface : Colors.white,
              ),
              onPressed: _refreshInsights,
              tooltip: 'Refresh Insights',
            ),
            AppSettingsMenu(
              iconColor: isDark ? colorScheme.onSurface : Colors.white,
            ),
          ],
        ),
        body: AppGradientBackground(
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeCard(),
                const SizedBox(height: 20),
                
                // Financial Health Score
                _buildFinancialHealthCard(),
                const SizedBox(height: 20),
                
                // Spending Trend Chart
                _buildSpendingTrendChart(),
                const SizedBox(height: 20),
                
                // AI Insights
                _buildAIInsightsList(),
                const SizedBox(height: 20),
                
                // Smart Recommendations
                _buildSmartRecommendations(),
                const SizedBox(height: 20),
                
                // Predictive Analysis
                if (_spendingPrediction.isNotEmpty)
                  _buildPredictiveAnalysis(),
                
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.9),
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
              Icon(Icons.psychology, color: AppTheme.primaryColor, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Financial Intelligence',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${_transactions.length} transactions analyzed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildQuickStat('This Month', '\$${_thisMonthSpending.toStringAsFixed(0)}', 
                _thisMonthSpending > _lastMonthSpending ? Icons.trending_up : Icons.trending_down,
                _thisMonthSpending > _lastMonthSpending ? AppTheme.errorColor : AppTheme.successColor),
              const SizedBox(width: 16),
              _buildQuickStat('Health Score', '${_financialHealthScore.toInt()}%', 
                Icons.favorite, _getHealthScoreColor(_financialHealthScore)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  Widget _buildFinancialHealthCard() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _getHealthScoreColor(_financialHealthScore).withValues(alpha: 0.3),
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
                  color: _getHealthScoreColor(_financialHealthScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.favorite,
                  color: _getHealthScoreColor(_financialHealthScore),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Financial Health Score',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${_financialHealthScore.toInt()}',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: _getHealthScoreColor(_financialHealthScore),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '%',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _getHealthScoreColor(_financialHealthScore),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getHealthScoreColor(_financialHealthScore).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  _getHealthScoreLabel(_financialHealthScore),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getHealthScoreColor(_financialHealthScore),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _getHealthScoreDescription(_financialHealthScore),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthScoreLabel(double score) {
    if (score >= 90) return 'Excellent';
    if (score >= 80) return 'Very Good';
    if (score >= 70) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Attention';
  }

  String _getHealthScoreDescription(double score) {
    if (score >= 80) return 'Your spending patterns are consistent and healthy. Keep up the great work!';
    if (score >= 60) return 'Your financial habits are on the right track with some room for improvement.';
    return 'Consider reviewing your spending patterns for better financial health.';
  }

  Widget _buildSpendingTrendChart() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: 220,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.9),
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
              Icon(Icons.show_chart, color: AppTheme.primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Spending Trend (7 Days)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _spendingTrendData.isNotEmpty
                ? LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: _spendingTrendData,
                          isCurved: true,
                          color: AppTheme.primaryColor,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(show: true),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  )
                : Center(
                    child: Text(
                      'No data available',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIInsightsList() {
    if (_isLoadingAI) {
      return _buildLoadingCard('Generating AI insights...');
    }
    
    if (_aiError.isNotEmpty) {
      return _buildErrorCard(_aiError);
    }
    
    if (_aiInsights.isEmpty) {
      return _buildFallbackInsights();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AI Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._aiInsights.take(5).map((insight) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ExpandableInsightCard(
              insight: insight,
              onFeedback: (isHelpful) {
                // Handle feedback
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSmartRecommendations() {
    if (_aiRecommendations.isEmpty) {
      return _buildFallbackRecommendations();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Recommendations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._aiRecommendations.take(3).map((recommendation) => 
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SmartRecommendationCard(
              recommendation: recommendation,
              onFeedback: (isHelpful) {
                // Handle feedback
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPredictiveAnalysis() {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppTheme.infoColor.withValues(alpha: 0.3),
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
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(
                  Icons.crystal_ball,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Spending Prediction',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _spendingPrediction,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingCard(String message) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(String error) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppTheme.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: AppTheme.errorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackInsights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Financial Insights',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSimpleInsightCard(
          'Spending Analysis',
          'Your ${_topSpendingCategory.toLowerCase()} spending is ${_thisMonthSpending > _lastMonthSpending ? "higher" : "lower"} than last month.',
          _thisMonthSpending > _lastMonthSpending ? Icons.trending_up : Icons.trending_down,
          _thisMonthSpending > _lastMonthSpending ? AppTheme.errorColor : AppTheme.successColor,
        ),
        const SizedBox(height: 12),
        _buildSimpleInsightCard(
          'Financial Health',
          'Your financial health score is ${_financialHealthScore.toInt()}%. ${_getHealthScoreLabel(_financialHealthScore)} performance.',
          Icons.favorite,
          _getHealthScoreColor(_financialHealthScore),
        ),
      ],
    );
  }

  Widget _buildFallbackRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildSimpleInsightCard(
          'Budget Review',
          'Consider reviewing your ${_topSpendingCategory.toLowerCase()} expenses to optimize spending.',
          Icons.account_balance_wallet,
          AppTheme.primaryColor,
        ),
        const SizedBox(height: 12),
        _buildSimpleInsightCard(
          'Savings Opportunity',
          'Track your daily expenses to improve spending consistency.',
          Icons.savings,
          AppTheme.successColor,
        ),
      ],
    );
  }

  Widget _buildSimpleInsightCard(String title, String description, IconData icon, Color color) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.surfaceContainer.withValues(alpha: 0.4)
            : colorScheme.surface.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showTimeFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Filter'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Last 7 Days'),
              leading: Radio<String>(
                value: '7D',
                groupValue: _selectedTimeFrame,
                onChanged: (value) {
                  setState(() {
                    _selectedTimeFrame = value!;
                  });
                  Navigator.pop(context);
                  _generateSpendingTrendData(_transactions);
                },
              ),
            ),
            ListTile(
              title: const Text('Last 30 Days'),
              leading: Radio<String>(
                value: '30D',
                groupValue: _selectedTimeFrame,
                onChanged: (value) {
                  setState(() {
                    _selectedTimeFrame = value!;
                  });
                  Navigator.pop(context);
                  _generateSpendingTrendData(_transactions);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}