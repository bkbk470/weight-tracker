import 'package:flutter/material.dart';

class GoalsScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const GoalsScreen({super.key, required this.onNavigate});

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final List<Goal> goals = [
    Goal(
      id: '1',
      title: 'Workout 5 times per week',
      current: 4,
      target: 5,
      unit: 'workouts',
      isCompleted: false,
      category: 'Frequency',
    ),
    Goal(
      id: '2',
      title: 'Bench Press 225 lbs',
      current: 215,
      target: 225,
      unit: 'lbs',
      isCompleted: false,
      category: 'Strength',
    ),
    Goal(
      id: '3',
      title: '30 day workout streak',
      current: 12,
      target: 30,
      unit: 'days',
      isCompleted: false,
      category: 'Consistency',
    ),
    Goal(
      id: '4',
      title: 'Squat 315 lbs',
      current: 315,
      target: 315,
      unit: 'lbs',
      isCompleted: true,
      category: 'Strength',
    ),
  ];

  void showAddGoalDialog() {
    showDialog(
      context: context,
      builder: (context) => const AddGoalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final activeGoals = goals.where((g) => !g.isCompleted).toList();
    final completedGoals = goals.where((g) => g.isCompleted).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('profile'),
        ),
        title: const Text('Goals'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: showAddGoalDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Summary Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _SummaryItem(
                    icon: Icons.flag,
                    label: 'Active',
                    value: activeGoals.length.toString(),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  _SummaryItem(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: completedGoals.length.toString(),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  _SummaryItem(
                    icon: Icons.trending_up,
                    label: 'Progress',
                    value: '${_calculateOverallProgress()}%',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Active Goals
          if (activeGoals.isNotEmpty) ...[
            Text(
              'Active Goals',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...activeGoals.map((goal) => _GoalCard(
                  goal: goal,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  onDelete: () {
                    setState(() => goals.removeWhere((g) => g.id == goal.id));
                  },
                )),
            const SizedBox(height: 32),
          ],

          // Completed Goals
          if (completedGoals.isNotEmpty) ...[
            Text(
              'Completed Goals',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...completedGoals.map((goal) => _GoalCard(
                  goal: goal,
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  onDelete: () {
                    setState(() => goals.removeWhere((g) => g.id == goal.id));
                  },
                )),
          ],

          // Empty State
          if (goals.isEmpty) ...[
            const SizedBox(height: 60),
            Center(
              child: Column(
                children: [
                  Icon(
                    Icons.flag_outlined,
                    size: 80,
                    color: colorScheme.onSurfaceVariant.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No goals yet',
                    style: textTheme.titleLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Set your first goal to get started',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: showAddGoalDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Goal'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: goals.isNotEmpty
          ? FloatingActionButton(
              onPressed: showAddGoalDialog,
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  int _calculateOverallProgress() {
    if (goals.isEmpty) return 0;
    final totalProgress = goals.fold<double>(
      0,
      (sum, goal) => sum + (goal.current / goal.target * 100),
    );
    return (totalProgress / goals.length).round();
  }
}

class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          value,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.colorScheme,
    required this.textTheme,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (goal.current / goal.target).clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goal.isCompleted
                        ? colorScheme.secondaryContainer
                        : colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    goal.isCompleted ? Icons.check_circle : Icons.flag,
                    size: 20,
                    color: goal.isCompleted
                        ? colorScheme.onSecondaryContainer
                        : colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: textTheme.titleMedium,
                      ),
                      Text(
                        goal.category,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${goal.current} / ${goal.target} ${goal.unit}',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: textTheme.bodyMedium?.copyWith(
                    color: goal.isCompleted
                        ? colorScheme.secondary
                        : colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: colorScheme.surfaceVariant,
                color: goal.isCompleted
                    ? colorScheme.secondary
                    : colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AddGoalDialog extends StatefulWidget {
  const AddGoalDialog({super.key});

  @override
  State<AddGoalDialog> createState() => _AddGoalDialogState();
}

class _AddGoalDialogState extends State<AddGoalDialog> {
  final titleController = TextEditingController();
  final targetController = TextEditingController();
  String selectedCategory = 'Strength';
  final categories = ['Strength', 'Frequency', 'Consistency', 'Weight Loss', 'Endurance'];

  @override
  void dispose() {
    titleController.dispose();
    targetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Add New Goal'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                hintText: 'e.g., Bench Press 225 lbs',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: targetController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target Value',
                hintText: 'e.g., 225',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            // Add goal logic here
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Goal added successfully!')),
            );
          },
          child: const Text('Add Goal'),
        ),
      ],
    );
  }
}

class Goal {
  final String id;
  final String title;
  final double current;
  final double target;
  final String unit;
  final bool isCompleted;
  final String category;

  Goal({
    required this.id,
    required this.title,
    required this.current,
    required this.target,
    required this.unit,
    required this.isCompleted,
    required this.category,
  });
}
