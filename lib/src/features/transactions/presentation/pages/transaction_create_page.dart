import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../data/services/transaction_service.dart';
import '../../data/models/transaction_model.dart';
import '../../../dashboard/data/services/dashboard_sync_service.dart';
import '../../../goals/data/services/goal_service.dart';
import '../../../goals/data/models/goal_model.dart';
import '../../../goals/data/services/goal_transaction_sync_service.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/receipt_scanner_widget.dart';
import '../../../../shared/services/receipt_ocr_service.dart';

class TransactionCreatePage extends StatefulWidget {
  final String mode;
  final Transaction? transaction;
  final String? initialTransactionType;

  const TransactionCreatePage({
    super.key,
    this.mode = 'create',
    this.transaction,
    this.initialTransactionType,
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

    // Set initial transaction type from parameter or default to 'expense'
    if (widget.initialTransactionType != null &&
        _categories.containsKey(widget.initialTransactionType)) {
      _transactionType = widget.initialTransactionType!;
    }

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

        final snackBar = SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.mode == 'edit'
                      ? 'Transaction updated successfully!'
                      : '${_transactionType == 'expense' ? 'Expense' : 'Income'} added successfully!',
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: AppTheme.successColor, // Always green for success
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(
            bottom: 120, // Add bottom margin to avoid button overlap
            left: 16,
            right: 16,
          ),
          duration: const Duration(milliseconds: 1500),
        );

        ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((_) {
          // Navigate only after snackbar is closed/dismissed
          if (mounted && context.mounted) {
            // Dismiss any open keyboards first
            FocusScope.of(context).unfocus();
            context.go('/transactions');
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

  /// Handle back navigation with unsaved changes check
  void _handleBackNavigation() {
    // Check if form has been modified
    final hasChanges =
        _descriptionController.text.isNotEmpty ||
        _amountController.text.isNotEmpty ||
        _notesController.text.isNotEmpty ||
        _selectedDate != DateTime.now().subtract(const Duration(days: 0)) ||
        (widget.mode == 'edit' && _hasFormChanges());

    if (hasChanges && widget.mode != 'edit') {
      // Show confirmation dialog for unsaved changes
      showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              icon: const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.warningColor,
              ),
              title: const Text('Discard Changes?'),
              content: const Text(
                'You have unsaved changes that will be lost. Are you sure you want to go back?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Stay'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                    context.pop(); // Go back
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.warningColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Discard'),
                ),
              ],
            ),
      );
    } else {
      // No changes or edit mode, go back directly
      context.pop();
    }
  }

  /// Check if form has changes in edit mode
  bool _hasFormChanges() {
    if (widget.transaction == null) return false;

    final original = widget.transaction!;
    return _descriptionController.text != original.description ||
        _amountController.text != original.amount.abs().toStringAsFixed(2) ||
        _notesController.text != (original.notes ?? '') ||
        _selectedDate.difference(original.date).inDays.abs() > 0;
  }

  /// Handle receipt scan result and auto-fill form fields
  void _handleReceiptScan(ReceiptScanResult result) {
    print('🔍 TRANSACTION DEBUG: Receipt scan callback called');
    final data = result.extractedData;

    print('🔍 TRANSACTION DEBUG: Processing scan result...');
    print('🔍 TRANSACTION DEBUG: Raw text length: ${result.rawText.length}');
    print('🔍 TRANSACTION DEBUG: Merchant: ${data.merchantName}');
    print('🔍 TRANSACTION DEBUG: Amount: ${data.totalAmount}');
    print('🔍 TRANSACTION DEBUG: Date: ${data.date}');
    print('🔍 TRANSACTION DEBUG: Has essential data: ${data.hasEssentialData}');
    print('🔍 TRANSACTION DEBUG: Items count: ${data.items.length}');

    // Auto-fill description with merchant name or suggested description
    if (data.merchantName != null && data.merchantName!.isNotEmpty) {
      print(
        '🔍 TRANSACTION DEBUG: Setting description to merchant: ${data.merchantName}',
      );
      _descriptionController.text = data.merchantName!;
    } else if (data.suggestedDescription.isNotEmpty) {
      print(
        '🔍 TRANSACTION DEBUG: Setting description to suggested: ${data.suggestedDescription}',
      );
      _descriptionController.text = data.suggestedDescription;
    }

    // Auto-fill amount (use absolute value since transaction type will handle sign)
    if (data.totalAmount != null) {
      print('🔍 TRANSACTION DEBUG: Setting amount to: ${data.totalAmount}');
      _amountController.text = data.totalAmount!.abs().toStringAsFixed(2);
    }

    // Auto-select category based on merchant/content
    final suggestedCategory = data.suggestedCategory;
    print('🔍 TRANSACTION DEBUG: Suggested category: $suggestedCategory');
    if (_categories[_transactionType]?.contains(suggestedCategory) == true) {
      print('🔍 TRANSACTION DEBUG: Setting category to: $suggestedCategory');
      setState(() {
        _selectedCategory = suggestedCategory;
      });
    }

    // Auto-fill date if extracted
    if (data.date != null) {
      print('🔍 TRANSACTION DEBUG: Setting date to: ${data.date}');
      setState(() {
        _selectedDate = data.date!;
      });
    }

    // Auto-fill notes with receipt details if we have items
    if (data.items.isNotEmpty) {
      final itemsText = data.items
          .take(3) // Limit to first 3 items to avoid too much text
          .map(
            (item) =>
                '${item.description} (\$${item.amount.toStringAsFixed(2)})',
          )
          .join(', ');
      _notesController.text = 'Items: $itemsText';

      if (data.items.length > 3) {
        _notesController.text += '... and ${data.items.length - 3} more items';
      }
      print('🔍 TRANSACTION DEBUG: Set notes with ${data.items.length} items');
    }

    // Show debug dialog first
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🔍 OCR Debug Results'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Raw Text (${result.rawText.length} characters):'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.grey[50],
                      ),
                      child: Text(
                        result.rawText.isEmpty
                            ? '❌ NO TEXT EXTRACTED!'
                            : result.rawText,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Extracted Data:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text('• Merchant: ${data.merchantName ?? "❌ None found"}'),
                    Text(
                      '• Amount: ${data.totalAmount != null ? "\$${data.totalAmount!.toStringAsFixed(2)}" : "❌ None found"}',
                    ),
                    Text(
                      '• Date: ${data.date?.toString().split(' ')[0] ?? "❌ None found"}',
                    ),
                    Text('• Items: ${data.items.length}'),
                    Text('• Category: ${data.suggestedCategory}'),
                    Text(
                      '• Has essential data: ${data.hasEssentialData ? "✅ Yes" : "❌ No"}',
                    ),
                    if (data.items.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      const Text('Items found:'),
                      ...data.items
                          .take(3)
                          .map(
                            (item) => Text(
                              '  - ${item.description}: \$${item.amount.toStringAsFixed(2)}',
                            ),
                          ),
                      if (data.items.length > 3)
                        Text('  ... and ${data.items.length - 3} more'),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              data.hasEssentialData ? Icons.check_circle : Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                data.hasEssentialData
                    ? 'Receipt scanned! Merchant: ${data.merchantName ?? "N/A"}, Amount: \$${data.totalAmount?.toStringAsFixed(2) ?? "N/A"}'
                    : 'Receipt scanned with limited data (${result.rawText.length} chars extracted)',
              ),
            ),
          ],
        ),
        backgroundColor:
            data.hasEssentialData
                ? AppTheme.successColor
                : AppTheme.warningColor,
        duration: const Duration(seconds: 5),
      ),
    );

    // Trigger goal impact check
    _checkGoalImpacts();
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
                        onPressed: () => _handleBackNavigation(),
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

                                    // Receipt Scanner Section (only show for new transactions)
                                    if (!isEditMode)
                                      _buildReceiptScannerSection(
                                        theme,
                                        colorScheme,
                                      ),
                                    if (!isEditMode)
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
            fillColor:
                Theme.of(context).brightness == Brightness.dark
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
            fillColor:
                Theme.of(context).brightness == Brightness.dark
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

  // Helper method to build receipt scanner section
  Widget _buildReceiptScannerSection(ThemeData theme, ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with AI badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [colorScheme.primary, colorScheme.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'AI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.receipt_long, color: colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Smart Receipt Scanner',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            'Instantly extract merchant name, amount, date, and items from any receipt using AI-powered text recognition.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),

          // Tips section (collapsible)
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(top: 8, bottom: 4),
              leading: Icon(
                Icons.lightbulb_outline,
                color: Colors.amber[700],
                size: 20,
              ),
              title: Text(
                'Scanning Tips',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipItem(
                        '📱',
                        'Hold phone steady and focus on receipt',
                      ),
                      _buildTipItem(
                        '💡',
                        'Ensure good lighting, avoid shadows',
                      ),
                      _buildTipItem(
                        '📄',
                        'Keep receipt flat and fully visible',
                      ),
                      _buildTipItem(
                        '🔍',
                        'Include total amount and merchant name',
                      ),
                      _buildTipItem('✨', 'Works best with printed receipts'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Enhanced scan buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openReceiptScanner(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt, size: 20),
                  label: const Text('Take Photo'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openReceiptScanner(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library, size: 20),
                  label: const Text('From Gallery'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Build a tip item with emoji and text
  Widget _buildTipItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: Colors.amber[800],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Open receipt scanner with the specified source
  void _openReceiptScanner(ImageSource source) async {
    try {
      final ocrService = ReceiptOCRService();
      final result = await ocrService.scanReceiptFromSource(source);

      if (result != null) {
        _handleReceiptScan(result);
      }

      ocrService.dispose();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Failed to scan receipt: ${e.toString()}'),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
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
            color:
                Theme.of(context).brightness == Brightness.dark
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
              color:
                  Theme.of(context).brightness == Brightness.dark
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
            fillColor:
                Theme.of(context).brightness == Brightness.dark
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
        color:
            Theme.of(context).brightness == Brightness.dark
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
