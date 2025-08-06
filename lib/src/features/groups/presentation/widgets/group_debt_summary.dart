import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/theme/app_spacing.dart';

class GroupDebtSummary extends StatefulWidget {
  final GroupWithMembersModel group;

  const GroupDebtSummary({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupDebtSummary> createState() => _GroupDebtSummaryState();
}

class _GroupDebtSummaryState extends State<GroupDebtSummary> {
  final BillService _billService = BillService();
  List<DebtModel> _debts = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadDebts();
  }

  Future<void> _loadDebts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _billService.fetchGroupDebtsWithFallback(
        widget.group.group.id!,
      );
      setState(() {
        _debts =
            result.data
                .where(
                  (debt) =>
                      debt.status == 'pending' && debt.remainingAmount > 0.01,
                )
                .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _markDebtAsPaid(DebtModel debt) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark as Paid'),
            content: Text(
              'Mark debt of \$${debt.remainingAmount.toStringAsFixed(2)} as paid?\n\n'
              '${debt.debtorName ?? 'You'} → ${debt.creditorName ?? 'Unknown'}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Mark Paid'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Create a simple payment record (MVP approach)
      final payment = PaymentModel(
        debtId: debt.id!,
        payerUserId: debt.debtorUserId,
        receiverUserId: debt.creditorUserId,
        amount: debt.remainingAmount,
        currency: debt.currency,
        paymentDate: DateTime.now(),
        paymentMethod: 'cash', // Default for MVP
        isConfirmed: true,
      );

      await _billService.recordPayment(payment);
      await _loadDebts(); // Refresh the list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment recorded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error recording payment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.read<GroupsProvider>().getCurrentUserId();

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Column(
        children: [
          Icon(Icons.error_outline, color: colorScheme.error),
          const SizedBox(height: 8),
          Text('Failed to load debts: $_error'),
        ],
      );
    }

    // Separate debts into what you owe and what you're owed
    final debtsYouOwe =
        _debts.where((debt) => debt.debtorUserId == currentUserId).toList();
    final debtsOwedToYou =
        _debts.where((debt) => debt.creditorUserId == currentUserId).toList();

    // Show empty state if no debts
    if (debtsYouOwe.isEmpty && debtsOwedToYou.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          border: Border.all(color: colorScheme.outline.withOpacity(0.1)),
        ),
        child: Column(
          children: [
            Icon(
              Icons.account_balance_wallet,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'All settled up!',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'No outstanding balances in this group',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Debts you owe
        if (debtsYouOwe.isNotEmpty) ...[
          Text(
            'You Owe',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.error,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...debtsYouOwe.map((debt) => _buildDebtTile(debt, isYouOwe: true)),
          const SizedBox(height: AppSpacing.md),
        ],

        // Debts owed to you
        if (debtsOwedToYou.isNotEmpty) ...[
          Text(
            'Owed to You',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...debtsOwedToYou.map(
            (debt) => _buildDebtTile(debt, isYouOwe: false),
          ),
        ],
      ],
    );
  }

  Widget _buildDebtTile(DebtModel debt, {required bool isYouOwe}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final amount = debt.remainingAmount;
    final otherPersonName = isYouOwe ? debt.creditorName : debt.debtorName;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor:
                isYouOwe
                    ? colorScheme.error.withValues(alpha: 0.2)
                    : colorScheme.primary.withValues(alpha: 0.2),
            child: Icon(
              isYouOwe ? Icons.arrow_upward : Icons.arrow_downward,
              size: 16,
              color: isYouOwe ? colorScheme.error : colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  otherPersonName ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '\$${amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isYouOwe ? colorScheme.error : colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (isYouOwe)
            TextButton(
              onPressed: () => _markDebtAsPaid(debt),
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 0),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              ),
              child: const Text('Mark Paid', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
