import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';

class GoalCreatePage extends StatefulWidget {
  final Goal? goal; // null for create, Goal instance for edit

  const GoalCreatePage({super.key, this.goal});

  @override
  State<GoalCreatePage> createState() => _GoalCreatePageState();
}

class _GoalCreatePageState extends State<GoalCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _selectedDeadline;
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditMode => widget.goal != null;

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
      lastDate: DateTime.now().add(
        const Duration(days: 365 * 5),
      ), // 5 years from now
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme,
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
                Icon(Icons.check_circle, color: Theme.of(context).colorScheme.onPrimary, size: 24),
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

        // Navigate back to goals page
        context.go('/goals');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to ${_isEditMode ? 'update' : 'create'} goal: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Goal' : 'Create Goal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.go('/goals'),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.surface],
            stops: [0.0, 0.3],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Error Message
                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Goal Name
                _buildInputField(
                  controller: _nameController,
                  label: 'Goal Name',
                  hint: 'e.g., Emergency Fund, Vacation, New Car',
                  icon: Icons.flag,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Goal name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Goal name must be at least 2 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Target Amount
                _buildInputField(
                  controller: _targetAmountController,
                  label: 'Target Amount',
                  hint: '0.00',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Target amount is required';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid amount greater than 0';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Current Amount (optional for new goals)
                _buildInputField(
                  controller: _currentAmountController,
                  label: 'Current Amount (Optional)',
                  hint: '0.00',
                  icon: Icons.savings,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      final amount = double.tryParse(value);
                      if (amount == null || amount < 0) {
                        return 'Please enter a valid amount';
                      }
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Deadline
                _buildDeadlineField(),

                const SizedBox(height: 20),

                // Description
                _buildInputField(
                  controller: _descriptionController,
                  label: 'Description (Optional)',
                  hint: 'Add notes about your goal...',
                  icon: Icons.description,
                  maxLines: 3,
                ),

                const SizedBox(height: 32),

                // Progress Preview (only in edit mode)
                if (_isEditMode) _buildProgressPreview(),

                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveGoal,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child:
                        _isLoading
                            ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.surface,
                                ),
                              ),
                            )
                            : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isEditMode ? Icons.save : Icons.flag),
                                const SizedBox(width: 8),
                                Text(
                                  _isEditMode ? 'Update Goal' : 'Create Goal',
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
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            validator: validator,
            style: const TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16),
              prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.primary),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeadlineField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deadline (Optional)',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectDeadline,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _selectedDeadline != null
                        ? '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}'
                        : 'Select deadline date',
                    style: TextStyle(
                      color:
                          _selectedDeadline != null
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (_selectedDeadline != null)
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _selectedDeadline = null;
                      });
                    },
                    icon: const Icon(Icons.clear, color: Colors.grey),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressPreview() {
    final targetAmount = double.tryParse(_targetAmountController.text) ?? 0;
    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0;
    final progress = targetAmount > 0 ? currentAmount / targetAmount : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progress Preview',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 1.0 ? 1.0 : progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${currentAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
              Text(
                '${(progress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  color: progress >= 1.0 ? Colors.green : Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '\$${targetAmount.toStringAsFixed(2)}',
                style: const TextStyle(color: Theme.of(context).colorScheme.onSurface, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
