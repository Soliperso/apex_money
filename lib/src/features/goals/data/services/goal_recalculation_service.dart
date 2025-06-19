import 'dart:async';
import '../models/goal_model.dart';
import 'goal_service.dart';
import 'goal_transaction_sync_service.dart';
import '../../../transactions/data/services/transaction_service.dart';

/// Service to manage goal recalculation and synchronization
class GoalRecalculationService {
  static final GoalRecalculationService _instance =
      GoalRecalculationService._internal();
  factory GoalRecalculationService() => _instance;
  GoalRecalculationService._internal();

  final GoalService _goalService = GoalService();
  final GoalTransactionSyncService _syncService = GoalTransactionSyncService();
  final TransactionService _transactionService = TransactionService();

  /// Recalculate all auto-update goals from scratch based on all transactions
  Future<void> recalculateAllGoals() async {
    print('Starting goal recalculation...');

    try {
      // Fetch all goals and transactions
      final futures = await Future.wait([
        _goalService.fetchGoals(),
        _transactionService.fetchTransactions(),
      ]);

      final goals = futures[0] as List<Goal>;
      final allTransactions = futures[1] as List; // transactions

      // Filter goals that have auto-update enabled
      final autoUpdateGoals = goals.where((goal) => goal.autoUpdate).toList();

      print('Found ${autoUpdateGoals.length} auto-update goals to recalculate');

      // Recalculate each goal
      for (final goal in autoUpdateGoals) {
        await _recalculateGoal(goal, allTransactions);
      }

      print('Goal recalculation completed successfully');
    } catch (e) {
      print('Error during goal recalculation: $e');
      rethrow;
    }
  }

  /// Recalculate a specific goal
  Future<void> recalculateGoal(String goalId) async {
    try {
      final goals = await _goalService.fetchGoals();
      final goal = goals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => throw Exception('Goal not found'),
      );

      if (!goal.autoUpdate) {
        print(
          'Goal ${goal.name} has auto-update disabled, skipping recalculation',
        );
        return;
      }

      final allTransactions = await _transactionService.fetchTransactions();
      await _recalculateGoal(goal, allTransactions);
    } catch (e) {
      print('Error recalculating goal $goalId: $e');
      rethrow;
    }
  }

  /// Recalculate a single goal based on all transactions
  Future<void> _recalculateGoal(Goal goal, List allTransactions) async {
    print('Recalculating goal: ${goal.name}');

    double calculatedAmount = 0.0;

    // Calculate amount based on goal type and linked categories
    for (final transaction in allTransactions) {
      if (goal.linkedCategories.contains(transaction.category)) {
        final contribution = _calculateTransactionContribution(
          goal,
          transaction,
        );
        calculatedAmount += contribution;
      }
    }

    // Ensure non-negative values for most goal types
    if (goal.type != GoalType.netWorth && calculatedAmount < 0) {
      calculatedAmount = 0.0;
    }

    // Update the goal if the calculated amount differs from current
    if ((calculatedAmount - goal.currentAmount).abs() > 0.01) {
      // Allow for small floating point differences
      print(
        'Updating goal ${goal.name}: ${goal.currentAmount} -> $calculatedAmount',
      );

      final isCompleted = calculatedAmount >= goal.targetAmount;
      final updatedGoal = goal.copyWith(
        currentAmount: calculatedAmount,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      );

      await _goalService.updateGoal(updatedGoal);
    } else {
      print('Goal ${goal.name} already up to date');
    }
  }

  /// Calculate how much a transaction contributes to a goal
  double _calculateTransactionContribution(Goal goal, dynamic transaction) {
    switch (goal.type) {
      case GoalType.savings:
        // For savings goals, only positive amounts (income) contribute
        return transaction.amount > 0 ? transaction.amount : 0.0;

      case GoalType.expenseLimit:
        // For expense limit goals, track spending (negative amounts)
        return transaction.amount < 0 ? transaction.amount.abs() : 0.0;

      case GoalType.incomeTarget:
        // For income goals, only positive amounts contribute
        return transaction.amount > 0 ? transaction.amount : 0.0;

      case GoalType.debtPaydown:
        // For debt paydown, track payments (expenses in debt categories)
        return transaction.amount < 0 ? transaction.amount.abs() : 0.0;

      case GoalType.netWorth:
        // For net worth goals, all transactions contribute (positive or negative)
        return transaction.amount;
    }
  }

  /// Get goals that need recalculation (have auto-update enabled)
  Future<List<Goal>> getAutoUpdateGoals() async {
    final goals = await _goalService.fetchGoals();
    return goals.where((goal) => goal.autoUpdate).toList();
  }

  /// Force recalculation of all goals (useful for migration or data fixes)
  Future<void> forceRecalculateAllGoals() async {
    print('Force recalculating ALL goals (including manual ones)...');

    try {
      final futures = await Future.wait([
        _goalService.fetchGoals(),
        _transactionService.fetchTransactions(),
      ]);

      final goals = futures[0] as List<Goal>;
      final allTransactions = futures[1] as List;

      print('Force recalculating ${goals.length} goals');

      for (final goal in goals) {
        // Force recalculate even manual goals, but don't update manual ones
        if (goal.autoUpdate) {
          await _recalculateGoal(goal, allTransactions);
        } else {
          print('Skipping manual goal: ${goal.name}');
        }
      }

      print('Force recalculation completed');
    } catch (e) {
      print('Error during force recalculation: $e');
      rethrow;
    }
  }
}
