import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';
import '../../../dashboard/data/services/dashboard_sync_service.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/data/services/goal_transaction_sync_service.dart';

class TransactionCreatePage extends StatefulWidget {
  final String mode;
  final Transaction? transaction;

  const TransactionCreatePage({
    super.key,
    this.mode = 'create',
    this.transaction,
  });

  @override
  _TransactionCreatePageState createState() => _TransactionCreatePageState();
}

class _TransactionCreatePageState extends State<TransactionCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String _transactionType = 'expense';
  String _selectedCategory = '';
  bool _isLoading = false;
  bool _isRecurring = false;
  String? _errorMessage;
  List<Goal> _affectedGoals = [];
  String? _goalUpdateMessage;

  // Predefined categories
  final Map<String, List<String>> _categories = {
    'expense': [
      'Housing',
      'Utilities',
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Education',
      'Travel',
      'Groceries',
      'Gas',
      'Other',
    ],
    'income': [
      'Salary',
      'Freelance',
      'Investment',
      'Business',
      'Gift',
      'Bonus',
      'Savings',
      'Other',
    ],
  };

  // Category icons
  final Map<String, IconData> _categoryIcons = {
    'Food & Dining': Icons.restaurant,
    'Housing': Icons.home,
    'Utilities': Icons.lightbulb,
    'Transportation': Icons.directions_car,
    'Shopping': Icons.shopping_bag,
    'Entertainment': Icons.movie,
    'Bills & Utilities': Icons.receipt,
    'Healthcare': Icons.local_hospital,
    'Education': Icons.school,
    'Travel': Icons.flight,
    'Groceries': Icons.local_grocery_store,
    'Gas': Icons.local_gas_station,
    'Salary': Icons.work,
    'Freelance': Icons.laptop,
    'Investment': Icons.trending_up,
    'Business': Icons.business,
    'Gift': Icons.card_giftcard,
    'Bonus': Icons.star,
    'Savings': Icons.savings,
    'Other': Icons.category,
  };

  @override
  void initState() {
    super.initState();

    // Set up goal update callback
    GoalTransactionSyncService().setGoalUpdateCallback((goalName, newAmount) {
      setState(() {
        _goalUpdateMessage =
            'Goal "$goalName" updated to \$${newAmount.toStringAsFixed(0)}';
      });
    });

    // Add listener to amount field for goal hints
    _amountController.addListener(() {
      if (_affectedGoals.isNotEmpty) {
        setState(() {}); // Refresh to update hint amounts
      }
    });

    // If we're in edit mode, pre-fill the form fields
    if (widget.mode == 'edit' && widget.transaction != null) {
      _presetEditMode();
    } else {
      _selectedCategory = _categories[_transactionType]!.first;
    }
  }

  void _presetEditMode() {
    final transaction = widget.transaction!;

    // Pre-fill form fields
    _descriptionController.text = transaction.description;
    _amountController.text =
        transaction.amount.abs().toString(); // Show absolute value
    _notesController.text = transaction.notes ?? '';

    // Set date and transaction type
    _selectedDate = transaction.date;
    _transactionType = transaction.type;

    // Set category (ensure it exists in the category list)
    if (_categories[_transactionType]!.contains(transaction.category)) {
      _selectedCategory = transaction.category;
    } else {
      _selectedCategory = _categories[_transactionType]!.first;
    }

    // Set recurring status
    _isRecurring = transaction.isRecurring;
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _createTransaction() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory.isEmpty) {
      setState(() {
        _errorMessage = 'Please select a category';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Calculate amount with proper sign (negative for expenses, positive for income)
      final rawAmount = double.parse(_amountController.text);
      final finalAmount =
          _transactionType == 'expense' ? -rawAmount.abs() : rawAmount.abs();

      final transaction = Transaction(
        id:
            widget.mode == 'edit'
                ? widget.transaction!.id
                : null, // Preserve ID for updates
        description: _descriptionController.text.trim(),
        amount: finalAmount,
        date: _selectedDate,
        category: _selectedCategory,
        type: _transactionType,
        status: 'completed',
        paymentMethodId:
            widget.mode == 'edit'
                ? widget.transaction!.paymentMethodId
                : 'default',
        accountId:
            widget.mode == 'edit' ? widget.transaction!.accountId : 'default',
        isRecurring: _isRecurring,
        notes:
            _notesController.text.trim().isEmpty
                ? null
                : _notesController.text.trim(),
        // Preserve other fields from original transaction when editing
        toAccountId:
            widget.mode == 'edit' ? widget.transaction!.toAccountId : null,
        recurringFrequency:
            widget.mode == 'edit'
                ? widget.transaction!.recurringFrequency
                : null,
        locationName:
            widget.mode == 'edit' ? widget.transaction!.locationName : null,
        latitude: widget.mode == 'edit' ? widget.transaction!.latitude : null,
        longitude: widget.mode == 'edit' ? widget.transaction!.longitude : null,
      );

      // Call appropriate service method based on mode
      if (widget.mode == 'edit') {
        await TransactionService().updateTransaction(
          widget.transaction!.id!,
          transaction,
        );
      } else {
        await TransactionService().createTransaction(transaction);
      }

      // Refresh dashboard to update summary cards with new transaction
      DashboardSyncService().refreshDashboard();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.mode == 'edit'
                            ? 'Transaction updated successfully!'
                            : '${_transactionType == 'expense' ? 'Expense' : 'Income'} added successfully!',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                if (_goalUpdateMessage != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.flag, color: Theme.of(context).colorScheme.onPrimary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _goalUpdateMessage!,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Add a small delay before navigation to prevent any UI conflicts
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            // Use GoRouter to navigate back to transactions page
            GoRouter.of(context).go('/transactions');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getFriendlyErrorMessage(e.toString());
          _isLoading = false;
        });
      }
    }
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains('Unauthorized') || error.contains('login again')) {
      return 'Session expired. Please login again.';
    } else if (error.contains('Validation error')) {
      return error.replaceAll('Exception: ', '');
    } else if (error.contains('network') ||
        error.contains('connection') ||
        error.contains('SocketException')) {
      return 'Network error. Please check your connection.';
    } else if (error.contains('timeout') ||
        error.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    } else if (error.contains('server') || error.contains('500')) {
      return 'Server error. Please try again later.';
    } else if (error.contains('Invalid server response')) {
      return 'Invalid server response. Please contact support.';
    }
    return 'Failed to create transaction. Please try again.';
  }

  String? _validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a description';
    }
    if (value.trim().length < 3) {
      return 'Description must be at least 3 characters';
    }
    return null;
  }

  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter an amount';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid number';
    }
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 1000000) {
      return 'Amount too large';
    }
    return null;
  }

  Future<void> _checkGoalImpacts() async {
    if (_selectedCategory.isEmpty || _transactionType != 'income') {
      setState(() {
        _affectedGoals = [];
      });
      return;
    }

    try {
      final goals = await GoalService().fetchGoals();
      final affected =
          goals
              .where(
                (goal) =>
                    goal.autoUpdate &&
                    goal.linkedCategories.contains(_selectedCategory),
              )
              .toList();

      setState(() {
        _affectedGoals = affected;
      });
    } catch (e) {
      // Silently fail - goal hints are not critical
      setState(() {
        _affectedGoals = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: Theme.of(context).brightness == Brightness.dark
                ? [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface,
                  ]
                : [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.4),
                    Theme.of(context).colorScheme.surface,
                  ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => GoRouter.of(context).go('/transactions'),
                      icon: Icon(
                        Icons.arrow_back,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Theme.of(context).colorScheme.onSurface
                            : Colors.white,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        widget.mode == 'edit'
                            ? 'Edit Transaction'
                            : 'Add Transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.onSurface
                              : Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the back button
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Transaction Type Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                                spreadRadius: 2,
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _transactionType = 'expense';
                                      _selectedCategory =
                                          _categories[_transactionType]!.first;
                                    });
                                    _checkGoalImpacts();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _transactionType == 'expense'
                                              ? Colors.red
                                              : Colors.transparent,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.remove_circle_outline,
                                          color:
                                              _transactionType == 'expense'
                                                  ? Colors.white
                                                  : Colors.red,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Expense',
                                          style: TextStyle(
                                            color:
                                                _transactionType == 'expense'
                                                    ? Colors.white
                                                    : Colors.red,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _transactionType = 'income';
                                      _selectedCategory =
                                          _categories[_transactionType]!.first;
                                    });
                                    _checkGoalImpacts();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          _transactionType == 'income'
                                              ? Colors.green
                                              : Colors.transparent,
                                      borderRadius: const BorderRadius.only(
                                        topRight: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_circle_outline,
                                          color:
                                              _transactionType == 'income'
                                                  ? Colors.white
                                                  : Colors.green,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Income',
                                          style: TextStyle(
                                            color:
                                                _transactionType == 'income'
                                                    ? Colors.white
                                                    : Colors.green,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Main Form Card
                        Card(
                          elevation: 8,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Error Message
                                if (_errorMessage != null)
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    margin: const EdgeInsets.only(bottom: 16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.errorContainer,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.error_outline,
                                          color: Theme.of(context).colorScheme.error,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            _errorMessage!,
                                            style: TextStyle(
                                              color: Theme.of(context).colorScheme.onErrorContainer,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // Amount Field
                                Text(
                                  'Amount',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _amountController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  inputFormatters: [
                                    FilteringTextInputFormatter.allow(
                                      RegExp(r'^\d*\.?\d{0,2}$'),
                                    ),
                                  ],
                                  validator: _validateAmount,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: '0.00',
                                    prefixIcon: Container(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        '\$',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color:
                                              _transactionType == 'expense'
                                                  ? Colors.red
                                                  : Colors.green,
                                        ),
                                      ),
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color:
                                            _transactionType == 'expense'
                                                ? Colors.red
                                                : Colors.green,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Description Field
                                Text(
                                  'Description',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _descriptionController,
                                  validator: _validateDescription,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: InputDecoration(
                                    hintText: 'What was this transaction for?',
                                    prefixIcon: const Icon(
                                      Icons.description_outlined,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Category Selection
                                Text(
                                  'Category',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: DropdownButtonFormField<String>(
                                    value:
                                        _selectedCategory.isEmpty
                                            ? null
                                            : _selectedCategory,
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 12,
                                      ),
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    hint: const Text('Select a category'),
                                    items:
                                        _categories[_transactionType]!.map((
                                          category,
                                        ) {
                                          return DropdownMenuItem(
                                            value: category,
                                            child: Row(
                                              children: [
                                                Icon(
                                                  _categoryIcons[category] ??
                                                      Icons.category,
                                                  size: 20,
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(category),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCategory = value ?? '';
                                      });
                                      _checkGoalImpacts();
                                    },
                                  ),
                                ),

                                // Goal Impact Hints
                                if (_affectedGoals.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.flag,
                                              color: Theme.of(context).colorScheme.primary,
                                              size: 18,
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Goal Impact',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.primary,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 8),
                                        ...(_affectedGoals.map((goal) {
                                          final amount =
                                              double.tryParse(
                                                _amountController.text,
                                              ) ??
                                              0;
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 4,
                                            ),
                                            child: Text(
                                              amount > 0
                                                  ? '💡 "${goal.name}" will increase by \$${amount.toStringAsFixed(0)}'
                                                  : '💡 This will update "${goal.name}" goal',
                                              style: TextStyle(
                                                color: Theme.of(context).colorScheme.onPrimaryContainer,
                                                fontSize: 13,
                                              ),
                                            ),
                                          );
                                        }).toList()),
                                      ],
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 24),

                                // Date Selection
                                Text(
                                  'Date',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: _selectDate,
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Theme.of(context).colorScheme.outline,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Spacer(),
                                        Icon(
                                          Icons.arrow_forward_ios,
                                          size: 16,
                                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),

                                // Recurring Toggle
                                Row(
                                  children: [
                                    Icon(
                                      Icons.repeat,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 12),
                                    const Text(
                                      'Recurring Transaction',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    const Spacer(),
                                    Switch(
                                      value: _isRecurring,
                                      onChanged: (value) {
                                        setState(() {
                                          _isRecurring = value;
                                        });
                                      },
                                      activeColor: Theme.of(context).colorScheme.primary,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 32),

                                // Create Button
                                SizedBox(
                                  width: double.infinity,
                                  height: 56,
                                  child: ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _createTransaction,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          _transactionType == 'expense'
                                              ? Colors.red
                                              : Colors.green,
                                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                    ),
                                    child:
                                        _isLoading
                                            ? SizedBox(
                                              height: 24,
                                              width: 24,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(Theme.of(context).colorScheme.onPrimary),
                                              ),
                                            )
                                            : Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  widget.mode == 'edit'
                                                      ? Icons.save
                                                      : (_transactionType ==
                                                              'expense'
                                                          ? Icons
                                                              .remove_circle_outline
                                                          : Icons
                                                              .add_circle_outline),
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  widget.mode == 'edit'
                                                      ? 'Update Transaction'
                                                      : 'Add ${_transactionType == 'expense' ? 'Expense' : 'Income'}',
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clear goal update callback
    GoalTransactionSyncService().clearGoalUpdateCallback();

    _descriptionController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
