import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/groups_provider.dart';
import '../../data/models/models.dart';

class GroupInvitationsBanner extends StatelessWidget {
  const GroupInvitationsBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, child) {
        final pendingInvitations = provider.invitations;

        if (pendingInvitations.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3)
                    : Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow:
                Theme.of(context).brightness == Brightness.dark
                    ? null
                    : [
                      BoxShadow(
                        color: Theme.of(
                          context,
                        ).colorScheme.shadow.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.mail,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${pendingInvitations.length} Group Invitation${pendingInvitations.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed:
                        () =>
                            _showInvitationsDialog(context, pendingInvitations),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('View All'),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Show first invitation as preview
              if (pendingInvitations.isNotEmpty)
                _buildInvitationPreview(context, pendingInvitations.first),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInvitationPreview(
    BuildContext context,
    GroupInvitationModel invitation,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(
              invitation.groupName?.isNotEmpty == true
                  ? invitation.groupName!.substring(0, 1).toUpperCase()
                  : '?',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.groupName ?? 'Unknown Group',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Invited by ${invitation.inviterName ?? 'Unknown'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => _declineInvitation(context, invitation),
                icon: const Icon(Icons.close, size: 20),
                tooltip: 'Decline',
                color: theme.colorScheme.error,
                style: IconButton.styleFrom(minimumSize: const Size(32, 32)),
              ),
              IconButton(
                onPressed: () => _acceptInvitation(context, invitation),
                icon: const Icon(Icons.check, size: 20),
                tooltip: 'Accept',
                color: Theme.of(context).colorScheme.primary,
                style: IconButton.styleFrom(minimumSize: const Size(32, 32)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showInvitationsDialog(
    BuildContext context,
    List<GroupInvitationModel> invitations,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Group Invitations'),
            contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = invitations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor:
                                          Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                      child: Text(
                                        invitation.groupName?.isNotEmpty == true
                                            ? invitation.groupName!
                                                .substring(0, 1)
                                                .toUpperCase()
                                            : '?',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            invitation.groupName ??
                                                'Unknown Group',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            'Invited by ${invitation.inviterName ?? 'Unknown'}',
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                if (invitation.message?.isNotEmpty == true) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(
                                            context,
                                          ).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      invitation.message!,
                                      style:
                                          Theme.of(context).textTheme.bodySmall,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 12),

                                // Expiry date and buttons in separate rows for better layout
                                Text(
                                  'Expires: ${_formatExpiryDate(invitation.expiresAt)}',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.bodySmall?.copyWith(
                                    color:
                                        invitation.isExpired
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.error
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                  ),
                                ),

                                const SizedBox(height: 8),

                                // Buttons row with proper spacing
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _declineInvitation(context, invitation);
                                      },
                                      child: const Text('Decline'),
                                    ),
                                    const SizedBox(width: 8),
                                    FilledButton(
                                      onPressed:
                                          invitation.isExpired
                                              ? null
                                              : () {
                                                Navigator.of(context).pop();
                                                _acceptInvitation(
                                                  context,
                                                  invitation,
                                                );
                                              },
                                      child: const Text('Accept'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Future<void> _acceptInvitation(
    BuildContext context,
    GroupInvitationModel invitation,
  ) async {
    final provider = context.read<GroupsProvider>();

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 16),
                Text('Accepting invitation...'),
              ],
            ),
          ),
    );

    try {
      final success = await provider.acceptInvitation(invitation.id!);

      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully joined ${invitation.groupName}!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to accept invitation: ${provider.error}'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invitation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _declineInvitation(
    BuildContext context,
    GroupInvitationModel invitation,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Decline Invitation'),
            content: Text(
              'Are you sure you want to decline the invitation to join "${invitation.groupName}"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Decline'),
              ),
            ],
          ),
    );

    if (confirmed == true && context.mounted) {
      final provider = context.read<GroupsProvider>();
      final success = await provider.declineInvitation(invitation.id!);

      if (success && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invitation declined')));
      } else if (context.mounted && provider.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline invitation: ${provider.error}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatExpiryDate(DateTime? expiryDate) {
    if (expiryDate == null) return 'Unknown';

    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays != 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours != 1 ? 's' : ''}';
    } else {
      return 'Soon';
    }
  }
}
