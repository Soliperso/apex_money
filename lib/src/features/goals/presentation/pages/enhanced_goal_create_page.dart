import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';

class EnhancedGoalCreatePage extends StatefulWidget {
  final Goal? goal; // null for create, Goal instance for edit

  const EnhancedGoalCreatePage({super.key, this.goal});

  @override
  State<EnhancedGoalCreatePage> createState() => _EnhancedGoalCreatePageState();
}

class _EnhancedGoalCreatePageState extends State<EnhancedGoalCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDeadline;
  GoalType _selectedType = GoalType.savings;
  List<String> _selectedCategories = [];
  bool _autoUpdate = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditMode => widget.goal != null;

  // Available transaction categories for linking
  final Map<String, List<String>> _availableCategories = {
    'Income': [
      'Salary',
      'Freelance',
      'Investment',
      'Business',
      'Gift',
      'Bonus',
    ],
    'Expenses': [
      'Food & Dining',
      'Transportation',
      'Shopping',
      'Entertainment',
      'Bills & Utilities',
      'Healthcare',
      'Travel',
      'Education',
      'Personal Care',
      'Gifts & Donations',
      'Gas',
    ],
    'Savings & Investment': ['Savings', 'Investment', 'Emergency Fund'],
    'Debt': ['Credit Card', 'Loan Payment', 'Mortgage'],
  };

  @override
  void initState() {
    super.initState();

    // Pre-fill form if editing
    if (_isEditMode) {
      _nameController.text = widget.goal!.name;
      _targetAmountController.text = widget.goal!.targetAmount.toString();
      _currentAmountController.text = widget.goal!.currentAmount.toString();
      _descriptionController.text = widget.goal!.description ?? '';
      _selectedDeadline = widget.goal!.deadline;
      _selectedType = widget.goal!.type;
      _selectedCategories = List.from(widget.goal!.linkedCategories);
      _autoUpdate = widget.goal!.autoUpdate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDeadline() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _selectedDeadline ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blueAccent,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDeadline = picked;
      });
    }
  }

  void _showCategorySelector() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setModalState) => Container(
                  height: MediaQuery.of(context).size.height * 0.75,
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.dark
                            ? colorScheme.surfaceContainer
                            : colorScheme.surface,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(20),
                            topRight: Radius.circular(20),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              'Link Transaction Categories',
                              style: TextStyle(
                                color: colorScheme.onPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(
                                Icons.close,
                                color: colorScheme.onPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children:
                              _availableCategories.entries.map((entry) {
                                return ExpansionTile(
                                  title: Text(
                                    entry.key,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  children:
                                      entry.value.map((category) {
                                        final isSelected = _selectedCategories
                                            .contains(category);
                                        return CheckboxListTile(
                                          title: Text(category),
                                          value: isSelected,
                                          onChanged: (bool? value) {
                                            setModalState(() {
                                              if (value == true) {
                                                _selectedCategories.add(
                                                  category,
                                                );
                                              } else {
                                                _selectedCategories.remove(
                                                  category,
                                                );
                                              }
                                            });
                                            setState(
                                              () {},
                                            ); // Update parent state too
                                          },
                                          activeColor: colorScheme.primary,
                                        );
                                      }).toList(),
                                );
                              }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            minimumSize: const Size(double.infinity, 50),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Done (${_selectedCategories.length} selected)',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  String _getGoalTypeDescription(GoalType type) {
    switch (type) {
      case GoalType.savings:
        return 'Save money';
      case GoalType.expenseLimit:
        return 'Limit spending';
      case GoalType.incomeTarget:
        return 'Income goal';
      case GoalType.netWorth:
        return 'Wealth tracking';
      case GoalType.debtPaydown:
        return 'Pay debt';
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final targetAmount = double.parse(_targetAmountController.text);
      final currentAmount = double.parse(
        _currentAmountController.text.isEmpty
            ? '0'
            : _currentAmountController.text,
      );

      if (currentAmount > targetAmount) {
        setState(() {
          _errorMessage = 'Current amount cannot exceed target amount';
          _isLoading = false;
        });
        return;
      }

      final goal = Goal(
        id: _isEditMode ? widget.goal!.id : null,
        name: _nameController.text.trim(),
        targetAmount: targetAmount,
        currentAmount: currentAmount,
        deadline: _selectedDeadline,
        description:
            _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
        createdAt: _isEditMode ? widget.goal!.createdAt : DateTime.now(),
        updatedAt: DateTime.now(),
        isCompleted: currentAmount >= targetAmount,
        type: _selectedType,
        linkedCategories: _selectedCategories,
        autoUpdate: _autoUpdate,
      );

      if (_isEditMode) {
        await GoalService().updateGoal(goal);
      } else {
        await GoalService().createGoal(goal);
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isEditMode
                        ? 'Goal updated successfully!'
                        : 'Goal created successfully!',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );

        // Navigate back
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors:
                theme.brightness == Brightness.dark
                    ? [colorScheme.surfaceContainer, colorScheme.surface]
                    : [colorScheme.primary, colorScheme.surface],
            stops: const [0.0, 0.3],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: Icon(
                        Icons.arrow_back,
                        color:
                            theme.brightness == Brightness.dark
                                ? colorScheme.onSurface
                                : colorScheme.onPrimary,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        _isEditMode ? 'Edit Goal' : 'Create New Goal',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              theme.brightness == Brightness.dark
                                  ? colorScheme.onSurface
                                  : colorScheme.onPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Goal Name
                        _buildSectionCard(
                          title: 'Goal Details',
                          children: [
                            TextFormField(
                              controller: _nameController,
                              maxLength: 50,
                              decoration: const InputDecoration(
                                labelText: 'Goal Name',
                                hintText: 'e.g., Emergency Fund, Vacation...',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.flag),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                counterText: '',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter a goal name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _descriptionController,
                              maxLength: 200,
                              decoration: const InputDecoration(
                                labelText: 'Description (Optional)',
                                hintText: 'What is this goal for?',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.description),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                counterText: '',
                              ),
                              maxLines: 2,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Goal Type Selection
                        _buildSectionCard(
                          title: 'Goal Type',
                          children: [
                            SizedBox(
                              height: 56,
                              child: DropdownButtonFormField<GoalType>(
                                value: _selectedType,
                                isExpanded: true,
                                menuMaxHeight: 200,
                                decoration: const InputDecoration(
                                  labelText: 'Goal Type',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.category),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  isDense: true,
                                ),
                                items:
                                    GoalType.values.map((type) {
                                      return DropdownMenuItem(
                                        value: type,
                                        child: Text(
                                          '${type.name.toUpperCase()} - ${_getGoalTypeDescription(type)}',
                                          style: const TextStyle(fontSize: 14),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 1,
                                        ),
                                      );
                                    }).toList(),
                                onChanged: (GoalType? newType) {
                                  setState(() {
                                    _selectedType = newType!;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Amount Fields
                        _buildSectionCard(
                          title: 'Financial Details',
                          children: [
                            TextFormField(
                              controller: _targetAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Target Amount',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.attach_money),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a target amount';
                                }
                                final amount = double.tryParse(value);
                                if (amount == null || amount <= 0) {
                                  return 'Please enter a valid amount';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _currentAmountController,
                              decoration: const InputDecoration(
                                labelText: 'Current Amount',
                                hintText: '0.00',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.savings),
                                contentPadding: EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Deadline Selection
                        _buildSectionCard(
                          title: 'Timeline',
                          children: [
                            InkWell(
                              onTap: _selectDeadline,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Deadline (Optional)',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.calendar_today),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  _selectedDeadline != null
                                      ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                                      : 'Select deadline',
                                  style: TextStyle(
                                    color:
                                        _selectedDeadline != null
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Category Linking
                        _buildSectionCard(
                          title: 'Transaction Integration',
                          children: [
                            InkWell(
                              onTap: _showCategorySelector,
                              child: InputDecorator(
                                decoration: const InputDecoration(
                                  labelText: 'Linked Categories',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.link),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 12,
                                  ),
                                ),
                                child: Text(
                                  _selectedCategories.isEmpty
                                      ? 'Select categories to track'
                                      : '${_selectedCategories.length} categories selected',
                                  style: TextStyle(
                                    color:
                                        _selectedCategories.isNotEmpty
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.onSurface
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ),
                            if (_selectedCategories.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children:
                                      _selectedCategories.map((category) {
                                        return Chip(
                                          label: Text(
                                            category,
                                            style: const TextStyle(
                                              fontSize: 12,
                                            ),
                                          ),
                                          onDeleted: () {
                                            setState(() {
                                              _selectedCategories.remove(
                                                category,
                                              );
                                            });
                                          },
                                          deleteIcon: const Icon(
                                            Icons.close,
                                            size: 16,
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        );
                                      }).toList(),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                            SwitchListTile(
                              title: const Text(
                                'Auto-update from transactions',
                                style: TextStyle(fontSize: 14),
                              ),
                              subtitle: const Text(
                                'Auto-update progress from relevant transactions',
                                style: TextStyle(fontSize: 12),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              value: _autoUpdate,
                              onChanged: (bool value) {
                                setState(() {
                                  _autoUpdate = value;
                                });
                              },
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Error Message
                        if (_errorMessage != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colorScheme.errorContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.error.withOpacity(0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: colorScheme.error,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: TextStyle(
                                      color: colorScheme.onErrorContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                        const SizedBox(height: 24),

                        // Save Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _saveGoal,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child:
                                _isLoading
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              colorScheme.onPrimary,
                                            ),
                                      ),
                                    )
                                    : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isEditMode ? Icons.save : Icons.add,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isEditMode
                                              ? 'Update Goal'
                                              : 'Create Goal',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                          ),
                        ),
                        const SizedBox(
                          height: 16,
                        ), // Add bottom padding for scrolling
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

  Widget _buildSectionCard({
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.8)
                : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border:
            theme.brightness == Brightness.dark
                ? Border.all(
                  color: colorScheme.outline.withOpacity(0.3),
                  width: 1,
                )
                : Border.all(
                  color: colorScheme.outline.withOpacity(0.2),
                  width: 1,
                ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(
              theme.brightness == Brightness.dark ? 0.15 : 0.08,
            ),
            spreadRadius: 1,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}
