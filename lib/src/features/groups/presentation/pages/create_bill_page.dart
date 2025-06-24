import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../../data/services/bill_calculation_service.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

class CreateBillPage extends StatefulWidget {
  final String groupId;

  const CreateBillPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<CreateBillPage> createState() => _CreateBillPageState();
}

class _CreateBillPageState extends State<CreateBillPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  
  final BillService _billService = BillService();
  
  GroupWithMembersModel? _group;
  String _splitMethod = 'equal';
  String? _selectedPayerId;
  List<GroupMemberModel> _selectedMembers = [];
  Map<String, double> _customAmounts = {};
  Map<String, double> _percentages = {};
  bool _isLoading = false;
  bool _isCreatingBill = false;

  @override
  void initState() {
    super.initState();
    _loadGroup();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);
    
    final provider = context.read<GroupsProvider>();
    _group = provider.getGroupById(widget.groupId);
    
    if (_group == null) {
      await provider.loadGroups();
      _group = provider.getGroupById(widget.groupId);
    }
    
    if (_group != null) {
      // Initially select all members and set equal split
      _selectedMembers = List.from(_group!.members);
      _selectedPayerId = _group!.members.isNotEmpty ? _group!.members.first.userId : null;
      _initializePercentages();
      _initializeCustomAmounts();
    }
    
    setState(() => _isLoading = false);
  }

  void _initializePercentages() {
    if (_selectedMembers.isNotEmpty) {
      final percentage = 100.0 / _selectedMembers.length;
      _percentages = {
        for (final member in _selectedMembers) member.userId: percentage
      };
    }
  }

  void _initializeCustomAmounts() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (_selectedMembers.isNotEmpty && amount > 0) {
      final amountPerPerson = amount / _selectedMembers.length;
      _customAmounts = {
        for (final member in _selectedMembers) member.userId: amountPerPerson
      };
    }
  }

  void _onSplitMethodChanged(String? method) {
    setState(() {
      _splitMethod = method ?? 'equal';
      if (_splitMethod == 'percentage') {
        _initializePercentages();
      } else if (_splitMethod == 'custom') {
        _initializeCustomAmounts();
      }
    });
  }

  void _onMemberSelectionChanged(GroupMemberModel member, bool selected) {
    setState(() {
      if (selected) {
        _selectedMembers.add(member);
      } else {
        _selectedMembers.removeWhere((m) => m.userId == member.userId);
        _percentages.remove(member.userId);
        _customAmounts.remove(member.userId);
      }
      
      if (_splitMethod == 'percentage') {
        _initializePercentages();
      } else if (_splitMethod == 'custom') {
        _initializeCustomAmounts();
      }
    });
  }

  void _onAmountChanged() {
    if (_splitMethod == 'custom') {
      _initializeCustomAmounts();
      setState(() {});
    }
  }

  bool _validateSplit() {
    final amount = double.tryParse(_amountController.text) ?? 0.0;
    
    return BillCalculationService.validateSplitConfiguration(
      splitMethod: _splitMethod,
      totalAmount: amount,
      selectedMembers: _selectedMembers,
      customAmounts: _customAmounts,
      percentages: _percentages,
    );
  }

  Future<void> _createBill() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_validateSplit()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fix the split configuration'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    setState(() => _isCreatingBill = true);

    try {
      final amount = double.parse(_amountController.text);
      
      // Calculate splits
      final splits = BillCalculationService.calculateSplits(
        billId: '', // Will be set by service
        totalAmount: amount,
        splitMethod: _splitMethod,
        selectedMembers: _selectedMembers,
        customAmounts: _customAmounts,
        percentages: _percentages,
      );

      // Create bill
      final bill = BillModel(
        groupId: widget.groupId,
        title: _titleController.text,
        description: _descriptionController.text,
        totalAmount: amount,
        currency: _group?.group.defaultCurrency ?? 'USD',
        paidByUserId: _selectedPayerId!,
        dateCreated: DateTime.now(),
        status: 'active',
        splitMethod: _splitMethod,
        splits: splits,
      );

      await _billService.createBill(bill);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bill created successfully!'),
            backgroundColor: Colors.green, // Keep green for success
          ),
        );
        GoRouter.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating bill: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingBill = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breadcrumb navigation
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Groups',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  Text(
                    'Loading...',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
              // Page title
              Text(
                'Create Bill',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? colorScheme.onSurface : Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
          foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_group == null) {
      return Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Breadcrumb navigation
              Row(
                children: [
                  Icon(
                    Icons.group,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Groups',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  Text(
                    'Not Found',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 14,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ),
              // Page title
              Text(
                'Create Bill',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: isDark ? colorScheme.onSurface : Colors.white,
                ),
              ),
            ],
          ),
          backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
          foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
        ),
        body: const Center(
          child: Text('Group not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => GoRouter.of(context).pop(),
          tooltip: 'Back to ${_group?.group.name ?? "Group"}',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Breadcrumb navigation
            Row(
              children: [
                const Icon(
                  Icons.group,
                  size: 14,
                  color: Colors.white70,
                ),
                const SizedBox(width: 4),
                Text(
                  'Groups',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.white70,
                ),
                Flexible(
                  child: Text(
                    _group?.group.name ?? 'Loading...',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark 
                        ? colorScheme.onSurface.withValues(alpha: 0.7)
                        : Colors.white.withValues(alpha: 0.7),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 14,
                  color: Colors.white70,
                ),
              ],
            ),
            // Page title
            const Text(
              'Create Bill',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isCreatingBill ? null : _createBill,
            child: _isCreatingBill
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDark ? colorScheme.onSurface : Colors.white,
                    ),
                  )
                : Text(
                    'Create',
                    style: TextStyle(
                      color: isDark ? colorScheme.onSurface : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill Details Section
              _buildSectionHeader('Bill Details'),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'e.g., Dinner at Restaurant',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value?.isEmpty == true ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional details about the bill',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Amount * (${_group!.group.defaultCurrency})',
                  hintText: '0.00',
                  border: const OutlineInputBorder(),
                  prefixText: '\$',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Amount is required';
                  final amount = double.tryParse(value!);
                  if (amount == null || amount <= 0) return 'Enter a valid amount';
                  return null;
                },
                onChanged: (_) => _onAmountChanged(),
              ),
              
              const SizedBox(height: 32),
              
              // Payer Selection
              _buildSectionHeader('Who Paid?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedPayerId,
                decoration: const InputDecoration(
                  labelText: 'Paid by',
                  border: OutlineInputBorder(),
                ),
                items: _group!.members.map((member) {
                  return DropdownMenuItem(
                    value: member.userId,
                    child: Text(member.userName ?? 'Unknown'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedPayerId = value),
                validator: (value) => value == null ? 'Please select who paid' : null,
              ),
              
              const SizedBox(height: 32),
              
              // Split Method
              _buildSectionHeader('How to Split?'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _splitMethod,
                decoration: const InputDecoration(
                  labelText: 'Split method',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'equal', child: Text('Split Equally')),
                  DropdownMenuItem(value: 'percentage', child: Text('By Percentage')),
                  DropdownMenuItem(value: 'custom', child: Text('Custom Amounts')),
                ],
                onChanged: _onSplitMethodChanged,
              ),
              
              const SizedBox(height: 32),
              
              // Member Selection and Split Details
              _buildSectionHeader('Split Between'),
              const SizedBox(height: 16),
              ..._buildMemberSelection(),
              
              if (_splitMethod != 'equal') ...[
                const SizedBox(height: 24),
                _buildSplitDetails(),
              ],
              
              const SizedBox(height: 32),
              
              // Split Preview
              _buildSplitPreview(),
              
              const SizedBox(height: 100), // Space for floating action button
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }

  List<Widget> _buildMemberSelection() {
    return _group!.members.map((member) {
      final isSelected = _selectedMembers.any((m) => m.userId == member.userId);
      return CheckboxListTile(
        title: Text(member.userName ?? 'Unknown'),
        subtitle: Text(member.userEmail ?? ''),
        value: isSelected,
        onChanged: (selected) => _onMemberSelectionChanged(member, selected ?? false),
        activeColor: Theme.of(context).colorScheme.primary,
      );
    }).toList();
  }

  Widget _buildSplitDetails() {
    if (_selectedMembers.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Select members to configure split'),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _splitMethod == 'percentage' ? 'Set Percentages' : 'Set Custom Amounts',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._selectedMembers.map((member) => _buildMemberSplitInput(member)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSplitInput(GroupMemberModel member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(member.userName ?? 'Unknown'),
          ),
          Expanded(
            child: TextFormField(
              initialValue: _splitMethod == 'percentage'
                  ? _percentages[member.userId]?.toStringAsFixed(1) ?? '0'
                  : _customAmounts[member.userId]?.toStringAsFixed(2) ?? '0',
              decoration: InputDecoration(
                suffix: Text(_splitMethod == 'percentage' ? '%' : '\$'),
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final numValue = double.tryParse(value) ?? 0.0;
                setState(() {
                  if (_splitMethod == 'percentage') {
                    _percentages[member.userId] = numValue;
                  } else {
                    _customAmounts[member.userId] = numValue;
                  }
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPreview() {
    if (_selectedMembers.isEmpty || _amountController.text.isEmpty) {
      return const SizedBox.shrink();
    }

    final amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) return const SizedBox.shrink();

    try {
      final splits = BillCalculationService.calculateSplits(
        billId: '',
        totalAmount: amount,
        splitMethod: _splitMethod,
        selectedMembers: _selectedMembers,
        customAmounts: _customAmounts,
        percentages: _percentages,
      );

      return Card(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Split Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...splits.map((split) {
                final member = _selectedMembers.firstWhere((m) => m.userId == split.userId);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(member.userName ?? 'Unknown'),
                      Text(
                        '\$${split.amount.toStringAsFixed(2)} (${split.percentage.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                );
              }),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '\$${amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      return Card(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Split Error: $e',
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ),
      );
    }
  }
}