import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/theme/app_spacing.dart';
import '../../../../shared/theme/theme_provider.dart';
import '../../../../shared/theme/app_theme.dart';

class GoalsPage extends StatefulWidget {
  const GoalsPage({super.key});

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  late Future<List<Goal>> _goalsFuture;
  Map<String, dynamic>? _statistics;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    setState(() {
      _goalsFuture = GoalService().fetchGoals();
    });

    _goalsFuture.then((goals) {
      _loadStatistics();
    });
  }

  void _loadStatistics() async {
    try {
      final stats = await GoalService().getGoalStatistics();
      setState(() {
        _statistics = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    }
  }

  void _deleteGoal(Goal goal) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Goal'),
            content: Text('Are you sure you want to delete "${goal.name}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await GoalService().deleteGoal(goal.id!);
        _loadGoals(); // Refresh the list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Goal deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete goal: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  void _showUpdateProgressDialog(Goal goal) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Update ${goal.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current: ${CurrencyFormatter.format(goal.currentAmount)}',
                ),
                Text('Target: ${CurrencyFormatter.format(goal.targetAmount)}'),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'New Amount',
                    prefixText: '\$',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newAmount = double.tryParse(controller.text);
                  if (newAmount != null && newAmount >= 0) {
                    try {
                      await GoalService().setGoalProgress(goal.id!, newAmount);
                      Navigator.of(context).pop();
                      _loadGoals(); // Refresh the list

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Goal progress updated!'),
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update progress: $e'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      body: AppGradientBackground(
        child: RefreshIndicator(
          onRefresh: () async {
            _loadGoals();
          },
          child: CustomScrollView(
            slivers: [
              // Modern App Bar
              _buildSliverAppBar(theme, themeProvider),

              // Goals Content
              SliverPadding(
                padding: const EdgeInsets.all(AppSpacing.screenPadding),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Statistics Card
                    if (_statistics != null) _buildStatisticsCard(),

                    const SizedBox(height: AppSpacing.lg),

                    // Goals List
                    _buildGoalsList(),

                    const SizedBox(
                      height: AppSpacing.massive,
                    ), // Extra space for bottom navigation
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),

      // Modern Bottom Navigation
      bottomNavigationBar: _buildBottomNavigation(theme),

      // Modern FAB
      floatingActionButton: _buildFloatingActionButton(theme),
      floatingActionButtonLocation:
          const _CustomCenterFloatingActionButtonLocation(),
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, ThemeProvider themeProvider) {
    final appBarColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.surface
            : theme.colorScheme.primary;

    final titleColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurface
            : Colors.white;

    final iconColor =
        theme.brightness == Brightness.dark
            ? theme.colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9);

    return SliverAppBar(
      floating: false,
      pinned: true,
      expandedHeight: 56,
      backgroundColor: appBarColor,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shadowColor: theme.colorScheme.shadow,
      forceElevated: false,
      systemOverlayStyle:
          theme.brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.light,
      flexibleSpace: Container(decoration: BoxDecoration(color: appBarColor)),
      title: Text(
        'Goals',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: titleColor,
        ),
      ),
      actions: [
        // Theme toggle
        IconButton(
          onPressed: themeProvider.toggleTheme,
          icon: Icon(themeProvider.themeModeIcon),
          tooltip: 'Switch theme',
          color: iconColor,
        ),

        // Refresh
        IconButton(
          onPressed: _loadGoals,
          icon: const Icon(Icons.refresh),
          color: iconColor,
          tooltip: 'Refresh Goals',
        ),
      ],
    );
  }

  Widget _buildGoalsList() {
    return FutureBuilder<List<Goal>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: AppTheme.errorColor),
                const SizedBox(height: 16),
                Text(
                  'Error: ${snapshot.error}',
                  style: TextStyle(color: AppTheme.errorColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadGoals,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                  : Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.flag_outlined,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.4),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No goals yet',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Create your first goal to get started',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          );
        } else {
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildGoalCard(snapshot.data![index]);
            },
          );
        }
      },
    );
  }

  Widget _buildBottomNavigation(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusXl),
          topRight: Radius.circular(AppSpacing.radiusXl),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
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
          currentIndex: 2,
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
                // Already on goals page
                break;
              case 3:
                context.go('/groups');
                break;
              case 4:
                context.go('/ai-insights');
                break;
            }
          },
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () => context.go('/create-goal'),
      tooltip: 'Create Goal',
      child: const Icon(Icons.flag),
    );
  }

  Widget _buildStatisticsCard() {
    final theme = Theme.of(context);
    final stats = _statistics!;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Overview',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Total Goals',
                  stats['totalGoals'].toString(),
                  Icons.flag,
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Completed',
                  stats['completedGoals'].toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Active',
                  stats['activeGoals'].toString(),
                  Icons.trending_up,
                  Colors.orange,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  'Overdue',
                  stats['overdueGoals'].toString(),
                  Icons.warning,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1)
                      : Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Progress',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${(stats['overallProgress'] * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? color.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGoalCard(Goal goal) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color:
              goal.isCompleted
                  ? Colors.green.withValues(alpha: 0.3)
                  : goal.isOverdue
                  ? AppTheme.errorColor.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    goal.name,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: AppSpacing.xs,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: AppTheme.successColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        context.go('/create-goal', extra: goal);
                        break;
                      case 'update':
                        _showUpdateProgressDialog(goal);
                        break;
                      case 'delete':
                        _deleteGoal(goal);
                        break;
                    }
                  },
                  itemBuilder:
                      (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 18),
                              SizedBox(width: 8),
                              Text('Edit Goal'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'update',
                          child: Row(
                            children: [
                              Icon(Icons.trending_up, size: 18),
                              SizedBox(width: 8),
                              Text('Update Progress'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, size: 18, color: Colors.red),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                  child: Icon(
                    Icons.more_vert,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                backgroundColor: theme.colorScheme.outlineVariant.withValues(
                  alpha: 0.3,
                ),
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted
                      ? AppTheme.successColor
                      : goal.isOverdue
                      ? AppTheme.errorColor
                      : theme.colorScheme.primary,
                ),
                minHeight: 8,
              ),
            ),

            const SizedBox(height: 12),

            // Amount Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(goal.currentAmount),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${(goal.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color:
                            goal.isCompleted
                                ? Colors.green
                                : goal.isOverdue
                                ? AppTheme.errorColor
                                : theme.colorScheme.primary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Target',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(goal.targetAmount),
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Deadline Info
            if (goal.deadline != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color:
                      goal.isOverdue
                          ? AppTheme.errorColor.withValues(alpha: 0.1)
                          : theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(
                      goal.isOverdue ? Icons.warning : Icons.schedule,
                      color:
                          goal.isOverdue
                              ? AppTheme.errorColor
                              : theme.colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      goal.isOverdue
                          ? 'Overdue'
                          : '${goal.daysRemaining} days remaining',
                      style: TextStyle(
                        color:
                            goal.isOverdue
                                ? AppTheme.errorColor
                                : theme.colorScheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Category Connection Info
            if (goal.linkedCategories.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.green, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-updates from:',
                            style: TextStyle(
                              color: Colors.green[700]!,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.linkedCategories.join(', '),
                            style: TextStyle(
                              color: Colors.green[600]!,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (goal.autoUpdate) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'No categories linked - add income to categories to auto-update',
                        style: TextStyle(
                          color: Colors.orange[700]!,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
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
