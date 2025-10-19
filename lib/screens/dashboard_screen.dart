import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
  List<Map<String, dynamic>> _folders = [];
  Map<String?, List<Map<String, dynamic>>> _workoutsByFolder = {};
  Map<String, DateTime?> _workoutLastCompletedDates = {}; // Track last completed dates
  List<Map<String, dynamic>> _recentWorkoutLogs = [];
  String? _expandedFolderId;

  @override
  void initState() {
    super.initState();
    _loadFoldersAndWorkouts();
    _loadRecentWorkouts();
  }

  Future<void> _loadFoldersAndWorkouts() async {
    setState(() => _isLoadingWorkouts = true);

    try {
      // Load folders
      final folders = await _supabaseService.getWorkoutFolders();
      
      // Load all workouts
      final allWorkouts = await _supabaseService.getWorkouts();
      
      // Group workouts by folder
      final Map<String?, List<Map<String, dynamic>>> grouped = {};
      grouped[null] = []; // Default "My Workouts" bucket for workouts without a folder
      
      for (var folder in folders) {
        grouped[folder['id'] as String] = [];
      }
      
      for (var workout in allWorkouts) {
        final folderId = workout['plan_id'] as String?;
        if (grouped.containsKey(folderId)) {
          grouped[folderId]!.add(workout);
        } else {
          grouped[null]!.add(workout);
        }
      }

      // Load last completed date for each workout
      final Map<String, DateTime?> lastDates = {};
      for (var workout in allWorkouts) {
        final workoutId = workout['id'] as String;
        final lastDate = await _getLastWorkoutDate(workoutId);
        lastDates[workoutId] = lastDate;
      }

      if (!mounted) return;
      setState(() {
        _folders = folders;
        _workoutsByFolder = grouped;
        _workoutLastCompletedDates = lastDates;
        _isLoadingWorkouts = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _folders = [];
        _workoutsByFolder = {null: []};
        _workoutLastCompletedDates = {};
        _isLoadingWorkouts = false;
      });
      debugPrint('Failed to load folders and workouts: $e');
    }
  }

  /// Get the last completed date for a workout by checking workout_logs
  Future<DateTime?> _getLastWorkoutDate(String workoutId) async {
    try {
      final response = await _supabaseService.client
          .from('workout_logs')
          .select('start_time')
          .eq('workout_id', workoutId)
          .order('start_time', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null && response['start_time'] != null) {
        return DateTime.parse(response['start_time'] as String);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting last workout date: $e');
      return null;
    }
  }

  /// Format the "last completed" text (e.g., "2 days ago at 3:45 PM")
  String _formatLastCompleted(DateTime? date) {
    if (date == null) return 'Never completed';

    final now = DateTime.now();
    final difference = now.difference(date);

    String timeAgo;
    if (difference.inDays == 0) {
      timeAgo = 'Today';
    } else if (difference.inDays == 1) {
      timeAgo = 'Yesterday';
    } else if (difference.inDays < 7) {
      timeAgo = '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      timeAgo = weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      timeAgo = months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      timeAgo = years == 1 ? '1 year ago' : '$years years ago';
    }

    final timeFormat = DateFormat('h:mm a');
    final timeStr = timeFormat.format(date);

    return '$timeAgo at $timeStr';
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

  void _showCreatePlanDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedColor = 'blue';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text('Create Workout Plan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Plan Name',
                    hintText: 'e.g., Strength Training, Cardio Mix',
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Brief description of this plan',
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                const Text('Plan Color'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['blue', 'green', 'orange', 'purple', 'red']
                      .map((color) => ChoiceChip(
                            label: Text(color),
                            selected: selectedColor == color,
                            onSelected: (selected) {
                              if (selected) {
                                setDialogState(() {
                                  selectedColor = color;
                                });
                              }
                            },
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a plan name')),
                  );
                  return;
                }

                try {
                  await _supabaseService.createFolder(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty
                        ? null
                        : descriptionController.text.trim(),
                    color: selectedColor,
                    icon: 'folder',
                  );

                  Navigator.pop(dialogContext);
                  _loadFoldersAndWorkouts();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Workout plan created successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddWorkoutToPlanDialog(String planId, String planName) async {
    // Get all workouts
    final allWorkouts = await _supabaseService.getWorkouts();
    
    // Get workouts already in this plan
    final workoutsInPlan = await _supabaseService.getWorkoutsByFolder(planId);
    final workoutIdsInPlan = workoutsInPlan.map((w) => w['id'] as String).toSet();
    
    // Filter to show only workouts not yet in this plan
    final availableWorkouts = allWorkouts.where((workout) => 
      !workoutIdsInPlan.contains(workout['id'] as String)
    ).toList();

    if (!mounted) return;

    if (availableWorkouts.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Workouts Available'),
          content: const Text(
            'All your workouts are already in this plan, or you don\'t have any workouts yet. Create a new workout to add it.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onNavigate('workout-builder');
              },
              child: const Text('Create Workout'),
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Workout to $planName'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: availableWorkouts.length,
            itemBuilder: (context, index) {
              final workout = availableWorkouts[index];
              final exercises = workout['workout_exercises'] as List? ?? [];
              
              return ListTile(
                leading: Icon(
                  Icons.fitness_center,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(workout['name'] as String),
                subtitle: Text('${exercises.length} exercises'),
                trailing: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () async {
                    try {
                      await _supabaseService.addWorkoutToPlan(
                        workout['id'] as String,
                        planId,
                      );
                      
                      Navigator.pop(context);
                      _loadFoldersAndWorkouts();
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Added "${workout['name']}" to plan'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onNavigate('workout-builder');
            },
            child: const Text('Create New'),
          ),
        ],
      ),
    );
  }

  Color _getColorFromString(String? colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      default:
        return Colors.grey;
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
              // Header with greeting and stats
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        'Good morning, Alex',
                        style: textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Let\'s keep your streak alive!',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: _ActionButton(
                              label: 'Start Workout',
                              icon: Icons.add,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                              onTap: () => widget.onNavigate('workout'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _ActionButton(
                              label: 'Templates',
                              icon: Icons.list_alt,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                              onTap: () => widget.onNavigate('workout', {'selectedTab': 'Templates'}),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Content
              SliverPadding(
                padding: const EdgeInsets.all(24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Workout Plans Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Workout Plans',
                          style: textTheme.titleLarge,
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: _showCreatePlanDialog,
                              icon: const Icon(Icons.create_new_folder, size: 18),
                              label: const Text('New Plan'),
                            ),
                            TextButton.icon(
                              onPressed: () => widget.onNavigate('workout-folders'),
                              icon: const Icon(Icons.folder, size: 18),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildWorkoutsFolders(colorScheme, textTheme),
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

  Widget _buildWorkoutsFolders(ColorScheme colorScheme, TextTheme textTheme) {
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

    final hasAnyWorkouts = _workoutsByFolder.values.any((workouts) => workouts.isNotEmpty);

    if (!hasAnyWorkouts) {
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

    return Column(
      children: [
        // Folders
        ..._folders.map((folder) {
          final folderId = folder['id'] as String;
          final workouts = _workoutsByFolder[folderId] ?? [];
          
          // Show all plans, even if empty
          final isExpanded = _expandedFolderId == folderId;
          final color = _getColorFromString(folder['color'] as String?);

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.folder, color: color, size: 28),
                    title: Text(
                      folder['name'] as String,
                      style: textTheme.titleMedium,
                    ),
                    subtitle: Text('${workouts.length} workout${workouts.length != 1 ? 's' : ''}'),
                    trailing: Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                    ),
                    onTap: () {
                      setState(() {
                        _expandedFolderId = isExpanded ? null : folderId;
                      });
                    },
                  ),
                  if (isExpanded) ...[
                    const Divider(height: 1),
                    if (workouts.isEmpty)
                      Padding(
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
                              'No workouts in this plan yet',
                              style: textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add workouts to get started',
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => _showAddWorkoutToPlanDialog(
                                folderId,
                                folder['name'] as String,
                              ),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Workout'),
                            ),
                          ],
                        ),
                      ),
                    if (workouts.isNotEmpty)
                      ...workouts.take(5).map((workout) {
                      final workoutId = workout['id'] as String;
                      final lastDate = _workoutLastCompletedDates[workoutId];
                      final isLastItem = workouts.take(5).toList().last == workout;
                      
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _MyWorkoutTile(
                            workout: workout,
                            lastCompleted: _formatLastCompleted(lastDate),
                            hasBeenCompleted: lastDate != null,
                            colorScheme: colorScheme,
                            textTheme: textTheme,
                            isInFolder: true,
                            onTap: () => widget.onNavigate('workout-detail', {
                              'workout': workout,
                            }),
                          ),
                          if (!isLastItem)
                            Divider(
                              height: 1,
                              thickness: 1,
                              indent: 56,
                              endIndent: 16,
                              color: colorScheme.outlineVariant.withOpacity(0.5),
                            ),
                        ],
                      );
                    }),
                    if (workouts.length > 5)
                      ListTile(
                        contentPadding: const EdgeInsets.only(left: 72, right: 16),
                        title: Text(
                          '+ ${workouts.length - 5} more',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.primary,
                          ),
                        ),
                        onTap: () => widget.onNavigate('workout-folders'),
                      ),
                  ],
                ],
              ),
            ),
          );
        }),

        // My Workouts default section
        if (_workoutsByFolder[null]?.isNotEmpty ?? false) ...[
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.folder_open, size: 28),
                  title: Text(
                    'My Workouts',
                    style: textTheme.titleMedium,
                  ),
                  subtitle: Text('${_workoutsByFolder[null]!.length} workout${_workoutsByFolder[null]!.length != 1 ? 's' : ''}'),
                  trailing: Icon(
                    _expandedFolderId == null ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () {
                    setState(() {
                      _expandedFolderId = _expandedFolderId == null ? 'expanded' : null;
                    });
                  },
                ),
                if (_expandedFolderId == null) ...[
                  const Divider(height: 1),
                  ..._workoutsByFolder[null]!.take(5).map((workout) {
                    final workoutId = workout['id'] as String;
                    final lastDate = _workoutLastCompletedDates[workoutId];
                    final isLastItem = _workoutsByFolder[null]!.take(5).toList().last == workout;
                    
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _MyWorkoutTile(
                          workout: workout,
                          lastCompleted: _formatLastCompleted(lastDate),
                          hasBeenCompleted: lastDate != null,
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          isInFolder: true,
                          onTap: () => widget.onNavigate('workout-detail', {
                            'workout': workout,
                          }),
                        ),
                        if (!isLastItem)
                          Divider(
                            height: 1,
                            thickness: 1,
                            indent: 56,
                            endIndent: 16,
                            color: colorScheme.outlineVariant.withOpacity(0.5),
                          ),
                      ],
                    );
                  }),
                  if (_workoutsByFolder[null]!.length > 5)
                    ListTile(
                      contentPadding: const EdgeInsets.only(left: 72, right: 16),
                      title: Text(
                        '+ ${_workoutsByFolder[null]!.length - 5} more',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                        ),
                      ),
                      onTap: () => widget.onNavigate('workout-folders'),
                    ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
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

// New Action Button Widget
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: colorScheme.surfaceVariant.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyWorkoutTile extends StatelessWidget {
  final Map<String, dynamic> workout;
  final String lastCompleted;
  final bool hasBeenCompleted;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final bool isInFolder;

  const _MyWorkoutTile({
    required this.workout,
    required this.lastCompleted,
    required this.hasBeenCompleted,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.isInFolder = false,
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

    final subtitleParts = <String>[];
    if (exercises.isNotEmpty) {
      subtitleParts.add('${exercises.length} exercises');
    }
    if (durationMinutes != null && durationMinutes > 0) {
      subtitleParts.add('$durationMinutes min');
    }

    final subtitle = subtitleParts.isNotEmpty ? subtitleParts.join(' • ') : 'Custom workout';

    return ListTile(
      contentPadding: isInFolder
          ? const EdgeInsets.only(left: 16, right: 16, top: 8, bottom: 8)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Icon(
        Icons.fitness_center,
        size: 24,
        color: colorScheme.primary,
      ),
      title: Text(
        (workout['name'] ?? 'Workout') as String,
        style: textTheme.titleSmall,
      ),
      subtitle: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: subtitle,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            TextSpan(
              text: ' • ',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Icon(
                hasBeenCompleted ? Icons.check_circle : Icons.error_outline,
                size: 12,
                color: hasBeenCompleted 
                  ? colorScheme.primary.withOpacity(0.7)
                  : colorScheme.error.withOpacity(0.7),
              ),
            ),
            TextSpan(
              text: ' $lastCompleted',
              style: textTheme.bodySmall?.copyWith(
                color: hasBeenCompleted 
                  ? colorScheme.primary.withOpacity(0.7)
                  : colorScheme.error.withOpacity(0.7),
                fontStyle: FontStyle.italic,
                fontSize: 11,
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right, size: 20),
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
                      Flexible(
                        child: Text(
                          '$date${time.isNotEmpty ? " • $time" : ""}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
