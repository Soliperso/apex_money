import 'package:flutter/material.dart';
import '../../data/models/models.dart';

class GroupDetailInfo extends StatelessWidget {
  final GroupWithMembersModel group;

  const GroupDetailInfo({Key? key, required this.group}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header Card
          _buildGroupHeaderCard(context),

          const SizedBox(height: 20),

          // Statistics Cards
          _buildStatisticsSection(context),

          const SizedBox(height: 20),

          // Description Section
          if (group.group.description?.isNotEmpty == true)
            _buildDescriptionSection(context),

          const SizedBox(height: 20),

          // Activity Section (placeholder for future)
          _buildActivitySection(context),
        ],
      ),
    );
  }

  Widget _buildGroupHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Group Avatar
                CircleAvatar(
                  radius: 32,
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
                  child: Text(
                    group.group.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const SizedBox(width: 16),

                // Group Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        group.group.name,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Created ${_formatDate(group.group.createdAt)}',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      if (group.group.updatedAt != group.group.createdAt) ...[
                        const SizedBox(height: 2),
                        Text(
                          'Last updated ${_formatDate(group.group.updatedAt)}',
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Group Properties
            Row(
              children: [
                _buildPropertyChip(
                  Icons.currency_exchange,
                  group.settings?.defaultCurrency ?? 'USD',
                  Colors.green,
                ),
                const SizedBox(width: 12),
                _buildPropertyChip(
                  Icons.admin_panel_settings,
                  group.adminMember?.userName ?? 'Unknown Admin',
                  Colors.purple,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Member Permissions
            Row(
              children: [
                _buildPropertyChip(
                  group.group.allowMemberInvites ? Icons.check : Icons.close,
                  group.group.allowMemberInvites
                      ? 'Members can invite'
                      : 'Admin only invites',
                  group.group.allowMemberInvites ? Colors.green : Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPropertyChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Group Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Total Members',
                    group.memberCount.toString(),
                    Icons.people,
                    colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Pending Invites',
                    (group.pendingInvitationsCount ?? 0).toString(),
                    Icons.schedule,
                    colorScheme.tertiary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Active Status',
                    group.group.isActive ? 'Active' : 'Inactive',
                    group.group.isActive ? Icons.check_circle : Icons.cancel,
                    group.group.isActive
                        ? colorScheme.primary
                        : colorScheme.error,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    context,
                    'Bills Created',
                    '0', // Placeholder for future bill integration
                    Icons.receipt,
                    colorScheme.secondary,
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
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              group.group.description!,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.timeline, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for future activity feed
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colorScheme.outline.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.timeline,
                    size: 48,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Activity feed coming soon',
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Track member activity, bill creation, and more',
                    style: TextStyle(
                      fontSize: 12,
                      color: colorScheme.onSurfaceVariant.withOpacity(0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }
}
