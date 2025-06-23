import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../widgets/groups_list.dart';
import '../widgets/create_group_fab.dart';
import '../widgets/group_invitations_banner.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
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

    return Scaffold(
      body: AppGradientBackground(
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
                    actions: [
                      IconButton(
                        icon: Icon(
                          Icons.refresh,
                          color:
                              theme.brightness == Brightness.dark
                                  ? theme.colorScheme.onSurface
                                  : Colors.white,
                        ),
                        onPressed: () {
                          final provider = context.read<GroupsProvider>();
                          provider.loadGroups();
                          provider.loadInvitations();
                        },
                      ),
                    ],
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
                                color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                                border: Border.all(
                                  color: theme.colorScheme.error.withValues(alpha: 0.3),
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
                                          color: theme.colorScheme.errorContainer,
                                          borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                                        ),
                                        child: Icon(
                                          Icons.error_outline,
                                          size: 18,
                                          color: theme.colorScheme.onErrorContainer,
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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXl),
            topRight: Radius.circular(AppSpacing.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppSpacing.radiusXl),
            topRight: Radius.circular(AppSpacing.radiusXl),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3,
            selectedItemColor: theme.colorScheme.primary,
            unselectedItemColor: theme.colorScheme.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            elevation: 0,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_rounded),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Transactions',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.flag_rounded),
                label: 'Goals',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.group_rounded),
                label: 'Groups',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.insights_rounded),
                label: 'AI Insights',
              ),
            ],
            onTap: (index) {
              switch (index) {
                case 0:
                  context.go('/dashboard');
                  break;
                case 1:
                  context.go('/transactions');
                  break;
                case 2:
                  context.go('/goals');
                  break;
                case 3:
                  // Already on groups page
                  break;
                case 4:
                  context.go('/ai-insights');
                  break;
              }
            },
          ),
        ),
      ),
      floatingActionButton: const CreateGroupFab(),
      floatingActionButtonLocation:
          const _CustomCenterFloatingActionButtonLocation(),
    );
  }
}

/// Custom FloatingActionButtonLocation that positions the FAB slightly above center docked
class _CustomCenterFloatingActionButtonLocation
    extends FloatingActionButtonLocation {
  const _CustomCenterFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    // Get the center docked position
    final Offset centerDocked = FloatingActionButtonLocation.centerDocked
        .getOffset(scaffoldGeometry);

    // Move it up by 16 pixels to clear the bottom navigation
    return Offset(centerDocked.dx, centerDocked.dy - 16);
  }
}
