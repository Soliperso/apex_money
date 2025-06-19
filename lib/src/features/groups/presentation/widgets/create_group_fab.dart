import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';

class CreateGroupFab extends StatelessWidget {
  const CreateGroupFab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, child) {
        return FloatingActionButton(
          onPressed:
              provider.isCreating
                  ? null
                  : () => _showCreateGroupDialog(context),
          backgroundColor:
              provider.isCreating
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)
                  : Theme.of(context).colorScheme.primary,
          shape: const CircleBorder(),
          tooltip:
              provider.isCreating ? 'Creating Group...' : 'Create a new group',
          child:
              provider.isCreating
                  ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.onPrimary,
                      ),
                    ),
                  )
                  : Icon(
                    Icons.group_add,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }
}

class CreateGroupDialog extends StatefulWidget {
  const CreateGroupDialog({Key? key}) : super(key: key);

  @override
  State<CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<CreateGroupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedCurrency = 'USD';
  bool _allowMemberInvites = true;

  final List<String> _currencies = [
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'CAD',
    'AUD',
    'CHF',
    'CNY',
    'SEK',
    'NZD',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Create New Group',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Group Name *',
                  hintText: 'e.g., Family Expenses, Trip to Paris',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.group),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a group name';
                  }
                  if (value.trim().length < 2) {
                    return 'Group name must be at least 2 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'What is this group for?',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),

              const SizedBox(height: 16),

              // Currency selection
              DropdownButtonFormField<String>(
                value: _selectedCurrency,
                decoration: const InputDecoration(
                  labelText: 'Default Currency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_exchange),
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

              // Member invitation setting
              CheckboxListTile(
                title: const Text('Allow members to invite others'),
                subtitle: const Text(
                  'When disabled, only admins can invite new members',
                ),
                value: _allowMemberInvites,
                onChanged: (value) {
                  setState(() {
                    _allowMemberInvites = value ?? true;
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            return FilledButton(
              onPressed: provider.isCreating ? null : _createGroup,
              child:
                  provider.isCreating
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                      : const Text('Create Group'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GroupsProvider>();

    final group = await provider.createGroup(
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
      defaultCurrency: _selectedCurrency,
      allowMemberInvites: _allowMemberInvites,
    );

    if (group != null && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Group "${group.group.name}" created successfully!'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          action: SnackBarAction(
            label: 'View',
            onPressed: () {
              context.push('/groups/${group.group.id}');
            },
          ),
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create group: ${provider.error}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
