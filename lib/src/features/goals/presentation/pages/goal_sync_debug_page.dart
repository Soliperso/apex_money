import 'package:flutter/material.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../data/services/goal_transaction_sync_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/services/transaction_service.dart';

class GoalSyncDebugPage extends StatefulWidget {
  const GoalSyncDebugPage({super.key});

  @override
  State<GoalSyncDebugPage> createState() => _GoalSyncDebugPageState();
}

class _GoalSyncDebugPageState extends State<GoalSyncDebugPage> {
  final GoalService _goalService = GoalService();
  final TransactionService _transactionService = TransactionService();
  final GoalTransactionSyncService _syncService = GoalTransactionSyncService();
  String _debugResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goal-Transaction Sync Debug'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Goal-Transaction Sync Diagnostics',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runFullDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🔍 Run Full Diagnostic'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _analyzeGoalCategories,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('📊 Analyze Goal Categories'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed:
                            _isLoading ? null : _analyzeTransactionCategories,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('💰 Analyze Transaction Categories'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testCategoryMatching,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🎯 Test Category Matching'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _simulateTransactionSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🧪 Simulate Transaction Sync'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Debug Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade50,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _isLoading ? 'Running diagnostic...' : _debugResults,
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runFullDiagnostic() async {
    setState(() {
      _isLoading = true;
      _debugResults =
          'Running comprehensive goal-transaction sync diagnostic...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🎯 GOAL-TRANSACTION SYNC DIAGNOSTIC REPORT');
      results.writeln('=' * 50);
      results.writeln('');

      // 1. Check Goals
      results.writeln('📋 STEP 1: Analyzing Goals');
      results.writeln('-' * 30);
      final goals = await _goalService.fetchGoals();
      results.writeln('Total goals found: ${goals.length}');
      results.writeln('');

      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        results.writeln('Goal ${i + 1}: "${goal.name}"');
        results.writeln('  - ID: ${goal.id}');
        results.writeln('  - Type: ${goal.type.name}');
        results.writeln('  - Target Amount: \$${goal.targetAmount}');
        results.writeln('  - Current Amount: \$${goal.currentAmount}');
        results.writeln('  - Auto Update: ${goal.autoUpdate}');
        results.writeln('  - Linked Categories: ${goal.linkedCategories}');
        results.writeln('  - Is Completed: ${goal.isCompleted}');

        // Check for potential issues
        if (goal.linkedCategories.isEmpty) {
          results.writeln(
            '  ⚠️  WARNING: No linked categories - this goal won\'t sync with transactions',
          );
        }
        if (!goal.autoUpdate) {
          results.writeln(
            '  ⚠️  WARNING: Auto-update disabled - this goal won\'t sync automatically',
          );
        }
        results.writeln('');
      }

      // 2. Check Transactions
      results.writeln('💰 STEP 2: Analyzing Recent Transactions');
      results.writeln('-' * 40);
      final transactions = await _transactionService.fetchTransactions();
      results.writeln('Total transactions found: ${transactions.length}');
      results.writeln('');

      // Get unique categories from transactions
      final transactionCategories = <String>{};
      for (final transaction in transactions.take(10)) {
        transactionCategories.add(transaction.category);
        results.writeln('Transaction: "${transaction.description}"');
        results.writeln('  - Amount: \$${transaction.amount}');
        results.writeln('  - Type: ${transaction.type}');
        results.writeln('  - Category: "${transaction.category}"');
        results.writeln(
          '  - Date: ${transaction.date.toString().split(' ')[0]}',
        );
        results.writeln('');
      }

      // 3. Category Analysis
      results.writeln('📊 STEP 3: Category Matching Analysis');
      results.writeln('-' * 35);

      final goalCategories = <String>{};
      for (final goal in goals) {
        goalCategories.addAll(goal.linkedCategories);
      }

      results.writeln('Goal Categories: ${goalCategories.toList()}');
      results.writeln(
        'Transaction Categories: ${transactionCategories.toList()}',
      );
      results.writeln('');

      // Find matches and mismatches
      final matchingCategories = goalCategories.intersection(
        transactionCategories,
      );
      final unmatchedGoalCategories = goalCategories.difference(
        transactionCategories,
      );
      final unmatchedTransactionCategories = transactionCategories.difference(
        goalCategories,
      );

      results.writeln('✅ Matching Categories: ${matchingCategories.toList()}');
      results.writeln(
        '❌ Goal Categories with no transactions: ${unmatchedGoalCategories.toList()}',
      );
      results.writeln(
        '❌ Transaction Categories with no goals: ${unmatchedTransactionCategories.toList()}',
      );
      results.writeln('');

      // 4. Sync Test
      results.writeln('🧪 STEP 4: Testing Sync Logic');
      results.writeln('-' * 30);

      if (transactions.isNotEmpty) {
        final testTransaction = transactions.first;
        results.writeln(
          'Testing with transaction: "${testTransaction.description}"',
        );
        results.writeln('  - Category: "${testTransaction.category}"');
        results.writeln('  - Amount: \$${testTransaction.amount}');
        results.writeln('');

        // Find which goals should match this transaction
        final matchingGoals =
            goals
                .where(
                  (goal) =>
                      goal.linkedCategories.contains(
                        testTransaction.category,
                      ) &&
                      goal.autoUpdate,
                )
                .toList();

        results.writeln(
          'Goals that should match this transaction: ${matchingGoals.length}',
        );
        for (final goal in matchingGoals) {
          results.writeln('  - "${goal.name}" (${goal.type.name})');
        }
        results.writeln('');
      }

      // 5. Recommendations
      results.writeln('💡 STEP 5: Recommendations');
      results.writeln('-' * 25);

      if (goals.any((g) => g.linkedCategories.isEmpty)) {
        results.writeln(
          '🔧 Fix: Some goals have no linked categories. Add categories to enable auto-sync.',
        );
      }

      if (goals.any((g) => !g.autoUpdate)) {
        results.writeln(
          '🔧 Fix: Some goals have auto-update disabled. Enable auto-update for synchronization.',
        );
      }

      if (unmatchedGoalCategories.isNotEmpty) {
        results.writeln(
          '🔧 Fix: Some goal categories don\'t match any transactions.',
        );
        results.writeln(
          '   Consider updating goal categories to match existing transaction categories.',
        );
      }

      if (unmatchedTransactionCategories.isNotEmpty) {
        results.writeln(
          '🔧 Fix: Some transaction categories don\'t match any goals.',
        );
        results.writeln(
          '   Consider creating goals for these categories or updating existing goals.',
        );
      }

      results.writeln('');
      results.writeln('✅ Diagnostic complete!');
    } catch (e) {
      results.writeln('❌ Diagnostic failed: $e');
    }

    setState(() {
      _debugResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _analyzeGoalCategories() async {
    setState(() {
      _isLoading = true;
      _debugResults = 'Analyzing goal categories...\n\n';
    });

    final results = StringBuffer();

    try {
      final goals = await _goalService.fetchGoals();

      results.writeln('📊 GOAL CATEGORIES ANALYSIS');
      results.writeln('=' * 30);
      results.writeln('');

      final categoryCount = <String, int>{};
      final goalsWithoutCategories = <Goal>[];
      final goalsWithAutoUpdateDisabled = <Goal>[];

      for (final goal in goals) {
        if (goal.linkedCategories.isEmpty) {
          goalsWithoutCategories.add(goal);
        } else {
          for (final category in goal.linkedCategories) {
            categoryCount[category] = (categoryCount[category] ?? 0) + 1;
          }
        }

        if (!goal.autoUpdate) {
          goalsWithAutoUpdateDisabled.add(goal);
        }
      }

      results.writeln('Category Usage Count:');
      categoryCount.entries.forEach((entry) {
        results.writeln('  - "${entry.key}": ${entry.value} goal(s)');
      });
      results.writeln('');

      if (goalsWithoutCategories.isNotEmpty) {
        results.writeln('⚠️  Goals without linked categories (won\'t sync):');
        for (final goal in goalsWithoutCategories) {
          results.writeln('  - "${goal.name}"');
        }
        results.writeln('');
      }

      if (goalsWithAutoUpdateDisabled.isNotEmpty) {
        results.writeln('⚠️  Goals with auto-update disabled:');
        for (final goal in goalsWithAutoUpdateDisabled) {
          results.writeln('  - "${goal.name}"');
        }
        results.writeln('');
      }
    } catch (e) {
      results.writeln('❌ Analysis failed: $e');
    }

    setState(() {
      _debugResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _analyzeTransactionCategories() async {
    setState(() {
      _isLoading = true;
      _debugResults = 'Analyzing transaction categories...\n\n';
    });

    final results = StringBuffer();

    try {
      final transactions = await _transactionService.fetchTransactions();

      results.writeln('💰 TRANSACTION CATEGORIES ANALYSIS');
      results.writeln('=' * 35);
      results.writeln('');

      final categoryStats = <String, Map<String, dynamic>>{};

      for (final transaction in transactions) {
        final category = transaction.category;
        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'count': 0,
            'totalAmount': 0.0,
            'incomeAmount': 0.0,
            'expenseAmount': 0.0,
          };
        }

        categoryStats[category]!['count']++;
        categoryStats[category]!['totalAmount'] += transaction.amount;

        if (transaction.amount > 0) {
          categoryStats[category]!['incomeAmount'] += transaction.amount;
        } else {
          categoryStats[category]!['expenseAmount'] += transaction.amount.abs();
        }
      }

      results.writeln('Category Statistics:');
      categoryStats.entries.forEach((entry) {
        final stats = entry.value;
        results.writeln('📂 "${entry.key}":');
        results.writeln('   - Count: ${stats['count']} transactions');
        results.writeln(
          '   - Total Amount: \$${stats['totalAmount'].toStringAsFixed(2)}',
        );
        results.writeln(
          '   - Income: \$${stats['incomeAmount'].toStringAsFixed(2)}',
        );
        results.writeln(
          '   - Expenses: \$${stats['expenseAmount'].toStringAsFixed(2)}',
        );
        results.writeln('');
      });
    } catch (e) {
      results.writeln('❌ Analysis failed: $e');
    }

    setState(() {
      _debugResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testCategoryMatching() async {
    setState(() {
      _isLoading = true;
      _debugResults = 'Testing category matching logic...\n\n';
    });

    final results = StringBuffer();

    try {
      final goals = await _goalService.fetchGoals();
      final transactions = await _transactionService.fetchTransactions();

      results.writeln('🎯 CATEGORY MATCHING TEST');
      results.writeln('=' * 25);
      results.writeln('');

      for (final goal in goals) {
        results.writeln('Goal: "${goal.name}"');
        results.writeln('  - Categories: ${goal.linkedCategories}');
        results.writeln('  - Auto-update: ${goal.autoUpdate}');

        final matchingTransactions =
            transactions
                .where(
                  (transaction) =>
                      goal.linkedCategories.contains(transaction.category),
                )
                .toList();

        results.writeln(
          '  - Matching transactions: ${matchingTransactions.length}',
        );

        if (matchingTransactions.isNotEmpty) {
          double totalContribution = 0;
          for (final transaction in matchingTransactions.take(5)) {
            // Simulate the contribution calculation
            double contribution = 0;
            switch (goal.type) {
              case GoalType.savings:
                contribution = transaction.amount > 0 ? transaction.amount : 0;
                break;
              case GoalType.expenseLimit:
                contribution =
                    transaction.amount < 0 ? transaction.amount.abs() : 0;
                break;
              case GoalType.incomeTarget:
                contribution = transaction.amount > 0 ? transaction.amount : 0;
                break;
              case GoalType.debtPaydown:
                contribution =
                    transaction.amount < 0 ? transaction.amount.abs() : 0;
                break;
              case GoalType.netWorth:
                contribution = transaction.amount;
                break;
            }
            totalContribution += contribution;

            results.writeln(
              '    - "${transaction.description}": \$${transaction.amount} → contribution: \$${contribution}',
            );
          }
          results.writeln(
            '  - Total contribution: \$${totalContribution.toStringAsFixed(2)}',
          );
        }
        results.writeln('');
      }
    } catch (e) {
      results.writeln('❌ Testing failed: $e');
    }

    setState(() {
      _debugResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _simulateTransactionSync() async {
    setState(() {
      _isLoading = true;
      _debugResults = 'Simulating transaction sync...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🧪 TRANSACTION SYNC SIMULATION');
      results.writeln('=' * 30);
      results.writeln('');

      // Create test transactions for different scenarios
      final testTransactions = [
        Transaction(
          description: 'Test Salary',
          amount: 100.0,
          date: DateTime.now(),
          category: 'Salary',
          type: 'income',
          status: 'completed',
          paymentMethodId: 'test',
          accountId: 'test',
          isRecurring: false,
        ),
        Transaction(
          description: 'Test Savings',
          amount: 50.0,
          date: DateTime.now(),
          category: 'Savings',
          type: 'income',
          status: 'completed',
          paymentMethodId: 'test',
          accountId: 'test',
          isRecurring: false,
        ),
        Transaction(
          description: 'Test Food Expense',
          amount: -25.0,
          date: DateTime.now(),
          category: 'Food & Dining',
          type: 'expense',
          status: 'completed',
          paymentMethodId: 'test',
          accountId: 'test',
          isRecurring: false,
        ),
      ];

      for (final transaction in testTransactions) {
        results.writeln('Testing transaction: "${transaction.description}"');
        results.writeln('  - Amount: \$${transaction.amount}');
        results.writeln('  - Category: "${transaction.category}"');
        results.writeln('  - Type: ${transaction.type}');

        // Test the sync logic
        await _syncService.debugGoalTransactionMatching(transaction);

        results.writeln(
          '  - ✅ Sync test completed (check console for details)',
        );
        results.writeln('');
      }
    } catch (e) {
      results.writeln('❌ Simulation failed: $e');
    }

    setState(() {
      _debugResults = results.toString();
      _isLoading = false;
    });
  }
}
