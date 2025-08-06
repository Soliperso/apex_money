import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/currency_formatter.dart';

class SettlementHistoryPage extends StatefulWidget {
  final String groupId;

  const SettlementHistoryPage({Key? key, required this.groupId})
    : super(key: key);

  @override
  State<SettlementHistoryPage> createState() => _SettlementHistoryPageState();
}

class _SettlementHistoryPageState extends State<SettlementHistoryPage> {
  final BillService _billService = BillService();

  GroupWithMembersModel? _group;
  List<BillModel> _settledBills = [];
  List<SettlementRecord> _allPayments = [];
  bool _isLoading = true;
  String? _error;
  String _selectedFilter = 'all'; // all, last_30_days, last_3_months
  String? _selectedMember;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final provider = context.read<GroupsProvider>();
      _group = provider.getGroupById(widget.groupId);

      if (_group == null) {
        await provider.loadGroups();
        _group = provider.getGroupById(widget.groupId);
      }

      if (_group != null) {
        // Load all bills for the group
        final billsResult = await _billService.fetchGroupBillsWithFallback(
          widget.groupId,
        );
        final allBills = billsResult.data;

        // Filter for settled bills
        _settledBills =
            allBills.where((bill) => bill.status == 'settled').toList();

        // Sort by most recent first
        _settledBills.sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        // Extract all payments from settled bills
        _allPayments = [];
        for (final bill in _settledBills) {
          for (final split in bill.splits) {
            if (split.isPaid && split.paidDate != null) {
              // Create a SettlementRecord from the split data
              final payment = SettlementRecord(
                id: '${bill.id}_${split.userId}',
                billId: bill.id!,
                billTitle: bill.title,
                payerUserId: split.userId,
                payerName:
                    _group!.members
                        .firstWhere(
                          (m) => m.userId == split.userId,
                          orElse:
                              () => GroupMemberModel(
                                groupId: widget.groupId,
                                userId: split.userId,
                                role: GroupMemberRole.member,
                                status: GroupMemberStatus.active,
                                joinedAt: DateTime.now(),
                                userName: 'Unknown',
                              ),
                        )
                        .userName ??
                    'Unknown',
                amount: split.amount,
                currency: bill.currency,
                paymentDate: split.paidDate!,
                status: 'completed',
              );
              _allPayments.add(payment);
            }
          }
        }

        // Sort payments by most recent first
        _allPayments.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SettlementRecord> get _filteredPayments {
    List<SettlementRecord> filtered = List.from(_allPayments);

    // Filter by date range
    final now = DateTime.now();
    switch (_selectedFilter) {
      case 'last_30_days':
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        filtered =
            filtered
                .where((p) => p.paymentDate.isAfter(thirtyDaysAgo))
                .toList();
        break;
      case 'last_3_months':
        final threeMonthsAgo = now.subtract(const Duration(days: 90));
        filtered =
            filtered
                .where((p) => p.paymentDate.isAfter(threeMonthsAgo))
                .toList();
        break;
    }

    // Filter by member
    if (_selectedMember != null && _selectedMember != 'all') {
      filtered =
          filtered.where((p) => p.payerUserId == _selectedMember).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        appBar: _buildAppBar(context, isDark, colorScheme),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _group == null) {
      return Scaffold(
        appBar: _buildAppBar(context, isDark, colorScheme),
        body: AppGradientBackground(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  _group == null ? 'Group not found' : 'Error loading data',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: 16),
                FilledButton(onPressed: _loadData, child: const Text('Retry')),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: _buildAppBar(context, isDark, colorScheme),
      body: AppGradientBackground(
        child: Column(
          children: [
            // Filters
            _buildFilters(context, theme),

            // Settlement History List
            Expanded(
              child:
                  _filteredPayments.isEmpty
                      ? _buildEmptyState(context, colorScheme)
                      : _buildSettlementsList(context, theme),
            ),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar(
    BuildContext context,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/groups/${widget.groupId}'),
        tooltip: 'Back to Group',
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Breadcrumb navigation
          Row(
            children: [
              const Icon(Icons.group, size: 14, color: Colors.white70),
              const SizedBox(width: 4),
              Text(
                'Groups',
                style: TextStyle(
                  fontSize: 11,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
              Flexible(
                child: Text(
                  _group?.group.name ?? 'Loading...',
                  style: TextStyle(
                    fontSize: 11,
                    color:
                        isDark
                            ? colorScheme.onSurface.withValues(alpha: 0.7)
                            : Colors.white.withValues(alpha: 0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.chevron_right, size: 14, color: Colors.white70),
            ],
          ),
          // Page title
          const Text(
            'Settlement History',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
        ],
      ),
      backgroundColor: AppTheme.primaryColor,
      foregroundColor: Colors.white,
    );
  }

  Widget _buildFilters(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Date filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedFilter,
                  decoration: const InputDecoration(
                    labelText: 'Time Period',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'all', child: Text('All Time')),
                    DropdownMenuItem(
                      value: 'last_30_days',
                      child: Text('Last 30 Days'),
                    ),
                    DropdownMenuItem(
                      value: 'last_3_months',
                      child: Text('Last 3 Months'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() => _selectedFilter = value ?? 'all');
                  },
                ),
              ),
              const SizedBox(width: 12),
              // Member filter
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedMember ?? 'all',
                  decoration: const InputDecoration(
                    labelText: 'Member',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: 'all',
                      child: Text('All Members'),
                    ),
                    ..._group!.members.map(
                      (member) => DropdownMenuItem(
                        value: member.userId,
                        child: Text(member.userName ?? 'Unknown'),
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    setState(
                      () => _selectedMember = value == 'all' ? null : value,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'No Settlement History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Payments and settlements will appear here once bills are marked as paid.',
            textAlign: TextAlign.center,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildSettlementsList(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final filteredPayments = _filteredPayments;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Settlement History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${filteredPayments.length} payment${filteredPayments.length != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Payments List
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: filteredPayments.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final payment = filteredPayments[index];
                return _buildPaymentCard(context, payment, theme);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentCard(
    BuildContext context,
    SettlementRecord payment,
    ThemeData theme,
  ) {
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Payment header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  payment.billTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.successColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Paid',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Payment details
          Row(
            children: [
              Icon(Icons.person, size: 16, color: colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(
                payment.payerName,
                style: TextStyle(
                  fontSize: 14,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                CurrencyFormatter.format(payment.amount),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Payment date
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                _formatPaymentDate(payment.paymentDate),
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPaymentDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

// Settlement record model for settlement history
class SettlementRecord {
  final String id;
  final String billId;
  final String billTitle;
  final String payerUserId;
  final String payerName;
  final double amount;
  final String currency;
  final DateTime paymentDate;
  final String status;

  const SettlementRecord({
    required this.id,
    required this.billId,
    required this.billTitle,
    required this.payerUserId,
    required this.payerName,
    required this.amount,
    required this.currency,
    required this.paymentDate,
    required this.status,
  });

  factory SettlementRecord.fromJson(Map<String, dynamic> json) {
    return SettlementRecord(
      id: json['id'] as String,
      billId: json['bill_id'] as String,
      billTitle: json['bill_title'] as String? ?? 'Unknown Bill',
      payerUserId: json['payer_user_id'] as String,
      payerName: json['payer_name'] as String? ?? 'Unknown',
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      paymentDate: DateTime.parse(json['payment_date'] as String),
      status: json['status'] as String? ?? 'completed',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bill_id': billId,
      'bill_title': billTitle,
      'payer_user_id': payerUserId,
      'payer_name': payerName,
      'amount': amount,
      'currency': currency,
      'payment_date': paymentDate.toIso8601String(),
      'status': status,
    };
  }
}
