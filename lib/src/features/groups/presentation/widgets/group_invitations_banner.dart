import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../data/models/models.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/app_theme.dart';

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

        final theme = Theme.of(context);

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: AppSpacing.lg),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color:
                theme.brightness == Brightness.dark
                    ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.6)
                    : theme.colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section Header with icon - matching Settings/Info tab style
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(
                            AppSpacing.radiusSm,
                          ),
                        ),
                        child: Icon(
                          Icons.mail_rounded,
                          size: 18,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Group Invitations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed:
                        () =>
                            _showInvitationsDialog(context, pendingInvitations),
                    child: Text(
                      'View All',
                      style: TextStyle(
                        color:
                            theme.brightness == Brightness.dark
                                ? theme.colorScheme.primary
                                : theme.colorScheme.primary.withValues(
                                  alpha: 0.9,
                                ),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Invitation count indicator
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      theme.brightness == Brightness.dark
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  border: Border.all(
                    color:
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.primary.withValues(alpha: 0.3)
                            : theme.colorScheme.primary.withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${pendingInvitations.length} pending invitation${pendingInvitations.length != 1 ? 's' : ''}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color:
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.primary
                            : theme.colorScheme.primary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),

              const SizedBox(height: 16),

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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
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
              width: MediaQuery.of(context).size.width * 0.9,
              height: 400,
              child: Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: invitations.length,
                      itemBuilder: (context, index) {
                        final invitation = invitations[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          elevation: 2,
                          color:
                              Theme.of(context).brightness == Brightness.dark
                                  ? Theme.of(context)
                                      .colorScheme
                                      .surfaceContainer
                                      .withValues(alpha: 0.8)
                                  : Theme.of(
                                    context,
                                  ).colorScheme.surface.withValues(alpha: 0.5),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
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
                                    const SizedBox(width: 16),
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
                                              fontSize: 18,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
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
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color:
                                          Theme.of(context).brightness ==
                                                  Brightness.dark
                                              ? Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHigh
                                                  .withValues(alpha: 0.7)
                                              : Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest
                                                  .withValues(alpha: 0.4),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      invitation.message!,
                                      style:
                                          Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],

                                const SizedBox(height: 16),

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
                                        context.pop();
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
                                                context.pop();
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
                onPressed: () => context.pop(),
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
        context.pop(); // Close loading dialog

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
        context.pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error accepting invitation: $e'),
            backgroundColor: AppTheme.errorColor,
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
            backgroundColor: AppTheme.errorColor,
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
