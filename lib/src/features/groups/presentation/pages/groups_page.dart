// GROUPS FUNCTIONALITY COMMENTED OUT - ENTIRE FILE DISABLED
/*
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../widgets/groups_list.dart';
import '../widgets/create_group_fab.dart';
import '../widgets/group_invitations_banner.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/main_navigation_wrapper.dart';
import '../../../../shared/widgets/app_settings_menu.dart';
import '../../../../shared/theme/app_spacing.dart';

class GroupsPage extends StatefulWidget {
  const GroupsPage({Key? key}) : super(key: key);

  @override
  State<GroupsPage> createState() => _GroupsPageState();
}

class _GroupsPageState extends State<GroupsPage> {
  @override
  void initState() {
    super.initState();
    // Load groups and invitations when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroupsProvider>();
      provider.loadGroups();
      provider.loadInvitations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MainNavigationWrapper(
      currentIndex: 3,
      floatingActionButton: const CreateGroupFab(),
      floatingActionButtonLocation:
          const CustomCenterFloatingActionButtonLocation(),
      child: AppGradientBackground(
        child: Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadGroups();
                await provider.loadInvitations();
              },
              child: CustomScrollView(
                slivers: [
                  SliverAppBar(
                    floating: false,
                    pinned: true,
                    expandedHeight: 56,
                    backgroundColor:
                        theme.brightness == Brightness.dark
                            ? theme.colorScheme.surface
                            : theme.colorScheme.primary,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    forceElevated: false,
                    title: Text(
                      'Groups',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            theme.brightness == Brightness.dark
                                ? theme.colorScheme.onSurface
                                : Colors.white,
                      ),
                    ),
                    actions: [],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        children: [
                          // Invitations banner
                          const GroupInvitationsBanner(),

                          // Error display
                          if (provider.hasError) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.errorContainer
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(
                                  AppSpacing.radiusMd,
                                ),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(
                                    alpha: 0.3,
                                  ),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Section Header with icon - matching Settings/Info tab style
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              theme.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 18,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onErrorContainer,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        'Error',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.close),
                                        onPressed: provider.clearError,
                                        color: theme.colorScheme.error,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    provider.error!,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Groups list
                  const SliverFillRemaining(child: GroupsList()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
*/
