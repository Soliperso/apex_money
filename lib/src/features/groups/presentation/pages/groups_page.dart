import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/groups_provider.dart';
import '../widgets/groups_list.dart';
import '../widgets/create_group_fab.dart';
import '../widgets/group_invitations_banner.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Groups',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurface
                    : Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
        foregroundColor:
            Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.white.withValues(alpha: 0.9),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(
                      context,
                    ).colorScheme.surface.withValues(alpha: 0.95)
                    : Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color:
                    Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(
                          context,
                        ).colorScheme.outlineVariant.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
          color:
              Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Colors.white,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = context.read<GroupsProvider>();
              provider.loadGroups();
              provider.loadInvitations();
            },
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.onSurfaceVariant
                    : Colors.white,
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Consumer<GroupsProvider>(
          builder: (context, provider, child) {
            return RefreshIndicator(
              onRefresh: () async {
                await provider.loadGroups();
                await provider.loadInvitations();
              },
              child: Column(
                children: [
                  // Invitations banner
                  const GroupInvitationsBanner(),

                  // Error display
                  if (provider.hasError) ...[
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            Theme.of(context).brightness == Brightness.dark
                                ? Theme.of(context).colorScheme.errorContainer
                                : Theme.of(
                                  context,
                                ).colorScheme.surface.withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.error.withValues(alpha: 0.3),
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
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              provider.error!,
                              style: TextStyle(
                                color:
                                    Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(
                                          context,
                                        ).colorScheme.onErrorContainer
                                        : Theme.of(context).colorScheme.error,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: provider.clearError,
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Groups list
                  const Expanded(child: GroupsList()),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(
                context,
              ).colorScheme.shadow.withValues(alpha: 0.1),
              spreadRadius: 0,
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            currentIndex: 3,
            selectedItemColor: const Color(0xFF64B5F6),
            unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedFontSize: 12,
            unselectedFontSize: 11,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
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
    );
  }
}
