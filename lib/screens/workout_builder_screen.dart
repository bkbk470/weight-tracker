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
          (index) => WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: 120),
        ),
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

  void _updateSetWeight(int exerciseIndex, int setIndex, int value) {
    setState(() {
      exercises[exerciseIndex].sets[setIndex].weight = value;
    });
  }

  void _updateSetReps(int exerciseIndex, int setIndex, int value) {
    setState(() {
      exercises[exerciseIndex].sets[setIndex].reps = value;
    });
  }

  void _updateRestTime(int exerciseIndex, int setIndex, int value) {
    setState(() {
      exercises[exerciseIndex].sets[setIndex].restSeconds = value;
    });
  }

  void _updateNotes(int exerciseIndex, String value) {
    setState(() {
      exercises[exerciseIndex].notes = value;
    });
  }

  void _addSet(int exerciseIndex) {
    setState(() {
      final exercise = exercises[exerciseIndex];
      final template = exercise.sets.isNotEmpty
          ? exercise.sets.last
          : WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: 90);
      exercise.sets.add(WorkoutExerciseSet(
        weight: template.weight,
        reps: template.reps,
        restSeconds: template.restSeconds,
      ));
    });
  }

  void _removeSet(int exerciseIndex, int setIndex) {
    if (exercises[exerciseIndex].sets.length <= 1) return;
    setState(() {
      exercises[exerciseIndex].sets.removeAt(setIndex);
    });
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

      // Fetch all exercises once, outside the loop for better performance
      // Use ExerciseCacheService for faster loading
      print('⏱️  Fetching exercises list...');
      final existingExercises = await ExerciseCacheService.instance.getExercises();
      print('✅ Fetched ${existingExercises.length} exercises from cache');

      // Prepare all workout_exercises data for batch insert
      print('📦 Preparing ${exercises.length} exercises for batch save...');
      final workoutExercisesData = <Map<String, dynamic>>[];

      for (int i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];

        try {
          // Find the exercise in the already-fetched list
          final matchingExercise = existingExercises.firstWhere(
            (e) => e['name'] == exercise.name,
            orElse: () => {},
          );

          String exerciseId;
          if (matchingExercise.isNotEmpty && matchingExercise['id'] != null) {
            exerciseId = matchingExercise['id'];
          } else {
            // Create the exercise if it doesn't exist (these are rare, so OK to do sequentially)
            final newExercise = await SupabaseService.instance.createExercise(
              name: exercise.name,
              category: 'Other',
              difficulty: 'Intermediate',
              equipment: 'Various',
            );
            exerciseId = newExercise['id'];
            existingExercises.add(newExercise);
          }

          // Prepare set details
          final setDetails = exercise.sets.map((set) => {
            'weight': set.weight,
            'reps': set.reps,
            'rest_time': set.restSeconds,
          }).toList();

          final restTimeSeconds = exercise.sets.isNotEmpty ? exercise.sets.first.restSeconds : 90;

          // Add to batch data
          workoutExercisesData.add({
            'workout_id': workoutId,
            'exercise_id': exerciseId,
            'order_index': i,
            'target_sets': exercise.sets.length,
            'target_reps': exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0,
            'rest_time_seconds': restTimeSeconds,
            'set_details': setDetails,  // Include set_details in the initial insert!
          });
        } catch (e) {
          print('❌ Error preparing exercise ${exercise.name}: $e');
        }
      }

      // Batch insert all workout_exercises in a SINGLE database call
      if (workoutExercisesData.isNotEmpty) {
        print('💾 Saving ${workoutExercisesData.length} exercises in one batch...');
        await SupabaseService.instance.client
            .from('workout_exercises')
            .insert(workoutExercisesData);
        print('✅ All exercises saved!');
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

                      return _ExerciseBuilderCard(
                        key: ValueKey('exercise_$index'),
                        exercise: exercise,
                        exerciseIndex: index,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                        onUpdateWeight: (setIndex, value) => _updateSetWeight(index, setIndex, value),
                        onUpdateReps: (setIndex, value) => _updateSetReps(index, setIndex, value),
                        onUpdateRestTime: (setIndex, value) => _updateRestTime(index, setIndex, value),
                        onUpdateNotes: (value) => _updateNotes(index, value),
                        onAddSet: () => _addSet(index),
                        onRemoveSet: (setIndex) => _removeSet(index, setIndex),
                        onDelete: () => removeExercise(index),
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
  String notes;

  WorkoutExercise({
    required this.name,
    required List<WorkoutExerciseSet> sets,
    this.notes = '',
  }) : sets = sets.map((set) => set.copy()).toList();

  WorkoutExercise copy() {
    return WorkoutExercise(
      name: name,
      sets: sets.map((set) => set.copy()).toList(),
      notes: notes,
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
    this.restSeconds = 90,
  });

  WorkoutExerciseSet copy() => WorkoutExerciseSet(
    weight: weight,
    reps: reps,
    restSeconds: restSeconds,
  );
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
      sets = [WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: 90)];
    }
    restTime = sets.isNotEmpty ? sets.first.restSeconds : 90;
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
      // Update all sets with the new rest time
      for (var set in sets) {
        set.restSeconds = value;
      }
    });
  }

  void _addSet() {
    setState(() {
      final template = sets.isNotEmpty ? sets.last : WorkoutExerciseSet(weight: 0, reps: 10, restSeconds: restTime);
      sets.add(WorkoutExerciseSet(
        weight: template.weight,
        reps: template.reps,
        restSeconds: restTime,
      ));
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
        notes: widget.exercise.notes,
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

class _ExerciseBuilderCard extends StatefulWidget {
  final WorkoutExercise exercise;
  final int exerciseIndex;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final void Function(int setIndex, int value) onUpdateWeight;
  final void Function(int setIndex, int value) onUpdateReps;
  final void Function(int setIndex, int value) onUpdateRestTime;
  final ValueChanged<String> onUpdateNotes;
  final VoidCallback onAddSet;
  final void Function(int setIndex) onRemoveSet;
  final VoidCallback onDelete;

  const _ExerciseBuilderCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.colorScheme,
    required this.textTheme,
    required this.onUpdateWeight,
    required this.onUpdateReps,
    required this.onUpdateRestTime,
    required this.onUpdateNotes,
    required this.onAddSet,
    required this.onRemoveSet,
    required this.onDelete,
  });

  @override
  State<_ExerciseBuilderCard> createState() => _ExerciseBuilderCardState();
}

class _ExerciseBuilderCardState extends State<_ExerciseBuilderCard> {
  late List<TextEditingController> weightControllers;
  late List<TextEditingController> repsControllers;
  late List<TextEditingController> restControllers;
  late TextEditingController notesController;

  @override
  void initState() {
    super.initState();
    _initControllers();
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
    notesController = TextEditingController(text: widget.exercise.notes);
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
  void didUpdateWidget(covariant _ExerciseBuilderCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (weightControllers.length != widget.exercise.sets.length) {
      _disposeSetControllers();
      weightControllers = widget.exercise.sets
          .map((set) => TextEditingController(text: set.weight.toString()))
          .toList();
      repsControllers = widget.exercise.sets
          .map((set) => TextEditingController(text: set.reps.toString()))
          .toList();
      restControllers = widget.exercise.sets
          .map((set) => TextEditingController(text: set.restSeconds.toString()))
          .toList();
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
                  icon: const Icon(Icons.delete_outline),
                  onPressed: widget.onDelete,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Column headers
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 28,
                    child: Text(
                      '#',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Weight',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Reps',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Rest',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Sets list with TextFormFields
            ...exercise.sets.asMap().entries.map((entry) {
              final setIndex = entry.key;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest,
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
                            widget.onUpdateRestTime(setIndex, parsed);
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

            // Add Set button
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: widget.onAddSet,
                icon: const Icon(Icons.add),
                label: const Text('Add Set'),
              ),
            ),

            const SizedBox(height: 12),

            // Notes field
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
        ),
      ),
    );
  }
}
