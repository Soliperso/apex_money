import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';

class EditGroupDialog extends StatefulWidget {
  final GroupWithMembersModel group;

  const EditGroupDialog({Key? key, required this.group}) : super(key: key);

  @override
  State<EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<EditGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late String _selectedCurrency;
  late bool _allowMemberInvites;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'INR',
    'BRL',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.group.name);
    _descriptionController = TextEditingController(
      text: widget.group.group.description ?? '',
    );
    _selectedCurrency = widget.group.settings?.defaultCurrency ?? 'USD';
    _allowMemberInvites = widget.group.group.allowMemberInvites;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Text(
        'Edit Group',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: colorScheme.onSurface,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Group Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Group Name',
                    hintText: 'Enter group name',
                    prefixIcon: Icon(Icons.group),
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a group name';
                    }
                    if (value.trim().length < 3) {
                      return 'Group name must be at least 3 characters';
                    }
                    if (value.trim().length > 50) {
                      return 'Group name must be less than 50 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Description
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'What is this group for?',
                    prefixIcon: Icon(Icons.description),
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) {
                    if (value != null && value.trim().length > 200) {
                      return 'Description must be less than 200 characters';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // Currency Selection
                DropdownButtonFormField<String>(
                  value: _selectedCurrency,
                  decoration: const InputDecoration(
                    labelText: 'Default Currency',
                    prefixIcon: Icon(Icons.currency_exchange),
                    border: OutlineInputBorder(),
                  ),
                  items:
                      _currencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency,
                          child: Text(currency),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCurrency = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // Member Invitation Setting
                CheckboxListTile(
                  title: Text(
                    'Allow members to invite others',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                  subtitle: Text(
                    'When disabled, only admins can invite new members',
                    style: TextStyle(color: colorScheme.onSurfaceVariant),
                  ),
                  value: _allowMemberInvites,
                  onChanged: (value) {
                    setState(() {
                      _allowMemberInvites = value ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: colorScheme.primary,
                  checkColor: colorScheme.onPrimary,
                ),

                const SizedBox(height: 16),

                // Info Container
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Changes will be visible to all group members immediately.',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            return FilledButton(
              onPressed:
                  provider.isUpdating ? null : () => _saveChanges(context),
              child:
                  provider.isUpdating
                      ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                      : const Text('Save Changes'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveChanges(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GroupsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // Check if anything has changed
    final hasChanges =
        _nameController.text.trim() != widget.group.group.name ||
        _descriptionController.text.trim() !=
            (widget.group.group.description ?? '') ||
        _selectedCurrency !=
            (widget.group.settings?.defaultCurrency ?? 'USD') ||
        _allowMemberInvites != widget.group.group.allowMemberInvites;

    if (!hasChanges) {
      context.pop();
      return;
    }

    final updatedGroup = await provider.updateGroup(
      groupId: widget.group.group.id!,
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isNotEmpty
              ? _descriptionController.text.trim()
              : null,
      defaultCurrency: _selectedCurrency,
      allowMemberInvites: _allowMemberInvites,
    );

    if (updatedGroup != null && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Group updated successfully'),
          backgroundColor: colorScheme.primary,
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update group: ${provider.error}'),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}

/// Helper function to show the edit group dialog
void showEditGroupDialog(BuildContext context, GroupWithMembersModel group) {
  showDialog(
    context: context,
    builder: (context) => EditGroupDialog(group: group),
  );
}
