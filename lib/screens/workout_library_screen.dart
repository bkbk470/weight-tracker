import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

/// Curated developer-managed workout templates available to every user.
const List<Map<String, dynamic>> _curatedTemplateWorkouts = [
  {
    'id': 'tmpl_full_body_foundations',
    'name': 'Full Body Foundations',
    'description': 'Balanced beginner friendly session touching every major muscle group.',
    'difficulty': 'Beginner',
    'estimated_duration_minutes': 40,
    'workout_template_exercises': [
      {
        'exercise_name': 'Goblet Squat',
        'target_sets': 3,
        'target_reps': 12,
        'rest_time_seconds': 75,
        'notes': 'Keep chest tall and pause for a beat at the bottom.',
        'category': 'Legs',
      },
      {
        'exercise_name': 'Push-Up',
        'target_sets': 3,
        'target_reps': 10,
        'rest_time_seconds': 60,
        'notes': 'Use an incline if you cannot complete quality reps.',
        'category': 'Chest',
      },
      {
        'exercise_name': 'Dumbbell Row',
        'target_sets': 3,
        'target_reps': 12,
        'rest_time_seconds': 75,
        'notes': 'Drive elbow toward hip and squeeze at the top.',
        'category': 'Back',
      },
      {
        'exercise_name': 'Plank',
        'target_sets': 3,
        'target_reps': 45,
        'rest_time_seconds': 45,
        'notes': 'Hold for 45 seconds, maintain straight line from head to heel.',
        'category': 'Core',
      },
    ],
  },
  {
    'id': 'tmpl_push_power_45',
    'name': 'Push Power 45',
    'description': 'Upper-body push day built around heavy presses and triceps finishers.',
    'difficulty': 'Intermediate',
    'estimated_duration_minutes': 45,
    'workout_template_exercises': [
      {
        'exercise_name': 'Barbell Bench Press',
        'target_sets': 4,
        'target_reps': 8,
        'rest_time_seconds': 120,
        'notes': 'Two second lowering phase, explode up.',
        'category': 'Chest',
      },
      {
        'exercise_name': 'Standing Overhead Press',
        'target_sets': 3,
        'target_reps': 10,
        'rest_time_seconds': 105,
        'notes': 'Brace glutes to protect lower back.',
        'category': 'Shoulders',
      },
      {
        'exercise_name': 'Incline Dumbbell Press',
        'target_sets': 3,
        'target_reps': 12,
        'rest_time_seconds': 90,
        'notes': 'Stop two reps shy of failure each set.',
        'category': 'Chest',
      },
      {
        'exercise_name': 'Cable Tricep Pressdown',
        'target_sets': 3,
        'target_reps': 15,
        'rest_time_seconds': 60,
        'notes': 'Keep elbows pinned to sides and squeeze at lockout.',
        'category': 'Arms',
      },
    ],
  },
  {
    'id': 'tmpl_lower_body_strength',
    'name': 'Lower Body Strength',
    'description': 'Strength focused lower day with posterior chain attention.',
    'difficulty': 'Advanced',
    'estimated_duration_minutes': 55,
    'workout_template_exercises': [
      {
        'exercise_name': 'Back Squat',
        'target_sets': 5,
        'target_reps': 5,
        'rest_time_seconds': 150,
        'notes': 'Work up to a challenging five with perfect depth.',
        'category': 'Legs',
      },
      {
        'exercise_name': 'Romanian Deadlift',
        'target_sets': 4,
        'target_reps': 8,
        'rest_time_seconds': 120,
        'notes': 'Keep slight knee bend and feel hamstring stretch.',
        'category': 'Posterior Chain',
      },
      {
        'exercise_name': 'Walking Lunge',
        'target_sets': 3,
        'target_reps': 12,
        'rest_time_seconds': 90,
        'notes': '12 steps per leg, hold dumbbells for load.',
        'category': 'Legs',
      },
      {
        'exercise_name': 'Leg Press',
        'target_sets': 3,
        'target_reps': 15,
        'rest_time_seconds': 75,
        'notes': 'Controlled tempo, do not lock knees.',
        'category': 'Legs',
      },
      {
        'exercise_name': 'Hanging Knee Raise',
        'target_sets': 3,
        'target_reps': 12,
        'rest_time_seconds': 60,
        'notes': 'Pause at the top to engage core.',
        'category': 'Core',
      },
    ],
  },
];

class WorkoutLibraryScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) onNavigate;
  final String? initialTab;

  const WorkoutLibraryScreen({
    super.key,
    required this.onNavigate,
    this.initialTab,
  });

  @override
  State<WorkoutLibraryScreen> createState() => _WorkoutLibraryScreenState();
}

class _WorkoutLibraryScreenState extends State<WorkoutLibraryScreen> {
  String selectedTab = 'My Workouts';
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  List<Map<String, dynamic>> myWorkouts = [];
  List<Map<String, dynamic>> workoutTemplates = [];
  bool isLoading = true;
  bool isLoadingTemplates = false;

  @override
  void initState() {
    super.initState();
    // Set initial tab if provided
    if (widget.initialTab != null) {
      selectedTab = widget.initialTab!;
      // Load templates if starting on Templates tab
      if (selectedTab == 'Templates') {
        _loadTemplates();
      }
    }
    _loadWorkouts();
  }

  Future<void> _loadWorkouts() async {
    setState(() => isLoading = true);
    
    try {
      final workouts = await SupabaseService.instance.getWorkouts();
      setState(() {
        myWorkouts = workouts;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading workouts: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _loadTemplates() async {
    if (workoutTemplates.isNotEmpty) return; // Already loaded

    setState(() => isLoadingTemplates = true);

    await Future<void>.delayed(const Duration(milliseconds: 150));

    setState(() {
      workoutTemplates = _curatedTemplateWorkouts.map((template) {
        final templateCopy = Map<String, dynamic>.from(template);
        final exercises =
            List<Map<String, dynamic>>.from(template['workout_template_exercises'] as List);
        templateCopy['workout_template_exercises'] =
            exercises.map((exercise) => Map<String, dynamic>.from(exercise)).toList();
        return templateCopy;
      }).toList();
      isLoadingTemplates = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final Widget contentSliver = _buildSelectedContent(colorScheme, textTheme);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Workouts',
                            style: textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => widget.onNavigate('workout-builder'),
                          icon: const Icon(Icons.add),
                          label: const Text('New Workout'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Browse your workouts, templates, and organize them into folders.',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value;
                    });
                  },
                  decoration: InputDecoration(
                    hintText: 'Search workouts...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                  ),
                ),
              ),
            ),

            // Tab Selection
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'My Workouts',
                            label: Text('My Workouts'),
                            icon: Icon(Icons.bookmark),
                          ),
                          ButtonSegment(
                            value: 'Templates',
                            label: Text('Templates'),
                            icon: Icon(Icons.library_books),
                          ),
                        ],
                        selected: {selectedTab},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            selectedTab = newSelection.first;
                          });
                          // Load templates when Templates tab is selected
                          if (selectedTab == 'Templates') {
                            _loadTemplates();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content based on selected tab
            contentSliver,
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedContent(ColorScheme colorScheme, TextTheme textTheme) {
    if (selectedTab == 'My Workouts') {
      if (isLoading) {
        return const SliverFillRemaining(
          child: Center(child: CircularProgressIndicator()),
        );
      }

      if (myWorkouts.isEmpty) {
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.fitness_center_outlined,
                  size: 80,
                  color: colorScheme.primary.withOpacity(0.3),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Workouts Yet',
                  style: textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first workout template!',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
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

      return _buildNormalWorkoutList(colorScheme, textTheme);
    }

    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: isLoadingTemplates
          ? const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          : workoutTemplates.isEmpty
              ? SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.library_books_outlined,
                          size: 80,
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No Templates Available',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check back later for workout templates',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildListDelegate([
                    Text(
                      'Workout Templates',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...workoutTemplates.map((template) {
                      final exercises = template['workout_template_exercises'] as List? ?? [];
                      return _WorkoutCard(
                        name: template['name'] ?? 'Unnamed Template',
                        description: template['description'] ?? 'No description',
                        exercises: exercises.length,
                        duration: '${template['estimated_duration_minutes'] ?? 45} min',
                        difficulty: template['difficulty'] ?? 'Intermediate',
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        onTap: () => widget.onNavigate(
                          'workout-detail',
                          {
                            'workout': template,
                          },
                        ),
                        onDuplicate: () async {
                          try {
                            final templateName = template['name'] as String? ?? 'Workout Template';
                            final description = template['description'] as String?;
                            final difficulty = template['difficulty'] as String?;
                            final durationMinutes =
                                template['estimated_duration_minutes'] as int?;
                            final exercises = (template['workout_template_exercises'] as List)
                                .whereType<Map<String, dynamic>>()
                                .toList();

                            final newWorkout = await SupabaseService.instance.createWorkout(
                              name: 'Copy of $templateName',
                              description: description,
                              difficulty: difficulty,
                              estimatedDurationMinutes: durationMinutes,
                            );

                            for (var i = 0; i < exercises.length; i++) {
                              final exercise = exercises[i];
                              final exerciseName =
                                  (exercise['exercise_name'] as String?) ?? 'Exercise';
                              final rawNotes = (exercise['notes'] as String?)?.trim();
                              final exerciseNotes = (rawNotes == null || rawNotes.isEmpty) ? null : rawNotes;
                              final category = (exercise['category'] as String?)?.trim();
                              try {
                                final exerciseId = await SupabaseService.instance.getOrCreateExerciseId(
                                  name: exerciseName,
                                  category: category == null || category.isEmpty ? 'Other' : category,
                                  notes: exerciseNotes,
                                );

                                if (exerciseId == null) continue;

                                await SupabaseService.instance.addExerciseToWorkout(
                                  workoutId: newWorkout['id'] as String,
                                  exerciseId: exerciseId,
                                  orderIndex: i,
                                  targetSets: exercise['target_sets'] as int? ?? 3,
                                  targetReps: exercise['target_reps'] as int? ?? 10,
                                  restTimeSeconds: exercise['rest_time_seconds'] as int? ?? 90,
                                  notes: exerciseNotes,
                                );
                              } catch (exerciseError) {
                                print('Failed to add exercise $exerciseName: $exerciseError');
                              }
                            }

                            await _loadWorkouts();

                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Workout "$templateName" added to My Workouts'),
                                  backgroundColor: Colors.green,
                                  action: SnackBarAction(
                                    label: 'View',
                                    textColor: Colors.white,
                                    onPressed: () {
                                      setState(() {
                                        selectedTab = 'My Workouts';
                                      });
                                    },
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error adding workout: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    }).toList(),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: () => widget.onNavigate('workout-builder'),
                      icon: const Icon(Icons.add),
                      label: const Text('Create New Workout'),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () => widget.onNavigate('active-workout-start'),
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Empty Workout'),
                    ),
                  ]),
                ),
    );
  }

  Widget _buildNormalWorkoutList(ColorScheme colorScheme, TextTheme textTheme) {
    return SliverPadding(
      padding: const EdgeInsets.all(16),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          Text(
            'Your Custom Workouts',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...myWorkouts.map((workout) {
            final exercises = workout['workout_exercises'] as List? ?? [];
            return _WorkoutCard(
              name: workout['name'] ?? 'Unnamed Workout',
              description: workout['description'] ?? 'No description',
              exercises: exercises.length,
              duration: '${workout['estimated_duration_minutes'] ?? 45} min',
              difficulty: workout['difficulty'] ?? 'Intermediate',
              colorScheme: colorScheme,
              textTheme: textTheme,
              onTap: () => widget.onNavigate(
                'workout-detail',
                {
                  'workout': workout,
                },
              ),
              onDuplicate: () async {
                try {
                  // Create duplicate workout
                  final originalName = workout['name'] as String? ?? 'Workout';
                  final newWorkout = await SupabaseService.instance.createWorkout(
                    name: 'Copy of $originalName',
                    description: workout['description'] as String?,
                    difficulty: workout['difficulty'] as String?,
                    estimatedDurationMinutes: workout['estimated_duration_minutes'] as int?,
                  );

                  // Duplicate all exercises
                  for (var i = 0; i < exercises.length; i++) {
                    final exercise = exercises[i] as Map<String, dynamic>;
                    final exerciseData = exercise['exercise'] as Map<String, dynamic>?;
                    final exerciseId = exercise['exercise_id'] as String? ?? exerciseData?['id'] as String?;
                    
                    if (exerciseId != null) {
                      await SupabaseService.instance.addExerciseToWorkout(
                        workoutId: newWorkout['id'] as String,
                        exerciseId: exerciseId,
                        orderIndex: i,
                        targetSets: exercise['target_sets'] as int? ?? 3,
                        targetReps: exercise['target_reps'] as int? ?? 10,
                        restTimeSeconds: exercise['rest_time_seconds'] as int? ?? 90,
                        notes: exercise['notes'] as String?,
                      );
                    }
                  }

                  // Reload workouts
                  await _loadWorkouts();
                  
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Workout "${newWorkout['name']}" created'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error duplicating workout: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              onDelete: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Workout'),
                    content: Text('Are you sure you want to delete "${workout['name']}"?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.error,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await SupabaseService.instance.deleteWorkout(workout['id'] as String);
                    await _loadWorkouts();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Workout deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            );
          }).toList(),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => widget.onNavigate('workout-builder'),
            icon: const Icon(Icons.add),
            label: const Text('Create New Workout'),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: () => widget.onNavigate('active-workout-start'),
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Empty Workout'),
          ),
        ]),
      ),
    );
  }
}

class _WorkoutCard extends StatelessWidget {
  final String name;
  final String description;
  final int exercises;
  final String duration;
  final String difficulty;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final VoidCallback onTap;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;

  const _WorkoutCard({
    super.key,
    required this.name,
    required this.description,
    required this.exercises,
    required this.duration,
    required this.difficulty,
    required this.colorScheme,
    required this.textTheme,
    required this.onTap,
    this.onDuplicate,
    this.onDelete,
  });

  Color _getDifficultyColor() {
    switch (difficulty) {
      case 'Beginner':
        return colorScheme.secondary;
      case 'Intermediate':
        return colorScheme.primary;
      case 'Advanced':
        return colorScheme.error;
      default:
        return colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: colorScheme.onPrimaryContainer,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor().withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            difficulty,
                            style: textTheme.labelSmall?.copyWith(
                              color: _getDifficultyColor(),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.fitness_center,
                          size: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$exercises ex',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 8),
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
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
