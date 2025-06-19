import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';
import 'invite_member_dialog.dart';

class GroupMembersList extends StatelessWidget {
  final GroupWithMembersModel group;

  const GroupMembersList({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = context.read<GroupsProvider>().getCurrentUserId();
    final isAdmin = group.isUserAdmin(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12), // Reduced padding to give more space
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with member count
          _buildHeader(context, isAdmin),

          const SizedBox(height: 16),

          // Active Members
          _buildMembersSection(
            context,
            'Active Members',
            group.activeMembers,
            Icons.people,
            colorScheme.primary,
            isAdmin,
            currentUserId,
          ),

          // Pending Members (if any)
          if (group.pendingMembers.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildMembersSection(
              context,
              'Pending Members',
              group.pendingMembers,
              Icons.schedule,
              colorScheme.tertiary,
              isAdmin,
              currentUserId,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isAdmin) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Group Members',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${group.activeMembers.length} active • ${group.pendingMembers.length} pending',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        // Add Member Button (Admin only)
        if (isAdmin) ...[
          ElevatedButton.icon(
            onPressed: () => _showInviteMemberDialog(context),
            icon: const Icon(Icons.person_add, size: 18),
            label: const Text('Invite'),
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMembersSection(
    BuildContext context,
    String title,
    List<GroupMemberModel> members,
    IconData icon,
    Color color,
    bool isAdmin,
    String currentUserId,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                members.length.toString(),
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Members List
        ...members.map(
          (member) => _buildMemberCard(context, member, isAdmin, currentUserId),
        ),
      ],
    );
  }

  Widget _buildMemberCard(
    BuildContext context,
    GroupMemberModel member,
    bool isCurrentUserAdmin,
    String currentUserId,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final isCurrentUser = member.userId == currentUserId;
    final isAdmin = member.role == GroupMemberRole.admin;
    final canManage = isCurrentUserAdmin && !isCurrentUser && !isAdmin;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: colorScheme.surfaceContainer,
      child: IntrinsicHeight(
        // Ensure consistent height
        child: Padding(
          padding: const EdgeInsets.all(12), // Reduced padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: _getAvatarColor(member.role, colorScheme),
                child: Text(
                  (member.userName ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Member Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name and "You" badge with proper overflow handling
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            member.userName ?? 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCurrentUser) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'You',
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      member.userEmail ?? 'No email',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Role, status, and join date - using Wrap for better overflow handling
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        _buildRoleBadge(member.role, colorScheme),
                        _buildStatusBadge(member.status, colorScheme),
                        if (member.status == GroupMemberStatus.active)
                          Text(
                            'Joined ${_formatJoinDate(member.joinedAt)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions Menu
              if (canManage) ...[
                PopupMenuButton<String>(
                  onSelected:
                      (value) => _handleMemberAction(context, member, value),
                  icon: Icon(
                    Icons.more_vert,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  itemBuilder:
                      (context) => [
                        if (member.role != GroupMemberRole.admin) ...[
                          PopupMenuItem(
                            value: 'promote',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.admin_panel_settings,
                                  size: 18,
                                  color: colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Make Admin',
                                  style: TextStyle(
                                    color: colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        PopupMenuItem(
                          value: 'remove',
                          child: Row(
                            children: [
                              Icon(
                                Icons.person_remove,
                                size: 18,
                                color: colorScheme.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Remove',
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ],
                          ),
                        ),
                      ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleBadge(GroupMemberRole role, ColorScheme colorScheme) {
    final isAdmin = role == GroupMemberRole.admin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            isAdmin
                ? colorScheme.primary.withOpacity(0.1)
                : colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isAdmin
                  ? colorScheme.primary.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.3),
        ),
      ),
      child: Text(
        isAdmin ? 'Admin' : 'Member',
        style: TextStyle(
          fontSize: 10,
          color: isAdmin ? colorScheme.primary : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStatusBadge(GroupMemberStatus status, ColorScheme colorScheme) {
    Color color;
    String text;

    switch (status) {
      case GroupMemberStatus.active:
        color = colorScheme.primary;
        text = 'Active';
        break;
      case GroupMemberStatus.invited:
        color = colorScheme.tertiary;
        text = 'Pending';
        break;
      case GroupMemberStatus.left:
        color = colorScheme.onSurfaceVariant;
        text = 'Left';
        break;
      case GroupMemberStatus.removed:
        color = colorScheme.error;
        text = 'Removed';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getAvatarColor(GroupMemberRole role, ColorScheme colorScheme) {
    return role == GroupMemberRole.admin
        ? colorScheme.primary
        : colorScheme.secondary;
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

  void _showInviteMemberDialog(BuildContext context) {
    showInviteMemberDialog(context, group);
  }

  void _handleMemberAction(
    BuildContext context,
    GroupMemberModel member,
    String action,
  ) async {
    switch (action) {
      case 'promote':
        _showPromoteConfirmation(context, member);
        break;
      case 'remove':
        _showRemoveConfirmation(context, member);
        break;
    }
  }

  void _showPromoteConfirmation(BuildContext context, GroupMemberModel member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Make Admin'),
            content: Text(
              'Are you sure you want to make ${member.userName} an admin? This will transfer admin privileges to them.',
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
                  final success = await provider.transferAdminRole(
                    groupId: group.group.id!,
                    newAdminUserId: member.userId,
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.userName} is now the admin'),
                      ),
                    );
                  } else if (context.mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to transfer admin: ${provider.error}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(backgroundColor: Colors.purple),
                child: const Text('Make Admin'),
              ),
            ],
          ),
    );
  }

  void _showRemoveConfirmation(BuildContext context, GroupMemberModel member) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Remove Member'),
            content: Text(
              'Are you sure you want to remove ${member.userName} from this group?',
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
                  final success = await provider.removeMember(
                    groupId: group.group.id!,
                    userId: member.userId,
                  );

                  if (success && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${member.userName} has been removed'),
                      ),
                    );
                  } else if (context.mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to remove member: ${provider.error}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
