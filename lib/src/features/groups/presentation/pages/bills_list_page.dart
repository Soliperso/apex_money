import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../providers/groups_provider.dart';
import '../widgets/group_bills_tab.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/error_boundary.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/utils/currency_formatter.dart';

class BillsListPage extends StatefulWidget {
  final String groupId;

  const BillsListPage({super.key, required this.groupId});

  @override
  State<BillsListPage> createState() => _BillsListPageState();
}

class _BillsListPageState extends State<BillsListPage>
    with SingleTickerProviderStateMixin {
  final BillService _billService = BillService();
  late TabController _tabController;

  List<BillModel> _allBills = [];
  GroupWithMembersModel? _group;
  bool _isLoading = true;
  String? _error;

  // Filter states
  List<BillModel> _activeBills = [];
  List<BillModel> _settledBills = [];
  List<BillModel> _filteredBills = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    HapticService().selection();
    setState(() {
      switch (_tabController.index) {
        case 0: // All
          _filteredBills = _allBills;
          break;
        case 1: // Active
          _filteredBills = _activeBills;
          break;
        case 2: // Settled
          _filteredBills = _settledBills;
          break;
      }
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load group data
      final provider = context.read<GroupsProvider>();
      _group = provider.getGroupById(widget.groupId);

      if (_group == null) {
        await provider.loadGroups();
        _group = provider.getGroupById(widget.groupId);
      }

      if (_group == null) {
        throw Exception('Group not found');
      }

      // Load bills
      final bills = await _billService.fetchGroupBills(widget.groupId);

      setState(() {
        _allBills =
            bills..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        _activeBills =
            bills.where((bill) => bill.status == 'active').toList()
              ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        _settledBills =
            bills.where((bill) => bill.status == 'settled').toList()
              ..sort((a, b) => b.dateCreated.compareTo(a.dateCreated));

        // Set initial filtered list based on current tab
        _onTabChanged();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _navigateToBillDetail(BillModel bill) {
    HapticService().light();
    context.go('/groups/${widget.groupId}/bills/${bill.id}');
  }

  void _createNewBill() {
    HapticService().buttonPress();
    context.go('/groups/${widget.groupId}/create-bill');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

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
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
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
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
                if (_group != null)
                  Flexible(
                    child: Text(
                      _group!.group.name,
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
                Icon(
                  Icons.chevron_right,
                  size: 14,
                  color:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                ),
              ],
            ),
            // Page title
            Text(
              'All Bills',
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
        bottom:
            _isLoading
                ? null
                : TabBar(
                  controller: _tabController,
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('All'),
                          if (_allBills.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.white.withValues(alpha: 0.2)
                                        : Colors.white.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_allBills.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Active'),
                          if (_activeBills.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppTheme.warningColor.withValues(
                                          alpha: 0.3,
                                        )
                                        : AppTheme.warningColor.withValues(
                                          alpha: 0.4,
                                        ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_activeBills.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Settled'),
                          if (_settledBills.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppTheme.successColor.withValues(
                                          alpha: 0.3,
                                        )
                                        : AppTheme.successColor.withValues(
                                          alpha: 0.4,
                                        ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${_settledBills.length}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  labelColor: isDark ? colorScheme.onSurface : Colors.white,
                  unselectedLabelColor:
                      isDark
                          ? colorScheme.onSurface.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.7),
                  indicatorColor: isDark ? colorScheme.primary : Colors.white,
                ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewBill,
        tooltip: 'Create New Bill',
        child: const Icon(Icons.add),
      ),
      body: AppGradientBackground(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return _buildLoadingSkeleton();
    }

    if (_error != null) {
      return ErrorBoundary(
        errorTitle: 'Unable to Load Bills',
        errorMessage: 'There was a problem loading the bills for this group.',
        onRetry: () {
          HapticService().buttonPress();
          _loadData();
        },
        child: const SizedBox.shrink(),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        _buildBillsList(_allBills, 'No bills in this group yet'),
        _buildBillsList(_activeBills, 'No active bills'),
        _buildBillsList(_settledBills, 'No settled bills yet'),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: List.generate(
          5,
          (index) => const SkeletonCard(
            height: 120,
            margin: EdgeInsets.only(bottom: AppSpacing.md),
            children: [
              Row(
                children: [
                  SkeletonAvatar(size: 50),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonText(height: 18, width: 200),
                        SizedBox(height: 8),
                        SkeletonText(height: 14, width: 150),
                        SizedBox(height: 8),
                        SkeletonText(height: 12, width: 100),
                      ],
                    ),
                  ),
                  SkeletonText(height: 24, width: 80),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillsList(List<BillModel> bills, String emptyMessage) {
    if (bills.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              emptyMessage,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton.icon(
              onPressed: _createNewBill,
              icon: const Icon(Icons.add),
              label: const Text('Create First Bill'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: bills.length,
        itemBuilder: (context, index) {
          return withErrorBoundary(
            _buildBillCard(bills[index]),
            errorTitle: 'Bill Display Error',
            errorMessage: 'Unable to display this bill.',
            onRetry: _loadData,
          );
        },
      ),
    );
  }

  Widget _buildBillCard(BillModel bill) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final payer =
        _group?.members.where((m) => m.userId == bill.paidByUserId).firstOrNull;

    final statusColor = _getBillStatusColor(bill.status, colorScheme);
    final statusIcon = _getBillStatusIcon(bill.status);

    // Calculate settlement progress
    final totalSplits = bill.splits.length;
    final paidSplits = bill.splits.where((split) => split.isPaid).length;
    final settlementProgress = totalSplits > 0 ? paidSplits / totalSplits : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color:
            isDark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToBillDetail(bill),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: Icon(statusIcon, color: statusColor, size: 24),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (bill.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            bill.description,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyFormatter.format(bill.totalAmount),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusXs,
                          ),
                        ),
                        child: Text(
                          bill.status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.md),

              // Settlement progress bar
              if (bill.status == 'active' && bill.splits.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Settlement Progress',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '$paidSplits of $totalSplits paid',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(
                              AppSpacing.radiusXs,
                            ),
                            child: LinearProgressIndicator(
                              value: settlementProgress,
                              backgroundColor: colorScheme.outlineVariant
                                  .withValues(alpha: 0.3),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                settlementProgress == 1.0
                                    ? AppTheme.successColor
                                    : colorScheme.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // Bottom info row
              Row(
                children: [
                  Icon(
                    Icons.person,
                    size: 16,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Paid by ${payer?.userName ?? 'Unknown'}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(bill.dateCreated),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getBillStatusColor(String status, ColorScheme colorScheme) {
    switch (status) {
      case 'active':
        return AppTheme.warningColor;
      case 'settled':
        return AppTheme.successColor;
      case 'cancelled':
        return AppTheme.errorColor;
      default:
        return colorScheme.outline;
    }
  }

  IconData _getBillStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.pending;
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
}
