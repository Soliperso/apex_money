import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';
import 'transfer_admin_dialog.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

class GroupSettingsPanel extends StatefulWidget {
  final GroupWithMembersModel group;

  const GroupSettingsPanel({Key? key, required this.group}) : super(key: key);

  @override
  State<GroupSettingsPanel> createState() => _GroupSettingsPanelState();
}

class _GroupSettingsPanelState extends State<GroupSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final currentUserId = context.read<GroupsProvider>().getCurrentUserId();
    final isAdmin = widget.group.isUserAdmin(currentUserId);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Settings
          _buildBasicSettingsSection(context, isAdmin),

          const SizedBox(height: AppSpacing.xl),

          // Member Permissions
          _buildPermissionsSection(context, isAdmin),

          const SizedBox(height: AppSpacing.xl),

          // Future Settings (Bill Sharing)
          _buildFutureSettingsSection(context, isAdmin),

          const SizedBox(height: AppSpacing.xl),

          // Danger Zone (Admin only)
          if (isAdmin) _buildDangerZone(context),
        ],
      ),
    );
  }

  Widget _buildBasicSettingsSection(BuildContext context, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Basic Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

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
    );
  }

  Widget _buildPermissionsSection(BuildContext context, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Member Permissions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Allow Member Invites
          _buildSwitchSetting(
            'Allow members to invite others',
            'When enabled, any member can send invitations',
            widget.group.group.allowMemberInvites,
            Icons.person_add,
            onChanged:
                isAdmin ? (value) => _updateInvitePermission(value) : null,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Future: Allow Member Create Bills
          _buildSwitchSetting(
            'Allow members to create bills',
            'When enabled, any member can create and manage bills',
            widget.group.settings?.allowMemberCreateBills ?? true,
            Icons.receipt_long,
            onChanged: null, // Disabled for now - future feature
            isComingSoon: true,
          ),

          const SizedBox(height: AppSpacing.lg),

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
    );
  }

  Widget _buildFutureSettingsSection(BuildContext context, bool isAdmin) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Bill Sharing Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
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

          const SizedBox(height: AppSpacing.lg),

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
    );
  }

  Widget _buildDangerZone(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Text(
            'Danger Zone',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.errorColor,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Transfer Admin
          _buildDangerAction(
            'Transfer Admin Role',
            'Transfer admin privileges to another member',
            Icons.admin_panel_settings,
            AppTheme.warningColor,
            () => _transferAdmin(context),
          ),

          const SizedBox(height: AppSpacing.md),

          // Delete Group
          _buildDangerAction(
            'Delete Group',
            'Permanently delete this group and all associated data',
            Icons.delete_forever,
            AppTheme.errorColor,
            () => _deleteGroup(context),
          ),
        ],
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
            Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: AppSpacing.md),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            if (isComingSoon) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Coming Soon',
                  style: TextStyle(
                    fontSize: 10,
                    color: AppTheme.infoColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ] else if (showEdit) ...[
              Icon(
                Icons.edit,
                size: 16,
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
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
        Icon(
          icon,
          size: 20,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: AppSpacing.md),
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
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        if (isComingSoon) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Coming Soon',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.infoColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ] else ...[
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.primaryColor,
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
            const SizedBox(width: AppSpacing.md),
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
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
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
    final TextEditingController controller = TextEditingController(
      text: widget.group.group.name,
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Group Name'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Group Name',
                border: OutlineInputBorder(),
              ),
              maxLength: 50,
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newName = controller.text.trim();
                  if (newName.isNotEmpty &&
                      newName != widget.group.group.name) {
                    context.pop();
                    await _updateGroupField('name', newName);
                  } else {
                    context.pop();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _editDescription(BuildContext context) {
    final TextEditingController controller = TextEditingController(
      text: widget.group.group.description ?? '',
    );

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Edit Description'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 200,
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newDescription = controller.text.trim();
                  context.pop();
                  await _updateGroupField(
                    'description',
                    newDescription.isEmpty ? null : newDescription,
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  void _editCurrency(BuildContext context) {
    final currencies = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY', 'CHF', 'CNY'];

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Currency'),
            content: SizedBox(
              width: double.minPositive,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currencies.length,
                itemBuilder: (context, index) {
                  final currency = currencies[index];
                  final isSelected =
                      currency == widget.group.group.defaultCurrency;

                  return ListTile(
                    title: Text(currency),
                    leading: Radio<String>(
                      value: currency,
                      groupValue: widget.group.group.defaultCurrency,
                      onChanged: (value) {
                        context.pop();
                        if (value != null) {
                          _updateGroupField('defaultCurrency', value);
                        }
                      },
                    ),
                    onTap: () {
                      context.pop();
                      _updateGroupField('defaultCurrency', currency);
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
            ],
          ),
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
          backgroundColor: AppTheme.errorColor,
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
                onPressed: () => context.pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  context.pop();

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
                    context.pop(); // Go back to groups list
                  } else if (mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete group: ${provider.error}',
                        ),
                        backgroundColor: AppTheme.errorColor,
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

  Future<void> _updateGroupField(String field, dynamic value) async {
    final provider = context.read<GroupsProvider>();

    try {
      Map<String, dynamic> updateData = {};
      switch (field) {
        case 'name':
          updateData['name'] = value;
          break;
        case 'description':
          updateData['description'] = value;
          break;
        case 'defaultCurrency':
          updateData['defaultCurrency'] = value;
          break;
      }

      await provider.updateGroup(
        groupId: widget.group.group.id!,
        name: updateData['name'],
        description: updateData['description'],
        defaultCurrency: updateData['defaultCurrency'],
      );

      if (provider.hasError) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update: ${provider.error}'),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Group updated successfully'),
              backgroundColor: AppTheme.successColor,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating group: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}
