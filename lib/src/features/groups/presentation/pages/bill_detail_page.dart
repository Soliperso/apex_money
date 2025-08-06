import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../../data/services/bill_service.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/error_boundary.dart';
import '../../../../shared/services/haptic_service.dart';
import '../../../../shared/theme/app_spacing.dart';

class BillDetailPage extends StatefulWidget {
  final String groupId;
  final String billId;

  const BillDetailPage({Key? key, required this.groupId, required this.billId})
    : super(key: key);

  @override
  State<BillDetailPage> createState() => _BillDetailPageState();
}

class _BillDetailPageState extends State<BillDetailPage> {
  final BillService _billService = BillService();

  BillModel? _bill;
  GroupWithMembersModel? _group;
  bool _isLoading = true;
  bool _isDeleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBillData();
  }

  Future<void> _loadBillData() async {
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

      // Load bills and find the specific bill
      final bills = await _billService.fetchGroupBills(widget.groupId);
      _bill = bills.where((bill) => bill.id == widget.billId).firstOrNull;

      if (_bill == null) {
        throw Exception('Bill not found');
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteBill() async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (!confirmed) return;

    setState(() => _isDeleting = true);

    try {
      await _billService.deleteBill(widget.billId);

      if (mounted) {
        HapticService().success();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Bill deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        GoRouter.of(context).pop(); // Go back to group detail
      }
    } catch (e) {
      if (mounted) {
        HapticService().error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting bill: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<bool> _showDeleteConfirmationDialog() async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: const Text('Delete Bill'),
                content: Text(
                  'Are you sure you want to delete "${_bill?.title ?? 'this bill'}"? This action cannot be undone.',
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      HapticService().buttonPress();
                      Navigator.of(context).pop(false);
                    },
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      HapticService().heavy();
                      Navigator.of(context).pop(true);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: const Text('Delete'),
                  ),
                ],
              ),
        ) ??
        false;
  }

  void _editBill() {
    GoRouter.of(context).push(
      '/groups/${widget.groupId}/create-bill',
      extra: {'mode': 'edit', 'bill': _bill},
    );
  }

  void _markSplitAsPaid(String userId) async {
    // Show confirmation dialog
    final member = _group?.members.where((m) => m.userId == userId).firstOrNull;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Mark as Paid'),
            content: Text(
              'Mark ${member?.userName ?? 'this member'}\'s share as paid?\n\nThis action will update the settlement status.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  HapticService().buttonPress();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  HapticService().buttonPress();
                  Navigator.of(context).pop(true);
                },
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Mark Paid'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      // Get split info for notification
      final split = _bill?.splits.where((s) => s.userId == userId).firstOrNull;

      // Mark split as paid with enhanced response
      final result = await _billService.markSplitAsPaid(widget.billId, userId);

      // Send settlement notification
      if (split != null && _bill != null) {
        await _billService.sendSettlementNotification(
          groupId: widget.groupId,
          billId: widget.billId,
          payerUserId: userId,
          payeeUserId: _bill!.paidByUserId,
          amount: split.amount,
          billTitle: _bill!.title,
        );
      }

      await _loadBillData(); // Refresh data

      if (mounted) {
        HapticService().success();

        // Enhanced success message based on bill status
        final message =
            result['settlement_complete'] == true
                ? 'Bill fully settled! 🎉'
                : '${member?.userName ?? 'Payment'} marked as settled!';

        final backgroundColor =
            result['settlement_complete'] == true ? Colors.blue : Colors.green;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  result['settlement_complete'] == true
                      ? Icons.celebration
                      : Icons.check_circle,
                  color: Colors.white,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (result['settlement_complete'] == true)
                        const Text(
                          'All payments have been received',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: backgroundColor,
            duration: Duration(
              seconds: result['settlement_complete'] == true ? 4 : 3,
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        HapticService().error();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error marking payment: $e')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
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
          title: const Text('Loading...'),
          backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
          foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _bill == null || _group == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Bill Not Found'),
          backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
          foregroundColor: isDark ? colorScheme.onSurface : Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colorScheme.error),
              const SizedBox(height: 16),
              Text(_error ?? 'Bill not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).pop(),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final payer =
        _group!.members
            .where((m) => m.userId == _bill!.paidByUserId)
            .firstOrNull;

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
              'Bill Details',
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  _editBill();
                  break;
                case 'delete':
                  _deleteBill();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit Bill'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: colorScheme.error),
                        const SizedBox(width: 8),
                        Text(
                          'Delete Bill',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: AppGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bill Header
              _buildBillHeader(),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Bill Details
              _buildBillDetails(),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Split Details
              _buildSplitDetails(),
              const SizedBox(height: AppSpacing.sectionSpacing),

              // Actions
              if (!_isDeleting) _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBillHeader() {
    final colorScheme = Theme.of(context).colorScheme;
    final payer =
        _group!.members
            .where((m) => m.userId == _bill!.paidByUserId)
            .firstOrNull;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _bill!.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getBillStatusColor(
                    _bill!.status,
                  ).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  _bill!.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getBillStatusColor(_bill!.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                '\$${_bill!.totalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const Spacer(),
              Text(
                'Paid by ${payer?.userName ?? 'Unknown'}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBillDetails() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bill Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDetailRow(
            'Description',
            _bill!.description.isNotEmpty
                ? _bill!.description
                : 'No description',
          ),
          _buildDetailRow('Date Created', _formatDate(_bill!.dateCreated)),
          _buildDetailRow(
            'Split Method',
            _getSplitMethodDisplay(_bill!.splitMethod),
          ),
          _buildDetailRow('Currency', _bill!.currency),
          if (_bill!.dueDate != null)
            _buildDetailRow('Due Date', _formatDate(_bill!.dueDate!)),
          if (_bill!.metadata?['location'] != null)
            _buildDetailRow(
              'Location',
              _bill!.metadata!['location'].toString(),
            ),
          if (_bill!.metadata?['tags'] != null &&
              _bill!.metadata!['tags'] is List)
            _buildDetailRow(
              'Tags',
              (_bill!.metadata!['tags'] as List).join(', '),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: colorScheme.onSurface)),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitDetails() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            Theme.of(context).brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Split Details',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ..._bill!.splits.map((split) => _buildSplitTile(split)),
        ],
      ),
    );
  }

  Widget _buildSplitTile(BillSplitModel split) {
    final colorScheme = Theme.of(context).colorScheme;
    final member =
        _group!.members.where((m) => m.userId == split.userId).firstOrNull;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            split.isPaid
                ? colorScheme.primary.withValues(alpha: 0.1)
                : colorScheme.surface.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              split.isPaid
                  ? colorScheme.primary.withValues(alpha: 0.3)
                  : colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor:
                split.isPaid
                    ? colorScheme.primary.withValues(alpha: 0.2)
                    : colorScheme.surfaceVariant,
            child: Icon(
              split.isPaid ? Icons.check_circle : Icons.person,
              color:
                  split.isPaid
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member?.userName ?? 'Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${split.percentage.toStringAsFixed(1)}% of total',
                  style: TextStyle(
                    fontSize: 12,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                if (split.isPaid && split.paidDate != null)
                  Text(
                    'Paid on ${_formatDate(split.paidDate!)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$${split.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              if (!split.isPaid && split.userId != _bill!.paidByUserId)
                TextButton(
                  onPressed: () => _markSplitAsPaid(split.userId),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 0),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                  ),
                  child: const Text(
                    'Mark Paid',
                    style: TextStyle(fontSize: 11),
                  ),
                ),
              if (split.isPaid)
                Icon(Icons.check_circle, color: colorScheme.primary, size: 16),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _editBill,
            icon: const Icon(Icons.edit),
            label: const Text('Edit Bill'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isDeleting ? null : _deleteBill,
            icon:
                _isDeleting
                    ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.error,
                      ),
                    )
                    : const Icon(Icons.delete),
            label: Text(_isDeleting ? 'Deleting...' : 'Delete Bill'),
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Color _getBillStatusColor(String status) {
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

  String _getSplitMethodDisplay(String method) {
    switch (method) {
      case 'equal':
        return 'Split Equally';
      case 'percentage':
        return 'By Percentage';
      case 'custom':
        return 'Custom Amounts';
      default:
        return method;
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
