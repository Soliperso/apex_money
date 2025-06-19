import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../transactions/data/services/transaction_service.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../data/services/dashboard_sync_service.dart';
import 'package:apex_money/src/shared/utils/avatar_utils.dart';
import 'package:apex_money/src/shared/services/user_profile_notifier.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin {
  final TransactionService _transactionService = TransactionService();
  final GoalService _goalService = GoalService();
  final DashboardSyncService _syncService = DashboardSyncService();
  final UserProfileNotifier _profileNotifier = UserProfileNotifier();
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
  double _overallGoalProgress = 0.0;
  double _totalSavedAmount = 0.0;
  double _totalTargetAmount = 0.0;

  // Category breakdown data for charts
  Map<String, double> _categoryBreakdown = {};
  List<Transaction> _currentMonthTransactions = [];

  @override
  void initState() {
    super.initState();
    _loadData();
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

    // Initial profile fetch
    _profileNotifier.fetchUserProfile();
  }

  @override
  void dispose() {
    // Clear the sync callback when dashboard is disposed
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
          if (transaction.type.toLowerCase() == 'expense' || transaction.amount < 0) {
            final category = transaction.category;
            final amount = transaction.amount.abs();
            categoryTotals[category] = (categoryTotals[category] ?? 0.0) + amount;
          }
        }

        // Handle amounts properly - income should be positive, expenses should be negative in storage
        if (transaction.type.toLowerCase() == 'income' ||
            transaction.amount > 0) {
          if (isCurrentMonth) {
            income += transaction.amount.abs(); // Ensure positive for income
          }
          if (isPreviousMonth) {
            prevIncome += transaction.amount.abs();
          }
        } else {
          if (isCurrentMonth) {
            expenses +=
                transaction.amount
                    .abs(); // Convert negative expenses to positive for display
          }
          if (isPreviousMonth) {
            prevExpenses += transaction.amount.abs();
          }
        }
      }

      setState(() {
        _recentTransactions =
            transactions.take(5).toList(); // Show only recent 5
        _totalIncome = income;
        _totalExpenses = expenses;
        _previousIncome = prevIncome;
        _previousExpenses = prevExpenses;
        _savings = income - expenses;
        _currentMonthTransactions = currentMonthTransactions;
        _categoryBreakdown = categoryTotals;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
        // Keep empty lists as fallback
        _recentTransactions = [];
        _totalIncome = 0.0;
        _totalExpenses = 0.0;
        _savings = 0.0;
        // Reset goal data on error
        _totalGoals = 0;
        _overallGoalProgress = 0.0;
        _totalSavedAmount = 0.0;
        _totalTargetAmount = 0.0;
      });
    }
  }

  Future<void> _loadGoalStatistics() async {
    try {
      final stats = await _goalService.getGoalStatistics();

      _totalGoals = stats['totalGoals'] ?? 0;
      _overallGoalProgress = stats['overallProgress'] ?? 0.0;
      _totalSavedAmount = stats['totalSavedAmount'] ?? 0.0;
      _totalTargetAmount = stats['totalTargetAmount'] ?? 0.0;
    } catch (e) {
      print('Error loading goal statistics: $e');
      // Reset to defaults on error
      _totalGoals = 0;
      _overallGoalProgress = 0.0;
      _totalSavedAmount = 0.0;
      _totalTargetAmount = 0.0;
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      // Use the profile notifier to fetch and broadcast
      await _profileNotifier.fetchUserProfile();

      // The dashboard profile will be updated via the stream listener
      // which is set up in initState()
    } catch (e) {
      print('Error loading user profile: $e');
      // Keep default values on error
      setState(() {
        _userName = '';
        _userProfilePicture = null;
      });
    }
  }

  // Public method to refresh dashboard data when transactions are updated
  Future<void> refreshData() async {
    await _loadData();
  }

  // Debug method to check data
  Future<void> _debugData() async {
    try {
      print('=== DASHBOARD DEBUG ===');

      // Check transactions
      final transactions = await _transactionService.fetchTransactions();
      print('Total transactions: ${transactions.length}');
      for (int i = 0; i < transactions.length && i < 5; i++) {
        final t = transactions[i];
        print('Transaction $i: ${t.description} - \$${t.amount} (${t.type})');
      }

      // Check goals
      final goals = await _goalService.fetchGoals();
      print('Total goals: ${goals.length}');
      for (int i = 0; i < goals.length; i++) {
        final g = goals[i];
        print('Goal $i: ${g.name} - \$${g.currentAmount}/\$${g.targetAmount}');
      }

      // Check goal statistics
      final stats = await _goalService.getGoalStatistics();
      print('Goal stats: $stats');

      print('=== END DEBUG ===');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Debug info printed to console'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      print('Debug failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon:
                _isLoading
                    ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                    : const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadTransactions,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: _debugData,
            tooltip: 'Debug',
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // TODO: Navigate to notifications
            },
          ),
          IconButton(
            icon: AvatarUtils.buildAvatar(
              userName: _userName,
              profilePicture: _userProfilePicture,
              radius: 16,
              fontSize: 14,
            ),
            onPressed: () {
              GoRouter.of(context).go('/profile');
            },
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blueAccent, Colors.white],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.only(bottom: 20.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 5,
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(
                        Icons.person,
                        size: 30,
                        color: Colors.blueAccent,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _firstName.isNotEmpty
                                ? 'Welcome back, $_firstName!'
                                : 'Welcome back!',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'Here\'s your financial overview',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Financial Summary Cards
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'Income',
                      '\$${_totalIncome.toStringAsFixed(2)}',
                      Icons.trending_up,
                      Colors.green,
                      _isLoading
                          ? '...'
                          : _incomePercentage, // Use calculated percentage
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildFinancialCard(
                      'Expenses',
                      '\$${_totalExpenses.toStringAsFixed(2)}',
                      Icons.trending_down,
                      Colors.red,
                      _isLoading
                          ? '...'
                          : _expensesPercentage, // Use calculated percentage
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialCard(
                      'Savings',
                      '\$${_savings.toStringAsFixed(2)}',
                      Icons.savings,
                      Colors.blue,
                      _isLoading
                          ? '...'
                          : (_savings > 0 ? '+' : '') +
                              '${((_savings / (_totalIncome > 0 ? _totalIncome : 1)) * 100).toStringAsFixed(0)}%',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => GoRouter.of(context).go('/goals'),
                      child: _buildFinancialCard(
                        'Goals',
                        _isLoading
                            ? '...'
                            : _totalGoals == 0
                            ? 'No Goals'
                            : '\$${_totalSavedAmount.toStringAsFixed(0)}',
                        Icons.flag,
                        Colors.orange,
                        _isLoading
                            ? '...'
                            : _totalGoals == 0
                            ? 'Set Goals'
                            : _totalTargetAmount > 0
                            ? '${(_overallGoalProgress * 100).toStringAsFixed(1)}%'
                            : '0%',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Quick Actions
              _buildSectionHeader('Quick Actions', Icons.flash_on),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickAction(
                    'Add Expense',
                    Icons.add_circle_outline,
                    Colors.red,
                    () => GoRouter.of(context).go('/create-transaction'),
                  ),
                  _buildQuickAction(
                    'Add Income',
                    Icons.add_circle,
                    Colors.green,
                    () => GoRouter.of(context).go('/create-transaction'),
                  ),
                  _buildQuickAction(
                    'Set Goal',
                    Icons.flag_outlined,
                    Colors.orange,
                    () => GoRouter.of(context).go('/goals'),
                  ),
                  _buildQuickAction(
                    'View Report',
                    Icons.bar_chart,
                    Colors.purple,
                    () => GoRouter.of(context).go('/ai-insights'),
                  ),
                ],
              ),

              const SizedBox(height: 30),

              // Recent Transactions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _buildSectionHeader(
                      'Recent Transactions',
                      Icons.receipt_long,
                    ),
                  ),
                  TextButton(
                    onPressed: () => GoRouter.of(context).go('/transactions'),
                    child: const Text(
                      'View All',
                      style: TextStyle(
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    _isLoading
                        ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Colors.blueAccent,
                            ),
                          ),
                        )
                        : _error != null
                        ? Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                color: Colors.red,
                                size: 48,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Unable to load transactions',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _error!,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: _loadTransactions,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        )
                        : _recentTransactions.isEmpty
                        ? const Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.receipt_long_outlined,
                                color: Colors.grey,
                                size: 48,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'No transactions yet',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'Start by adding your first transaction',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentTransactions.length,
                          itemBuilder: (context, index) {
                            final transaction = _recentTransactions[index];
                            final isIncome =
                                transaction.type.toLowerCase() == 'income' ||
                                transaction.amount > 0;
                            return _buildTransactionTile(
                              transaction.description,
                              '${isIncome ? '+' : '-'}\$${transaction.amount.abs().toStringAsFixed(2)}',
                              transaction.category,
                              _getTransactionIcon(transaction.category),
                              isIncome ? Colors.green : Colors.red,
                            );
                          },
                        ),
              ),

              const SizedBox(height: 30),

              // Spending Breakdown Chart
              if (_categoryBreakdown.isNotEmpty) ...[
                _buildSectionHeader('Spending Breakdown', Icons.pie_chart),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: _buildCategoryPieChart(),
                        ),
                        const SizedBox(height: 16),
                        _buildCategoryLegend(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // Monthly Spending Trend
              if (_currentMonthTransactions.isNotEmpty) ...[
                _buildSectionHeader('Monthly Trend', Icons.show_chart),
                const SizedBox(height: 16),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: _buildMonthlyTrendChart(),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // AI Insights
              _buildSectionHeader('Smart Insights', Icons.psychology),
              const SizedBox(height: 16),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: _buildSmartInsights(),
                  ),
                ),
              ),

              const SizedBox(height: 100), // Extra space for bottom navigation
            ],
          ),
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
            currentIndex: 0,
            selectedItemColor: const Color(0xFF64B5F6),
            unselectedItemColor: Colors.grey.shade500,
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
                  GoRouter.of(context).go('/ai-insights');
                  break;
              }
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/create-transaction');
        },
        backgroundColor: Colors.blueAccent,
        shape: const CircleBorder(),
        child: const Icon(Icons.receipt_long, color: Colors.white),
        tooltip: 'Add Transaction',
      ),
    );
  }

  Widget _buildFinancialCard(
    String title,
    String amount,
    IconData icon,
    Color color,
    String change,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    change,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              amount,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blueAccent, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAction(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionTile(
    String title,
    String amount,
    String category,
    IconData icon,
    Color color,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        category,
        style: TextStyle(color: Colors.grey[600], fontSize: 12),
      ),
      trailing: Text(
        amount,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }

  Widget _buildInsightTile(
    String title,
    String description,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                description,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
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
  } // Avatar methods removed - now using shared AvatarUtils

  @override
  bool get wantKeepAlive => true;

  // Helper method to get first name from full name
  String get _firstName {
    if (_userName.isEmpty) return '';
    return _userName.split(' ').first;
  }

  /// Calculate percentage change between current and previous values
  String _calculatePercentageChange(double current, double previous) {
    if (previous == 0) {
      return current > 0 ? '+100%' : '0%';
    }

    final change = ((current - previous) / previous) * 100;
    final sign = change >= 0 ? '+' : '';
    return '$sign${change.toStringAsFixed(0)}%';
  }

  /// Get income percentage change
  String get _incomePercentage =>
      _calculatePercentageChange(_totalIncome, _previousIncome);

  /// Get expenses percentage change
  String get _expensesPercentage =>
      _calculatePercentageChange(_totalExpenses, _previousExpenses);

  // Chart Building Methods
  Widget _buildCategoryPieChart() {
    if (_categoryBreakdown.isEmpty) {
      return const Center(
        child: Text(
          'No expense data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final sections = _categoryBreakdown.entries
        .map((entry) {
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
        })
        .toList();

    return PieChart(
      PieChartData(
        sections: sections,
        centerSpaceRadius: 40,
        sectionsSpace: 2,
      ),
    );
  }

  Widget _buildCategoryLegend() {
    if (_categoryBreakdown.isEmpty) return const SizedBox.shrink();

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _categoryBreakdown.entries.map((entry) {
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
            const SizedBox(width: 4),
            Text(
              '${entry.key}: \$${entry.value.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyTrendChart() {
    if (_currentMonthTransactions.isEmpty) {
      return const Center(
        child: Text(
          'No transaction data available',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Group transactions by day and calculate daily totals
    final dailyTotals = <int, double>{};
    
    for (final transaction in _currentMonthTransactions) {
      if (transaction.type.toLowerCase() == 'expense' || transaction.amount < 0) {
        final day = transaction.date.day;
        dailyTotals[day] = (dailyTotals[day] ?? 0.0) + transaction.amount.abs();
      }
    }

    if (dailyTotals.isEmpty) {
      return const Center(
        child: Text(
          'No expense data for trend analysis',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    final spots = dailyTotals.entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value))
        .toList()
      ..sort((a, b) => a.x.compareTo(b.x));

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _totalExpenses / 5,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.withValues(alpha: 0.3),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 32,
              interval: 5,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  '\$${value.toInt()}',
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(
            color: Colors.grey.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blueAccent,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.blueAccent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blueAccent.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSmartInsights() {
    final insights = <Widget>[];
    
    if (_categoryBreakdown.isEmpty) {
      return [
        _buildInsightTile(
          'Start Tracking',
          'Add some transactions to see personalized insights',
          Icons.info_outline,
          Colors.blue,
        ),
      ];
    }

    // Find highest spending category
    final topCategory = _categoryBreakdown.entries
        .reduce((a, b) => a.value > b.value ? a : b);
    
    final topCategoryPercentage = 
        (_categoryBreakdown[topCategory.key]! / _totalExpenses * 100);
    
    insights.add(
      _buildInsightTile(
        'Top Spending Category',
        '${topCategory.key} accounts for ${topCategoryPercentage.toStringAsFixed(1)}% of your expenses (\$${topCategory.value.toStringAsFixed(0)})',
        Icons.trending_up,
        Colors.orange,
      ),
    );

    // Compare with previous month
    if (_previousExpenses > 0) {
      final expenseChange = _totalExpenses - _previousExpenses;
      final changePercentage = (expenseChange / _previousExpenses * 100).abs();
      
      if (expenseChange > 0) {
        insights.add(const Divider());
        insights.add(
          _buildInsightTile(
            'Spending Alert',
            'You\'ve spent \$${expenseChange.toStringAsFixed(0)} (${changePercentage.toStringAsFixed(1)}%) more than last month',
            Icons.warning_amber,
            Colors.red,
          ),
        );
      } else if (expenseChange < 0) {
        insights.add(const Divider());
        insights.add(
          _buildInsightTile(
            'Great Job!',
            'You\'ve saved \$${expenseChange.abs().toStringAsFixed(0)} (${changePercentage.toStringAsFixed(1)}%) compared to last month',
            Icons.celebration,
            Colors.green,
          ),
        );
      }
    }

    // Savings insight
    if (_totalIncome > 0) {
      final savingsRate = (_savings / _totalIncome * 100);
      insights.add(const Divider());
      
      if (savingsRate >= 20) {
        insights.add(
          _buildInsightTile(
            'Excellent Savings!',
            'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Keep up the great work!',
            Icons.star,
            Colors.green,
          ),
        );
      } else if (savingsRate >= 10) {
        insights.add(
          _buildInsightTile(
            'Good Progress',
            'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Try to reach 20% for optimal financial health.',
            Icons.thumb_up,
            Colors.blue,
          ),
        );
      } else if (savingsRate > 0) {
        insights.add(
          _buildInsightTile(
            'Room for Improvement',
            'You\'re saving ${savingsRate.toStringAsFixed(1)}% of your income. Consider reducing expenses in your top spending category.',
            Icons.lightbulb_outline,
            Colors.orange,
          ),
        );
      } else {
        insights.add(
          _buildInsightTile(
            'Budget Alert',
            'You\'re spending more than you earn. Review your ${topCategory.key} expenses first.',
            Icons.warning,
            Colors.red,
          ),
        );
      }
    }

    return insights;
  }
}
