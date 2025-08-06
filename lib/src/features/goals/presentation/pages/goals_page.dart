import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_gradient_background.dart';
import '../../../../shared/widgets/main_navigation_wrapper.dart';
import '../../../../shared/widgets/app_settings_menu.dart';
import '../../../../shared/widgets/skeleton_loader.dart';
import '../../../../shared/widgets/error_boundary.dart';
import '../../../../shared/services/haptic_service.dart';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh goals when returning to this page
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
                onPressed: () {
                  HapticService().buttonPress();
                  Navigator.of(context).pop(false);
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  HapticService().heavy();
                  Navigator.of(context).pop(true);
                },
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
          HapticService().success();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Goal deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          HapticService().error();
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
                onPressed: () {
                  HapticService().buttonPress();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  HapticService().buttonPress();
                  final newAmount = double.tryParse(controller.text);
                  if (newAmount != null && newAmount >= 0) {
                    try {
                      await GoalService().setGoalProgress(goal.id!, newAmount);
                      Navigator.of(context).pop();
                      _loadGoals(); // Refresh the list

                      if (mounted) {
                        HapticService().success();
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
                        HapticService().error();
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

    return MainNavigationWrapper(
      currentIndex: 2,
      floatingActionButton: _buildFloatingActionButton(theme),
      floatingActionButtonLocation:
          const CustomCenterFloatingActionButtonLocation(),
      child: AppGradientBackground(
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
      actions: [],
    );
  }

  Widget _buildGoalsList() {
    return FutureBuilder<List<Goal>>(
      future: _goalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonLoader();
        } else if (snapshot.hasError) {
          return ErrorBoundary(
            errorTitle: 'Unable to Load Goals',
            errorMessage:
                'There was a problem loading your goals. Please try again.',
            onRetry: () {
              HapticService().buttonPress();
              _loadGoals();
            },
            child: const SizedBox.shrink(),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color:
                  Theme.of(context).brightness == Brightness.dark
                      ? Theme.of(
                        context,
                      ).colorScheme.surfaceContainer.withValues(alpha: 0.6)
                      : Theme.of(
                        context,
                      ).colorScheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.3),
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
              return withErrorBoundary(
                _buildGoalCard(snapshot.data![index]),
                errorTitle: 'Goal Display Error',
                errorMessage: 'Unable to display this goal.',
                onRetry: _loadGoals,
              );
            },
          );
        }
      },
    );
  }

  Widget _buildSkeletonLoader() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Statistics card skeleton
          if (_statistics == null)
            SkeletonCard(
              height: 160, // Reduced height
              children: [
                SkeletonText(
                  height: 18,
                  width: MediaQuery.of(context).size.width * 0.4,
                ),
                const SizedBox(height: 12),
                const SkeletonText(height: 60, width: double.infinity),
                const SizedBox(height: 12),
                const Row(
                  children: [
                    Expanded(child: SkeletonText(height: 40)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonText(height: 40)),
                  ],
                ),
              ],
            ),
          const SizedBox(height: 16),
          // Goal cards skeleton
          ...List.generate(
            2,
            (index) => // Reduced from 3 to 2
                SkeletonCard(
              height: 140, // Reduced height
              children: [
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: SkeletonText(
                        height: 20,
                        width: MediaQuery.of(context).size.width * 0.5,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 1,
                      child: SkeletonText(
                        height: 16,
                        width: MediaQuery.of(context).size.width * 0.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const SkeletonText(height: 6, width: double.infinity),
                const SizedBox(height: 10),
                const Row(
                  children: [
                    Expanded(child: SkeletonText(height: 14)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonText(height: 14)),
                    SizedBox(width: 12),
                    Expanded(child: SkeletonText(height: 14)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(
            height: AppSpacing.massive,
          ), // Extra space for bottom nav
        ],
      ),
    );
  }

  FloatingActionButton _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton(
      onPressed: () {
        HapticService().buttonPress();
        context.go('/create-goal');
      },
      tooltip: 'Create Goal',
      child: const Icon(Icons.flag),
    );
  }

  Widget _buildStatisticsCard() {
    final theme = Theme.of(context);
    final stats = _statistics!;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainer.withValues(alpha: 0.6)
                : colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Goal Overview',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${stats['totalGoals']} Goals',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Enhanced Progress Overview with visual progress bar
          _buildProgressOverview(stats),

          const SizedBox(height: AppSpacing.lg),

          // Enhanced stat grid with progress indicators
          Row(
            children: [
              Expanded(
                child: _buildEnhancedStatItem(
                  'Completed',
                  stats['completedGoals'].toString(),
                  Icons.check_circle,
                  AppTheme.successColor,
                  stats['totalGoals'] > 0
                      ? stats['completedGoals'] / stats['totalGoals']
                      : 0.0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildEnhancedStatItem(
                  'Active',
                  stats['activeGoals'].toString(),
                  Icons.trending_up,
                  AppTheme.infoColor,
                  stats['totalGoals'] > 0
                      ? stats['activeGoals'] / stats['totalGoals']
                      : 0.0,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          Row(
            children: [
              Expanded(
                child: _buildEnhancedStatItem(
                  'Overdue',
                  stats['overdueGoals'].toString(),
                  Icons.warning,
                  AppTheme.errorColor,
                  stats['totalGoals'] > 0
                      ? stats['overdueGoals'] / stats['totalGoals']
                      : 0.0,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildEnhancedStatItem(
                  'On Track',
                  (stats['activeGoals'] - stats['overdueGoals']).toString(),
                  Icons.schedule,
                  AppTheme.warningColor,
                  stats['totalGoals'] > 0
                      ? (stats['activeGoals'] - stats['overdueGoals']) /
                          stats['totalGoals']
                      : 0.0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressOverview(Map<String, dynamic> stats) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final overallProgress = stats['overallProgress'] as double;
    final totalSavedAmount = stats['totalSavedAmount'] as double;
    final totalTargetAmount = stats['totalTargetAmount'] as double;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.primaryContainer.withValues(alpha: 0.2)
                : colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Overall Progress',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                '${(overallProgress * 100).toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: overallProgress,
              minHeight: 8,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.3,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(
                overallProgress >= 1.0
                    ? AppTheme.successColor
                    : colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Saved: ${CurrencyFormatter.format(totalSavedAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'Target: ${CurrencyFormatter.format(totalTargetAmount)}',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
    double progress,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color:
            theme.brightness == Brightness.dark
                ? colorScheme.surfaceContainerHigh.withValues(alpha: 0.5)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      value,
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 4,
              backgroundColor: colorScheme.outlineVariant.withValues(
                alpha: 0.2,
              ),
              valueColor: AlwaysStoppedAnimation<Color>(color),
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
        color:
            theme.brightness == Brightness.dark
                ? theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.7)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.4,
                ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color:
              goal.isCompleted
                  ? AppTheme.successColor.withValues(alpha: 0.3)
                  : goal.isOverdue
                  ? AppTheme.errorColor.withValues(alpha: 0.3)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
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
                    HapticService().selection();
                    switch (value) {
                      case 'edit':
                        context.push('/create-goal', extra: goal);
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
                              Icon(
                                Icons.delete,
                                size: 18,
                                color: AppTheme.errorColor,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Delete',
                                style: TextStyle(color: AppTheme.errorColor),
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
                                ? AppTheme.successColor
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
                  color: AppTheme.successColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: AppTheme.successColor, size: 16),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Auto-updates from:',
                            style: TextStyle(
                              color: AppTheme.successColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            goal.linkedCategories.join(', '),
                            style: TextStyle(
                              color: AppTheme.successColor,
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
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: AppTheme.warningColor,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'No categories linked - add income to categories to auto-update',
                        style: TextStyle(
                          color: AppTheme.warningColor,
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
