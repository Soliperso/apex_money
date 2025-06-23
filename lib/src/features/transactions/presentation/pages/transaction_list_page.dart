import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';
import '../../../dashboard/data/services/dashboard_sync_service.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/theme_provider.dart';

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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
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
              content: const Text(
                'Failed to open edit page. Please try again.',
              ),
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
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
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
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: AppGradientBackground(
        child: CustomScrollView(
          slivers: [
            // Modern SliverAppBar
            _buildSliverAppBar(theme, themeProvider),

            // Transaction Content
            SliverToBoxAdapter(
              child: FutureBuilder<List<Transaction>>(
                future: _transactionsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Loading transactions...',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.errorColor,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Error: ${snapshot.error}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.errorColor,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            ElevatedButton(
                              onPressed: () {
                                setState(() {
                                  _transactionsFuture =
                                      TransactionService().fetchTransactions();
                                });
                              },
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else if (!snapshot.hasData ||
                      (snapshot.data!.isEmpty && _allTransactions.isEmpty)) {
                    return Container(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: _buildEmptyState(),
                    );
                  } else {
                    return Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        children: [
                          // Filter Section
                          _buildFilterRow(),
                          const SizedBox(height: AppSpacing.md),

                          // Transaction List
                          _buildTransactionList(),

                          // Extra space for bottom navigation
                          const SizedBox(height: AppSpacing.massive),
                        ],
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => GoRouter.of(context).go('/create-transaction'),
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation:
          const _CustomCenterFloatingActionButtonLocation(),
      bottomNavigationBar: _buildBottomNavigation(theme),
    );
  }

  Widget _buildTransactionCard(Transaction transaction, int index) {
    final theme = Theme.of(context);
    final isExpense = transaction.amount < 0;
    final color = isExpense ? AppTheme.errorColor : theme.colorScheme.primary;
    final icon = _getTransactionIcon(transaction.category);
    final isSelected = _selectedTransactionIds.contains(transaction.id);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _isSelectionMode && isSelected
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: _isSelectionMode && isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: _isSelectionMode && isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () {
          if (_isSelectionMode && transaction.id != null) {
            _toggleTransactionSelection(transaction.id!);
          } else {
            _showTransactionDetails(transaction);
          }
        },
        child: GestureDetector(
          onLongPress: () {
            if (!_isSelectionMode) {
              _showTransactionOptions(transaction);
            }
          },
          child: Row(
            children: [
              if (_isSelectionMode)
                Container(
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  child: Checkbox(
                    value: isSelected,
                    onChanged:
                        transaction.id != null
                            ? (bool? value) =>
                                _toggleTransactionSelection(transaction.id!)
                            : null,
                  ),
                ),
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.description,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Text(
                              transaction.category,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatDate(transaction.date),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        // Add status indicator for recurring transactions
                        if (transaction.isRecurring)
                          Container(
                            margin: const EdgeInsets.only(left: AppSpacing.sm),
                            child: Icon(
                              Icons.repeat,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        if (transaction.locationName != null &&
                            transaction.locationName!.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(left: AppSpacing.xs),
                            child: Icon(
                              Icons.location_on,
                              size: 14,
                              color: theme.colorScheme.secondary,
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (!_isSelectionMode) ...[
                    const SizedBox(width: AppSpacing.sm),
                    // Compact delete button
                    SizedBox(
                      width: 32,
                      height: 32,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        color: AppTheme.errorColor,
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
                leading: Icon(Icons.delete, color: Colors.red),
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
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;
        final isExpense = transaction.amount < 0;
        final amountColor =
            isExpense ? AppTheme.errorColor : colorScheme.primary;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: 20,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Enhanced handle indicator
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),

                // Amount - Primary focus
                Text(
                  CurrencyFormatter.formatWithSign(transaction.amount),
                  style: theme.textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),

                // Minimal details in a subtle container
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            transaction.category,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Date',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(transaction.date),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // Enhanced action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _editTransaction(transaction);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: colorScheme.primary,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppTheme.errorColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                            _deleteTransaction(transaction);
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 18,
                                color: AppTheme.errorColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.errorColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
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
    final theme = Theme.of(context);
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
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xs),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            ),
            child: Icon(
              Icons.filter_list,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Active filters: ${activeFilters.join(', ')}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: _clearFilters,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              backgroundColor: theme.colorScheme.surface,
              foregroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                side: BorderSide(color: theme.colorScheme.primary),
              ),
            ),
            child: Text(
              'Clear',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ThemeProvider themeProvider) {
    final appBarColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : theme.colorScheme.primary;

    final titleColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : Colors.white;

    final iconColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9);

    return SliverAppBar(
      floating: false,
      pinned: true,
      expandedHeight: 56,
      backgroundColor: appBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: theme.colorScheme.shadow,
      forceElevated: false,
      systemOverlayStyle:
          theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.light,
      flexibleSpace: Container(decoration: BoxDecoration(color: appBarColor)),
      title: Text(
        _isSelectionMode
            ? '${_selectedTransactionIds.length} selected'
            : 'Transactions',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      leading:
          _isSelectionMode
              ? IconButton(
                icon: const Icon(Icons.close),
                color: iconColor,
                onPressed: _toggleSelectionMode,
              )
              : null,
      actions:
          _isSelectionMode
              ? [
                if (_selectedTransactionIds.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.delete),
                    color: iconColor,
                    onPressed: _deleteSelectedTransactions,
                    tooltip: 'Delete Selected',
                  ),
              ]
              : [
                IconButton(
                  icon: const Icon(Icons.select_all),
                  color: iconColor,
                  onPressed: _toggleSelectionMode,
                  tooltip: 'Select Multiple',
                ),
                IconButton(
                  icon: const Icon(Icons.search),
                  color: iconColor,
                  onPressed: () {}, // TODO: Implement search
                  tooltip: 'Search Transactions',
                ),
              ],
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: 1,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurfaceVariant,
          backgroundColor: Colors.transparent,
          elevation: 0,
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
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark 
              ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
              : theme.colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Section Header with icon - matching other screens style
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Icon(
                    Icons.receipt_long_outlined,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Icon(
              Icons.receipt_long_outlined,
              size: 48,
              color: Colors.grey.withValues(alpha: 0.4),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No transactions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first transaction to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark 
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all', _selectedFilter == 'all'),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                    'Income',
                    'income',
                    _selectedFilter == 'income',
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  _buildFilterChip(
                    'Expenses',
                    'expense',
                    _selectedFilter == 'expense',
                  ),
                ],
              ),
            ),
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
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 8,
                        minHeight: 8,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed: () => _showFilterOptions(context),
            tooltip: 'More Filters',
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, bool isSelected) {
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (bool selected) {
        setState(() {
          _selectedFilter = value;
        });
        _applyFilters();
      },
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: theme.colorScheme.primary,
      backgroundColor: theme.colorScheme.surfaceContainer.withValues(
        alpha: 0.3,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
    );
  }

  Widget _buildTransactionList() {
    final transactionsToShow =
        _allTransactions.isNotEmpty ? _filteredTransactions : [];

    if (transactionsToShow.isEmpty && _isFilterActive) {
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: Colors.grey.withValues(alpha: 0.4),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'No transactions match your filters',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Try adjusting your filters or add a new transaction',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(
                onPressed: () => context.go('/create-transaction'),
                child: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: transactionsToShow.length,
      itemBuilder:
          (context, index) =>
              _buildTransactionCard(transactionsToShow[index], index),
    );
  }

  // ...existing code...
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
    final theme = Theme.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85;
    final minHeight = screenHeight * 0.5;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight, minHeight: minHeight),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusXl),
          ),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 50,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs,
                          ),
                        ),
                        child: Icon(
                          Icons.filter_list,
                          size: 16,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Filter Transactions',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      if (widget.isFilterActive)
                        TextButton(
                          onPressed: () {
                            widget.onClearFilters();
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppTheme.errorColor,
                          ),
                          child: const Text('Clear All'),
                        ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          foregroundColor: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainer
                            .withValues(alpha: 0.3),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _tempSearchQuery = value;
                        });
                      },
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Transaction Type
                    _buildSectionTitle('Transaction Type'),
                    _buildTransactionTypeChips(),

                    const SizedBox(height: AppSpacing.lg),

                    // Categories
                    _buildSectionTitle('Categories'),
                    _buildCategoryChips(),

                    const SizedBox(height: AppSpacing.lg),

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
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainer
                                  .withValues(alpha: 0.3),
                            ),
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              _tempMinAmount = double.tryParse(value);
                            },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            decoration: InputDecoration(
                              labelText: 'Max Amount',
                              prefixText: '\$',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surfaceContainer
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

                    const SizedBox(height: AppSpacing.lg),

                    // Date Range
                    _buildSectionTitle('Date Range'),
                    InkWell(
                      onTap: _selectDateRange,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          border: Border.all(color: theme.colorScheme.outline),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusMd,
                          ),
                          color: theme.colorScheme.surfaceContainer.withValues(
                            alpha: 0.3,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.date_range,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Text(
                                _tempSelectedDateRange != null
                                    ? '${_formatDate(_tempSelectedDateRange!.start)} - ${_formatDate(_tempSelectedDateRange!.end)}'
                                    : 'Select date range',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      _tempSelectedDateRange != null
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
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
                                style: IconButton.styleFrom(
                                  foregroundColor:
                                      theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),
                  ],
                ),
              ),
            ),

            // Apply Button
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                ),
              ),
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
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                  ),
                  child: Text(
                    'Apply Filters',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
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

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildTransactionTypeChips() {
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      children: [
        _buildFilterChip(
          'All',
          'all',
          _tempSelectedFilter == 'all',
          theme.colorScheme.primary,
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
          theme.colorScheme.secondary,
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
          AppTheme.errorColor,
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
    final theme = Theme.of(context);
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children:
          _availableCategories.map((category) {
            final isSelected = _tempSelectedCategories.contains(category);
            return _buildFilterChip(
              _capitalize(category),
              category,
              isSelected,
              theme.colorScheme.tertiary,
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
    final theme = Theme.of(context);
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      side: BorderSide(
        color: isSelected ? color : theme.colorScheme.outline,
        width: 1,
      ),
      backgroundColor: theme.colorScheme.surfaceContainer.withValues(
        alpha: 0.3,
      ),
      labelStyle: TextStyle(
        color: isSelected ? color : theme.colorScheme.onSurfaceVariant,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
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

/// Custom FloatingActionButtonLocation that positions the FAB slightly above center docked
class _CustomCenterFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _CustomCenterFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the center docked position
    final Offset centerDocked = FloatingActionButtonLocation.centerDocked
        .getOffset(scaffoldGeometry);

    // Move it up by 16 pixels to clear the bottom navigation
    return Offset(centerDocked.dx, centerDocked.dy - 16);
  }
}
