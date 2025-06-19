import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/models.dart';
import '../providers/groups_provider.dart';

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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will transfer all admin privileges to the selected member. You will become a regular member.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
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
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.people_outline,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No eligible members',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'There are no active members to transfer admin role to.',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
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

              const SizedBox(height: 12),

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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (eligibleMembers.isNotEmpty)
          Consumer<GroupsProvider>(
            builder: (context, provider, child) {
              return FilledButton(
                onPressed:
                    _selectedMember == null || provider.isUpdating
                        ? null
                        : () => _transferAdmin(context),
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.orange.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.grey[300]!,
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
                color: isSelected ? Colors.orange : Colors.transparent,
                border: Border.all(
                  color: isSelected ? Colors.orange : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
            ),

            const SizedBox(width: 12),

            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blueAccent,
              child: Text(
                (member.userName ?? 'U').substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 12),

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
                      color: isSelected ? Colors.orange[800] : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    member.userEmail ?? 'No email',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Joined ${_formatJoinDate(member.joinedAt)}',
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
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
                style: FilledButton.styleFrom(backgroundColor: Colors.orange),
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
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Admin role transferred to ${_selectedMember!.userName}',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted && provider.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to transfer admin: ${provider.error}'),
          backgroundColor: Colors.red,
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
