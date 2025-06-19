import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/services/goal_service.dart';
import '../../data/models/goal_model.dart';
import '../../../../shared/utils/currency_formatter.dart';
import '../../../../shared/widgets/app_gradient_background.dart';

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
                style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
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
                Text('Current: ${CurrencyFormatter.format(goal.currentAmount)}'),
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to update progress: $e'),
                            backgroundColor: Theme.of(context).colorScheme.error,
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Goals',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurface
                : Colors.white,
          ),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95)
            : Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
        foregroundColor: Theme.of(context).brightness == Brightness.dark
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : Colors.white.withValues(alpha: 0.9),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.surface.withValues(alpha: 0.95)
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.95),
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.2),
                width: 0.5,
              ),
            ),
          ),
        ),
        leading: IconButton(
          onPressed: () => context.go('/dashboard'),
          icon: const Icon(Icons.arrow_back),
          color: Theme.of(context).brightness == Brightness.dark
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : Colors.white,
        ),
        actions: [
          IconButton(
            onPressed: _loadGoals, 
            icon: const Icon(Icons.refresh),
            color: Theme.of(context).brightness == Brightness.dark
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Colors.white,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'test_api') {
                context.go('/goal-api-test');
              } else if (value == 'create_goal') {
                context.go('/create-goal');
              } else if (value == 'debug_sync') {
                context.go('/goal-sync-debug');
              } else if (value == 'quick_diagnostic') {
                context.go('/quick-sync-diagnostic');
              }
            },
            itemBuilder:
                (BuildContext context) => [
                  PopupMenuItem<String>(
                    value: 'create_goal',
                    child: Row(
                      children: [
                        Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('Create Goal'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'quick_diagnostic',
                    child: Row(
                      children: [
                        Icon(Icons.medical_services, color: Theme.of(context).colorScheme.error),
                        const SizedBox(width: 8),
                        const Text('Quick Diagnostic'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'debug_sync',
                    child: Row(
                      children: [
                        Icon(Icons.bug_report, color: Theme.of(context).colorScheme.tertiary),
                        const SizedBox(width: 8),
                        const Text('Debug Sync'),
                      ],
                    ),
                  ),
                  PopupMenuItem<String>(
                    value: 'test_api',
                    child: Row(
                      children: [
                        Icon(Icons.api, color: Theme.of(context).colorScheme.secondary),
                        const SizedBox(width: 8),
                        const Text('Test API'),
                      ],
                    ),
                  ),
                ],
            icon: Icon(
              Icons.more_vert,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : Colors.white,
            ),
          ),
        ],
      ),
      body: AppGradientBackground(
        child: Column(
          children: [
            // Statistics Card
            if (_statistics != null) _buildStatisticsCard(),

            // Goals List
            Expanded(
              child: FutureBuilder<List<Goal>>(
                future: _goalsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: Colors.red.withValues(alpha: 0.6),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading goals',
                            style: TextStyle(
                              color: Colors.red.withValues(alpha: 0.6),
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.outline,
                              fontSize: 14,
                            ),
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
                  }

                  final goals = snapshot.data ?? [];

                  if (goals.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.flag_outlined,
                            color: Theme.of(context).colorScheme.outline,
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Goals Yet',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Create your first financial goal to start saving!\nTap the + button above to get started.',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return _buildGoalCard(goal);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          GoRouter.of(context).go('/create-goal');
        },
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        child: Icon(Icons.flag_outlined, color: Theme.of(context).colorScheme.onPrimary),
        tooltip: 'Create Goal',
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
              color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
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
            currentIndex: 2,
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
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final theme = Theme.of(context);
    final stats = _statistics!;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
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
                  Colors.green,
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
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                  : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Progress',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 14),
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
              color: Theme.of(context).brightness == Brightness.dark
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? theme.colorScheme.surfaceContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              goal.isCompleted
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.green.withValues(alpha: 0.5))
                  : goal.isOverdue
                  ? (Theme.of(context).brightness == Brightness.dark
                      ? Colors.red.withValues(alpha: 0.3)
                      : Colors.red.withValues(alpha: 0.5))
                  : (Theme.of(context).brightness == Brightness.dark
                      ? theme.colorScheme.primary.withValues(alpha: 0.2)
                      : theme.colorScheme.primary.withValues(alpha: 0.4)),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Completed',
                      style: TextStyle(
                        color: Colors.green,
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
                  child: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Progress Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: goal.progressPercentage,
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? Theme.of(context).colorScheme.outline.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  goal.isCompleted
                      ? Colors.green
                      : goal.isOverdue
                      ? Colors.red
                      : Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
                    ),
                    Text(
                      '${(goal.progressPercentage * 100).toStringAsFixed(1)}%',
                      style: TextStyle(
                        color:
                            goal.isCompleted
                                ? Colors.green
                                : goal.isOverdue
                                ? Colors.red
                                : Theme.of(context).colorScheme.primary,
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
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      goal.isOverdue
                          ? (Theme.of(context).brightness == Brightness.dark
                              ? Colors.red.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.2))
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1)
                              : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.6)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      goal.isOverdue ? Icons.warning : Icons.schedule,
                      color: goal.isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      goal.isOverdue
                          ? 'Overdue'
                          : '${goal.daysRemaining} days remaining',
                      style: TextStyle(
                        color: goal.isOverdue ? Colors.red : Theme.of(context).colorScheme.primary,
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.link, color: Colors.green, size: 16),
                    const SizedBox(width: 8),
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
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.orange.withValues(alpha: 0.1)
                      : Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
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
