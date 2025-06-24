import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../../data/models/models.dart';
import '../widgets/group_detail_info.dart';
import '../widgets/group_members_list.dart';
import '../widgets/group_settings_panel.dart';
import '../widgets/group_bills_tab.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../widgets/invite_member_dialog.dart';
import '../widgets/edit_group_dialog.dart';
import '../widgets/group_bills_tab.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

class GroupDetailPage extends StatefulWidget {
  final String groupId;

  const GroupDetailPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  GroupWithMembersModel? _group;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadGroup();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadGroup() async {
    setState(() => _isLoading = true);

    final provider = context.read<GroupsProvider>();
    _group = provider.getGroupById(widget.groupId);

    // If group not found in provider, try loading all groups
    if (_group == null) {
      await provider.loadGroups();
      _group = provider.getGroupById(widget.groupId);
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    if (_isLoading) {
      return Scaffold(
        body: AppGradientBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                expandedHeight: 56,
                backgroundColor:
                    isDark ? colorScheme.surface : colorScheme.primary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                forceElevated: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Breadcrumb navigation
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: isDark 
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? colorScheme.onSurface.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isDark 
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    // Loading text
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              ),
            ],
          ),
        ),
      );
    }

    if (_group == null) {
      return Scaffold(
        body: AppGradientBackground(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                floating: false,
                pinned: true,
                expandedHeight: 56,
                backgroundColor:
                    isDark ? colorScheme.surface : colorScheme.primary,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                forceElevated: false,
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Breadcrumb navigation
                    Row(
                      children: [
                        Icon(
                          Icons.group,
                          size: 16,
                          color: isDark 
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Groups',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark 
                                ? colorScheme.onSurface.withValues(alpha: 0.7)
                                : Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                        Icon(
                          Icons.chevron_right,
                          size: 16,
                          color: isDark 
                              ? colorScheme.onSurface.withValues(alpha: 0.7)
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ),
                    // Error text
                    Text(
                      'Group Not Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Group not found',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This group may have been deleted or you may not have access to it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isAdmin = _group!.isUserAdmin(
      context.read<GroupsProvider>().getCurrentUserId(),
    );

    return Scaffold(
      body: AppGradientBackground(
        child: Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            // Update group data from provider
            final updatedGroup = provider.getGroupById(widget.groupId);
            if (updatedGroup != null) {
              _group = updatedGroup;
            }

            return NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    expandedHeight: 56,
                    backgroundColor:
                        isDark ? colorScheme.surface : colorScheme.primary,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    forceElevated: false,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? colorScheme.onSurface : Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to Groups',
                    ),
                    title: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Breadcrumb navigation
                        Row(
                          children: [
                            Icon(
                              Icons.group,
                              size: 16,
                              color: isDark 
                                  ? colorScheme.onSurface.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Groups',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark 
                                    ? colorScheme.onSurface.withValues(alpha: 0.7)
                                    : Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              size: 16,
                              color: isDark 
                                  ? colorScheme.onSurface.withValues(alpha: 0.7)
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ),
                        // Group name
                        Text(
                          _group!.group.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                      ],
                    ),
                    centerTitle: false,
                    actions: [
                      // More options menu
                      PopupMenuButton<String>(
                        onSelected: (value) => _handleMenuAction(value),
                        icon: Icon(
                          Icons.more_vert,
                          color: isDark ? colorScheme.onSurface : Colors.white,
                        ),
                        itemBuilder:
                            (context) => [
                              if (isAdmin) ...[
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit, size: 20),
                                      SizedBox(width: 12),
                                      Text('Edit Group'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'invite',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_add, size: 20),
                                      SizedBox(width: 12),
                                      Text('Invite Members'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete,
                                        size: 20,
                                        color: colorScheme.error,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Delete Group',
                                        style: TextStyle(
                                          color: colorScheme.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ] else ...[
                                PopupMenuItem(
                                  value: 'leave',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.exit_to_app,
                                        size: 20,
                                        color: colorScheme.tertiary,
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Leave Group',
                                        style: TextStyle(
                                          color: colorScheme.tertiary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                      ),
                    ],
                    bottom: TabBar(
                      controller: _tabController,
                      indicatorColor: colorScheme.primary,
                      labelColor: isDark ? colorScheme.onSurface : Colors.white,
                      unselectedLabelColor:
                          isDark
                              ? colorScheme.onSurfaceVariant
                              : Colors.white.withValues(alpha: 0.7),
                      tabs: [
                        Tab(
                          text: 'Info',
                          icon: Icon(
                            Icons.info_outline,
                            color:
                                isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        Tab(
                          text: 'Members',
                          icon: Icon(
                            Icons.people,
                            color:
                                isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        Tab(
                          text: 'Bills',
                          icon: Icon(
                            Icons.receipt_long,
                            color:
                                isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                        Tab(
                          text: 'Settings',
                          icon: Icon(
                            Icons.settings,
                            color:
                                isDark ? colorScheme.onSurface : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Info Tab
                  GroupDetailInfo(group: _group!),

                  // Members Tab
                  GroupMembersList(group: _group!),

                  // Bills Tab
                  GroupBillsTab(group: _group!),

                  // Settings Tab
                  GroupSettingsPanel(group: _group!),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'edit':
        _showEditGroupDialog();
        break;
      case 'invite':
        _showInviteMemberDialog();
        break;
      case 'delete':
        _showDeleteConfirmation();
        break;
      case 'leave':
        _showLeaveConfirmation();
        break;
    }
  }

  void _showEditGroupDialog() {
    showEditGroupDialog(context, _group!);
  }

  void _showInviteMemberDialog() {
    showInviteMemberDialog(context, _group!);
  }

  void _showDeleteConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Group'),
            content: Text(
              'Are you sure you want to delete "${_group!.group.name}"? This action cannot be undone.',
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
                  final success = await provider.deleteGroup(_group!.group.id!);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Group deleted successfully'),
                      ),
                    );
                    context.pop(); // Navigate back to groups page
                  } else if (mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to delete group: ${provider.error}',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Leave Group'),
            content: Text(
              'Are you sure you want to leave "${_group!.group.name}"?',
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
                  final success = await provider.leaveGroup(_group!.group.id!);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Left group successfully')),
                    );
                    context.pop(); // Navigate back to groups page
                  } else if (mounted && provider.hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to leave group: ${provider.error}',
                        ),
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
                child: const Text('Leave'),
              ),
            ],
          ),
    );
  }
}
