import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';

class InviteMemberDialog extends StatefulWidget {
  final GroupWithMembersModel group;

  const InviteMemberDialog({Key? key, required this.group}) : super(key: key);

  @override
  State<InviteMemberDialog> createState() => _InviteMemberDialogState();
}

class _InviteMemberDialogState extends State<InviteMemberDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _messageController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Invite Member',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Info
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blueAccent.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inviting to:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.group.group.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Email Field
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter the email of the person to invite',
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an email address';
                  }

                  // Basic email validation
                  final emailRegex = RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  );
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Please enter a valid email address';
                  }

                  // Check if user is already a member
                  final email = value.trim().toLowerCase();
                  final isAlreadyMember = widget.group.members.any(
                    (member) => member.userEmail?.toLowerCase() == email,
                  );
                  if (isAlreadyMember) {
                    return 'This person is already a member of the group';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Optional Message Field
              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Personal Message (Optional)',
                  hintText: 'Add a personal note to the invitation',
                  prefixIcon: Icon(Icons.message),
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
              ),

              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.orange,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The person will receive an email invitation that expires in 7 days.',
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => context.pop(), child: const Text('Cancel')),
        Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            return FilledButton(
              onPressed:
                  provider.isSendingInvitation
                      ? null
                      : () => _sendInvitation(context),
              child:
                  provider.isSendingInvitation
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('Send Invitation'),
            );
          },
        ),
      ],
    );
  }

  Future<void> _sendInvitation(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<GroupsProvider>();

    final invitation = await provider.sendInvitation(
      groupId: widget.group.group.id!,
      inviteeEmail: _emailController.text.trim(),
      message:
          _messageController.text.trim().isNotEmpty
              ? _messageController.text.trim()
              : null,
    );

    if (invitation != null && mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation sent to ${_emailController.text.trim()}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send invitation: ${provider.error}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// Helper function to show the invite member dialog
void showInviteMemberDialog(BuildContext context, GroupWithMembersModel group) {
  showDialog(
    context: context,
    builder: (context) => InviteMemberDialog(group: group),
  );
}
