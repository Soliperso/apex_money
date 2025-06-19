import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../data/models/models.dart';
import 'invite_member_dialog.dart';
import 'edit_group_dialog.dart';

class GroupsList extends StatelessWidget {
  const GroupsList({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.groups.isEmpty) {
          return _buildEmptyState(context);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: provider.groups.length,
          itemBuilder: (context, index) {
            final group = provider.groups[index];
            return _buildGroupCard(context, group);
          },
        );
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 120,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 32),
            Text(
              'No Groups Yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Create your first group to start sharing expenses with friends and family.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context),
              icon: Icon(
                Icons.add,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
              label: Text(
                'Create Your First Group',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupCard(BuildContext context, GroupWithMembersModel group) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color:
            isDark
                ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : theme.colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border:
            isDark
                ? null
                : Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _navigateToGroupDetail(context, group),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Group avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primaryContainer,
                child:
                    group.group.imageUrl != null
                        ? ClipOval(
                          child: Image.network(
                            group.group.imageUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) =>
                                    _buildGroupInitials(
                                      context,
                                      group.group.name,
                                    ),
                          ),
                        )
                        : _buildGroupInitials(context, group.group.name),
              ),
              const SizedBox(width: 12),

              // Group info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Group name
                    Text(
                      group.group.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Member count and currency in one clean line
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${group.members.length} member${group.members.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.currency_exchange,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          group.settings?.defaultCurrency ?? 'USD',
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),

                    // Show pending invitations if any
                    if ((group.pendingInvitationsCount ?? 0) > 0) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            Icons.schedule,
                            size: 14,
                            color: theme.colorScheme.tertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.pendingInvitationsCount ?? 0} pending invitation${(group.pendingInvitationsCount ?? 0) != 1 ? 's' : ''}',
                            style: TextStyle(
                              color: theme.colorScheme.tertiary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Action menu - simplified
              PopupMenuButton<String>(
                onSelected: (value) => _handleMenuAction(context, group, value),
                icon: Icon(
                  Icons.more_vert,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                itemBuilder:
                    (context) => [
                      const PopupMenuItem(
                        value: 'view',
                        child: Row(
                          children: [
                            Icon(Icons.visibility, size: 20),
                            SizedBox(width: 12),
                            Text('View Details'),
                          ],
                        ),
                      ),
                      if (group.isUserAdmin(
                        context.read<GroupsProvider>().getCurrentUserId(),
                      )) ...[
                        const PopupMenuItem(
                          value: 'invite',
                          child: Row(
                            children: [
                              Icon(Icons.person_add, size: 20),
                              SizedBox(width: 12),
                              Text('Invite Members'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 12),
                              Text('Edit Group'),
                            ],
                          ),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                color: theme.colorScheme.error,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Delete Group',
                                style: TextStyle(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        PopupMenuItem(
                          value: 'leave',
                          child: Row(
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                color: theme.colorScheme.tertiary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Leave Group',
                                style: TextStyle(
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
              ),
            ],
          ),
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
    context.push('/groups/${group.group.id}');
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();
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
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  Navigator.of(context).pop();
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
