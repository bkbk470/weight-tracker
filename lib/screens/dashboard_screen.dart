import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DashboardScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) onNavigate;
  final bool hasActiveWorkout;
  final int activeWorkoutTime;

  const DashboardScreen({
    super.key,
    required this.onNavigate,
    this.hasActiveWorkout = false,
    this.activeWorkoutTime = 0,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final SupabaseService _supabaseService = SupabaseService.instance;
  bool _isLoadingWorkouts = true;
  bool _isLoadingRecentWorkouts = true;
  List<Map<String, dynamic>> _myWorkouts = [];
  List<Map<String, dynamic>> _recentWorkoutLogs = [];

  @override
  void initState() {
    super.initState();
    _loadWorkouts();
    _loadRecentWorkouts();
  }

  Future<void> _loadWorkouts() async {
    try {
      final workouts = await _supabaseService.getWorkouts();
      if (!mounted) return;
      setState(() {
        _myWorkouts = workouts;
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _myWorkouts = [];
        _isLoadingWorkouts = false;
      });
      debugPrint('Failed to load workouts: $e');
    }
  }

  Future<void> _loadRecentWorkouts() async {
    try {
      final logs = await _supabaseService.getWorkoutLogs(limit: 3);
      if (!mounted) return;
      setState(() {
        _recentWorkoutLogs = logs;
        _isLoadingRecentWorkouts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recentWorkoutLogs = [];
        _isLoadingRecentWorkouts = false;
      });
      debugPrint('Failed to load recent workouts: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Stack(
        children: [
          // Background gradients
          Positioned(
            top: MediaQuery.of(context).size.height / 4,
            right: -80,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 3,
            left: -100,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Header
              SliverAppBar(
                expandedHeight: 200,
                pinned: false,
                backgroundColor: colorScheme.surfaceVariant.withOpacity(0.5),
                flexibleSpace: FlexibleSpaceBar(
                  background: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Good morning!',
                                      style: textTheme.headlineSmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Ready to crush your workout?',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: colorScheme.secondaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.local_fire_department,
                                  color: colorScheme.secondary,
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.primaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'This Week',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '4',
                                            style: textTheme.headlineMedium?.copyWith(
                                              color: colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.fitness_center,
                                        color: colorScheme.primary.withOpacity(0.3),
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: colorScheme.secondaryContainer.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Day Streak',
                                            style: textTheme.labelSmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '12',
                                            style: textTheme.headlineMedium?.copyWith(
                                              color: colorScheme.secondary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Icon(
                                        Icons.local_fire_department,
                                        color: colorScheme.secondary.withOpacity(0.3),
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Quick Actions
                    Text(
                      'Quick Actions',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.add,
                            label: 'Start Workout',
                            colorScheme: colorScheme,
                            onTap: () => widget.onNavigate('workout'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.trending_up,
                            label: 'View Progress',
                            colorScheme: colorScheme,
                            onTap: () => widget.onNavigate('progress'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // My Workouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Workouts',
                          style: textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate('workout-builder'),
                          child: const Text('Create New'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildMyWorkoutsCard(colorScheme, textTheme),
                    const SizedBox(height: 32),

                    // Workout Examples
                    Text(
                      'Workout Examples',
                      style: textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: const Text('Full Body'),
                            subtitle: const Text('8 exercises • 60 min • Intermediate'),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => widget.onNavigate('workout-detail'),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: const Text('Upper Body'),
                            subtitle: const Text('6 exercises • 45 min • Beginner'),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => widget.onNavigate('workout-detail'),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: const Text('Lower Body'),
                            subtitle: const Text('7 exercises • 50 min • Advanced'),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => widget.onNavigate('workout-detail'),
                            ),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: colorScheme.secondaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.fitness_center,
                                size: 20,
                                color: colorScheme.onSecondaryContainer,
                              ),
                            ),
                            title: const Text('Core Focus'),
                            subtitle: const Text('5 exercises • 30 min • Beginner'),
                            trailing: IconButton(
                              icon: const Icon(Icons.chevron_right),
                              onPressed: () => widget.onNavigate('workout-detail'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Recent Workouts
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent Workouts',
                          style: textTheme.titleLarge,
                        ),
                        TextButton(
                          onPressed: () => widget.onNavigate('workout-history'),
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentWorkoutsSection(colorScheme, textTheme),
                    const SizedBox(height: 32),

                    // Start Workout CTA
                    FilledButton.icon(
                      onPressed: () => widget.onNavigate('active-workout-start'),
                      icon: const Icon(Icons.add),
                      label: const Text('Start New Workout'),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildMyWorkoutsCard(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingWorkouts) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Text(
                'Loading your workouts...',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    if (_myWorkouts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'No workouts yet',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Build your first custom workout to see it here.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () => widget.onNavigate('workout-builder'),
                icon: const Icon(Icons.add),
                label: const Text('Create Workout'),
              ),
            ],
          ),
        ),
      );
    }

    final workoutsToShow = _myWorkouts.take(7).toList();

    return Card(
      child: Column(
        children: [
          for (var i = 0; i < workoutsToShow.length; i++) ...[
            _MyWorkoutTile(
              workout: workoutsToShow[i],
              colorScheme: colorScheme,
              textTheme: textTheme,
              onTap: () => widget.onNavigate('workout-detail', {
                'workout': workoutsToShow[i],
              }),
            ),
            if (i < workoutsToShow.length - 1) const Divider(height: 1),
          ],
          if (_myWorkouts.length > workoutsToShow.length) const Divider(height: 1),
          if (_myWorkouts.length > workoutsToShow.length)
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('View all workouts'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => widget.onNavigate('workout'),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return 'N/A';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  String _formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    }
  }

  String _formatTime24Hour(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildRecentWorkoutsSection(ColorScheme colorScheme, TextTheme textTheme) {
    if (_isLoadingRecentWorkouts) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: CircularProgressIndicator(color: colorScheme.primary),
          ),
        ),
      );
    }

    if (_recentWorkoutLogs.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No workouts yet',
                style: textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Start your first workout to see it here',
                style: textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: _recentWorkoutLogs.map((log) {
        final startTimeStr = log['start_time'] as String?;
        final durationSeconds = log['duration_seconds'] as int?;
        final sets = log['exercise_sets'] as List?;
        final workoutName = log['workout_name'] as String? ?? 'Workout';

        DateTime? startTime;
        if (startTimeStr != null) {
          startTime = DateTime.tryParse(startTimeStr);
        }

        final relativeDate = startTime != null ? _formatRelativeDate(startTime) : 'Unknown';
        final timeOfDay = startTime != null ? _formatTime24Hour(startTime) : '';
        final duration = _formatDuration(durationSeconds);
        final exerciseCount = sets?.length ?? 0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _WorkoutCard(
            name: workoutName,
            date: relativeDate,
            time: timeOfDay,
            duration: duration,
            exercises: exerciseCount,
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
        );
      }).toList(),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MyWorkoutTile extends StatelessWidget {
  final Map<String, dynamic> workout;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _MyWorkoutTile({
    required this.workout,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> exercises = workout['workout_exercises'] as List<dynamic>? ?? [];
    final durationValue = workout['estimated_duration_minutes'];
    final int? durationMinutes = durationValue is int
        ? durationValue
        : durationValue is double
            ? durationValue.round()
            : int.tryParse('$durationValue');
    final difficulty = workout['difficulty'] as String?;

    DateTime? updatedAt;
    final rawUpdatedAt = workout['updated_at'] ?? workout['created_at'];
    if (rawUpdatedAt is String) {
      updatedAt = DateTime.tryParse(rawUpdatedAt);
    }

    String? relativeText;
    if (updatedAt != null) {
      final now = DateTime.now();
      final difference = now.difference(updatedAt);
      final int days = difference.inDays;
      if (days <= 0) {
        relativeText = 'Today';
      } else if (days == 1) {
        relativeText = '1 day ago';
      } else if (days < 7) {
        relativeText = '$days days ago';
      } else {
        final weeks = (days / 7).floor();
        relativeText = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
      }
    }

    final subtitleParts = <String>[];
    if (exercises.isNotEmpty) {
      subtitleParts.add('${exercises.length} exercises');
    }
    if (durationMinutes != null && durationMinutes > 0) {
      subtitleParts.add('$durationMinutes min');
    }
    if (relativeText != null && relativeText.isNotEmpty) {
      subtitleParts.add(relativeText);
    } else if (difficulty != null && difficulty.isNotEmpty) {
      subtitleParts.add(difficulty);
    }

    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : 'Custom workout';

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.fitness_center,
          size: 20,
          color: colorScheme.onPrimaryContainer,
        ),
      ),
      title: Text(
        (workout['name'] ?? 'Workout') as String,
        style: textTheme.titleMedium,
      ),
      subtitle: Text(
        subtitle,
        style: textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.chevron_right),
        onPressed: onTap,
      ),
      onTap: onTap,
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String date;
  final String time;
  final String duration;
  final int exercises;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _WorkoutCard({
    required this.name,
    required this.date,
    required this.time,
    required this.duration,
    required this.exercises,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 16,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        duration,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$date${time.isNotEmpty ? " • $time" : ""}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$exercises sets',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
