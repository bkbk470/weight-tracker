import 'package:flutter/material.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?]) onNavigate;
  final String? workoutId;
  final String workoutName;
  final String workoutDescription;
  final String duration;
  final String difficulty;
  final List<WorkoutExercise>? initialExercises;
  final Map<String, dynamic>? workoutData;

  const WorkoutDetailScreen({
    super.key,
    required this.onNavigate,
    this.workoutId,
    this.workoutName = 'Push Day',
    this.workoutDescription = 'Chest, shoulders, and triceps',
    this.duration = '45 min',
    this.difficulty = 'Intermediate',
    this.initialExercises,
    this.workoutData,
  });

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  List<WorkoutExercise> exercises = [];
  bool isEditMode = false;

  @override
  void initState() {
    super.initState();
    final provided = widget.initialExercises;
    if (provided != null && provided.isNotEmpty) {
      exercises = provided.map((e) => e.copy()).toList();
    } else {
      // Sample exercises for the workout
      exercises = [
        WorkoutExercise(
          name: 'Bench Press',
          sets: [
            WorkoutExerciseSet(weight: 135, reps: 12, restSeconds: 150),
            WorkoutExerciseSet(weight: 185, reps: 8, restSeconds: 180),
            WorkoutExerciseSet(weight: 205, reps: 6, restSeconds: 180),
            WorkoutExerciseSet(weight: 205, reps: 6, restSeconds: 180),
          ],
        ),
        WorkoutExercise(
          name: 'Incline Dumbbell Press',
          sets: [
            WorkoutExerciseSet(weight: 60, reps: 12, restSeconds: 120),
            WorkoutExerciseSet(weight: 65, reps: 10, restSeconds: 120),
            WorkoutExerciseSet(weight: 65, reps: 8, restSeconds: 120),
          ],
        ),
        WorkoutExercise(
          name: 'Dumbbell Flyes',
          sets: [
            WorkoutExerciseSet(weight: 30, reps: 15, restSeconds: 90),
            WorkoutExerciseSet(weight: 30, reps: 15, restSeconds: 90),
            WorkoutExerciseSet(weight: 30, reps: 15, restSeconds: 90),
          ],
        ),
        WorkoutExercise(
          name: 'Overhead Press',
          sets: [
            WorkoutExerciseSet(weight: 95, reps: 10, restSeconds: 150),
            WorkoutExerciseSet(weight: 105, reps: 8, restSeconds: 150),
            WorkoutExerciseSet(weight: 110, reps: 6, restSeconds: 150),
          ],
        ),
        WorkoutExercise(
          name: 'Lateral Raises',
          sets: [
            WorkoutExerciseSet(weight: 20, reps: 15, restSeconds: 60),
            WorkoutExerciseSet(weight: 20, reps: 15, restSeconds: 60),
            WorkoutExerciseSet(weight: 20, reps: 15, restSeconds: 60),
          ],
        ),
        WorkoutExercise(
          name: 'Tricep Dips',
          sets: [
            WorkoutExerciseSet(weight: 0, reps: 12, restSeconds: 90),
            WorkoutExerciseSet(weight: 0, reps: 12, restSeconds: 90),
            WorkoutExerciseSet(weight: 0, reps: 12, restSeconds: 90),
          ],
        ),
      ];
    }
  }

  void startWorkout() {
    // Convert exercises to the format expected by active workout screen
    final exercisesData = exercises.asMap().entries.map((entry) {
      final index = entry.key;
      final exercise = entry.value;
      final noteText = exercise.notes.trim();
      return {
        'name': exercise.name,
        'sets': exercise.sets.length,
        'reps': exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0,
        'restTime': exercise.sets.isNotEmpty ? exercise.sets.first.restSeconds : 120,
        'setDetails': exercise.sets
            .map((set) => {
                  'weight': set.weight,
                  'reps': set.reps,
                  'rest': set.restSeconds,
                })
            .toList(),
        'notes': noteText,
        'workoutExerciseId': exercise.workoutExerciseId,
        'exerciseId': exercise.exerciseId,
        'orderIndex': index,
      };
    }).toList();
    
    // Pass exercises data when navigating
    final payload = <String, dynamic>{
      'exercises': exercisesData,
      'workoutName': widget.workoutName,
    };
    if (widget.workoutId != null) {
      payload['workoutId'] = widget.workoutId;
    }
    widget.onNavigate('active-workout-start', payload);
  }

  void deleteExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exercise removed')),
    );
  }

  void addExercise() {
    showDialog(
      context: context,
      builder: (context) => _AddExerciseDialog(
        onAdd: (exercise) {
          setState(() {
            exercises.add(exercise);
          });
        },
      ),
    );
  }

  void updateSetValue(int exerciseIndex, int setIndex, {int? weight, int? reps, int? restSeconds}) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;
    final sets = exercises[exerciseIndex].sets;
    if (setIndex < 0 || setIndex >= sets.length) return;

    setState(() {
      if (weight != null) {
        sets[setIndex].weight = weight;
      }
      if (reps != null) {
        sets[setIndex].reps = reps;
      }
      if (restSeconds != null) {
        final clamped = restSeconds.clamp(0, 600);
        sets[setIndex].restSeconds = clamped is num ? clamped.toInt() : restSeconds;
      }
    });
  }

  void addSetToExercise(int exerciseIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;

    setState(() {
      final exercise = exercises[exerciseIndex];
      final template = exercise.sets.isNotEmpty
          ? exercise.sets.last
          : WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: 90);
      exercise.sets.add(template.copy());
    });
  }

  void removeSetFromExercise(int exerciseIndex, int setIndex) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;
    final sets = exercises[exerciseIndex].sets;
    if (sets.length <= 1) return;
    if (setIndex < 0 || setIndex >= sets.length) return;

    setState(() {
      sets.removeAt(setIndex);
    });
  }

  void updateExerciseNotes(int exerciseIndex, String notes) {
    if (exerciseIndex < 0 || exerciseIndex >= exercises.length) return;
    setState(() {
      exercises[exerciseIndex].notes = notes;
    });
  }

  void _normalizeNotes() {
    bool updated = false;
    for (final exercise in exercises) {
      final trimmed = exercise.notes.trim();
      if (trimmed != exercise.notes) {
        exercise.notes = trimmed;
        updated = true;
      }
    }
    if (updated && mounted) {
      setState(() {});
    }
  }

  Future<void> _persistWorkoutChanges() async {
    if (widget.workoutId == null) return;

    final updates = <Future<void>>[];
    bool needsRebuild = false;
    for (final exercise in exercises) {
      final workoutExerciseId = exercise.workoutExerciseId;
      if (workoutExerciseId == null) continue;

      final targetReps = exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0;
      final restSeconds = exercise.sets.isNotEmpty ? exercise.sets.first.restSeconds : 0;
      final trimmedNotes = exercise.notes.trim();
      if (exercise.notes != trimmedNotes) {
        exercise.notes = trimmedNotes;
        needsRebuild = true;
      }
      updates.add(
        SupabaseService.instance.updateWorkoutExercise(workoutExerciseId, {
          'target_sets': exercise.sets.length,
          'target_reps': targetReps,
          'rest_time_seconds': restSeconds,
          'notes': trimmedNotes.isEmpty ? null : trimmedNotes,
        }),
      );
    }

    if (updates.isEmpty) return;

    try {
      await Future.wait(updates);
      if (mounted) {
        if (needsRebuild) {
          setState(() {});
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes saved'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save changes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
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
            expandedHeight: 200,
            pinned: true,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => widget.onNavigate('dashboard'),
            ),
            actions: [
              IconButton(
                icon: Icon(isEditMode ? Icons.check : Icons.edit),
                onPressed: () async {
                  final wasEditing = isEditMode;
                  setState(() {
                    isEditMode = !isEditMode;
                  });
                  if (wasEditing) {
                    if (widget.workoutId != null) {
                      await _persistWorkoutChanges();
                    } else {
                      _normalizeNotes();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Changes updated locally')),
                        );
                      }
                    }
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show more options
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(widget.workoutName),
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
                child: Center(
                  child: Icon(
                    Icons.fitness_center,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.3),
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
                // Workout Info
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.workoutDescription,
                          style: textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoChip(
                              icon: Icons.fitness_center,
                              label: '${exercises.length} exercises',
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            _InfoChip(
                              icon: Icons.access_time,
                              label: widget.duration,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                            _InfoChip(
                              icon: Icons.signal_cellular_alt,
                              label: widget.difficulty,
                              colorScheme: colorScheme,
                              textTheme: textTheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Start Workout Button
                FilledButton.icon(
                  onPressed: startWorkout,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Workout'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                const SizedBox(height: 32),

                // Exercises Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Exercises',
                      style: textTheme.titleLarge,
                    ),
                    if (isEditMode)
                      TextButton.icon(
                        onPressed: addExercise,
                        icon: const Icon(Icons.add),
                        label: const Text('Add'),
                      ),
                  ],
                ),
                const SizedBox(height: 16),

                // Exercise List
                ...exercises.asMap().entries.map((entry) {
                  final index = entry.key;
                  final exercise = entry.value;
                  return _ExerciseCard(
                    exercise: exercise,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    isEditMode: isEditMode,
                    onDelete: () => deleteExercise(index),
                    onUpdateWeight: (setIndex, value) => updateSetValue(index, setIndex, weight: value),
                    onUpdateReps: (setIndex, value) => updateSetValue(index, setIndex, reps: value),
                    onUpdateRest: (setIndex, value) => updateSetValue(index, setIndex, restSeconds: value),
                    onAddSet: () => addSetToExercise(index),
                    onRemoveSet: (setIndex) => removeSetFromExercise(index, setIndex),
                    onUpdateNotes: (value) => updateExerciseNotes(index, value),
                  );
                }).toList(),

                const SizedBox(height: 24),

                // Add Exercise Button (only in edit mode)
                if (isEditMode)
                  OutlinedButton.icon(
                    onPressed: addExercise,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Exercise'),
                  ),
                if (isEditMode)
                  const SizedBox(height: 32),

                // Additional Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _duplicateWorkout();
                        },
                        icon: const Icon(Icons.copy),
                        label: const Text('Duplicate'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Delete workout
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Workout'),
                              content: const Text(
                                'Are you sure you want to delete this workout? This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _deleteWorkout();
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: colorScheme.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        icon: Icon(Icons.delete, color: colorScheme.error),
                        label: Text(
                          'Delete',
                          style: TextStyle(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class WorkoutExercise {
  String name;
  List<WorkoutExerciseSet> sets;
  String notes;
  String? workoutExerciseId;
  String? exerciseId;
  int? orderIndex;

  WorkoutExercise({
    required this.name,
    required List<WorkoutExerciseSet> sets,
    this.notes = '',
    this.workoutExerciseId,
    this.exerciseId,
    this.orderIndex,
  }) : sets = sets.map((set) => set.copy()).toList();

  WorkoutExercise copy() {
    return WorkoutExercise(
      name: name,
      sets: sets.map((set) => set.copy()).toList(),
      notes: notes,
      workoutExerciseId: workoutExerciseId,
      exerciseId: exerciseId,
      orderIndex: orderIndex,
    );
  }
}

class WorkoutExerciseSet {
  int weight;
  int reps;
  int restSeconds;

  WorkoutExerciseSet({
    required this.weight,
    required this.reps,
    required this.restSeconds,
  });

  WorkoutExerciseSet copy() => WorkoutExerciseSet(weight: weight, reps: reps, restSeconds: restSeconds);
}

extension on _WorkoutDetailScreenState {
  Future<Map<String, dynamic>> _createWorkoutFromCuratedTemplate(
    Map<String, dynamic> template,
  ) async {
    final templateName = template['name'] as String? ?? 'Workout Template';
    final description = template['description'] as String?;
    final difficulty = template['difficulty'] as String?;
    final durationMinutes = template['estimated_duration_minutes'] as int?;

    final newWorkout = await SupabaseService.instance.createWorkout(
      name: 'Copy of $templateName',
      description: description,
      difficulty: difficulty,
      estimatedDurationMinutes: durationMinutes,
    );

    final exercises = (template['workout_template_exercises'] as List?)
            ?.whereType<Map<String, dynamic>>()
            .toList() ??
        [];

    for (var i = 0; i < exercises.length; i++) {
      final exercise = exercises[i];
      final exerciseName = (exercise['exercise_name'] as String?) ?? 'Exercise';
      final rawNotes = (exercise['notes'] as String?)?.trim();
      final notes = rawNotes == null || rawNotes.isEmpty ? null : rawNotes;
      final category = (exercise['category'] as String?)?.trim();

      try {
        final exerciseId = await SupabaseService.instance.getOrCreateExerciseId(
          name: exerciseName,
          category: category == null || category.isEmpty ? 'Other' : category,
          notes: notes,
        );

        if (exerciseId == null) continue;

        await SupabaseService.instance.addExerciseToWorkout(
          workoutId: newWorkout['id'] as String,
          exerciseId: exerciseId,
          orderIndex: i,
          targetSets: exercise['target_sets'] as int? ?? 3,
          targetReps: exercise['target_reps'] as int? ?? 10,
          restTimeSeconds: exercise['rest_time_seconds'] as int? ?? 90,
          notes: notes,
        );
      } catch (e) {
        print('Failed to add curated template exercise $exerciseName: $e');
      }
    }

    final created =
        await SupabaseService.instance.getWorkout(newWorkout['id'] as String);
    return created ?? newWorkout;
  }

  Future<void> _duplicateWorkout() async {
    final data = widget.workoutData;
    final workoutId = widget.workoutId ?? data?['id'] as String?;
    final isTemplate = data != null && data.containsKey('workout_template_exercises');

    if (workoutId == null && !isTemplate) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot duplicate workout: missing identifier'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      Map<String, dynamic> duplicated;
      if (isTemplate) {
        final templateId = data?['id']?.toString();
        if (templateId == null) throw Exception('Template identifier missing');
        if (templateId.startsWith('tmpl_')) {
          duplicated = await _createWorkoutFromCuratedTemplate(data!);
        } else {
          duplicated = await SupabaseService.instance.duplicateTemplateToWorkout(templateId);
        }
      } else {
        final originalWorkout = await SupabaseService.instance.getWorkout(workoutId!);
        if (originalWorkout == null) {
          throw Exception('Workout not found');
        }

        final originalName = originalWorkout['name'] as String? ?? 'Workout';
        final newWorkout = await SupabaseService.instance.createWorkout(
          name: 'Copy of $originalName',
          description: originalWorkout['description'] as String?,
          difficulty: originalWorkout['difficulty'] as String?,
          estimatedDurationMinutes: originalWorkout['estimated_duration_minutes'] as int?,
        );

        final workoutExercises = originalWorkout['workout_exercises'] as List? ?? [];
        for (var i = 0; i < workoutExercises.length; i++) {
          final exercise = workoutExercises[i] as Map<String, dynamic>;
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

        duplicated = await SupabaseService.instance.getWorkout(newWorkout['id'] as String) ?? newWorkout;
      }

      if (!mounted) return;

      // Show success message and navigate to workout library
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Workout "${duplicated['name'] ?? 'Workout'}" created'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back to workout library
      widget.onNavigate('workout');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to duplicate workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteWorkout() async {
    if (widget.workoutId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete workout: missing identifier'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await SupabaseService.instance.deleteWorkout(widget.workoutId!);

      if (!mounted) return;

      widget.onNavigate('workout');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout deleted'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete workout: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: colorScheme.primary),
        const SizedBox(height: 4),
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

class _ExerciseCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isEditMode;
  final VoidCallback onDelete;
  final void Function(int setIndex, int value) onUpdateWeight;
  final void Function(int setIndex, int value) onUpdateReps;
  final void Function(int setIndex, int value) onUpdateRest;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onRemoveSet;
  final ValueChanged<String> onUpdateNotes;

  const _ExerciseCard({
    required this.exercise,
    required this.colorScheme,
    required this.textTheme,
    required this.isEditMode,
    required this.onDelete,
    required this.onUpdateWeight,
    required this.onUpdateReps,
    required this.onUpdateRest,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onUpdateNotes,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  late List<TextEditingController> weightControllers;
  late List<TextEditingController> repsControllers;
  late List<TextEditingController> restControllers;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    _initControllers();
    notesController = TextEditingController(text: widget.exercise.notes);
  }

  void _initControllers() {
    weightControllers = widget.exercise.sets
        .map((set) => TextEditingController(text: set.weight.toString()))
        .toList();
    repsControllers = widget.exercise.sets
        .map((set) => TextEditingController(text: set.reps.toString()))
        .toList();
    restControllers = widget.exercise.sets
        .map((set) => TextEditingController(text: set.restSeconds.toString()))
        .toList();
  }

  void _disposeSetControllers() {
    for (final controller in weightControllers) {
      controller.dispose();
    }
    for (final controller in repsControllers) {
      controller.dispose();
    }
    for (final controller in restControllers) {
      controller.dispose();
    }
  }

  @override
  void didUpdateWidget(covariant _ExerciseCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (weightControllers.length != widget.exercise.sets.length) {
      _disposeSetControllers();
      _initControllers();
    } else {
      for (int i = 0; i < widget.exercise.sets.length; i++) {
        final newWeight = widget.exercise.sets[i].weight.toString();
        if (weightControllers[i].text != newWeight) {
          weightControllers[i].value = TextEditingValue(
            text: newWeight,
            selection: TextSelection.collapsed(offset: newWeight.length),
          );
        }

        final newReps = widget.exercise.sets[i].reps.toString();
        if (repsControllers[i].text != newReps) {
          repsControllers[i].value = TextEditingValue(
            text: newReps,
            selection: TextSelection.collapsed(offset: newReps.length),
          );
        }

        final newRest = widget.exercise.sets[i].restSeconds.toString();
        if (restControllers[i].text != newRest) {
          restControllers[i].value = TextEditingValue(
            text: newRest,
            selection: TextSelection.collapsed(offset: newRest.length),
          );
        }
      }
    }

    if (notesController.text != widget.exercise.notes) {
      notesController.value = TextEditingValue(
        text: widget.exercise.notes,
        selection: TextSelection.collapsed(offset: widget.exercise.notes.length),
      );
    }
  }

  @override
  void dispose() {
    _disposeSetControllers();
    notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercise = widget.exercise;
    final colorScheme = widget.colorScheme;
    final textTheme = widget.textTheme;
    final isEditMode = widget.isEditMode;
    final noteText = exercise.notes.trim();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _buildSubtitle(),
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (!isEditMode && noteText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          noteText,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isEditMode)
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    color: colorScheme.error,
                    onPressed: widget.onDelete,
                  ),
              ],
            ),
            if (isEditMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    SizedBox(
                      width: 50,
                      child: Text(
                        '#',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Weight',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 60,
                      child: Text(
                        'Reps',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 70,
                      child: Text(
                        'Rest',
                        style: textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                  ],
                ),
              ),
              ...exercise.sets.asMap().entries.map((entry) {
                final setIndex = entry.key;
                final set = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: colorScheme.surfaceVariant,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${setIndex + 1}',
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 3,
                        child: TextFormField(
                          controller: weightControllers[setIndex],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 5,
                          maxLines: 1,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            counterText: '',
                          ),
                          onTap: () {
                            weightControllers[setIndex].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: weightControllers[setIndex].text.length,
                            );
                          },
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed != exercise.sets[setIndex].weight) {
                              widget.onUpdateWeight(setIndex, parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: repsControllers[setIndex],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          maxLines: 1,
                          style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            counterText: '',
                          ),
                          onTap: () {
                            repsControllers[setIndex].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: repsControllers[setIndex].text.length,
                            );
                          },
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed != exercise.sets[setIndex].reps) {
                              widget.onUpdateReps(setIndex, parsed);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: restControllers[setIndex],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          onTap: () {
                            restControllers[setIndex].selection = TextSelection(
                              baseOffset: 0,
                              extentOffset: restControllers[setIndex].text.length,
                            );
                          },
                          onChanged: (value) {
                            final parsed = int.tryParse(value);
                            if (parsed != null && parsed != exercise.sets[setIndex].restSeconds) {
                              widget.onUpdateRest(setIndex, parsed);
                            }
                          },
                        ),
                      ),
                      if (exercise.sets.length > 1) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: const Icon(Icons.close, size: 18),
                            color: colorScheme.error,
                            onPressed: () => widget.onRemoveSet(setIndex),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onAddSet,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Set'),
                ),
              ),
              if (isEditMode) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Notes',
                    hintText: 'Add notes about pacing, cues, etc.',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onChanged: widget.onUpdateNotes,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _buildSubtitle() {
    final exercise = widget.exercise;
    if (exercise.sets.isEmpty) {
      return 'No sets configured';
    }

    final repsSet = exercise.sets.map((set) => set.reps).toSet();
    final weightExists = exercise.sets.any((set) => set.weight > 0);
    final restSet = exercise.sets.map((set) => set.restSeconds).toSet();

    final repsSummary = repsSet.length == 1
        ? '${exercise.sets.first.reps} reps'
        : 'Reps: ${exercise.sets.map((set) => set.reps).join(', ')}';
    final restSummary = restSet.length == 1
        ? '${exercise.sets.first.restSeconds} rest'
        : 'Rest: ${exercise.sets.map((set) => set.restSeconds).join(', ')}';
    final weightSummary = weightExists
        ? ' • Weights: ${exercise.sets.map((set) => set.weight).join(', ')}'
        : '';

    return '${exercise.sets.length} sets • $repsSummary • $restSummary$weightSummary';
  }
}

class _AddExerciseDialog extends StatefulWidget {
  final Function(WorkoutExercise) onAdd;

  const _AddExerciseDialog({required this.onAdd});

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final searchController = TextEditingController();
  String selectedCategory = 'All';
  String searchQuery = '';
  List<Map<String, String>> customExercises = [];

  final categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Other'];

  @override
  void initState() {
    super.initState();
    _loadCustomExercises();
  }

  void _loadCustomExercises() async {
    // Try to load from Supabase first
    try {
      final supabaseExercises = await SupabaseService.instance.getExercises();
      
      // Filter only custom exercises
      final customOnly = supabaseExercises.where((e) => e['is_custom'] == true).toList();
      
      setState(() {
        customExercises = customOnly.map((e) => {
          'name': e['name'] as String,
          'category': e['category'] as String,
        }).toList();
      });
    } catch (e) {
      print('Failed to load from Supabase: $e');
      
      // Fall back to local storage
      final localStorage = LocalStorageService.instance;
      final saved = localStorage.getAllExercises();
      
      setState(() {
        customExercises = saved.map((e) => {
          'name': e['name'] as String,
          'category': e['category'] as String,
        }).toList();
      });
    }
  }

  final availableExercises = [
    {'name': 'Bench Press', 'category': 'Chest'},
    {'name': 'Incline Bench Press', 'category': 'Chest'},
    {'name': 'Dumbbell Flyes', 'category': 'Chest'},
    {'name': 'Deadlifts', 'category': 'Back'},
    {'name': 'Pull-ups', 'category': 'Back'},
    {'name': 'Barbell Rows', 'category': 'Back'},
    {'name': 'Squats', 'category': 'Legs'},
    {'name': 'Leg Press', 'category': 'Legs'},
    {'name': 'Lunges', 'category': 'Legs'},
    {'name': 'Overhead Press', 'category': 'Shoulders'},
    {'name': 'Lateral Raises', 'category': 'Shoulders'},
    {'name': 'Bicep Curls', 'category': 'Arms'},
    {'name': 'Tricep Dips', 'category': 'Arms'},
    {'name': 'Planks', 'category': 'Core'},
    {'name': 'Crunches', 'category': 'Core'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredExercises {
    final allExercises = [...availableExercises, ...customExercises];
    
    return allExercises.where((exercise) {
      final matchesCategory = selectedCategory == 'All' || exercise['category'] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty || 
          exercise['name']!.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercise',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Search bar
            TextField(
              controller: searchController,
              onChanged: (value) => setState(() => searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Category filter
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() => selectedCategory = category);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            // Exercise count
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filteredExercises.length} exercises',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Exercise list
            Expanded(
              child: filteredExercises.isEmpty
                  ? const Center(child: Text('No exercises found'))
                  : ListView.builder(
                      itemCount: filteredExercises.length,
                      itemBuilder: (context, index) {
                        final exercise = filteredExercises[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Icon(
                              Icons.fitness_center,
                              color: colorScheme.primary,
                            ),
                            title: Text(exercise['name']!),
                            subtitle: Text(exercise['category']!),
                            trailing: const Icon(Icons.add_circle_outline),
                            onTap: () {
                              widget.onAdd(
                                WorkoutExercise(
                                  name: exercise['name']!,
                                  sets: List.generate(
                                    3,
                                    (_) => WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: 90),
                                  ),
                                ),
                              );
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
