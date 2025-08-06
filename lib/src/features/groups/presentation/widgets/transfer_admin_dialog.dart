import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/theme/app_spacing.dart';

class TransferAdminDialog extends StatefulWidget {
  final GroupWithMembersModel group;

  const TransferAdminDialog({Key? key, required this.group}) : super(key: key);

  @override
  State<TransferAdminDialog> createState() => _TransferAdminDialogState();
}

class _TransferAdminDialogState extends State<TransferAdminDialog> {
  GroupMemberModel? _selectedMember;

  @override
  Widget build(BuildContext context) {
    final currentUserId = context.read<GroupsProvider>().getCurrentUserId();

    // Get all active members except current admin
    final eligibleMembers =
        widget.group.activeMembers
            .where(
              (member) =>
                  member.userId != currentUserId &&
                  member.role != GroupMemberRole.admin,
            )
            .toList();

    return AlertDialog(
      title: const Text(
        'Transfer Admin Role',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning Container
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppTheme.warningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.warningColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning,
                    color: AppTheme.warningColor,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will transfer all admin privileges to the selected member. You will become a regular member.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (eligibleMembers.isEmpty) ...[
              // No eligible members
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No eligible members',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'There are no active members to transfer admin role to.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Member selection
              const Text(
                'Select new admin:',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),

              const SizedBox(height: AppSpacing.md),

              // Members list
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Column(
                    children:
                        eligibleMembers
                            .map((member) => _buildMemberCard(member))
                            .toList(),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        if (eligibleMembers.isNotEmpty)
          Consumer<GroupsProvider>(
            builder: (context, provider, child) {
              return FilledButton(
                onPressed:
                    _selectedMember == null || provider.isUpdating
                        ? null
                        : () => _transferAdmin(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
                child:
                    provider.isUpdating
                        ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text('Transfer Admin'),
              );
            },
          ),
      ],
    );
  }

  Widget _buildMemberCard(GroupMemberModel member) {
    final isSelected = _selectedMember?.userId == member.userId;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMember = isSelected ? null : member;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppTheme.warningColor.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                isSelected
                    ? AppTheme.warningColor
                    : Theme.of(context).colorScheme.outline,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Selection indicator
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? AppTheme.warningColor : Colors.transparent,
                border: Border.all(
                  color:
                      isSelected
                          ? AppTheme.warningColor
                          : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
            ),

            const SizedBox(width: AppSpacing.md),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                (member.userName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.userName ?? 'Unknown User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color:
                          isSelected
                              ? AppTheme.warningColor
                              : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.userEmail ?? 'No email',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${_formatJoinDate(member.joinedAt)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 30) {
      return '${difference.inDays} days ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  Future<void> _transferAdmin(BuildContext context) async {
    if (_selectedMember == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Transfer'),
            content: Text(
              'Are you sure you want to transfer admin role to ${_selectedMember!.userName}?\n\n'
              'This action cannot be undone. You will lose all admin privileges.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.warningColor,
                ),
                child: const Text('Transfer'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    final provider = context.read<GroupsProvider>();

    final success = await provider.transferAdminRole(
      groupId: widget.group.group.id!,
      newAdminUserId: _selectedMember!.userId,
    );

    if (success && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin role transferred to ${_selectedMember!.userName}',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to transfer admin: ${provider.error}'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}

/// Helper function to show the transfer admin dialog
void showTransferAdminDialog(
  BuildContext context,
  GroupWithMembersModel group,
) {
  showDialog(
    context: context,
    builder: (context) => TransferAdminDialog(group: group),
  );
}
