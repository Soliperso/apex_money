import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../data/models/models.dart';
import 'invite_member_dialog.dart';
import 'edit_group_dialog.dart';
import '../../../../shared/theme/app_spacing.dart';

class GroupsList extends StatelessWidget {
  const GroupsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<GroupsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Groups content in a glass-morphism container matching Settings/Info tabs
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.surfaceContainer.withValues(
                              alpha: 0.6,
                            )
                            : theme.colorScheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.3,
                      ),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section Header with icon - matching Settings/Info tab style
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(
                                AppSpacing.radiusSm,
                              ),
                            ),
                            child: Icon(
                              Icons.group_rounded,
                              size: 18,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Your Groups',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Groups content
                      Expanded(
                        child:
                            provider.groups.isEmpty
                                ? Center(child: _buildEmptyState(context))
                                : _buildGroupsList(context, provider.groups),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.group_outlined,
          size: 48,
          color: Colors.grey.withValues(alpha: 0.4),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'No groups yet',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Create your first group to start sharing expenses',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.withValues(alpha: 0.5),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGroupsList(
    BuildContext context,
    List<GroupWithMembersModel> groups,
  ) {
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: groups.length,
      itemBuilder: (context, index) {
        final group = groups[index];
        return Padding(
          padding: EdgeInsets.only(
            bottom: index < groups.length - 1 ? AppSpacing.md : 0,
          ),
          child: _buildGroupCard(context, group),
        );
      },
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupWithMembersModel group) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        onTap: () => _navigateToGroupDetail(context, group),
        child: Row(
          children: [
            // Group info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name
                  Text(
                    group.group.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Member count and currency
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 2,
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        group.group.defaultCurrency,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Navigation arrow
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupInitials(BuildContext context, String name) {
    return Text(
      name.isNotEmpty ? name.substring(0, 1).toUpperCase() : '?',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
        fontSize: 20,
      ),
    );
  }

  void _navigateToGroupDetail(
    BuildContext context,
    GroupWithMembersModel group,
  ) {
    context.go('/groups/${group.group.id}');
  }

  void _handleMenuAction(
    BuildContext context,
    GroupWithMembersModel group,
    String action,
  ) {
    switch (action) {
      case 'view':
        _navigateToGroupDetail(context, group);
        break;
      case 'edit':
        _showEditGroupDialog(context, group);
        break;
      case 'invite':
        _showInviteMemberDialog(context, group);
        break;
      case 'delete':
        _showDeleteConfirmation(context, group);
        break;
      case 'leave':
        _showLeaveConfirmation(context, group);
        break;
    }
  }

  void _showCreateGroupDialog(BuildContext context) {
    // This will be implemented in CreateGroupFab
    // For now, just show a placeholder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create group functionality coming soon')),
    );
  }

  void _showEditGroupDialog(BuildContext context, GroupWithMembersModel group) {
    showEditGroupDialog(context, group);
  }

  void _showInviteMemberDialog(
    BuildContext context,
    GroupWithMembersModel group,
  ) {
    showInviteMemberDialog(context, group);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    GroupWithMembersModel group,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Group'),
            content: Text(
              'Are you sure you want to delete "${group.group.name}"? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  context.pop();
                  final provider = context.read<GroupsProvider>();
                  final success = await provider.deleteGroup(group.group.id!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group deleted successfully'),
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showLeaveConfirmation(
    BuildContext context,
    GroupWithMembersModel group,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: Text(
              'Are you sure you want to leave "${group.group.name}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  context.pop();
                  final provider = context.read<GroupsProvider>();
                  final success = await provider.leaveGroup(group.group.id!);
                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Left group successfully')),
                    );
                  }
                },
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }
}
