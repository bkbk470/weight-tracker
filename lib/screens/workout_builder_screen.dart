import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import '../services/exercise_cache_service.dart';
import '../widgets/storage_image.dart';

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
  late TextEditingController searchController;
  late List<WorkoutExercise> exercises;
  String selectedCategory = 'All';
  String searchQuery = '';
  final categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Other'];

  // Load all exercises from database
  List<Map<String, dynamic>> allExercises = [];
  bool isLoadingExercises = true;

  @override
  void initState() {
    super.initState();
    // Initialize with workout data if editing, otherwise start fresh
    workoutNameController = TextEditingController(text: widget.workoutName ?? '');
    searchController = TextEditingController();
    exercises = widget.initialExercises?.map((e) => e.copy()).toList() ?? [];
    _loadAllExercises();
  }

  void _loadAllExercises() async {
    // Use cache service for fast loading (memory > local > remote)
    try {
      final exercises = await ExerciseCacheService.instance.getExercises();

      setState(() {
        allExercises = exercises.map((e) => {
          'name': e['name'] as String,
          'category': e['category'] as String,
          'image_url': e['image_url'] as String?,
          'equipment': e['equipment'] as String?,
        }).toList();
        isLoadingExercises = false;
      });
    } catch (e) {
      print('Failed to load exercises: $e');
      setState(() {
        isLoadingExercises = false;
      });
    }
  }

  @override
  void dispose() {
    workoutNameController.dispose();
    searchController.dispose();
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

  void _editSetWeight(int exerciseIndex, int setIndex) async {
    final currentWeight = exercises[exerciseIndex].sets[setIndex].weight;
    final result = await _showNumberDialog(
      title: 'Set Weight',
      label: 'Weight (lbs)',
      initialValue: currentWeight,
    );
    if (result != null) {
      setState(() {
        exercises[exerciseIndex].sets[setIndex].weight = result;
      });
    }
  }

  void _editSetReps(int exerciseIndex, int setIndex) async {
    final currentReps = exercises[exerciseIndex].sets[setIndex].reps;
    final result = await _showNumberDialog(
      title: 'Set Reps',
      label: 'Reps',
      initialValue: currentReps,
    );
    if (result != null) {
      setState(() {
        exercises[exerciseIndex].sets[setIndex].reps = result;
      });
    }
  }

  void _editRestTime(int exerciseIndex) async {
    final currentRest = exercises[exerciseIndex].restTime;
    final result = await _showNumberDialog(
      title: 'Rest Time',
      label: 'Rest (seconds)',
      initialValue: currentRest,
    );
    if (result != null) {
      setState(() {
        exercises[exerciseIndex].restTime = result;
      });
    }
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = exercises[exerciseIndex];
      final template = exercise.sets.isNotEmpty
          ? exercise.sets.last
          : WorkoutExerciseSet(weight: 0, reps: 10);
      exercise.sets.add(WorkoutExerciseSet(
        weight: template.weight,
        reps: template.reps,
      ));
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    if (exercises[exerciseIndex].sets.length <= 1) return;
    setState(() {
      exercises[exerciseIndex].sets.removeAt(setIndex);
    });
  }

  Future<int?> _showNumberDialog({
    required String title,
    required String label,
    required int initialValue,
  }) async {
    final controller = TextEditingController(text: initialValue.toString());
    final result = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              Navigator.pop(context, value);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
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

  void _showAddExerciseModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddExerciseModal(
        allExercises: allExercises,
        isLoadingExercises: isLoadingExercises,
        onAddExercise: (exercise) {
          addExercise(exercise);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredExercises = allExercises.where((e) {
      final matchesCategory = selectedCategory == 'All' || e['category'] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          (e['name'] as String).toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

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

          // Empty state or Add Exercise button
          Expanded(
            child: exercises.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fitness_center,
                          size: 80,
                          color: colorScheme.primary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No exercises added yet',
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap the button below to add exercises',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurface.withOpacity(0.4),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ElevatedButton.icon(
                          onPressed: _showAddExerciseModal,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Exercise'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: exercises.length + 1,
                    itemBuilder: (context, index) {
                      if (index == exercises.length) {
                        // Add Exercise button at the end
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: OutlinedButton.icon(
                            onPressed: _showAddExerciseModal,
                            icon: const Icon(Icons.add),
                            label: const Text('Add Another Exercise'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        );
                      }

                      final exercise = exercises[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Exercise header
                              Row(
                                children: [
                                  Icon(Icons.drag_handle, color: colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      exercise.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
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
                              const SizedBox(height: 12),

                              // Sets list
                              ...List.generate(exercise.sets.length, (setIndex) {
                                final set = exercise.sets[setIndex];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: colorScheme.surfaceVariant.withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 32,
                                                  height: 32,
                                                  decoration: BoxDecoration(
                                                    color: colorScheme.primary.withOpacity(0.1),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Center(
                                                    child: Text(
                                                      '${setIndex + 1}',
                                                      style: textTheme.labelLarge?.copyWith(
                                                        color: colorScheme.primary,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 16),
                                                Expanded(
                                                  child: Row(
                                                    children: [
                                                      InkWell(
                                                        onTap: () => _editSetWeight(index, setIndex),
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.fitness_center, size: 16, color: colorScheme.onSurfaceVariant),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${set.weight} lbs',
                                                                style: textTheme.bodyMedium?.copyWith(
                                                                  color: colorScheme.primary,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 8),
                                                      InkWell(
                                                        onTap: () => _editSetReps(index, setIndex),
                                                        borderRadius: BorderRadius.circular(8),
                                                        child: Padding(
                                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                          child: Row(
                                                            mainAxisSize: MainAxisSize.min,
                                                            children: [
                                                              Icon(Icons.repeat, size: 16, color: colorScheme.onSurfaceVariant),
                                                              const SizedBox(width: 4),
                                                              Text(
                                                                '${set.reps} reps',
                                                                style: textTheme.bodyMedium?.copyWith(
                                                                  color: colorScheme.primary,
                                                                  fontWeight: FontWeight.w500,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        if (exercise.sets.length > 1)
                                          IconButton(
                                            icon: Icon(Icons.remove_circle_outline, color: colorScheme.error),
                                            onPressed: () => _removeSet(index, setIndex),
                                            padding: const EdgeInsets.all(8),
                                            constraints: const BoxConstraints(),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              }),

                              // Add Set button
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const SizedBox(width: 44),
                                  TextButton.icon(
                                    onPressed: () => _addSet(index),
                                    icon: const Icon(Icons.add_circle_outline, size: 18),
                                    label: const Text('Add Set'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                  ),
                                ],
                              ),

                              // Rest time
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _editRestTime(index),
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 44, vertical: 8),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.timer_outlined, size: 16, color: colorScheme.onSurfaceVariant),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Rest: ${exercise.restTime}s',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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

class _AddExerciseModal extends StatefulWidget {
  final List<Map<String, dynamic>> allExercises;
  final bool isLoadingExercises;
  final Function(Map<String, dynamic>) onAddExercise;

  const _AddExerciseModal({
    required this.allExercises,
    required this.isLoadingExercises,
    required this.onAddExercise,
  });

  @override
  State<_AddExerciseModal> createState() => _AddExerciseModalState();
}

class _AddExerciseModalState extends State<_AddExerciseModal> {
  final searchController = TextEditingController();
  String selectedCategory = 'All';
  String searchQuery = '';
  final categories = ['All', 'Chest', 'Back', 'Legs', 'Shoulders', 'Arms', 'Core', 'Cardio', 'Other'];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get filteredExercises {
    return widget.allExercises.where((e) {
      final matchesCategory = selectedCategory == 'All' || e['category'] == selectedCategory;
      final matchesSearch = searchQuery.isEmpty ||
          (e['name'] as String).toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Add Exercise',
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Search Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

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

              // Exercise count
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${filteredExercises.length} exercises',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),

              // Exercise Library
              Expanded(
                child: widget.isLoadingExercises
                    ? const Center(child: CircularProgressIndicator())
                    : filteredExercises.isEmpty
                        ? Center(
                            child: Text(
                              'No exercises found',
                              style: textTheme.bodyLarge,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: filteredExercises.length,
                            itemBuilder: (context, index) {
                              final exercise = filteredExercises[index];

                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: ListTile(
                                  leading: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: StorageImage(
                                      imageUrl: exercise['image_url'] as String?,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  title: Text(exercise['name'] as String),
                                  subtitle: Text(exercise['category'] as String),
                                  trailing: const Icon(Icons.add_circle_outline),
                                  onTap: () => widget.onAddExercise(exercise),
                                ),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
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
