import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/ai_insight_model.dart';
import '../config/api_config.dart';
import '../../features/transactions/data/models/transaction_model.dart';

class AIService {
  late final Dio _dio;

  AIService() {
    // Validate API configuration on initialization
    ApiConfig.validateConfig();

    // AI Service initialized successfully

    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.openAiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 30),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${ApiConfig.openAiApiKey}',
        },
      ),
    );
  }

  /// Generate AI insights from transaction data
  Future<AIInsightResponse> generateInsights(
    List<Transaction> transactions,
  ) async {
    try {
      final prompt = _buildSpendingAnalysisPrompt(transactions);

      final requestData = {
        'model': ApiConfig.openAiModel,
        'messages': [
          {
            'role': 'system',
            'content':
                'You are a helpful financial advisor AI that provides insights about spending patterns.',
          },
          {'role': 'user', 'content': prompt},
        ],
        'max_tokens': 1000,
        'temperature': 0.7,
      };

      final response = await _dio.post('/chat/completions', data: requestData);

      if (response.statusCode == 200) {
        final aiResponse =
            response.data['choices'][0]['message']['content'] as String;
        return _parseAIResponse(aiResponse);
      } else {
        throw Exception('AI service returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate AI insights: $e');
    }
  }

  /// Generate spending predictions
  Future<String> generateSpendingPredictions(
    List<Transaction> transactions,
  ) async {
    try {
      final prompt = _buildPredictionPrompt(transactions);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a financial forecasting AI that analyzes spending patterns and provides predictions.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 800,
          'temperature': 0.5,
        },
      );

      if (response.statusCode == 200) {
        return response.data['choices'][0]['message']['content'] as String;
      } else {
        throw Exception('AI service returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate predictions: $e');
    }
  }

  /// Generate personalized recommendations
  Future<List<AIRecommendation>> generateRecommendations(
    List<Transaction> transactions,
    Map<String, dynamic>? goalStats,
  ) async {
    try {
      final prompt = _buildRecommendationPrompt(transactions, goalStats);

      final response = await _dio.post(
        '/chat/completions',
        data: {
          'model': ApiConfig.openAiModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a personal financial advisor AI that provides actionable recommendations based on spending patterns and financial goals.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'max_tokens': 1200,
          'temperature': 0.6,
        },
      );

      if (response.statusCode == 200) {
        final aiResponse =
            response.data['choices'][0]['message']['content'] as String;
        return _parseRecommendations(aiResponse);
      } else {
        throw Exception('AI service returned status ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to generate recommendations: $e');
    }
  }

  /// Build enhanced spending analysis prompt with historical context
  String _buildSpendingAnalysisPrompt(List<Transaction> transactions) {
    final now = DateTime.now();
    final insights = _buildHistoricalAnalysis(transactions);
    final anomalies = _detectSpendingAnomalies(transactions);
    final seasonalPatterns = _analyzeSeasonalPatterns(transactions);

    return '''
You are an expert financial advisor AI with deep analytical capabilities. Analyze the comprehensive spending data below and provide 4-6 key insights that will help the user make better financial decisions.

HISTORICAL SPENDING ANALYSIS:
${insights['historicalSummary']}

MONTHLY BREAKDOWN:
${insights['monthlyBreakdown']}

CATEGORY TRENDS (Last 6 months):
${insights['categoryTrends']}

ANOMALIES DETECTED:
${anomalies.isNotEmpty ? anomalies.join('\n') : 'No significant anomalies detected.'}

SEASONAL PATTERNS:
${seasonalPatterns.isNotEmpty ? seasonalPatterns.join('\n') : 'Insufficient data for seasonal analysis.'}

SPENDING VELOCITY:
${insights['spendingVelocity']}

INSTRUCTIONS:
- Provide insights in valid JSON format only
- Each insight must have: title, description, type (positive/negative/neutral), severity (low/medium/high)
- Prioritize actionable insights over obvious observations
- Focus on trends, patterns, and behavioral changes
- Include specific numbers and percentages where relevant
- Identify both risks and opportunities
- Consider spending acceleration/deceleration
- Highlight unusual category shifts or new spending behaviors

Output format:
{
  "insights": [
    {
      "title": "Category Shift Alert",
      "description": "Entertainment spending increased 45% over 3 months while dining decreased 20% - possible lifestyle change",
      "type": "neutral",
      "severity": "medium"
    }
  ]
}
''';
  }

  /// Build prediction prompt
  String _buildPredictionPrompt(List<Transaction> transactions) {
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // Group by month for trend analysis
    final monthlySpending = <String, double>{};
    for (final transaction in expenses) {
      final monthKey =
          '${transaction.date.year}-${transaction.date.month.toString().padLeft(2, '0')}';
      monthlySpending[monthKey] =
          (monthlySpending[monthKey] ?? 0.0) + transaction.amount.abs();
    }

    return '''
You are a financial forecasting AI. Based on the historical spending data, predict next month's spending.

HISTORICAL DATA:
${monthlySpending.entries.map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}').join('\n')}

REQUIREMENTS:
- Predict next month's total spending
- Identify spending trends (increasing/decreasing/stable)
- Provide confidence level (low/medium/high)
- Give 2-3 specific recommendations
- Keep response under 150 words
- Use conversational tone

Focus on practical insights that help users make better financial decisions.
''';
  }

  /// Build recommendation prompt
  String _buildRecommendationPrompt(
    List<Transaction> transactions,
    Map<String, dynamic>? goalStats,
  ) {
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // Calculate category spending
    final categorySpending = <String, double>{};
    for (final transaction in expenses) {
      categorySpending[transaction.category] =
          (categorySpending[transaction.category] ?? 0.0) +
          transaction.amount.abs();
    }

    final totalSpending = expenses.fold(0.0, (sum, t) => sum + t.amount.abs());

    String goalInfo = '';
    if (goalStats != null) {
      final totalGoals = goalStats['totalGoals'] ?? 0;
      final completedGoals = goalStats['completedGoals'] ?? 0;
      final overallProgress = goalStats['overallProgress'] ?? 0.0;
      goalInfo = '''
GOAL PROGRESS:
- Total goals: $totalGoals
- Completed goals: $completedGoals
- Overall progress: ${(overallProgress * 100).toStringAsFixed(1)}%
''';
    }

    return '''
You are a personal financial advisor AI. Based on spending patterns and goals, provide 3-4 actionable recommendations.

SPENDING DATA:
- Total spending: \$${totalSpending.toStringAsFixed(2)}
- Top categories: ${categorySpending.entries.take(5).map((e) => '${e.key}: \$${e.value.toStringAsFixed(2)}').join(', ')}

$goalInfo

REQUIREMENTS:
- Provide recommendations in JSON format
- Each recommendation should have: title, description, action, potential_savings, priority (high/medium/low)
- Focus on practical, actionable advice
- Consider both spending optimization and goal achievement
- Be specific about amounts and timeframes

Example format:
{
  "recommendations": [
    {
      "title": "Reduce Food Spending",
      "description": "You're spending 30% more on food than recommended",
      "action": "Set a weekly food budget of \$150",
      "potential_savings": "\$200/month",
      "priority": "high"
    }
  ]
}
''';
  }

  /// Parse AI response into structured insights with enhanced error handling
  AIInsightResponse _parseAIResponse(String response) {
    try {
      // Try to extract JSON from the response (more robust regex)
      final jsonMatch = RegExp(
        r'\{[\s\S]*\}',
        multiLine: true,
      ).firstMatch(response);
      if (jsonMatch != null) {
        final jsonString = jsonMatch.group(0)!;
        final jsonData = json.decode(jsonString);
        final insights =
            (jsonData['insights'] as List? ?? [])
                .map((item) => AIInsight.fromJson(item))
                .toList();

        // Validate insights have required fields
        final validInsights =
            insights
                .where(
                  (insight) =>
                      insight.title.isNotEmpty &&
                      insight.description.isNotEmpty &&
                      [
                        'positive',
                        'negative',
                        'neutral',
                      ].contains(insight.type) &&
                      ['low', 'medium', 'high'].contains(insight.severity),
                )
                .toList();

        if (validInsights.isNotEmpty) {
          return AIInsightResponse(insights: validInsights);
        }
      }
    } catch (e) {
      // JSON parsing failed, will use fallback insights
    }

    // Enhanced fallback with multiple insights
    return AIInsightResponse(
      insights: [
        AIInsight(
          title: 'AI Analysis Available',
          description:
              'Financial analysis generated. Review your spending patterns for personalized insights.',
          type: 'neutral',
          severity: 'medium',
        ),
        AIInsight(
          title: 'Data Processing Complete',
          description:
              'Your transaction data has been analyzed. Consider reviewing recent spending trends.',
          type: 'positive',
          severity: 'low',
        ),
      ],
    );
  }

  /// Parse recommendations from AI response
  List<AIRecommendation> _parseRecommendations(String response) {
    try {
      final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(response);
      if (jsonMatch != null) {
        final jsonData = json.decode(jsonMatch.group(0)!);
        return (jsonData['recommendations'] as List? ?? [])
            .map((item) => AIRecommendation.fromJson(item))
            .toList();
      }
    } catch (e) {
      // If JSON parsing fails, create fallback recommendations
    }

    // Fallback: create recommendations from the raw response
    return [
      AIRecommendation(
        title: 'AI Recommendation',
        description:
            response.length > 150
                ? '${response.substring(0, 150)}...'
                : response,
        action: 'Review your spending patterns',
        potentialSavings: 'Varies',
        priority: 'medium',
      ),
    ];
  }

  /// Build detailed category insights
  String _buildCategoryInsights(List<Transaction> expenses) {
    final now = DateTime.now();
    final categoryTotals = <String, double>{};
    final categoryTransactions = <String, List<Transaction>>{};

    // Analyze last 3 months
    final recentExpenses =
        expenses
            .where((t) => t.date.isAfter(DateTime(now.year, now.month - 3)))
            .toList();

    for (final expense in recentExpenses) {
      final category = expense.category;
      categoryTotals[category] =
          (categoryTotals[category] ?? 0.0) + expense.amount.abs();
      categoryTransactions[category] ??= [];
      categoryTransactions[category]!.add(expense);
    }

    final totalSpending = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final insights = <String>[];

    // Top categories analysis
    final sortedCategories =
        categoryTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    for (int i = 0; i < sortedCategories.take(5).length; i++) {
      final entry = sortedCategories[i];
      final percentage = (entry.value / totalSpending) * 100;
      final transactions = categoryTransactions[entry.key]!;
      final avgPerTransaction = entry.value / transactions.length;

      insights.add(
        '${entry.key}: \$${entry.value.toStringAsFixed(0)} (${percentage.toStringAsFixed(0)}%, ${transactions.length} transactions, \$${avgPerTransaction.toStringAsFixed(0)} avg)',
      );
    }

    return insights.join('\n');
  }

  /// Analyze spending behavior patterns
  String _analyzeSpendingBehavior(List<Transaction> expenses) {
    if (expenses.isEmpty) return 'Insufficient data for behavior analysis.';

    final behaviors = <String>[];

    // Transaction frequency analysis
    final transactionsPerDay =
        expenses.length / 30; // Approximate daily frequency
    if (transactionsPerDay > 3) {
      behaviors.add(
        'High transaction frequency (${transactionsPerDay.toStringAsFixed(1)} transactions/day) - suggests frequent small purchases',
      );
    } else if (transactionsPerDay < 1) {
      behaviors.add(
        'Low transaction frequency (${transactionsPerDay.toStringAsFixed(1)} transactions/day) - suggests batched or planned purchases',
      );
    }

    // Average transaction size analysis
    final avgTransaction =
        expenses.fold(0.0, (sum, t) => sum + t.amount.abs()) / expenses.length;
    if (avgTransaction > 100) {
      behaviors.add(
        'High average transaction size (\$${avgTransaction.toStringAsFixed(0)}) - suggests large or planned purchases',
      );
    } else if (avgTransaction < 25) {
      behaviors.add(
        'Low average transaction size (\$${avgTransaction.toStringAsFixed(0)}) - suggests frequent small purchases or micro-transactions',
      );
    }

    // Day-of-week patterns
    final weekdayCount =
        expenses
            .where(
              (t) =>
                  ![
                    DateTime.saturday,
                    DateTime.sunday,
                  ].contains(t.date.weekday),
            )
            .length;
    final weekendCount = expenses.length - weekdayCount;
    if (weekendCount > weekdayCount * 0.5) {
      behaviors.add(
        'Weekend spending pattern detected - ${weekendCount} weekend transactions vs ${weekdayCount} weekday',
      );
    }

    return behaviors.isNotEmpty
        ? behaviors.join('\n')
        : 'Balanced spending behavior patterns detected.';
  }

  /// Identify optimization opportunities
  String _identifyOptimizationOpportunities(List<Transaction> expenses) {
    final opportunities = <String>[];

    // Find recurring transactions (same description/amount)
    final recurringPatterns = <String, List<Transaction>>{};
    for (final expense in expenses) {
      final key =
          '${expense.description.toLowerCase()}_${expense.amount.abs().toStringAsFixed(0)}';
      recurringPatterns[key] ??= [];
      recurringPatterns[key]!.add(expense);
    }

    final recurring =
        recurringPatterns.entries.where((e) => e.value.length >= 2).toList();
    if (recurring.isNotEmpty) {
      final totalRecurring = recurring.fold(
        0.0,
        (sum, e) => sum + (e.value.first.amount.abs() * e.value.length),
      );
      opportunities.add(
        'Recurring expenses identified: ${recurring.length} patterns totaling \$${totalRecurring.toStringAsFixed(0)} - review for optimization',
      );
    }

    // Find high-cost categories for optimization
    final categoryTotals = <String, double>{};
    for (final expense in expenses) {
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0.0) + expense.amount.abs();
    }

    final topCategory = categoryTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final totalSpending = categoryTotals.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    final topCategoryPercentage = (topCategory.value / totalSpending) * 100;

    if (topCategoryPercentage > 35) {
      opportunities.add(
        'High concentration in ${topCategory.key} (${topCategoryPercentage.toStringAsFixed(0)}%) - consider budgeting or alternatives',
      );
    }

    return opportunities.isNotEmpty
        ? opportunities.join('\n')
        : 'Current spending patterns appear well-distributed.';
  }

  /// Calculate goal achievement velocity
  String _calculateGoalVelocity(Map<String, dynamic> goalStats) {
    final progress = goalStats['overallProgress'] ?? 0.0;
    final totalGoals = goalStats['totalGoals'] ?? 0;

    if (totalGoals == 0) return 'No active goals to analyze';

    if (progress > 0.8) {
      return 'Excellent progress (goals near completion)';
    } else if (progress > 0.5) {
      return 'Good progress (on track for goal achievement)';
    } else if (progress > 0.2) {
      return 'Moderate progress (consider increasing savings rate)';
    } else {
      return 'Slow progress (may need budget reallocation)';
    }
  }

  /// Build comprehensive historical analysis for enhanced AI prompts
  Map<String, String> _buildHistoricalAnalysis(List<Transaction> transactions) {
    final now = DateTime.now();
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // Group transactions by month for the last 6 months
    final monthlyData = <String, Map<String, dynamic>>{};
    for (int i = 0; i < 6; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthKey =
          '${monthDate.year}-${monthDate.month.toString().padLeft(2, '0')}';
      final monthName = _getMonthName(monthDate.month);

      final monthExpenses =
          expenses
              .where(
                (t) =>
                    t.date.year == monthDate.year &&
                    t.date.month == monthDate.month,
              )
              .toList();

      final totalSpending = monthExpenses.fold(
        0.0,
        (sum, t) => sum + t.amount.abs(),
      );
      final transactionCount = monthExpenses.length;
      final avgPerTransaction =
          transactionCount > 0 ? totalSpending / transactionCount : 0.0;

      monthlyData[monthKey] = {
        'name': monthName,
        'total': totalSpending,
        'count': transactionCount,
        'avgPerTransaction': avgPerTransaction,
        'transactions': monthExpenses,
      };
    }

    // Generate historical summary
    final sortedMonths = monthlyData.keys.toList()..sort();
    final recentMonths = sortedMonths.reversed.take(3).toList();
    final historicalSummary = recentMonths
        .map((key) {
          final data = monthlyData[key]!;
          return '${data['name']}: \$${data['total'].toStringAsFixed(0)} (${data['count']} transactions)';
        })
        .join('\n');

    // Monthly breakdown with trends
    final monthlyBreakdown = monthlyData.entries
        .map((entry) {
          final data = entry.value;
          return '${data['name']}: \$${data['total'].toStringAsFixed(0)} total, ${data['count']} transactions, \$${data['avgPerTransaction'].toStringAsFixed(0)} avg/transaction';
        })
        .join('\n');

    // Category trends over time
    final categoryTrends = _analyzeCategoryTrends(expenses);

    // Spending velocity (acceleration/deceleration)
    final spendingVelocity = _calculateSpendingVelocity(monthlyData);

    return {
      'historicalSummary': historicalSummary,
      'monthlyBreakdown': monthlyBreakdown,
      'categoryTrends': categoryTrends,
      'spendingVelocity': spendingVelocity,
    };
  }

  /// Detect spending anomalies and unusual patterns
  List<String> _detectSpendingAnomalies(List<Transaction> transactions) {
    final anomalies = <String>[];
    final now = DateTime.now();
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    // Analyze last 3 months for anomalies
    for (int i = 0; i < 3; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthExpenses =
          expenses
              .where(
                (t) =>
                    t.date.year == monthDate.year &&
                    t.date.month == monthDate.month,
              )
              .toList();

      if (monthExpenses.isEmpty) continue;

      // Large single transactions (>2.5x average)
      final monthTotal = monthExpenses.fold(
        0.0,
        (sum, t) => sum + t.amount.abs(),
      );
      final avgTransaction = monthTotal / monthExpenses.length;
      final largeTransactions =
          monthExpenses
              .where((t) => t.amount.abs() > avgTransaction * 2.5)
              .toList();

      if (largeTransactions.isNotEmpty) {
        final monthName = _getMonthName(monthDate.month);
        anomalies.add(
          '$monthName: ${largeTransactions.length} unusually large transactions detected (avg: \$${avgTransaction.toStringAsFixed(0)})',
        );
      }

      // Category concentration (>60% in single category)
      final categoryTotals = <String, double>{};
      for (final expense in monthExpenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0.0) + expense.amount.abs();
      }

      if (categoryTotals.isNotEmpty) {
        final topEntry = categoryTotals.entries.reduce(
          (a, b) => a.value > b.value ? a : b,
        );
        final concentration = (topEntry.value / monthTotal) * 100;

        if (concentration > 60) {
          final monthName = _getMonthName(monthDate.month);
          anomalies.add(
            '$monthName: High concentration in ${topEntry.key} (${concentration.toStringAsFixed(0)}% of total spending)',
          );
        }
      }
    }

    // Day-of-week patterns (weekend vs weekday spending)
    final weekendSpending = expenses
        .where(
          (t) => [DateTime.saturday, DateTime.sunday].contains(t.date.weekday),
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());
    final weekdaySpending = expenses
        .where(
          (t) => ![DateTime.saturday, DateTime.sunday].contains(t.date.weekday),
        )
        .fold(0.0, (sum, t) => sum + t.amount.abs());

    if (weekendSpending > 0 && weekdaySpending > 0) {
      final weekendRatio =
          weekendSpending / (weekendSpending + weekdaySpending);
      if (weekendRatio > 0.4) {
        anomalies.add(
          'High weekend spending detected (${(weekendRatio * 100).toStringAsFixed(0)}% of total spending occurs on weekends)',
        );
      }
    }

    return anomalies;
  }

  /// Analyze seasonal spending patterns
  List<String> _analyzeSeasonalPatterns(List<Transaction> transactions) {
    final patterns = <String>[];
    final now = DateTime.now();
    final expenses =
        transactions
            .where((t) => t.type.toLowerCase() == 'expense' || t.amount < 0)
            .toList();

    if (expenses.length < 20) return patterns; // Need sufficient data

    // Group by season (last 12 months)
    final seasonalData = <String, double>{
      'Winter': 0.0,
      'Spring': 0.0,
      'Summer': 0.0,
      'Fall': 0.0,
    };

    for (final expense in expenses) {
      if (expense.date.isAfter(DateTime(now.year - 1, now.month))) {
        final season = _getSeason(expense.date.month);
        seasonalData[season] = seasonalData[season]! + expense.amount.abs();
      }
    }

    final totalSpending = seasonalData.values.fold(
      0.0,
      (sum, amount) => sum + amount,
    );
    if (totalSpending > 0) {
      final seasonalPercentages = seasonalData.map(
        (season, amount) => MapEntry(season, (amount / totalSpending) * 100),
      );

      final highestSeason = seasonalPercentages.entries.reduce(
        (a, b) => a.value > b.value ? a : b,
      );
      if (highestSeason.value > 30) {
        patterns.add(
          '${highestSeason.key} is your highest spending season (${highestSeason.value.toStringAsFixed(0)}% of annual spending)',
        );
      }
    }

    return patterns;
  }

  /// Analyze category trends over time
  String _analyzeCategoryTrends(List<Transaction> expenses) {
    final now = DateTime.now();
    final categoryTrends = <String, List<double>>{};

    // Analyze last 3 months
    for (int i = 0; i < 3; i++) {
      final monthDate = DateTime(now.year, now.month - i);
      final monthExpenses =
          expenses
              .where(
                (t) =>
                    t.date.year == monthDate.year &&
                    t.date.month == monthDate.month,
              )
              .toList();

      final categoryTotals = <String, double>{};
      for (final expense in monthExpenses) {
        categoryTotals[expense.category] =
            (categoryTotals[expense.category] ?? 0.0) + expense.amount.abs();
      }

      for (final entry in categoryTotals.entries) {
        categoryTrends[entry.key] ??= [];
        categoryTrends[entry.key]!.insert(0, entry.value);
      }
    }

    final trendAnalysis = <String>[];
    categoryTrends.forEach((category, amounts) {
      if (amounts.length >= 2) {
        final recent = amounts.last;
        final previous = amounts[amounts.length - 2];
        if (previous > 0) {
          final change = ((recent - previous) / previous) * 100;
          if (change.abs() > 20) {
            final direction = change > 0 ? 'increased' : 'decreased';
            trendAnalysis.add(
              '$category: $direction ${change.abs().toStringAsFixed(0)}% from previous month',
            );
          }
        }
      }
    });

    return trendAnalysis.isNotEmpty
        ? trendAnalysis.join('\n')
        : 'No significant category trends detected.';
  }

  /// Calculate spending velocity (acceleration/deceleration)
  String _calculateSpendingVelocity(
    Map<String, Map<String, dynamic>> monthlyData,
  ) {
    final sortedMonths = monthlyData.keys.toList()..sort();
    if (sortedMonths.length < 3)
      return 'Insufficient data for velocity analysis.';

    final recentMonths =
        sortedMonths.reversed.take(3).toList().reversed.toList();
    final amounts =
        recentMonths
            .map((key) => monthlyData[key]!['total'] as double)
            .toList();

    // Calculate month-over-month changes
    final changes = <double>[];
    for (int i = 1; i < amounts.length; i++) {
      if (amounts[i - 1] > 0) {
        changes.add(((amounts[i] - amounts[i - 1]) / amounts[i - 1]) * 100);
      }
    }

    if (changes.isEmpty) return 'Unable to calculate spending velocity.';

    final avgChange = changes.reduce((a, b) => a + b) / changes.length;
    final isAccelerating = changes.length > 1 && changes.last > changes.first;

    if (avgChange.abs() < 5) {
      return 'Spending velocity: Stable (${avgChange.toStringAsFixed(1)}% avg monthly change)';
    } else if (avgChange > 0) {
      final trend = isAccelerating ? 'accelerating' : 'increasing';
      return 'Spending velocity: $trend upward (${avgChange.toStringAsFixed(1)}% avg monthly increase)';
    } else {
      final trend = isAccelerating ? 'decelerating faster' : 'decreasing';
      return 'Spending velocity: $trend (${avgChange.abs().toStringAsFixed(1)}% avg monthly decrease)';
    }
  }

  /// Helper method to get month name
  String _getMonthName(int month) {
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

  /// Helper method to get season from month
  String _getSeason(int month) {
    if (month >= 12 || month <= 2) return 'Winter';
    if (month >= 3 && month <= 5) return 'Spring';
    if (month >= 6 && month <= 8) return 'Summer';
    return 'Fall';
  }
}
