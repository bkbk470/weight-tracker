import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/supabase_service.dart';

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
  bool isReordering = false;
  int? draggedIndex;
  int? hoveredIndex;

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
    
    try {
      final templates = await SupabaseService.instance.getWorkoutTemplates();
      setState(() {
        workoutTemplates = templates;
        isLoadingTemplates = false;
      });
    } catch (e) {
      print('Error loading templates: $e');
      setState(() => isLoadingTemplates = false);
    }
  }

  Future<void> _reorderWorkouts(int oldIndex, int newIndex) async {
    setState(() {
      // Adjust newIndex for list reordering
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }

      // Reorder the list
      final workout = myWorkouts.removeAt(oldIndex);
      myWorkouts.insert(newIndex, workout);
    });

    try {
      // Save the new order to the database
      await SupabaseService.instance.reorderWorkouts(myWorkouts);
    } catch (e) {
      print('Error saving workout order: $e');
      // Reload on error to get correct order
      _loadWorkouts();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _onDragStart(int index) {
    setState(() {
      draggedIndex = index;
    });
  }

  void _onDragEnd() {
    if (draggedIndex != null && hoveredIndex != null && draggedIndex != hoveredIndex) {
      _reorderWorkouts(draggedIndex!, hoveredIndex!);
    }
    setState(() {
      draggedIndex = null;
      hoveredIndex = null;
    });
  }

  void _onDragEnter(int index) {
    if (draggedIndex != null && draggedIndex != index) {
      setState(() {
        hoveredIndex = index;
      });
    }
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            pinned: true,
            expandedHeight: 120,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text('Workouts'),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.surface,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              if (selectedTab == 'My Workouts' && myWorkouts.isNotEmpty)
                IconButton(
                  icon: Icon(isReordering ? Icons.check : Icons.drag_handle),
                  onPressed: () {
                    setState(() {
                      isReordering = !isReordering;
                      if (!isReordering) {
                        draggedIndex = null;
                        hoveredIndex = null;
                      }
                    });
                  },
                  tooltip: isReordering ? 'Done Reordering' : 'Reorder Workouts',
                ),
              IconButton(
                icon: const Icon(Icons.folder),
                onPressed: () => widget.onNavigate('workout-folders'),
                tooltip: 'Organize Folders',
              ),
            ],
          ),

          // Search Bar
          if (!isReordering)
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
          if (!isReordering)
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

          // Reordering hint
          if (isReordering)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        kIsWeb 
                          ? 'Click and drag workouts to reorder them'
                          : 'Long press and drag workouts to reorder them',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Content based on selected tab
          if (selectedTab == 'My Workouts')
            isLoading
                ? SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  )
                : myWorkouts.isEmpty
                    ? SliverFillRemaining(
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
                      )
                    : isReordering
                        ? _buildReorderableWorkoutList(colorScheme, textTheme)
                        : _buildNormalWorkoutList(colorScheme, textTheme)
          else
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: isLoadingTemplates
                  ? SliverFillRemaining(
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
                                showDragHandle: false,
                                onTap: () => widget.onNavigate(
                                  'workout-detail',
                                  {
                                    'workout': template,
                                  },
                                ),
                                onDuplicate: () async {
                                  try {
                                    // Duplicate template to user's workouts
                                    final newWorkout = await SupabaseService.instance.duplicateTemplateToWorkout(
                                      template['id'] as String,
                                    );

                                    // Reload user's workouts
                                    await _loadWorkouts();
                                    
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Workout "${newWorkout['name']}" added to My Workouts'),
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
            ),
        ],
      ),
    );
  }

  Widget _buildReorderableWorkoutList(ColorScheme colorScheme, TextTheme textTheme) {
    if (kIsWeb) {
      // Use custom drag and drop for web
      return SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final workout = myWorkouts[index];
              final exercises = workout['workout_exercises'] as List? ?? [];
              final isDragging = draggedIndex == index;
              final isHovered = hoveredIndex == index;

              return Draggable<int>(
                data: index,
                onDragStarted: () => _onDragStart(index),
                onDragEnd: (_) => _onDragEnd(),
                feedback: Material(
                  elevation: 8,
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: MediaQuery.of(context).size.width - 32,
                    child: Opacity(
                      opacity: 0.8,
                      child: _WorkoutCard(
                        name: workout['name'] ?? 'Unnamed Workout',
                        description: workout['description'] ?? 'No description',
                        exercises: exercises.length,
                        duration: '${workout['estimated_duration_minutes'] ?? 45} min',
                        difficulty: workout['difficulty'] ?? 'Intermediate',
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        showDragHandle: true,
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.3,
                  child: _WorkoutCard(
                    name: workout['name'] ?? 'Unnamed Workout',
                    description: workout['description'] ?? 'No description',
                    exercises: exercises.length,
                    duration: '${workout['estimated_duration_minutes'] ?? 45} min',
                    difficulty: workout['difficulty'] ?? 'Intermediate',
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    showDragHandle: true,
                    onTap: () {},
                  ),
                ),
                child: DragTarget<int>(
                  onWillAccept: (data) => data != null && data != index,
                  onAccept: (data) {
                    _reorderWorkouts(data, index);
                  },
                  onMove: (_) => _onDragEnter(index),
                  builder: (context, candidateData, rejectedData) {
                    return Container(
                      decoration: BoxDecoration(
                        border: isHovered ? Border.all(
                          color: colorScheme.primary,
                          width: 2,
                        ) : null,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedOpacity(
                        opacity: isDragging ? 0.3 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: _WorkoutCard(
                          name: workout['name'] ?? 'Unnamed Workout',
                          description: workout['description'] ?? 'No description',
                          exercises: exercises.length,
                          duration: '${workout['estimated_duration_minutes'] ?? 45} min',
                          difficulty: workout['difficulty'] ?? 'Intermediate',
                          colorScheme: colorScheme,
                          textTheme: textTheme,
                          showDragHandle: true,
                          onTap: () {},
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            childCount: myWorkouts.length,
          ),
        ),
      );
    } else {
      // Use ReorderableListView for mobile
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            onReorder: _reorderWorkouts,
            children: myWorkouts.map((workout) {
              final exercises = workout['workout_exercises'] as List? ?? [];
              return _WorkoutCard(
                key: ValueKey(workout['id']),
                name: workout['name'] ?? 'Unnamed Workout',
                description: workout['description'] ?? 'No description',
                exercises: exercises.length,
                duration: '${workout['estimated_duration_minutes'] ?? 45} min',
                difficulty: workout['difficulty'] ?? 'Intermediate',
                colorScheme: colorScheme,
                textTheme: textTheme,
                showDragHandle: true,
                onTap: () {}, // Disable tap during reordering
              );
            }).toList(),
          ),
        ),
      );
    }
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
              showDragHandle: false,
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
  final bool showDragHandle;
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
    required this.showDragHandle,
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
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_handle,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
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
              if (!showDragHandle)
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
