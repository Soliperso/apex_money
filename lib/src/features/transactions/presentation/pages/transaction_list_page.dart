import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';
import '../../../dashboard/data/services/dashboard_sync_service.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

class TransactionListPage extends StatefulWidget {
  const TransactionListPage({Key? key}) : super(key: key);

  @override
  _TransactionListPageState createState() => _TransactionListPageState();
}

class _TransactionListPageState extends State<TransactionListPage> {
  late Future<List<Transaction>> _transactionsFuture;
  List<Transaction> _allTransactions = [];
  List<Transaction> _filteredTransactions = [];

  // Filter state
  String _selectedFilter = 'all'; // 'all', 'income', 'expense'
  DateTimeRange? _selectedDateRange;
  Set<String> _selectedCategories = {};
  String _searchQuery = '';
  double? _minAmount;
  double? _maxAmount;
  Set<String> _selectedPaymentMethods = {};
  bool _isFilterActive = false;

  // Bulk selection state
  bool _isSelectionMode = false;
  Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    _transactionsFuture = TransactionService().fetchTransactions();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final transactions = await TransactionService().fetchTransactions();
      print('Debug: Loaded ${transactions.length} transactions from service');
      for (int i = 0; i < transactions.length && i < 3; i++) {
        final t = transactions[i];
        print(
          'Debug: Transaction $i - desc: "${t.description}", amount: ${t.amount}, type: "${t.type}", category: "${t.category}", id: ${t.id}',
        );
      }
      setState(() {
        _allTransactions = transactions;
        _applyFilters(); // Apply current filters to new data
      });
    } catch (e) {
      // Handle error
      print('Error loading transactions: $e');
    }
  }

  void _applyFilters() {
    print(
      'Debug: Applying filters - selectedFilter: $_selectedFilter, allTransactions: ${_allTransactions.length}',
    );
    setState(() {
      _filteredTransactions =
          _allTransactions.where((transaction) {
            // Filter by type
            if (_selectedFilter == 'income') {
              // For income, check if type is income OR amount is positive
              final typeCheck = transaction.type.toLowerCase();
              final isPositiveAmount = transaction.amount > 0;
              print(
                'Debug: Income filter - transaction type: "$typeCheck", amount: ${transaction.amount}, isPositive: $isPositiveAmount',
              );
              if (typeCheck != 'income' && !isPositiveAmount) {
                return false;
              }
            } else if (_selectedFilter == 'expense') {
              // For expense, check if type is expense OR amount is negative
              final typeCheck = transaction.type.toLowerCase();
              final isNegativeAmount = transaction.amount < 0;
              print(
                'Debug: Expense filter - transaction type: "$typeCheck", amount: ${transaction.amount}, isNegative: $isNegativeAmount',
              );
              if (typeCheck == 'income' && !isNegativeAmount) {
                return false;
              }
            }

            // Filter by date range
            if (_selectedDateRange != null) {
              final transactionDate = DateTime(
                transaction.date.year,
                transaction.date.month,
                transaction.date.day,
              );
              final startDate = DateTime(
                _selectedDateRange!.start.year,
                _selectedDateRange!.start.month,
                _selectedDateRange!.start.day,
              );
              final endDate = DateTime(
                _selectedDateRange!.end.year,
                _selectedDateRange!.end.month,
                _selectedDateRange!.end.day,
              );

              if (transactionDate.isBefore(startDate) ||
                  transactionDate.isAfter(endDate)) {
                return false;
              }
            } // Filter by search query
            if (_searchQuery.isNotEmpty) {
              if (!transaction.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) &&
                  !(transaction.notes?.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ??
                      false)) {
                return false;
              }
            }

            // Filter by categories
            if (_selectedCategories.isNotEmpty) {
              if (!_selectedCategories.contains(
                transaction.category.toLowerCase(),
              )) {
                return false;
              }
            }

            // Filter by amount range
            if (_minAmount != null && transaction.amount.abs() < _minAmount!) {
              return false;
            }
            if (_maxAmount != null && transaction.amount.abs() > _maxAmount!) {
              return false;
            }

            // Filter by payment methods
            if (_selectedPaymentMethods.isNotEmpty) {
              if (!_selectedPaymentMethods.contains(
                transaction.paymentMethodId,
              )) {
                return false;
              }
            }

            return true;
          }).toList();

      print(
        'Debug: After filtering - filteredTransactions: ${_filteredTransactions.length}',
      );

      // Update filter active state
      _isFilterActive =
          _selectedFilter != 'all' ||
          _selectedDateRange != null ||
          _selectedCategories.isNotEmpty ||
          _searchQuery.isNotEmpty ||
          _minAmount != null ||
          _maxAmount != null ||
          _selectedPaymentMethods.isNotEmpty;
    });
    print('Debug: Filter active state: $_isFilterActive');
  }

  void _clearFilters() {
    setState(() {
      _selectedFilter = 'all';
      _selectedDateRange = null;
      _selectedCategories.clear();
      _searchQuery = '';
      _minAmount = null;
      _maxAmount = null;
      _selectedPaymentMethods.clear();
      _isFilterActive = false;
      _filteredTransactions = _allTransactions;
    });
  }

  Future<void> _deleteTransaction(Transaction transaction) async {
    // Show confirmation dialog
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: Text(
            'Are you sure you want to delete this transaction?\n\n'
            '${transaction.description}\n'
            '\$${transaction.amount.abs().toStringAsFixed(2)}',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting transaction...'),
              ],
            ),
          );
        },
      );
    }

    try {
      // Debug transaction ID information
      print('Debug: Transaction ID: "${transaction.id}"');
      print('Debug: Transaction ID is null: ${transaction.id == null}');
      print('Debug: Transaction description: "${transaction.description}"');

      // Use the actual transaction ID if available, otherwise fallback to generated ID
      final transactionId =
          transaction.id ?? transaction.description.hashCode.toString();

      print('Debug: Using transaction ID for deletion: $transactionId');
      await TransactionService().deleteTransaction(transactionId);

      // Remove from local state using ID if available, otherwise use multiple fields
      setState(() {
        if (transaction.id != null) {
          print('Debug: Removing by ID: ${transaction.id}');
          _allTransactions.removeWhere((t) => t.id == transaction.id);
        } else {
          print('Debug: Removing by description/amount/date match');
          _allTransactions.removeWhere(
            (t) =>
                t.description == transaction.description &&
                t.amount == transaction.amount &&
                t.date == transaction.date,
          );
        }
        _applyFilters(); // Reapply filters to update filtered list
      });

      print('Debug: Transaction deleted successfully from local state');

      // Refresh dashboard to update summary cards after deletion
      DashboardSyncService().refreshDashboard();

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted successfully'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete transaction: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _editTransaction(Transaction transaction) {
    // Navigate to create transaction page with edit mode and pre-filled data
    if (mounted) {
      try {
        GoRouter.of(context).go(
          '/create-transaction',
          extra: {'mode': 'edit', 'transaction': transaction},
        );
      } catch (e) {
        print('Error navigating to edit transaction: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to open edit page. Please try again.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedTransactionIds.clear();
      }
    });
  }

  void _toggleTransactionSelection(String transactionId) {
    setState(() {
      if (_selectedTransactionIds.contains(transactionId)) {
        _selectedTransactionIds.remove(transactionId);
      } else {
        _selectedTransactionIds.add(transactionId);
      }
    });
  }

  void _deleteSelectedTransactions() async {
    if (_selectedTransactionIds.isEmpty) return;

    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transactions'),
          content: Text(
            'Are you sure you want to delete ${_selectedTransactionIds.length} selected transactions?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    // Show loading indicator
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Deleting transactions...'),
              ],
            ),
          );
        },
      );
    }

    try {
      // Delete all selected transactions
      for (String transactionId in _selectedTransactionIds) {
        await TransactionService().deleteTransaction(transactionId);
      }

      // Remove from local state
      setState(() {
        _allTransactions.removeWhere(
          (t) => _selectedTransactionIds.contains(t.id),
        );
        _selectedTransactionIds.clear();
        _isSelectionMode = false;
        _applyFilters();
      });

      // Refresh dashboard
      DashboardSyncService().refreshDashboard();

      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedTransactionIds.length} transactions deleted successfully',
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Hide loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete some transactions: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            _isSelectionMode
                ? Text(
                  '${_selectedTransactionIds.length} selected',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                  ),
                )
                : Text(
                  'Transactions',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                  ),
                ),
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.white.withValues(alpha: 0.9),
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.95)
                    : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
        leading:
            _isSelectionMode
                ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: _toggleSelectionMode,
                )
                : null,
        actions:
            _isSelectionMode
                ? [
                  if (_selectedTransactionIds.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: _deleteSelectedTransactions,
                      tooltip: 'Delete Selected',
                    ),
                ]
                : [
                  IconButton(
                    icon: const Icon(Icons.select_all),
                    onPressed: _toggleSelectionMode,
                    tooltip: 'Select Multiple',
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.white,
                  ),
                  IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.filter_list),
                        if (_isFilterActive)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 10,
                                minHeight: 10,
                              ),
                              child: Text(
                                _getActiveFilterCount().toString(),
                                style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      _showFilterOptions(context);
                    },
                    color:
                        Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurfaceVariant
                            : Colors.white,
                  ),
                  // Bulk action button
                  if (_isSelectionMode)
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        _deleteSelectedTransactions();
                      },
                      tooltip: 'Delete Selected Transactions',
                      color:
                          Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurfaceVariant
                              : Colors.white,
                    ),
                ],
      ),
      body: AppGradientBackground(
        child: FutureBuilder<List<Transaction>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Loading transactions...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error: ${snapshot.error}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _transactionsFuture =
                              TransactionService().fetchTransactions();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            } else if (!snapshot.hasData ||
                (snapshot.data!.isEmpty && _allTransactions.isEmpty)) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No transactions found',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Start by adding your first transaction',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        GoRouter.of(context).go('/create-transaction');
                      },
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Add Transaction'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            } else {
              // Update local data when future completes
              if (snapshot.hasData && _allTransactions.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  setState(() {
                    _allTransactions = snapshot.data!;
                    _applyFilters(); // Apply current filters to new data
                  });
                });
              }

              // Use filtered transactions for display
              final transactionsToShow =
                  _allTransactions.isNotEmpty
                      ? _filteredTransactions
                      : snapshot.data!;

              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _transactionsFuture =
                        TransactionService().fetchTransactions();
                  });
                  await _loadTransactions(); // Also update local state
                },
                child:
                    transactionsToShow.isEmpty && _isFilterActive
                        ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.filter_list_off,
                                size: 64,
                                color: Theme.of(context).colorScheme.outline,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No transactions match your filters',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Try adjusting your filter criteria',
                                style: TextStyle(
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  _clearFilters();
                                },
                                icon: const Icon(Icons.clear),
                                label: const Text('Clear Filters'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.primary,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onPrimary,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                        : Column(
                          children: [
                            if (_isFilterActive) _buildFilterSummary(),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.all(16.0),
                                itemCount: transactionsToShow.length,
                                itemBuilder: (context, index) {
                                  final transaction = transactionsToShow[index];
                                  return _buildTransactionCard(
                                    transaction,
                                    index,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
              );
            }
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/create-transaction');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        tooltip: 'Add Transaction',
        child: Icon(
          Icons.receipt_long,
          color: Theme.of(context).colorScheme.onPrimary,
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
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.1),
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
            currentIndex: 1,
            selectedItemColor: const Color(0xFF64B5F6),
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
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
                  // Already on transactions page
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
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final theme = Theme.of(context);
    final isExpense = transaction.amount < 0;
    final color = isExpense ? Colors.red : theme.colorScheme.primary;
    final icon = _getTransactionIcon(transaction.category);
    final isSelected = _selectedTransactionIds.contains(transaction.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border:
            _isSelectionMode && isSelected
                ? Border.all(color: theme.colorScheme.primary, width: 2)
                : null,
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode && transaction.id != null) {
            _toggleTransactionSelection(transaction.id!);
          } else {
            _showTransactionDetails(transaction);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _showTransactionOptions(transaction);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color:
                _isSelectionMode && isSelected
                    ? theme.colorScheme.primary.withValues(alpha: 0.1)
                    : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                if (_isSelectionMode)
                  Container(
                    margin: const EdgeInsets.only(right: 12),
                    child: Checkbox(
                      value: isSelected,
                      onChanged:
                          transaction.id != null
                              ? (bool? value) {
                                _toggleTransactionSelection(transaction.id!);
                              }
                              : null,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainer
                                    .withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transaction.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(transaction.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          // Add status indicator for recurring transactions
                          if (transaction.isRecurring)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.repeat,
                                size: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          // Add location indicator
                          if (transaction.locationName != null &&
                              transaction.locationName!.isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(left: 4),
                              child: Icon(
                                Icons.location_on,
                                size: 14,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Amount and delete button in a compact layout
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      CurrencyFormatter.formatWithSign(transaction.amount),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    if (!_isSelectionMode) ...[
                      const SizedBox(width: 8),
                      // Compact delete button
                      SizedBox(
                        width: 32,
                        height: 32,
                        child: IconButton(
                          icon: const Icon(Icons.delete_outline, size: 20),
                          color: Colors.red,
                          onPressed: () => _deleteTransaction(transaction),
                          tooltip: 'Delete Transaction',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTransactionOptions(Transaction transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: const Text('Edit Transaction'),
                onTap: () async {
                  Navigator.pop(context);
                  // Wait for the bottom sheet to fully close before navigating
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    _editTransaction(transaction);
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete,
                  color: Colors.red,
                ),
                title: const Text('Delete Transaction'),
                onTap: () {
                  Navigator.pop(context);
                  _deleteTransaction(transaction);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getTransactionIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'dining':
      case 'restaurant':
        return Icons.restaurant;
      case 'transport':
      case 'transportation':
        return Icons.directions_car;
      case 'shopping':
        return Icons.shopping_bag;
      case 'entertainment':
        return Icons.movie;
      case 'health':
      case 'medical':
        return Icons.local_hospital;
      case 'utilities':
        return Icons.electrical_services;
      case 'salary':
      case 'income':
        return Icons.attach_money;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _showTransactionDetails(Transaction transaction) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(transaction.description),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                  'Amount',
                  '\$${transaction.amount.abs().toStringAsFixed(2)}',
                ),
                _buildDetailRow('Type', transaction.type),
                _buildDetailRow('Category', transaction.category),
                _buildDetailRow('Date', _formatDate(transaction.date)),
                _buildDetailRow('Status', transaction.status),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  _buildDetailRow('Notes', transaction.notes!),
                if (transaction.isRecurring)
                  _buildDetailRow(
                    'Recurring',
                    'Yes (${transaction.recurringFrequency ?? 'Unknown'})',
                  ),
                if (transaction.locationName != null &&
                    transaction.locationName!.isNotEmpty)
                  _buildDetailRow('Location', transaction.locationName!),
                if (transaction.id != null)
                  _buildDetailRow('ID', transaction.id!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Wait for the dialog to fully close before navigating
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  _editTransaction(transaction);
                }
              },
              child: const Text('Edit'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _EnhancedFilterBottomSheet(
            selectedFilter: _selectedFilter,
            selectedDateRange: _selectedDateRange,
            selectedCategories: _selectedCategories,
            searchQuery: _searchQuery,
            minAmount: _minAmount,
            maxAmount: _maxAmount,
            onFiltersChanged: (
              filter,
              dateRange,
              categories,
              search,
              minAmt,
              maxAmt,
            ) {
              setState(() {
                _selectedFilter = filter;
                _selectedDateRange = dateRange;
                _selectedCategories = categories;
                _searchQuery = search;
                _minAmount = minAmt;
                _maxAmount = maxAmt;
              });
              _applyFilters();
            },
            onClearFilters: _clearFilters,
            isFilterActive: _isFilterActive,
          ),
    );
  }

  int _getActiveFilterCount() {
    int count = 0;
    if (_selectedFilter != 'all') count++;
    if (_selectedDateRange != null) count++;
    if (_selectedCategories.isNotEmpty) count++;
    if (_searchQuery.isNotEmpty) count++;
    if (_minAmount != null || _maxAmount != null) count++;
    if (_selectedPaymentMethods.isNotEmpty) count++;
    return count;
  }

  Widget _buildFilterSummary() {
    List<String> activeFilters = [];

    if (_selectedFilter != 'all') {
      activeFilters.add(_selectedFilter == 'income' ? 'Income' : 'Expenses');
    }

    if (_selectedCategories.isNotEmpty) {
      if (_selectedCategories.length == 1) {
        activeFilters.add(_selectedCategories.first.toUpperCase());
      } else {
        activeFilters.add('${_selectedCategories.length} Categories');
      }
    }

    if (_selectedDateRange != null) {
      activeFilters.add('Date Range');
    }

    if (_searchQuery.isNotEmpty) {
      activeFilters.add(
        'Search: "${_searchQuery.length > 20 ? '${_searchQuery.substring(0, 20)}...' : _searchQuery}"',
      );
    }

    if (_minAmount != null || _maxAmount != null) {
      String amountFilter = 'Amount: ';
      if (_minAmount != null && _maxAmount != null) {
        amountFilter +=
            '\$${_minAmount!.toStringAsFixed(0)} - \$${_maxAmount!.toStringAsFixed(0)}';
      } else if (_minAmount != null) {
        amountFilter += '> \$${_minAmount!.toStringAsFixed(0)}';
      } else {
        amountFilter += '< \$${_maxAmount!.toStringAsFixed(0)}';
      }
      activeFilters.add(amountFilter);
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.filter_list,
            color: Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Active filters: ${activeFilters.join(', ')}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.1),
              foregroundColor: Theme.of(context).colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            child: Text(
              'Clear',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnhancedFilterBottomSheet extends StatefulWidget {
  final String selectedFilter;
  final DateTimeRange? selectedDateRange;
  final Set<String> selectedCategories;
  final String searchQuery;
  final double? minAmount;
  final double? maxAmount;
  final Function(String, DateTimeRange?, Set<String>, String, double?, double?)
  onFiltersChanged;
  final VoidCallback onClearFilters;
  final bool isFilterActive;

  const _EnhancedFilterBottomSheet({
    required this.selectedFilter,
    required this.selectedDateRange,
    required this.selectedCategories,
    required this.searchQuery,
    required this.minAmount,
    required this.maxAmount,
    required this.onFiltersChanged,
    required this.onClearFilters,
    required this.isFilterActive,
  });

  @override
  State<_EnhancedFilterBottomSheet> createState() =>
      _EnhancedFilterBottomSheetState();
}

class _EnhancedFilterBottomSheetState
    extends State<_EnhancedFilterBottomSheet> {
  late String _tempSelectedFilter;
  late DateTimeRange? _tempSelectedDateRange;
  late Set<String> _tempSelectedCategories;
  late String _tempSearchQuery;
  late double? _tempMinAmount;
  late double? _tempMaxAmount;

  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _minAmountController = TextEditingController();
  final TextEditingController _maxAmountController = TextEditingController();

  final List<String> _availableCategories = [
    'food',
    'transport',
    'shopping',
    'entertainment',
    'health',
    'utilities',
    'salary',
    'education',
    'investment',
    'savings',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    _tempSelectedFilter = widget.selectedFilter;
    _tempSelectedDateRange = widget.selectedDateRange;
    _tempSelectedCategories = Set.from(widget.selectedCategories);
    _tempSearchQuery = widget.searchQuery;
    _tempMinAmount = widget.minAmount;
    _tempMaxAmount = widget.maxAmount;

    _searchController.text = _tempSearchQuery;
    _minAmountController.text = _tempMinAmount?.toString() ?? '';
    _maxAmountController.text = _tempMaxAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _searchController.dispose();
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 50,
            height: 5,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2.5),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Filter Transactions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Row(
                  children: [
                    if (widget.isFilterActive)
                      TextButton(
                        onPressed: () {
                          widget.onClearFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Clear All'),
                      ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search
                  _buildSectionTitle('Search'),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by description...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _tempSearchQuery = value;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Transaction Type
                  _buildSectionTitle('Transaction Type'),
                  _buildTransactionTypeChips(),

                  const SizedBox(height: 24),

                  // Categories
                  _buildSectionTitle('Categories'),
                  _buildCategoryChips(),

                  const SizedBox(height: 24),

                  // Amount Range
                  _buildSectionTitle('Amount Range'),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _minAmountController,
                          decoration: InputDecoration(
                            labelText: 'Min Amount',
                            prefixText: '\$',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainer
                                .withValues(alpha: 0.3),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _tempMinAmount = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _maxAmountController,
                          decoration: InputDecoration(
                            labelText: 'Max Amount',
                            prefixText: '\$',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            filled: true,
                            fillColor: Theme.of(context)
                                .colorScheme
                                .surfaceContainer
                                .withValues(alpha: 0.3),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _tempMaxAmount = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Date Range
                  _buildSectionTitle('Date Range'),
                  InkWell(
                    onTap: _selectDateRange,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.date_range,
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _tempSelectedDateRange != null
                                  ? '${_formatDate(_tempSelectedDateRange!.start)} - ${_formatDate(_tempSelectedDateRange!.end)}'
                                  : 'Select date range',
                              style: TextStyle(
                                color:
                                    _tempSelectedDateRange != null
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onSurface
                                        : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          if (_tempSelectedDateRange != null)
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _tempSelectedDateRange = null;
                                });
                              },
                              icon: const Icon(Icons.clear, size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Apply Button
          Container(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onFiltersChanged(
                    _tempSelectedFilter,
                    _tempSelectedDateRange,
                    _tempSelectedCategories,
                    _tempSearchQuery,
                    _tempMinAmount,
                    _tempMaxAmount,
                  );
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Apply Filters',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTransactionTypeChips() {
    return Wrap(
      spacing: 8,
      children: [
        _buildFilterChip(
          'All',
          'all',
          _tempSelectedFilter == 'all',
          Theme.of(context).colorScheme.primary,
          (selected) {
            setState(() {
              _tempSelectedFilter = 'all';
            });
          },
        ),
        _buildFilterChip(
          'Income',
          'income',
          _tempSelectedFilter == 'income',
          Theme.of(context).colorScheme.secondary,
          (selected) {
            setState(() {
              _tempSelectedFilter = 'income';
            });
          },
        ),
        _buildFilterChip(
          'Expenses',
          'expense',
          _tempSelectedFilter == 'expense',
          Theme.of(context).colorScheme.error,
          (selected) {
            setState(() {
              _tempSelectedFilter = 'expense';
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children:
          _availableCategories.map((category) {
            final isSelected = _tempSelectedCategories.contains(category);
            return _buildFilterChip(
              _capitalize(category),
              category,
              isSelected,
              Theme.of(context).colorScheme.tertiary,
              (selected) {
                setState(() {
                  if (selected) {
                    _tempSelectedCategories.add(category);
                  } else {
                    _tempSelectedCategories.remove(category);
                  }
                });
              },
            );
          }).toList(),
    );
  }

  Widget _buildFilterChip(
    String label,
    String value,
    bool isSelected,
    Color color,
    Function(bool) onSelected,
  ) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color : Theme.of(context).colorScheme.outline,
        width: 1,
      ),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.surfaceContainer.withValues(alpha: 0.3),
      labelStyle: TextStyle(
        color:
            isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _tempSelectedDateRange,
    );
    if (picked != null) {
      setState(() {
        _tempSelectedDateRange = picked;
      });
    }
  }
}
