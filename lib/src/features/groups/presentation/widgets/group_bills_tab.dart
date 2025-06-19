import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../../../../shared/theme/app_spacing.dart';

class GroupBillsTab extends StatefulWidget {
  final GroupWithMembersModel group;

  const GroupBillsTab({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupBillsTab> createState() => _GroupBillsTabState();
}

class _GroupBillsTabState extends State<GroupBillsTab> {
  final BillService _billService = BillService();
  List<BillModel> _bills = [];
  List<DebtModel> _debts = [];
  Map<String, dynamic> _statistics = {};
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBillsData();
  }

  Future<void> _loadBillsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final futures = await Future.wait([
        _billService.fetchGroupBills(widget.group.group.id!),
        _billService.fetchGroupDebts(widget.group.group.id!),
        _billService.getBillStatistics(widget.group.group.id!),
      ]);

      setState(() {
        _bills = futures[0] as List<BillModel>;
        _debts = futures[1] as List<DebtModel>;
        _statistics = futures[2] as Map<String, dynamic>;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: RefreshIndicator(
        onRefresh: _loadBillsData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bills Summary
              if (_isLoading) ...[
                const Center(child: CircularProgressIndicator()),
              ] else if (_error != null) ...[
                _buildErrorWidget(),
              ] else ...[
                _buildBillsSummary(),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Quick Actions
                _buildQuickActions(),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Recent Bills
                _buildRecentBillsSection(),
                const SizedBox(height: AppSpacing.sectionSpacing),

                // Debt Summary
                if (_debts.isNotEmpty) ...[
                  _buildDebtSummarySection(),
                  const SizedBox(height: AppSpacing.sectionSpacing),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.error_outline, size: 48, color: colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load bills',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: _loadBillsData,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillsSummary() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Bills Overview',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Bills',
                    '${_statistics['totalBills'] ?? 0}',
                    Icons.receipt_long,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'Active Bills',
                    '${_statistics['activeBills'] ?? 0}',
                    Icons.pending_actions,
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Amount',
                    '\$${(_statistics['totalBillAmount'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.attach_money,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildStatCard(
                    'Outstanding',
                    '\$${(_statistics['activeDebtAmount'] ?? 0.0).toStringAsFixed(2)}',
                    Icons.schedule,
                    colorScheme.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToCreateBill(),
            icon: const Icon(Icons.add),
            label: const Text('Create Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToAllBills(),
            icon: const Icon(Icons.list),
            label: const Text('View All'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentBillsSection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Bills',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            if (_bills.length > 3)
              TextButton(
                onPressed: _navigateToAllBills,
                child: const Text('View All'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_bills.isEmpty)
          _buildEmptyBillsWidget()
        else
          ...(_bills.take(3).map((bill) => _buildBillTile(bill))),
      ],
    );
  }

  Widget _buildEmptyBillsWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No bills yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Create your first bill to start tracking group expenses',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton.icon(
              onPressed: _navigateToCreateBill,
              icon: const Icon(Icons.add),
              label: const Text('Create First Bill'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillTile(BillModel bill) {
    final colorScheme = Theme.of(context).colorScheme;
    final payer =
        widget.group.members
            .where((m) => m.userId == bill.paidByUserId)
            .firstOrNull;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainer,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getBillStatusColor(
            bill.status,
            context,
          ).withValues(alpha: 0.1),
          child: Icon(
            _getBillStatusIcon(bill.status),
            color: _getBillStatusColor(bill.status, context),
          ),
        ),
        title: Text(
          bill.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Paid by: ${payer?.userName ?? 'Unknown'}'),
            Text(
              '${_formatDate(bill.dateCreated)} • ${bill.splits.length} people',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${bill.totalAmount.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getBillStatusColor(
                  bill.status,
                  context,
                ).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                bill.status.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _getBillStatusColor(bill.status, context),
                ),
              ),
            ),
          ],
        ),
        onTap: () => _navigateToBillDetail(bill),
      ),
    );
  }

  Widget _buildDebtSummarySection() {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Outstanding Debts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...(_debts.take(3).map((debt) => _buildDebtTile(debt))),
            if (_debts.length > 3) ...[
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: TextButton(
                  onPressed: () => _navigateToDebtDetails(),
                  child: Text('View All Debts (${_debts.length})'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDebtTile(DebtModel debt) {
    final colorScheme = Theme.of(context).colorScheme;
    final debtor =
        widget.group.members
            .where((m) => m.userId == debt.debtorUserId)
            .firstOrNull;
    final creditor =
        widget.group.members
            .where((m) => m.userId == debt.creditorUserId)
            .firstOrNull;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${debtor?.userName ?? 'Unknown'} owes ${creditor?.userName ?? 'Unknown'}',
              style: TextStyle(color: colorScheme.onSurface),
            ),
          ),
          Text(
            '\$${debt.remainingAmount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }

  Color _getBillStatusColor(String status, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (status.toLowerCase()) {
      case 'active':
        return colorScheme.tertiary;
      case 'settled':
        return colorScheme.primary;
      case 'cancelled':
        return colorScheme.error;
      default:
        return colorScheme.onSurfaceVariant;
    }
  }

  IconData _getBillStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Icons.pending_actions;
      case 'settled':
        return Icons.check_circle;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.receipt;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _navigateToCreateBill() {
    GoRouter.of(context).push('/groups/${widget.group.group.id}/create-bill');
  }

  void _navigateToAllBills() {
    GoRouter.of(context).push('/groups/${widget.group.group.id}/bills');
  }

  void _navigateToBillDetail(BillModel bill) {
    GoRouter.of(
      context,
    ).push('/groups/${widget.group.group.id}/bills/${bill.id}');
  }

  void _navigateToDebtDetails() {
    GoRouter.of(context).push('/groups/${widget.group.group.id}/debts');
  }
}
