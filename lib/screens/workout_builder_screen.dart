import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class WorkoutBuilderScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final String? workoutId;
  final String? workoutName;
  final List<WorkoutExercise>? initialExercises;

  const WorkoutBuilderScreen({
    super.key,
    required this.onNavigate,
    this.workoutId,
    this.workoutName,
    this.initialExercises,
  });

  @override
  State<WorkoutBuilderScreen> createState() => _WorkoutBuilderScreenState();
}

class _WorkoutBuilderScreenState extends State<WorkoutBuilderScreen> {
  late TextEditingController workoutNameController;
  late List<WorkoutExercise> exercises;
  String selectedCategory = 'All';
  final categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core'];

  final availableExercises = [
    {'name': 'Bench Press', 'category': 'Chest', 'icon': Icons.fitness_center},
    {'name': 'Incline Bench Press', 'category': 'Chest', 'icon': Icons.fitness_center},
    {'name': 'Dumbbell Flyes', 'category': 'Chest', 'icon': Icons.fitness_center},
    {'name': 'Pull-ups', 'category': 'Back', 'icon': Icons.fitness_center},
    {'name': 'Barbell Rows', 'category': 'Back', 'icon': Icons.fitness_center},
    {'name': 'Lat Pulldown', 'category': 'Back', 'icon': Icons.fitness_center},
    {'name': 'Squats', 'category': 'Legs', 'icon': Icons.fitness_center},
    {'name': 'Deadlifts', 'category': 'Legs', 'icon': Icons.fitness_center},
    {'name': 'Leg Press', 'category': 'Legs', 'icon': Icons.fitness_center},
    {'name': 'Overhead Press', 'category': 'Shoulders', 'icon': Icons.fitness_center},
    {'name': 'Lateral Raises', 'category': 'Shoulders', 'icon': Icons.fitness_center},
    {'name': 'Bicep Curls', 'category': 'Arms', 'icon': Icons.fitness_center},
    {'name': 'Tricep Dips', 'category': 'Arms', 'icon': Icons.fitness_center},
    {'name': 'Planks', 'category': 'Core', 'icon': Icons.fitness_center},
    {'name': 'Crunches', 'category': 'Core', 'icon': Icons.fitness_center},
  ];

  @override
  void initState() {
    super.initState();
    // Initialize with workout data if editing, otherwise start fresh
    workoutNameController = TextEditingController(text: widget.workoutName ?? '');
    exercises = widget.initialExercises?.map((e) => e.copy()).toList() ?? [];
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    super.dispose();
  }

  void addExercise(Map<String, dynamic> exercise) {
    setState(() {
      exercises.add(WorkoutExercise(
        name: exercise['name'] as String,
        sets: List.generate(
          3,
          (index) => WorkoutExerciseSet(weight: 0, reps: 10),
        ),
        restTime: 120,
      ));
    });
  }

  void removeExercise(int index) {
    setState(() {
      exercises.removeAt(index);
    });
  }

  Future<void> editExercise(int index) async {
    final updatedExercise = await Navigator.of(context).push<WorkoutExercise?>(
      MaterialPageRoute(
        builder: (context) => ExerciseEditorScreen(
          exercise: exercises[index].copy(),
        ),
      ),
    );

    if (updatedExercise != null) {
      setState(() {
        exercises[index] = updatedExercise;
      });
    }
  }

  Future<void> saveWorkout() async {
    if (workoutNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a workout name'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one exercise'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Rough estimate: assume ~2 minutes per set including rest
      final estimatedMinutes = exercises.fold<int>(
        0,
        (total, ex) => total + (ex.sets.length * 2),
      );

      final String workoutId;
      final bool isEditing = widget.workoutId != null;

      if (isEditing) {
        // Update existing workout
        workoutId = widget.workoutId!;
        await SupabaseService.instance.updateWorkout(
          workoutId,
          {
            'name': workoutNameController.text.trim(),
            'description': 'Custom workout with ${exercises.length} exercises',
            'estimated_duration_minutes': estimatedMinutes,
          },
        );

        // Delete all existing workout_exercises for this workout
        final existingWorkoutExercises = await SupabaseService.instance.client
            .from('workout_exercises')
            .select('id')
            .eq('workout_id', workoutId);

        for (final row in existingWorkoutExercises) {
          await SupabaseService.instance.removeExerciseFromWorkout(row['id']);
        }
      } else {
        // Create new workout
        final workout = await SupabaseService.instance.createWorkout(
          name: workoutNameController.text.trim(),
          description: 'Custom workout with ${exercises.length} exercises',
          difficulty: 'Intermediate',
          estimatedDurationMinutes: estimatedMinutes,
        );
        workoutId = workout['id'];
      }

      // Add each exercise to the workout
      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        
        // First, try to find the exercise in the database
        try {
          final existingExercises = await SupabaseService.instance.getExercises();
          final matchingExercise = existingExercises.firstWhere(
            (e) => e['name'] == exercise.name,
            orElse: () => {},
          );

          String exerciseId;
          if (matchingExercise.isNotEmpty && matchingExercise['id'] != null) {
            exerciseId = matchingExercise['id'];
          } else {
            // Create the exercise if it doesn't exist
            final newExercise = await SupabaseService.instance.createExercise(
              name: exercise.name,
              category: 'Other',
              difficulty: 'Intermediate',
              equipment: 'Various',
            );
            exerciseId = newExercise['id'];
          }

          // Add exercise to workout with set details
          final setDetails = exercise.sets.map((set) => {
            'weight': set.weight,
            'reps': set.reps,
            'rest_time': exercise.restTime,
          }).toList();

          await SupabaseService.instance.addExerciseToWorkout(
            workoutId: workoutId,
            exerciseId: exerciseId,
            orderIndex: i,
            targetSets: exercise.sets.length,
            targetReps: exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0,
            restTimeSeconds: exercise.restTime,
          );

          // Update with set_details JSON
          final workoutExerciseRow = await SupabaseService.instance.getWorkoutExerciseRow(
            workoutId: workoutId,
            exerciseId: exerciseId,
          );

          if (workoutExerciseRow != null) {
            await SupabaseService.instance.client
                .from('workout_exercises')
                .update({'set_details': setDetails})
                .eq('id', workoutExerciseRow['id']);
          }
        } catch (e) {
          print('Error adding exercise ${exercise.name}: $e');
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${workoutNameController.text} ${isEditing ? 'updated' : 'saved'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onNavigate('workout');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving workout: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredExercises = selectedCategory == 'All'
        ? availableExercises
        : availableExercises.where((e) => e['category'] == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('workout'),
        ),
        title: const Text('Build Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: saveWorkout,
          ),
        ],
      ),
      body: Column(
        children: [
          // Workout Name Input
          Container(
            padding: const EdgeInsets.all(24),
            color: colorScheme.surfaceVariant.withOpacity(0.3),
            child: TextField(
              controller: workoutNameController,
              decoration: InputDecoration(
                labelText: 'Workout Name',
                hintText: 'e.g., Push Day, Full Body',
                prefixIcon: const Icon(Icons.edit),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          // Selected Exercises
          if (exercises.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selected Exercises (${exercises.length})',
                    style: textTheme.titleMedium,
                  ),
                  TextButton(
                    onPressed: () => setState(() => exercises.clear()),
                    child: const Text('Clear All'),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 200,
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: exercises.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex--;
                    final item = exercises.removeAt(oldIndex);
                    exercises.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  final repsSummary = exercise.sets.isEmpty
                      ? 'No reps configured'
                      : exercise.sets.map((set) => set.reps).toSet().length == 1
                          ? '${exercise.sets.first.reps} reps'
                          : 'Reps: ${exercise.sets.map((set) => set.reps).join(', ')}';
                  final weightSummary = exercise.sets.any((set) => set.weight > 0)
                      ? ' • Weights: ${exercise.sets.map((set) => set.weight).join(', ')} lbs'
                      : '';
                  return Card(
                    key: ValueKey(exercise.name + index.toString()),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(exercise.name),
                      subtitle: Text(
                        '${exercise.sets.length} sets • $repsSummary • ${exercise.restTime}s rest$weightSummary',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => editExercise(index),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => removeExercise(index),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],

          // Category Filter
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

          // Exercise Library
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredExercises.length,
              itemBuilder: (context, index) {
                final exercise = filteredExercises[index];
                final count = exercises.where((e) => e.name == exercise['name']).length;
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(
                      exercise['icon'] as IconData,
                      color: colorScheme.primary,
                    ),
                    title: Text(exercise['name'] as String),
                    subtitle: Text(
                      count > 0
                          ? '${exercise['category']} • Added $count time${count > 1 ? 's' : ''}'
                          : exercise['category'] as String,
                    ),
                    trailing: IconButton(
                      icon: Icon(
                        count > 0 ? Icons.add_circle : Icons.add_circle_outline,
                        color: count > 0 ? colorScheme.primary : null,
                      ),
                      onPressed: () => addExercise(exercise),
                    ),
                    onTap: () => addExercise(exercise),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: exercises.isNotEmpty
          ? FloatingActionButton.extended(
              onPressed: saveWorkout,
              icon: const Icon(Icons.save),
              label: const Text('Save Workout'),
            )
          : null,
    );
  }
}

class WorkoutExercise {
  final String name;
  List<WorkoutExerciseSet> sets;
  int restTime;

  WorkoutExercise({
    required this.name,
    required List<WorkoutExerciseSet> sets,
    required this.restTime,
  }) : sets = sets.map((set) => set.copy()).toList();

  WorkoutExercise copy() {
    return WorkoutExercise(
      name: name,
      sets: sets.map((set) => set.copy()).toList(),
      restTime: restTime,
    );
  }
}

class WorkoutExerciseSet {
  int weight;
  int reps;

  WorkoutExerciseSet({
    required this.weight,
    required this.reps,
  });

  WorkoutExerciseSet copy() => WorkoutExerciseSet(weight: weight, reps: reps);
}

class ExerciseEditorScreen extends StatefulWidget {
  final WorkoutExercise exercise;

  const ExerciseEditorScreen({super.key, required this.exercise});

  @override
  State<ExerciseEditorScreen> createState() => _ExerciseEditorScreenState();
}

class _ExerciseEditorScreenState extends State<ExerciseEditorScreen> {
  late List<WorkoutExerciseSet> sets;
  late int restTime;

  @override
  void initState() {
    super.initState();
    sets = widget.exercise.sets.map((set) => set.copy()).toList();
    if (sets.isEmpty) {
      sets = [WorkoutExerciseSet(weight: 0, reps: 10)];
    }
    restTime = widget.exercise.restTime;
  }

  void _updateSet(int index, {int? weight, int? reps}) {
    setState(() {
      if (weight != null) {
        sets[index].weight = weight;
      }
      if (reps != null) {
        sets[index].reps = reps;
      }
    });
  }

  void _updateRest(int value) {
    setState(() {
      restTime = value;
    });
  }

  void _addSet() {
    setState(() {
      final template = sets.isNotEmpty ? sets.last : WorkoutExerciseSet(weight: 0, reps: 10);
      sets.add(template.copy());
    });
  }

  void _removeSet(int index) {
    if (sets.length <= 1) return;
    setState(() {
      sets.removeAt(index);
    });
  }

  Future<void> _showNumberDialog({
    required String label,
    required int currentValue,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    String? suffix,
  }) async {
    final controller = TextEditingController(text: currentValue.toString());

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Set $label'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: label,
              border: const OutlineInputBorder(),
              suffixText: suffix,
            ),
            onSubmitted: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null && intValue >= min && intValue <= max) {
                onChanged(intValue);
                Navigator.pop(context);
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final intValue = int.tryParse(controller.text);
                if (intValue != null && intValue >= min && intValue <= max) {
                  onChanged(intValue);
                }
                Navigator.pop(context);
              },
              child: const Text('Done'),
            ),
          ],
        );
      },
    );

    controller.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      WorkoutExercise(
        name: widget.exercise.name,
        sets: sets.map((set) => set.copy()).toList(),
        restTime: restTime,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.exercise.name),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Sets',
                        style: textTheme.titleMedium,
                      ),
                      const Spacer(),
                      Text(
                        '${sets.length} total',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 60,
                          child: Text(
                            '#',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 12),
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
                        const SizedBox(width: 12),
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
                  const SizedBox(height: 4),
                  ...sets.asMap().entries.map((entry) {
                    final index = entry.key;
                    final set = entry.value;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: colorScheme.surfaceVariant,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 60,
                            child: Text(
                              '${index + 1}',
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: InkWell(
                              onTap: () => _showNumberDialog(
                                label: 'Weight',
                                currentValue: set.weight,
                                min: 0,
                                max: 500,
                                onChanged: (value) => _updateSet(index, weight: value),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${set.weight}',
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 60,
                            child: InkWell(
                              onTap: () => _showNumberDialog(
                                label: 'Reps',
                                currentValue: set.reps,
                                min: 1,
                                max: 100,
                                onChanged: (value) => _updateSet(index, reps: value),
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${set.reps}',
                                  style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          SizedBox(
                            width: 70,
                            child: InkWell(
                              onTap: () => _showNumberDialog(
                                label: 'Rest',
                                currentValue: restTime,
                                min: 0,
                                max: 600,
                                suffix: 'sec',
                                onChanged: _updateRest,
                              ),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.surface,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: colorScheme.outline.withOpacity(0.3),
                                  ),
                                ),
                                child: Text(
                                  '${restTime}s',
                                  style: textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ),
                          const Spacer(),
                          if (sets.length > 1)
                            IconButton(
                              icon: const Icon(Icons.close, size: 20),
                              visualDensity: VisualDensity.compact,
                              color: colorScheme.error,
                              onPressed: () => _removeSet(index),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _addSet,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Set'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.timer_outlined),
              title: const Text('Rest Time Between Sets'),
              subtitle: Text('${restTime}s'),
              trailing: FilledButton.tonalIcon(
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Adjust'),
                onPressed: () => _showNumberDialog(
                  label: 'Rest',
                  currentValue: restTime,
                  min: 0,
                  max: 600,
                  suffix: 'sec',
                  onChanged: _updateRest,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
