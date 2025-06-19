import 'dart:async';
import 'package:flutter/material.dart';
import '../models/goal_model.dart';
import 'goal_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/services/transaction_service.dart';

/// Service to automatically update goals based on transaction activity
class GoalTransactionSyncService {
  static final GoalTransactionSyncService _instance =
      GoalTransactionSyncService._internal();
  factory GoalTransactionSyncService() => _instance;
  GoalTransactionSyncService._internal();

  final GoalService _goalService = GoalService();

  // Callback for goal update notifications
  Function(String goalName, double amount)? _onGoalUpdated;

  /// Set callback for when goals are updated
  void setGoalUpdateCallback(
    Function(String goalName, double amount) callback,
  ) {
    _onGoalUpdated = callback;
  }

  /// Clear the callback
  void clearGoalUpdateCallback() {
    _onGoalUpdated = null;
  }

  /// Update all relevant goals when a transaction is created/updated
  Future<void> syncTransactionWithGoals(Transaction transaction) async {
    print(
      '🎯 Goal Sync: Processing transaction - ${transaction.description} (${transaction.amount}) in category: ${transaction.category}',
    );

    try {
      final goals = await _goalService.fetchGoals();
      print('🎯 Goal Sync: Found ${goals.length} total goals');

      // Print all goal details for debugging
      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        print('🎯 Goal ${i + 1}: "${goal.name}"');
        print('   - Type: ${goal.type.name}');
        print('   - Linked Categories: ${goal.linkedCategories}');
        print('   - Auto Update: ${goal.autoUpdate}');
        print('   - Current Amount: \$${goal.currentAmount}');
      }

      final relevantGoals = _getRelevantGoals(goals, transaction);
      print('🎯 Goal Sync: Found ${relevantGoals.length} relevant goals');

      if (relevantGoals.isEmpty) {
        print(
          '🎯 Goal Sync: No goals matched this transaction. Checking why...',
        );
        for (final goal in goals) {
          print('🎯 Goal "${goal.name}":');
          print('   - Goal categories: ${goal.linkedCategories}');
          print('   - Transaction category: "${transaction.category}"');
          print(
            '   - Categories contain transaction: ${goal.linkedCategories.contains(transaction.category)}',
          );
          print('   - Goal type: ${goal.type.name}');
          print('   - Auto update: ${goal.autoUpdate}');
        }
      }

      for (final goal in relevantGoals) {
        print(
          '🎯 Goal Sync: Processing goal "${goal.name}" (auto-update: ${goal.autoUpdate})',
        );
        if (goal.autoUpdate) {
          print(
            '🎯 Goal Sync: Updating goal "${goal.name}" with transaction amount ${transaction.amount}',
          );
          await _updateGoalProgress(goal, transaction, isAddition: true);
        } else {
          print(
            '🎯 Goal Sync: Skipping goal "${goal.name}" - auto-update disabled',
          );
        }
      }
    } catch (e) {
      print('🎯 Goal Sync Error: $e');
    }
  }

  /// Reverse goal updates when a transaction is deleted
  Future<void> reverseTransactionFromGoals(Transaction transaction) async {
    try {
      final goals = await _goalService.fetchGoals();
      final relevantGoals = _getRelevantGoals(goals, transaction);

      for (final goal in relevantGoals) {
        if (goal.autoUpdate) {
          await _updateGoalProgress(goal, transaction, isAddition: false);
        }
      }
    } catch (e) {
      print('Error reversing transaction from goals: $e');
    }
  }

  /// Recalculate all goal progress from scratch based on all transactions
  Future<void> recalculateAllGoalProgress(
    List<Transaction> allTransactions,
  ) async {
    try {
      final goals = await _goalService.fetchGoals();

      for (final goal in goals) {
        if (goal.autoUpdate) {
          final newAmount = _calculateGoalAmountFromTransactions(
            goal,
            allTransactions,
          );
          await _goalService.setGoalProgress(goal.id!, newAmount);
        }
      }
    } catch (e) {
      print('Error recalculating goal progress: $e');
    }
  }

  /// Get goals that should be updated by this transaction
  List<Goal> _getRelevantGoals(List<Goal> goals, Transaction transaction) {
    print(
      '🔍 Checking ${goals.length} goals for transaction category: "${transaction.category}"',
    );

    final relevantGoals =
        goals.where((goal) {
          print('🔍 Goal: "${goal.name}"');
          print('   - Linked categories: ${goal.linkedCategories}');
          print('   - Goal type: ${goal.type.name}');

          // If no linked categories, don't auto-update (manual goals)
          if (goal.linkedCategories.isEmpty) {
            print('   - ❌ No linked categories');
            return false;
          }

          // Check if transaction category matches goal's linked categories
          final matches = goal.linkedCategories.contains(transaction.category);
          print('   - ${matches ? "✅" : "❌"} Category match: $matches');
          return matches;
        }).toList();

    print('🔍 Found ${relevantGoals.length} relevant goals');
    return relevantGoals;
  }

  /// Update a single goal's progress based on a transaction
  Future<void> _updateGoalProgress(
    Goal goal,
    Transaction transaction, {
    required bool isAddition,
  }) async {
    print('🎯 _updateGoalProgress: Goal "${goal.name}"');
    print(
      '🎯 _updateGoalProgress: Current goal amount: \$${goal.currentAmount}',
    );
    print(
      '🎯 _updateGoalProgress: Transaction amount: \$${transaction.amount}',
    );
    print('🎯 _updateGoalProgress: Transaction type: ${transaction.type}');
    print('🎯 _updateGoalProgress: Goal type: ${goal.type.name}');

    final double contributionAmount = _calculateTransactionContribution(
      goal,
      transaction,
    );

    print(
      '🎯 _updateGoalProgress: Calculated contribution: \$${contributionAmount}',
    );

    if (contributionAmount == 0) {
      print('🎯 _updateGoalProgress: No contribution, skipping update');
      return;
    }

    final double finalAmount =
        isAddition ? contributionAmount : -contributionAmount;

    print('🎯 _updateGoalProgress: Final amount to add: \$${finalAmount}');
    print(
      '🎯 _updateGoalProgress: Expected new total: \$${goal.currentAmount + finalAmount}',
    );

    try {
      await _goalService.updateGoalProgress(goal.id!, finalAmount);
      print('🎯 _updateGoalProgress: Successfully updated goal');

      // Notify via callback if set
      _onGoalUpdated?.call(goal.name, goal.currentAmount + finalAmount);
    } catch (e) {
      print('🎯 _updateGoalProgress: Error updating goal ${goal.name}: $e');
    }
  }

  /// Calculate how much a transaction contributes to a goal
  double _calculateTransactionContribution(Goal goal, Transaction transaction) {
    print('🧮 Calculating contribution for goal type: ${goal.type.name}');
    print('🧮 Transaction amount: \$${transaction.amount}');
    print('🧮 Transaction type: ${transaction.type}');

    double contribution = 0.0;

    switch (goal.type) {
      case GoalType.savings:
        // For savings goals, only positive amounts (income) contribute
        contribution = transaction.amount > 0 ? transaction.amount : 0.0;
        print('🧮 Savings goal: Using positive amounts only');
        break;

      case GoalType.expenseLimit:
        // For expense limit goals, track spending (negative amounts)
        contribution = transaction.amount < 0 ? transaction.amount.abs() : 0.0;
        print('🧮 Expense limit goal: Using negative amounts (spending)');
        break;

      case GoalType.incomeTarget:
        // For income goals, only positive amounts contribute
        contribution = transaction.amount > 0 ? transaction.amount : 0.0;
        print('🧮 Income target goal: Using positive amounts only');
        break;

      case GoalType.debtPaydown:
        // For debt paydown, track payments (expenses in debt categories)
        contribution = transaction.amount < 0 ? transaction.amount.abs() : 0.0;
        print('🧮 Debt paydown goal: Using negative amounts (payments)');
        break;

      case GoalType.netWorth:
        // For net worth goals, all transactions contribute (positive or negative)
        contribution = transaction.amount;
        print('🧮 Net worth goal: Using all amounts');
        break;
    }

    print('🧮 Final contribution: \$${contribution}');
    return contribution;
  }

  /// Calculate total goal amount from all relevant transactions
  double _calculateGoalAmountFromTransactions(
    Goal goal,
    List<Transaction> transactions,
  ) {
    double total = 0.0;

    for (final transaction in transactions) {
      if (goal.linkedCategories.contains(transaction.category)) {
        total += _calculateTransactionContribution(goal, transaction);
      }
    }

    return total;
  }

  /// Debug method to test goal-transaction matching
  Future<void> debugGoalTransactionMatching(Transaction transaction) async {
    print('🔍 DEBUG: Testing goal-transaction matching for transaction:');
    print('   Description: ${transaction.description}');
    print('   Amount: ${transaction.amount}');
    print('   Type: ${transaction.type}');
    print('   Category: ${transaction.category}');

    try {
      final goals = await _goalService.fetchGoals();
      print('🔍 DEBUG: Found ${goals.length} total goals');

      for (final goal in goals) {
        print('🔍 DEBUG: Checking goal: ${goal.name}');
        print('   Goal type: ${goal.type.name}');
        print('   Linked categories: ${goal.linkedCategories}');
        print('   Auto-update: ${goal.autoUpdate}');

        // Check if this goal matches the transaction
        final isRelevant =
            goal.linkedCategories.isEmpty ||
            goal.linkedCategories.contains(transaction.category);
        print('   Is relevant: $isRelevant');

        if (isRelevant) {
          final contribution = _calculateTransactionContribution(
            goal,
            transaction,
          );
          print('   Transaction contribution: $contribution');
          print('   Current goal amount: ${goal.currentAmount}');
          print('   Target goal amount: ${goal.targetAmount}');
        }
        print('');
      }
    } catch (e) {
      print('🔍 DEBUG: Error during goal matching: $e');
    }
  }

  /// Comprehensive debug method to understand sync issues
  Future<Map<String, dynamic>> getComprehensiveDebugInfo() async {
    final debugInfo = <String, dynamic>{};

    try {
      // Get goals and transactions
      final goals = await _goalService.fetchGoals();
      final transactions = await TransactionService().fetchTransactions();

      debugInfo['goalsCount'] = goals.length;
      debugInfo['transactionsCount'] = transactions.length;

      // Analyze goals
      final goalsAnalysis = <String, dynamic>{};
      final goalsWithoutCategories = <String>[];
      final goalsWithoutAutoUpdate = <String>[];
      final allGoalCategories = <String>{};

      for (final goal in goals) {
        if (goal.linkedCategories.isEmpty) {
          goalsWithoutCategories.add(goal.name);
        }
        if (!goal.autoUpdate) {
          goalsWithoutAutoUpdate.add(goal.name);
        }
        allGoalCategories.addAll(goal.linkedCategories);
      }

      goalsAnalysis['goalsWithoutCategories'] = goalsWithoutCategories;
      goalsAnalysis['goalsWithoutAutoUpdate'] = goalsWithoutAutoUpdate;
      goalsAnalysis['allGoalCategories'] = allGoalCategories.toList();
      debugInfo['goalsAnalysis'] = goalsAnalysis;

      // Analyze transactions
      final transactionsAnalysis = <String, dynamic>{};
      final allTransactionCategories = <String>{};
      final categoryStats = <String, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        allTransactionCategories.add(transaction.category);

        if (!categoryStats.containsKey(transaction.category)) {
          categoryStats[transaction.category] = {
            'count': 0,
            'totalAmount': 0.0,
            'positiveAmount': 0.0,
            'negativeAmount': 0.0,
          };
        }

        categoryStats[transaction.category]!['count']++;
        categoryStats[transaction.category]!['totalAmount'] +=
            transaction.amount;

        if (transaction.amount > 0) {
          categoryStats[transaction.category]!['positiveAmount'] +=
              transaction.amount;
        } else {
          categoryStats[transaction.category]!['negativeAmount'] +=
              transaction.amount;
        }
      }

      transactionsAnalysis['allTransactionCategories'] =
          allTransactionCategories.toList();
      transactionsAnalysis['categoryStats'] = categoryStats;
      debugInfo['transactionsAnalysis'] = transactionsAnalysis;

      // Category matching analysis
      final matchingAnalysis = <String, dynamic>{};
      final matchingCategories = allGoalCategories.intersection(
        allTransactionCategories,
      );
      final unmatchedGoalCategories = allGoalCategories.difference(
        allTransactionCategories,
      );
      final unmatchedTransactionCategories = allTransactionCategories
          .difference(allGoalCategories);

      matchingAnalysis['matchingCategories'] = matchingCategories.toList();
      matchingAnalysis['unmatchedGoalCategories'] =
          unmatchedGoalCategories.toList();
      matchingAnalysis['unmatchedTransactionCategories'] =
          unmatchedTransactionCategories.toList();
      debugInfo['matchingAnalysis'] = matchingAnalysis;

      // Sync simulation
      final syncSimulation = <String, dynamic>{};
      final goalUpdates = <String, dynamic>{};

      for (final goal in goals) {
        if (goal.autoUpdate && goal.linkedCategories.isNotEmpty) {
          final relevantTransactions =
              transactions
                  .where((t) => goal.linkedCategories.contains(t.category))
                  .toList();

          double totalContribution = 0;
          for (final transaction in relevantTransactions) {
            totalContribution += _calculateTransactionContribution(
              goal,
              transaction,
            );
          }

          goalUpdates[goal.name] = {
            'currentAmount': goal.currentAmount,
            'calculatedAmount': totalContribution,
            'difference': totalContribution - goal.currentAmount,
            'relevantTransactionsCount': relevantTransactions.length,
          };
        }
      }

      syncSimulation['goalUpdates'] = goalUpdates;
      debugInfo['syncSimulation'] = syncSimulation;
    } catch (e) {
      debugInfo['error'] = e.toString();
    }

    return debugInfo;
  }

  /// Test real goal sync (actually updates the goal)
  Future<void> testRealGoalSync(Transaction transaction) async {
    print('🚀 REAL SYNC TEST: Starting actual goal sync for transaction:');
    print('   Description: ${transaction.description}');
    print('   Amount: ${transaction.amount}');
    print('   Category: ${transaction.category}');
    print('');

    try {
      // Call the actual sync method (not just debug)
      await syncTransactionWithGoals(transaction);
      print('🚀 REAL SYNC TEST: Sync completed');
    } catch (e) {
      print('🚀 REAL SYNC TEST: Error during sync: $e');
    }
  }
}
