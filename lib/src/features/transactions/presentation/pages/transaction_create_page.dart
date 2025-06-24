import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';
import '../../../dashboard/data/services/dashboard_sync_service.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/data/services/goal_transaction_sync_service.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';

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
          data: Theme.of(
            context,
          ).copyWith(colorScheme: Theme.of(context).colorScheme),
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
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 24,
                    ),
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
                      Icon(
                        Icons.flag,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 20,
                      ),
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
            // Navigate back to previous screen
            context.pop();
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isEditMode = widget.mode == 'edit';

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: AppGradientBackground(
          child: SafeArea(
            child: Column(
              children: [
                // Modern App Bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed:
                            () => context.pop(),
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color:
                              theme.brightness == Brightness.dark
                                  ? colorScheme.onSurface
                                  : Colors.white,
                          size: 20,
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Column(
                            children: [
                              Text(
                                isEditMode
                                    ? 'Edit Transaction'
                                    : 'New Transaction',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color:
                                      theme.brightness == Brightness.dark
                                          ? colorScheme.onSurface
                                          : Colors.white,
                                ),
                              ),
                              if (isEditMode)
                                Text(
                                  'Update your transaction details',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.brightness == Brightness.dark
                                            ? colorScheme.onSurfaceVariant
                                            : Colors.white.withValues(
                                              alpha: 0.8,
                                            ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // Balance the back button
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Column(
                      children: [
                        // Top handle
                        Container(
                          margin: const EdgeInsets.only(top: 12),
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.4,
                            ),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Form content
                        Expanded(
                          child: SafeArea(
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Transaction Type Selector
                                    _buildTransactionTypeSelector(
                                      theme,
                                      colorScheme,
                                    ),
                                    const SizedBox(height: AppSpacing.lg),

                                    // Amount Input
                                    _buildAmountInput(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.md),

                                    // Description Input
                                    _buildDescriptionInput(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.md),

                                    // Category Selection
                                    _buildCategorySelection(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.md),

                                    // Goal Impact Display
                                    if (_affectedGoals.isNotEmpty)
                                      _buildGoalImpactCard(theme, colorScheme),

                                    // Date Selection
                                    _buildDateSelection(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.md),

                                    // Notes Input
                                    _buildNotesInput(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.md),

                                    // Recurring Toggle
                                    _buildRecurringToggle(theme, colorScheme),
                                    const SizedBox(height: AppSpacing.lg),

                                    // Error Message
                                    if (_errorMessage != null)
                                      _buildErrorMessage(theme, colorScheme),

                                    // Submit Button
                                    _buildSubmitButton(
                                      theme,
                                      colorScheme,
                                      isEditMode,
                                    ),

                                    // Bottom spacing
                                    const SizedBox(height: AppSpacing.xl),
                                  ],
                                ),
                              ),
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
    );
  }

  // Helper method to build transaction type selector
  Widget _buildTransactionTypeSelector(
    ThemeData theme,
    ColorScheme colorScheme,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _transactionType = 'expense';
                  _selectedCategory = _categories[_transactionType]!.first;
                });
                _checkGoalImpacts();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color:
                      _transactionType == 'expense'
                          ? colorScheme.error
                          : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.remove_circle_outline,
                      color:
                          _transactionType == 'expense'
                              ? colorScheme.onError
                              : colorScheme.error,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Expense',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            _transactionType == 'expense'
                                ? colorScheme.onError
                                : colorScheme.error,
                        fontWeight: FontWeight.w600,
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
                  _selectedCategory = _categories[_transactionType]!.first;
                });
                _checkGoalImpacts();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color:
                      _transactionType == 'income'
                          ? AppTheme.successColor
                          : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_circle_outline,
                      color:
                          _transactionType == 'income'
                              ? Colors.white
                              : AppTheme.successColor,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Income',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color:
                            _transactionType == 'income'
                                ? Colors.white
                                : AppTheme.successColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build amount input
  Widget _buildAmountInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Amount',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}$')),
          ],
          validator: _validateAmount,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color:
                _transactionType == 'expense'
                    ? colorScheme.error
                    : AppTheme.successColor,
          ),
          decoration: InputDecoration(
            hintText: '0.00',
            prefixIcon: Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                '\$',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color:
                      _transactionType == 'expense'
                          ? colorScheme.error
                          : AppTheme.successColor,
                ),
              ),
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color:
                    _transactionType == 'expense'
                        ? colorScheme.error
                        : AppTheme.successColor,
                width: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build description input
  Widget _buildDescriptionInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Description',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _descriptionController,
          validator: _validateDescription,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: 'What was this transaction for?',
            prefixIcon: Icon(
              Icons.description_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build category selection
  Widget _buildCategorySelection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedCategory.isEmpty ? null : _selectedCategory,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              prefixIcon: Icon(
                Icons.category_outlined,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            hint: const Text('Select a category'),
            items:
                _categories[_transactionType]!.map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(
                          _categoryIcons[category] ?? Icons.category,
                          size: 20,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.md),
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
      ],
    );
  }

  // Helper method to build goal impact card
  Widget _buildGoalImpactCard(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.flag, color: colorScheme.primary, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Goal Impact',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ..._affectedGoals.map((goal) {
            final amount = double.tryParse(_amountController.text) ?? 0;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Text(
                amount > 0
                    ? '💡 "${goal.name}" will increase by \$${amount.toStringAsFixed(0)}'
                    : '💡 This will update "${goal.name}" goal',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // Helper method to build date selection
  Widget _buildDateSelection(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        GestureDetector(
          onTap: _selectDate,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                  : colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.md),
                Text(
                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                  style: theme.textTheme.bodyLarge,
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build notes input
  Widget _buildNotesInput(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: _notesController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Add any additional notes...',
            prefixIcon: Icon(
              Icons.note_outlined,
              color: colorScheme.onSurfaceVariant,
            ),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 2),
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to build recurring toggle
  Widget _buildRecurringToggle(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
            : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.repeat, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Recurring Transaction',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Switch(
            value: _isRecurring,
            onChanged: (value) {
              setState(() {
                _isRecurring = value;
              });
            },
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  // Helper method to build error message
  Widget _buildErrorMessage(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              _errorMessage!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to build submit button
  Widget _buildSubmitButton(
    ThemeData theme,
    ColorScheme colorScheme,
    bool isEditMode,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createTransaction,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              _transactionType == 'expense'
                  ? AppTheme.errorColor
                  : AppTheme.successColor,
          foregroundColor:
              _transactionType == 'expense' ? Colors.white : Colors.white,
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _transactionType == 'expense'
                          ? colorScheme.onError
                          : Colors.white,
                    ),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isEditMode
                          ? Icons.save
                          : (_transactionType == 'expense'
                              ? Icons.remove_circle_outline
                              : Icons.add_circle_outline),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      isEditMode
                          ? 'Update Transaction'
                          : 'Add ${_transactionType == 'expense' ? 'Expense' : 'Income'}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
