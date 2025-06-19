import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';
import 'transfer_admin_dialog.dart';

class GroupSettingsPanel extends StatefulWidget {
  final GroupWithMembersModel group;

  const GroupSettingsPanel({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupSettingsPanel> createState() => _GroupSettingsPanelState();
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currentUserId = context.read<GroupsProvider>().getCurrentUserId();
    final isAdmin = widget.group.isUserAdmin(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Group Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: 16),

          // Basic Settings
          _buildBasicSettingsSection(context, isAdmin),

          const SizedBox(height: 20),

          // Member Permissions
          _buildPermissionsSection(context, isAdmin),

          const SizedBox(height: 20),

          // Future Settings (Bill Sharing)
          _buildFutureSettingsSection(context, isAdmin),

          const SizedBox(height: 20),

          // Danger Zone (Admin only)
          if (isAdmin) _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildBasicSettingsSection(BuildContext context, bool isAdmin) {
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
                Icon(Icons.settings, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Basic Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Group Name
            _buildSettingItem(
              'Group Name',
              widget.group.group.name,
              Icons.group,
              onTap: isAdmin ? () => _editGroupName(context) : null,
              showEdit: isAdmin,
            ),

            const Divider(height: 24),

            // Description
            _buildSettingItem(
              'Description',
              widget.group.group.description?.isNotEmpty == true
                  ? widget.group.group.description!
                  : 'No description',
              Icons.description,
              onTap: isAdmin ? () => _editDescription(context) : null,
              showEdit: isAdmin,
            ),

            const Divider(height: 24),

            // Default Currency
            _buildSettingItem(
              'Default Currency',
              widget.group.settings?.defaultCurrency ?? 'USD',
              Icons.currency_exchange,
              onTap: isAdmin ? () => _editCurrency(context) : null,
              showEdit: isAdmin,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection(BuildContext context, bool isAdmin) {
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
                Icon(Icons.security, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Member Permissions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Allow Member Invites
            _buildSwitchSetting(
              'Allow members to invite others',
              'When enabled, any member can send invitations',
              widget.group.group.allowMemberInvites,
              Icons.person_add,
              onChanged:
                  isAdmin ? (value) => _updateInvitePermission(value) : null,
            ),

            const SizedBox(height: 16),

            // Future: Allow Member Create Bills
            _buildSwitchSetting(
              'Allow members to create bills',
              'When enabled, any member can create and manage bills',
              widget.group.settings?.allowMemberCreateBills ?? true,
              Icons.receipt_long,
              onChanged: null, // Disabled for now - future feature
              isComingSoon: true,
            ),

            const SizedBox(height: 16),

            // Future: Require Admin Approval
            _buildSwitchSetting(
              'Require admin approval for new members',
              'New members must be approved by an admin before joining',
              widget.group.settings?.requireAdminApproval ?? false,
              Icons.admin_panel_settings,
              onChanged: null, // Disabled for now - future feature
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureSettingsSection(BuildContext context, bool isAdmin) {
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
                Icon(Icons.upcoming, size: 20, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Bill Sharing Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            Text(
              'These settings will be available when bill sharing is implemented',
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),

            const SizedBox(height: 16),

            // Default Split Method
            _buildSettingItem(
              'Default split method',
              widget.group.settings?.defaultSplitMethod ?? 'equal',
              Icons.pie_chart,
              onTap: null,
              isComingSoon: true,
            ),

            const Divider(height: 24),

            // Auto Calculate Settlements
            _buildSwitchSetting(
              'Auto-calculate settlements',
              'Automatically suggest optimal payment settlements',
              widget.group.settings?.autoCalculateSettlements ?? true,
              Icons.calculate,
              onChanged: null,
              isComingSoon: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.3)),
      ),
      color: colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.warning, size: 20, color: Colors.red),
                const SizedBox(width: 8),
                Text(
                  'Danger Zone',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Transfer Admin
            _buildDangerAction(
              'Transfer Admin Role',
              'Transfer admin privileges to another member',
              Icons.admin_panel_settings,
              Colors.orange,
              () => _transferAdmin(context),
            ),

            const SizedBox(height: 12),

            // Delete Group
            _buildDangerAction(
              'Delete Group',
              'Permanently delete this group and all associated data',
              Icons.delete_forever,
              Colors.red,
              () => _deleteGroup(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingItem(
    String title,
    String value,
    IconData icon, {
    VoidCallback? onTap,
    bool showEdit = false,
    bool isComingSoon = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),
            if (isComingSoon) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.purple,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (showEdit) ...[
              Icon(Icons.edit, size: 16, color: Colors.grey[400]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    IconData icon, {
    ValueChanged<bool>? onChanged,
    bool isComingSoon = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
        ),
        if (isComingSoon) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 10,
                color: Colors.purple,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.blueAccent,
          ),
        ],
      ],
    );
  }

  Widget _buildDangerAction(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 14, color: color),
          ],
        ),
      ),
    );
  }

  void _editGroupName(BuildContext context) {
    // TODO: Implement group name editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit group name functionality coming soon'),
      ),
    );
  }

  void _editDescription(BuildContext context) {
    // TODO: Implement description editing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Edit description functionality coming soon'),
      ),
    );
  }

  void _editCurrency(BuildContext context) {
    // TODO: Implement currency selection
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit currency functionality coming soon')),
    );
  }

  void _updateInvitePermission(bool value) async {
    final provider = context.read<GroupsProvider>();

    final updatedGroup = await provider.updateGroup(
      groupId: widget.group.group.id!,
      allowMemberInvites: value,
    );

    if (updatedGroup != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Members can now invite others'
                : 'Only admins can invite members',
          ),
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update setting: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _transferAdmin(BuildContext context) {
    showTransferAdminDialog(context, widget.group);
  }

  void _deleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Group'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete "${widget.group.group.name}"?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'This action cannot be undone. All group data including:',
                ),
                const SizedBox(height: 8),
                const Text('• Member information'),
                const Text('• Group settings'),
                const Text('• Future bill data (when implemented)'),
                const SizedBox(height: 8),
                const Text(
                  'will be permanently deleted.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
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
                  final success = await provider.deleteGroup(
                    widget.group.group.id!,
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group deleted successfully'),
                      ),
                    );
                    Navigator.of(context).pop(); // Go back to groups list
                  } else if (mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete group: ${provider.error}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete Group'),
              ),
            ],
          ),
    );
  }
}
