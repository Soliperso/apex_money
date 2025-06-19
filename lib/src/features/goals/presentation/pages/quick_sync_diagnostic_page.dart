import 'package:flutter/material.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../data/services/goal_transaction_sync_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/services/transaction_service.dart';

class QuickSyncDiagnosticPage extends StatefulWidget {
  const QuickSyncDiagnosticPage({super.key});

  @override
  State<QuickSyncDiagnosticPage> createState() =>
      _QuickSyncDiagnosticPageState();
}

class _QuickSyncDiagnosticPageState extends State<QuickSyncDiagnosticPage> {
  final GoalService _goalService = GoalService();
  final TransactionService _transactionService = TransactionService();
  final GoalTransactionSyncService _syncService = GoalTransactionSyncService();
  String _diagnosticResults = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sync Diagnostic'),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: Colors.red.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Goal-Transaction Sync Issues',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'This tool will help diagnose why your goals are not syncing with transactions.',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runQuickDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🚨 Run Quick Diagnostic'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testCarGoalSpecifically,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🚗 Test Car Goal Specifically'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createTestTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('💸 Create Test Transaction'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Diagnostic Results:',
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
                    _isLoading ? 'Running diagnostic...' : _diagnosticResults,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runQuickDiagnostic() async {
    setState(() {
      _isLoading = true;
      _diagnosticResults =
          'Running quick diagnostic for goal-transaction sync issues...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🚨 GOAL-TRANSACTION SYNC DIAGNOSTIC');
      results.writeln('=' * 50);
      results.writeln('Date: ${DateTime.now()}');
      results.writeln('');

      // 1. Get the Car Goal
      results.writeln('🎯 STEP 1: Finding Your Car Goal');
      results.writeln('-' * 30);
      final goals = await _goalService.fetchGoals();

      final carGoal =
          goals.where((g) => g.name.toLowerCase().contains('car')).firstOrNull;

      if (carGoal == null) {
        results.writeln('❌ NO CAR GOAL FOUND!');
        results.writeln('Available goals:');
        for (final goal in goals) {
          results.writeln('  - ${goal.name}');
        }
        results.writeln('');
        results.writeln('🔧 FIX: Create a goal with "car" in the name');
        setState(() {
          _diagnosticResults = results.toString();
          _isLoading = false;
        });
        return;
      }

      results.writeln('✅ Found Car Goal: "${carGoal.name}"');
      results.writeln('  - Current Amount: \$${carGoal.currentAmount}');
      results.writeln('  - Target Amount: \$${carGoal.targetAmount}');
      results.writeln('  - Auto Update: ${carGoal.autoUpdate}');
      results.writeln('  - Linked Categories: ${carGoal.linkedCategories}');
      results.writeln('');

      // 2. Check Recent Transactions
      results.writeln('💰 STEP 2: Checking Recent Transactions');
      results.writeln('-' * 35);
      final transactions = await _transactionService.fetchTransactions();
      results.writeln('Total transactions found: ${transactions.length}');

      // Look for transactions that should match the car goal
      final matchingTransactions =
          transactions
              .where((t) => carGoal.linkedCategories.contains(t.category))
              .toList();

      results.writeln(
        'Transactions matching car goal categories: ${matchingTransactions.length}',
      );
      results.writeln('');

      if (matchingTransactions.isEmpty) {
        results.writeln('❌ NO MATCHING TRANSACTIONS FOUND!');
        results.writeln('');
        results.writeln(
          'Car goal expects transactions in categories: ${carGoal.linkedCategories}',
        );
        results.writeln('');
        results.writeln('Your recent transaction categories:');
        final recentCategories =
            transactions.take(10).map((t) => t.category).toSet();
        for (final category in recentCategories) {
          results.writeln('  - "$category"');
        }
        results.writeln('');
        results.writeln('🔧 FIX: Either:');
        results.writeln(
          '  1. Create transactions in "Salary" or "Savings" categories',
        );
        results.writeln(
          '  2. Update your car goal to include your actual transaction categories',
        );
      } else {
        results.writeln(
          '✅ Found ${matchingTransactions.length} matching transactions:',
        );
        double totalPositive = 0;
        double totalNegative = 0;

        for (final transaction in matchingTransactions.take(5)) {
          results.writeln(
            '  - "${transaction.description}": \$${transaction.amount} (${transaction.category})',
          );
          if (transaction.amount > 0) {
            totalPositive += transaction.amount;
          } else {
            totalNegative += transaction.amount;
          }
        }

        results.writeln('');
        results.writeln('📊 Transaction Summary:');
        results.writeln('  - Total Positive (Income): \$${totalPositive}');
        results.writeln('  - Total Negative (Expenses): \$${totalNegative}');
        results.writeln('  - Net Amount: \$${totalPositive + totalNegative}');
        results.writeln('');

        // For savings goals, only positive amounts should contribute
        if (carGoal.type == GoalType.savings) {
          results.writeln(
            '🎯 Expected Goal Amount: \$${totalPositive} (savings goals only count positive amounts)',
          );
          results.writeln('🎯 Actual Goal Amount: \$${carGoal.currentAmount}');

          if ((totalPositive - carGoal.currentAmount).abs() > 0.01) {
            results.writeln(
              '❌ AMOUNTS DON\'T MATCH! Goal sync is not working properly.',
            );
          } else {
            results.writeln('✅ Amounts match! Goal sync is working correctly.');
          }
        }
      }

      // 3. Test the sync logic directly
      results.writeln('');
      results.writeln('🧪 STEP 3: Testing Sync Logic');
      results.writeln('-' * 30);

      if (matchingTransactions.isNotEmpty) {
        final testTransaction = matchingTransactions.first;
        results.writeln('Testing sync with: "${testTransaction.description}"');
        results.writeln(
          'Amount: \$${testTransaction.amount}, Category: "${testTransaction.category}"',
        );
        results.writeln('');

        // Test the debug matching
        results.writeln('🔍 Running sync debug...');
        await _syncService.debugGoalTransactionMatching(testTransaction);
        results.writeln(
          '✅ Debug completed - check console for detailed output',
        );
      }

      results.writeln('');
      results.writeln('📋 SUMMARY & RECOMMENDATIONS');
      results.writeln('-' * 30);

      if (carGoal.linkedCategories.isEmpty) {
        results.writeln('🔧 CRITICAL: Car goal has no linked categories');
      } else if (!carGoal.autoUpdate) {
        results.writeln('🔧 CRITICAL: Car goal has auto-update disabled');
      } else if (matchingTransactions.isEmpty) {
        results.writeln('🔧 ISSUE: No transactions match car goal categories');
        results.writeln(
          '   Create transactions in: ${carGoal.linkedCategories}',
        );
      } else {
        results.writeln('✅ Goal appears to be configured correctly');
        results.writeln('   If sync still not working, check console logs');
      }
    } catch (e) {
      results.writeln('❌ Diagnostic failed: $e');
    }

    setState(() {
      _diagnosticResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testCarGoalSpecifically() async {
    setState(() {
      _isLoading = true;
      _diagnosticResults = 'Testing car goal specifically...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🚗 FOCUSED CAR GOAL TEST');
      results.writeln('=' * 25);

      final goals = await _goalService.fetchGoals();
      final carGoal =
          goals.where((g) => g.name.toLowerCase().contains('car')).firstOrNull;

      if (carGoal == null) {
        results.writeln('❌ No car goal found');
        setState(() {
          _diagnosticResults = results.toString();
          _isLoading = false;
        });
        return;
      }

      results.writeln('Goal Details:');
      results.writeln('  Name: ${carGoal.name}');
      results.writeln('  ID: ${carGoal.id}');
      results.writeln('  Type: ${carGoal.type.name}');
      results.writeln('  Current: \$${carGoal.currentAmount}');
      results.writeln('  Target: \$${carGoal.targetAmount}');
      results.writeln('  Categories: ${carGoal.linkedCategories}');
      results.writeln('  Auto-update: ${carGoal.autoUpdate}');
      results.writeln('');

      // Create a test transaction that should definitely match
      results.writeln('Creating test transaction for "Salary" category...');
      final testTransaction = Transaction(
        description: 'Test Salary for Car Goal',
        amount: 100.0,
        date: DateTime.now(),
        category: 'Salary', // This should match the car goal
        type: 'income',
        status: 'completed',
        paymentMethodId: 'test',
        accountId: 'test',
        isRecurring: false,
      );

      results.writeln('Test Transaction:');
      results.writeln('  Description: ${testTransaction.description}');
      results.writeln('  Amount: \$${testTransaction.amount}');
      results.writeln('  Category: "${testTransaction.category}"');
      results.writeln('  Type: ${testTransaction.type}');
      results.writeln('');

      // Test if this transaction would match the goal
      final shouldMatch = carGoal.linkedCategories.contains(
        testTransaction.category,
      );
      results.writeln('Should this transaction match the car goal?');
      results.writeln('  Goal categories: ${carGoal.linkedCategories}');
      results.writeln('  Transaction category: "${testTransaction.category}"');
      results.writeln('  Match result: ${shouldMatch ? "YES ✅" : "NO ❌"}');
      results.writeln('');

      if (shouldMatch) {
        results.writeln('Running sync test...');
        await _syncService.debugGoalTransactionMatching(testTransaction);
        results.writeln('✅ Sync test completed - check console for output');
      } else {
        results.writeln('❌ Transaction would not match goal');
        results.writeln(
          '🔧 FIX: Update goal categories or transaction category',
        );
      }
    } catch (e) {
      results.writeln('❌ Test failed: $e');
    }

    setState(() {
      _diagnosticResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _createTestTransaction() async {
    setState(() {
      _isLoading = true;
      _diagnosticResults = 'Creating test transaction...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('💸 CREATING TEST TRANSACTION');
      results.writeln('=' * 30);

      // Get the car goal first
      final goals = await _goalService.fetchGoals();
      final carGoal =
          goals.where((g) => g.name.toLowerCase().contains('car')).firstOrNull;

      if (carGoal == null) {
        results.writeln('❌ No car goal found - cannot create test transaction');
        setState(() {
          _diagnosticResults = results.toString();
          _isLoading = false;
        });
        return;
      }

      results.writeln('Car goal found: "${carGoal.name}"');
      results.writeln('Goal categories: ${carGoal.linkedCategories}');
      results.writeln('Current amount: \$${carGoal.currentAmount}');
      results.writeln('');

      // Create a transaction in the first linked category
      final categoryToUse =
          carGoal.linkedCategories.isNotEmpty
              ? carGoal.linkedCategories.first
              : 'Salary';

      final testTransaction = Transaction(
        description:
            'Test Income for Car Goal - ${DateTime.now().millisecondsSinceEpoch}',
        amount: 50.0, // Small test amount
        date: DateTime.now(),
        category: categoryToUse,
        type: 'income',
        status: 'completed',
        paymentMethodId: 'default',
        accountId: 'default',
        isRecurring: false,
      );

      results.writeln('Creating transaction:');
      results.writeln('  Description: ${testTransaction.description}');
      results.writeln('  Amount: \$${testTransaction.amount}');
      results.writeln('  Category: "${testTransaction.category}"');
      results.writeln('  Type: ${testTransaction.type}');
      results.writeln('');

      // Actually create the transaction (this should trigger goal sync)
      results.writeln('🔄 Creating transaction in backend...');
      await _transactionService.createTransaction(testTransaction);
      results.writeln('✅ Transaction created successfully!');
      results.writeln('');

      // Wait a moment for sync to complete
      await Future.delayed(const Duration(seconds: 2));

      // Check if the goal was updated
      results.writeln('🔍 Checking if goal was updated...');
      final updatedGoals = await _goalService.fetchGoals();
      final updatedCarGoal =
          updatedGoals
              .where((g) => g.name.toLowerCase().contains('car'))
              .firstOrNull;

      if (updatedCarGoal != null) {
        results.writeln('Goal after transaction:');
        results.writeln('  Previous amount: \$${carGoal.currentAmount}');
        results.writeln('  Current amount: \$${updatedCarGoal.currentAmount}');
        results.writeln(
          '  Change: \$${updatedCarGoal.currentAmount - carGoal.currentAmount}',
        );

        if (updatedCarGoal.currentAmount > carGoal.currentAmount) {
          results.writeln('✅ SUCCESS! Goal was updated by the transaction!');
        } else {
          results.writeln(
            '❌ FAILURE! Goal was not updated by the transaction!',
          );
          results.writeln('');
          results.writeln('🔧 This indicates a sync problem. Check:');
          results.writeln('  1. Goal auto-update setting');
          results.writeln('  2. Category matching');
          results.writeln('  3. Goal type vs transaction amount');
        }
      }

      // Cleanup: Delete the test transaction
      results.writeln('');
      results.writeln('🧹 Cleaning up test transaction...');
      try {
        final allTransactions = await _transactionService.fetchTransactions();
        final testTransactionToDelete =
            allTransactions
                .where((t) => t.description == testTransaction.description)
                .firstOrNull;

        if (testTransactionToDelete?.id != null) {
          await _transactionService.deleteTransaction(
            testTransactionToDelete!.id!,
          );
          results.writeln('✅ Test transaction cleaned up');
        } else {
          results.writeln('⚠️  Test transaction not found for cleanup');
        }
      } catch (e) {
        results.writeln('⚠️  Warning: Could not delete test transaction: $e');
      }
    } catch (e) {
      results.writeln('❌ Failed to create test transaction: $e');
    }

    setState(() {
      _diagnosticResults = results.toString();
      _isLoading = false;
    });
  }
}
