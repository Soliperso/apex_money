import 'package:flutter/material.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../data/services/goal_transaction_sync_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../transactions/data/services/transaction_service.dart';

class GoalApiTestPage extends StatefulWidget {
  const GoalApiTestPage({super.key});

  @override
  State<GoalApiTestPage> createState() => _GoalApiTestPageState();
}

class _GoalApiTestPageState extends State<GoalApiTestPage> {
  final GoalService _goalService = GoalService();
  String _testResults = '';
  bool _isLoading = false;

  Future<void> _runTests() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running API tests...\n\n';
    });

    final results = StringBuffer();

    // Test 1: Fetch Goals
    results.writeln('🔄 Testing fetchGoals()...');
    try {
      final goals = await _goalService.fetchGoals();
      results.writeln('✅ Successfully fetched ${goals.length} goals');

      for (int i = 0; i < goals.length && i < 3; i++) {
        final goal = goals[i];
        results.writeln(
          '   • ${goal.name}: \$${goal.currentAmount}/\$${goal.targetAmount}',
        );
      }
    } catch (e) {
      results.writeln('❌ Failed to fetch goals: $e');
    }
    results.writeln('');

    // Test 2: Create Goal
    results.writeln('🔄 Testing createGoal()...');
    try {
      final testGoal = Goal(
        name: 'API Test Goal',
        targetAmount: 1000.0,
        currentAmount: 100.0,
        description: 'Test goal created via API',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: GoalType.savings,
        linkedCategories: ['Salary'],
        autoUpdate: true,
      );

      final createdGoal = await _goalService.createGoal(testGoal);
      results.writeln('✅ Successfully created goal with ID: ${createdGoal.id}');

      // Test 3: Update Goal
      results.writeln('🔄 Testing updateGoal()...');
      final updatedGoal = createdGoal.copyWith(
        currentAmount: 200.0,
        updatedAt: DateTime.now(),
      );

      final savedGoal = await _goalService.updateGoal(updatedGoal);
      results.writeln(
        '✅ Successfully updated goal. New amount: \$${savedGoal.currentAmount}',
      );

      // Test 4: Delete Goal
      results.writeln('🔄 Testing deleteGoal()...');
      await _goalService.deleteGoal(createdGoal.id!);
      results.writeln('✅ Successfully deleted test goal');
    } catch (e) {
      results.writeln('❌ Failed goal CRUD operations: $e');
    }
    results.writeln('');

    // Test 5: Get Statistics
    results.writeln('🔄 Testing getGoalStatistics()...');
    try {
      final stats = await _goalService.getGoalStatistics();
      results.writeln('✅ Successfully fetched statistics:');
      results.writeln('   • Total Goals: ${stats['totalGoals']}');
      results.writeln('   • Active Goals: ${stats['activeGoals']}');
      results.writeln('   • Completed Goals: ${stats['completedGoals']}');
      results.writeln(
        '   • Overall Progress: ${(stats['overallProgress'] * 100).toStringAsFixed(1)}%',
      );
    } catch (e) {
      results.writeln('❌ Failed to get statistics: $e');
    }

    results.writeln('\n🏁 API testing completed!');

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _runDiagnosis() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running API diagnosis...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🔍 Starting comprehensive API diagnosis...\n');
      await _goalService.diagnoseApiResponse();
      results.writeln(
        '✅ Diagnosis completed. Check debug console for detailed output.\n',
      );

      // Also try to parse a test goal to see format
      final testGoal = Goal(
        name: 'Format Test',
        targetAmount: 1000.0,
        currentAmount: 0.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: GoalType.savings,
      );

      results.writeln('📋 Expected API format for goal creation:');
      final json = testGoal.toJson();
      json.forEach((key, value) {
        results.writeln('   "$key": ${value.runtimeType} = $value');
      });
    } catch (e) {
      results.writeln('❌ Diagnosis failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  Future<void> _testGoalCreation() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing goal creation with detailed debugging...\n\n';
    });

    final results = StringBuffer();

    try {
      // Create a test goal with all the data types
      final testGoal = Goal(
        name: 'Debug Test Goal ${DateTime.now().millisecondsSinceEpoch}',
        targetAmount: 1500.50, // Test decimal amount
        currentAmount: 250.25, // Test decimal amount
        description: 'Detailed test goal for API debugging',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: GoalType.savings, // Test enum serialization
        linkedCategories: ['Salary', 'Freelance'], // Test array serialization
        autoUpdate: true, // Test boolean serialization
        deadline: DateTime.now().add(
          const Duration(days: 30),
        ), // Test date serialization
      );

      results.writeln('🔍 Goal Data to Send:');
      final goalJson = testGoal.toJson();
      goalJson.forEach((key, value) {
        results.writeln('   $key: ${value.runtimeType} = $value');
      });
      results.writeln('');

      results.writeln('📤 Creating goal via API...');
      final createdGoal = await _goalService.createGoal(testGoal);

      results.writeln('✅ Goal created successfully!');
      results.writeln('   ID: ${createdGoal.id}');
      results.writeln('   Name: ${createdGoal.name}');
      results.writeln('   Type: ${createdGoal.type.name}');
      results.writeln('   Target: \$${createdGoal.targetAmount}');
      results.writeln('   Current: \$${createdGoal.currentAmount}');

      // Clean up - delete the test goal
      if (createdGoal.id != null) {
        results.writeln('🧹 Cleaning up test goal...');
        await _goalService.deleteGoal(createdGoal.id!);
        results.writeln('✅ Test goal deleted');
      }
    } catch (e) {
      results.writeln('❌ Goal creation failed: $e');
      results.writeln('');
      results.writeln('💡 Check the debug console for detailed API logs');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  /// Test goal sync functionality with a specific transaction
  Future<void> _testGoalSync() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing goal sync functionality...\n\n';
    });

    final results = StringBuffer();

    try {
      // First, check all existing goals
      results.writeln('📋 Current Goals:');
      final goals = await _goalService.fetchGoals();

      if (goals.isEmpty) {
        results.writeln('❌ No goals found! Create a goal first.');
        setState(() {
          _testResults = results.toString();
          _isLoading = false;
        });
        return;
      }

      for (int i = 0; i < goals.length; i++) {
        final goal = goals[i];
        results.writeln('${i + 1}. "${goal.name}"');
        results.writeln('   - Type: ${goal.type.name}');
        results.writeln('   - Target: \$${goal.targetAmount}');
        results.writeln('   - Current: \$${goal.currentAmount}');
        results.writeln('   - Linked Categories: ${goal.linkedCategories}');
        results.writeln('   - Auto Update: ${goal.autoUpdate}');
        results.writeln('');
      }

      // Create a test transaction that should match your car goal
      results.writeln('🚗 Creating test transaction for car goal:');
      final testTransaction = Transaction(
        description: 'Test Car Savings',
        amount: 100.0, // Positive amount for income
        date: DateTime.now(),
        category: 'Savings', // This should match your goal
        type: 'income',
        status: 'completed',
        paymentMethodId: 'test',
        accountId: 'test',
        isRecurring: false,
      );

      results.writeln('Transaction details:');
      results.writeln('   - Description: ${testTransaction.description}');
      results.writeln('   - Amount: \$${testTransaction.amount}');
      results.writeln('   - Type: ${testTransaction.type}');
      results.writeln('   - Category: ${testTransaction.category}');
      results.writeln('');

      // Test the sync manually
      results.writeln('🔄 Testing goal sync...');
      final syncService = GoalTransactionSyncService();

      results.writeln(
        'Before sync - Goal current amount: \$${goals.first.currentAmount}',
      );

      // This will trigger all the debug output
      await syncService.syncTransactionWithGoals(testTransaction);

      // Check the goal again after sync
      results.writeln('🔄 Checking goal after sync...');
      final updatedGoals = await _goalService.fetchGoals();
      final carGoal = updatedGoals.firstWhere((g) => g.name.contains('Car'));

      results.writeln(
        'After sync - Goal current amount: \$${carGoal.currentAmount}',
      );
      results.writeln(
        'Amount change: \$${carGoal.currentAmount - goals.first.currentAmount}',
      );

      results.writeln('✅ Goal sync test completed!');
      results.writeln('');
      results.writeln(
        '📱 Check your device console for detailed debug output.',
      );
      results.writeln('Look for lines starting with "🎯 Goal Sync:"');
    } catch (e) {
      results.writeln('❌ Goal sync test failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  /// Reset car goal to correct positive amount
  Future<void> _resetCarGoal() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Resetting car goal to positive amount...\n\n';
    });

    final results = StringBuffer();

    try {
      // Get all goals
      final goals = await _goalService.fetchGoals();

      // Find the car goal
      final carGoal = goals.firstWhere(
        (goal) => goal.name.toLowerCase().contains('car'),
        orElse: () => throw Exception('Car goal not found'),
      );

      results.writeln('🚗 Found goal: "${carGoal.name}"');
      results.writeln('   Current amount: \$${carGoal.currentAmount}');
      results.writeln('   Target amount: \$${carGoal.targetAmount}');
      results.writeln('');

      // Reset to a reasonable starting amount (like $0 or $500)
      results.writeln('🔄 Resetting goal to \$0...');
      await _goalService.setGoalProgress(carGoal.id!, 0.0);

      results.writeln('✅ Goal reset successfully!');
      results.writeln('');
      results.writeln('Now try adding a real income transaction with:');
      results.writeln('- Amount: \$100');
      results.writeln('- Type: Income');
      results.writeln('- Category: Savings');
      results.writeln('');
      results.writeln('Your goal should increase to \$100! 🎉');
    } catch (e) {
      results.writeln('❌ Reset failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  /// Quick diagnostic for goal-transaction sync issues
  Future<void> _runQuickSyncDiagnostic() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Running quick goal-transaction sync diagnostic...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🚨 GOAL-TRANSACTION SYNC DIAGNOSTIC');
      results.writeln('=' * 50);
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
          _testResults = results.toString();
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
      final transactionService = TransactionService();
      final transactions = await transactionService.fetchTransactions();
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
            results.writeln('');
            results.writeln('🔧 POSSIBLE FIXES:');
            results.writeln(
              '  1. Check if goal sync is called when creating transactions',
            );
            results.writeln(
              '  2. Verify goal updates are persisting to backend',
            );
            results.writeln('  3. Check console logs for sync errors');
          } else {
            results.writeln('✅ Amounts match! Goal sync is working correctly.');
          }
        }
      }

      // 3. Create and test a transaction
      results.writeln('');
      results.writeln('🧪 STEP 3: Creating Test Transaction');
      results.writeln('-' * 30);

      final categoryToUse =
          carGoal.linkedCategories.isNotEmpty
              ? carGoal.linkedCategories.first
              : 'Salary';

      final testTransaction = Transaction(
        description:
            'TEST: Goal Sync Diagnostic - ${DateTime.now().millisecondsSinceEpoch}',
        amount: 25.0, // Small test amount
        date: DateTime.now(),
        category: categoryToUse,
        type: 'income',
        status: 'completed',
        paymentMethodId: 'test',
        accountId: 'test',
        isRecurring: false,
      );

      results.writeln('Creating test transaction:');
      results.writeln('  - Description: ${testTransaction.description}');
      results.writeln('  - Amount: \$${testTransaction.amount}');
      results.writeln('  - Category: "${testTransaction.category}"');
      results.writeln('  - Type: ${testTransaction.type}');
      results.writeln('');

      final beforeAmount = carGoal.currentAmount;
      results.writeln('Goal amount before transaction: \$${beforeAmount}');

      // Create the transaction (this should trigger goal sync)
      results.writeln('🔄 Creating transaction...');
      await transactionService.createTransaction(testTransaction);
      results.writeln('✅ Transaction created successfully!');

      // Wait a moment for sync
      await Future.delayed(const Duration(seconds: 2));

      // Check goal again
      results.writeln('🔍 Checking goal after transaction...');
      final updatedGoals = await _goalService.fetchGoals();
      final updatedCarGoal =
          updatedGoals
              .where((g) => g.name.toLowerCase().contains('car'))
              .firstOrNull;

      if (updatedCarGoal != null) {
        results.writeln(
          'Goal amount after transaction: \$${updatedCarGoal.currentAmount}',
        );
        final change = updatedCarGoal.currentAmount - beforeAmount;
        results.writeln('Change: \$${change}');

        if (change > 0) {
          results.writeln('✅ SUCCESS! Goal was updated by \$${change}');
          results.writeln('🎉 Goal-transaction sync is working!');
        } else {
          results.writeln('❌ FAILURE! Goal was not updated');
          results.writeln('');
          results.writeln('🚨 SYNC IS NOT WORKING!');
          results.writeln('🔧 Check these issues:');
          results.writeln('  1. Goal sync service not being called');
          results.writeln('  2. Category matching not working');
          results.writeln('  3. Goal updates not persisting');
          results.writeln('  4. Check console for error messages');
        }
      }

      // Cleanup: Find and delete the test transaction
      results.writeln('');
      results.writeln('🧹 Cleaning up test transaction...');
      try {
        final allTransactions = await transactionService.fetchTransactions();
        final testTransactionToDelete =
            allTransactions
                .where((t) => t.description == testTransaction.description)
                .firstOrNull;

        if (testTransactionToDelete?.id != null) {
          await transactionService.deleteTransaction(
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
      results.writeln('❌ Diagnostic failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  /// Fix Emergency Funds goal to match actual Savings transactions
  Future<void> _fixEmergencyFundsGoal() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Fixing Emergency Funds goal...\n\n';
    });

    final results = StringBuffer();

    try {
      results.writeln('🔧 FIXING EMERGENCY FUNDS GOAL');
      results.writeln('=' * 40);
      results.writeln('');

      // Get the Emergency Funds goal
      final goals = await _goalService.fetchGoals();
      final emergencyGoal = goals.firstWhere(
        (goal) => goal.name == 'Emergency Funds',
        orElse: () => throw Exception('Emergency Funds goal not found'),
      );

      results.writeln('📊 Current Emergency Funds Goal:');
      results.writeln('   - Current amount: \$${emergencyGoal.currentAmount}');
      results.writeln('   - Target amount: \$${emergencyGoal.targetAmount}');
      results.writeln(
        '   - Linked categories: ${emergencyGoal.linkedCategories}',
      );
      results.writeln('');

      // Get all Savings transactions to calculate correct amount
      final transactionService = TransactionService();
      final transactions = await transactionService.fetchTransactions();
      final savingsTransactions =
          transactions.where((t) => t.category == 'Savings').toList();

      double correctAmount = 0;
      results.writeln(
        '💰 Calculating correct amount from Savings transactions:',
      );
      for (final transaction in savingsTransactions) {
        if (transaction.type == 'income' || transaction.type == 'transfer_in') {
          correctAmount += transaction.amount;
          results.writeln(
            '   + \$${transaction.amount} (${transaction.description})',
          );
        } else if (transaction.type == 'expense' && transaction.amount < 0) {
          final absAmount = transaction.amount.abs();
          correctAmount += absAmount;
          results.writeln(
            '   + \$${absAmount} (${transaction.description} - converted from negative expense)',
          );
        }
      }

      results.writeln('');
      results.writeln(
        '✅ Correct amount should be: \$${correctAmount.toStringAsFixed(2)}',
      );
      results.writeln(
        '❌ Current amount is: \$${emergencyGoal.currentAmount.toStringAsFixed(2)}',
      );

      final difference = emergencyGoal.currentAmount - correctAmount;
      results.writeln(
        '🔧 Need to adjust by: -\$${difference.toStringAsFixed(2)}',
      );
      results.writeln('');

      // Set the goal to the correct amount
      results.writeln('🎯 Setting goal to correct amount...');
      await _goalService.setGoalProgress(emergencyGoal.id!, correctAmount);

      results.writeln('✅ Emergency Funds goal fixed!');
      results.writeln('   - New amount: \$${correctAmount.toStringAsFixed(2)}');
      results.writeln(
        '   - Progress: ${((correctAmount / emergencyGoal.targetAmount) * 100).toStringAsFixed(1)}%',
      );
      results.writeln('');
      results.writeln(
        '🎉 Your goal now accurately reflects only your Savings transactions!',
      );
    } catch (e) {
      results.writeln('❌ Fix failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals API Test'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'API Endpoint Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Base URL: https://srv797850.hstgr.cloud/api/goals',
                    ),
                    const Text('Authentication: Bearer Token Required'),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runTests,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child:
                            _isLoading
                                ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Running Tests...'),
                                  ],
                                )
                                : const Text('Run API Tests'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runDiagnosis,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Diagnose API Response'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testGoalCreation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Test Goal Creation'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testGoalSync,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🚗 Test Goal Sync (Car Goal)'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetCarGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🔄 Reset Car Goal to \$0'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runQuickSyncDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red.shade700,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🚨 Quick Sync Diagnostic'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _runQuickSyncDiagnostic,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🔍 Diagnose Category Sync'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _fixEmergencyFundsGoal,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('🔧 Fix Emergency Funds Goal'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Test Results:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              height: 400, // Fixed height for results area
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SingleChildScrollView(
                child: Text(
                  _testResults.isEmpty
                      ? 'Click "Run API Tests" to test the goals API integration...'
                      : _testResults,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 20), // Bottom padding
          ],
        ),
      ),
    );
  }
}
