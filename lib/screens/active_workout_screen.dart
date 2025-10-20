import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/local_storage_service.dart';
import '../services/workout_timer_service.dart';
import '../services/supabase_service.dart';
import '../widgets/editable_number_field.dart';

class WorkoutScreen extends StatefulWidget {
  final Function(String) onNavigate;
  final bool autoStart;
  final String? workoutName;
  final String? workoutId;
  final Function(bool, int)? onWorkoutStateChanged;
  final List<Map<String, dynamic>>? preloadedExercises;

  const WorkoutScreen({
    super.key,
    required this.onNavigate,
    this.autoStart = false,
    this.workoutName,
    this.workoutId,
    this.onWorkoutStateChanged,
    this.preloadedExercises,
  });

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  bool isWorkoutActive = false;
  final WorkoutTimerService _timerService = WorkoutTimerService.instance;
  int workoutTime = 0;
  int restTimer = 0;
  int maxRestTime = 0;
  bool isResting = false;
  Timer? restTimerInstance;

  List<Exercise> exercises = [];

  @override
  void initState() {
    super.initState();
    
    // Set up timer listener
    _timerService.addListener(_onTimerUpdate);
    workoutTime = _timerService.elapsedSeconds;
    
    // Load preloaded exercises if provided
    if (widget.preloadedExercises != null) {
      exercises = widget.preloadedExercises!.asMap().entries.map((entry) {
        final index = entry.key;
        final ex = entry.value;
        final dynamicSetDetails = ex['setDetails'];
        List<ExerciseSet> plannedSets;
        if (dynamicSetDetails is List && dynamicSetDetails.isNotEmpty) {
          plannedSets = dynamicSetDetails.map((set) {
            final weightRaw = set is Map ? set['weight'] : null;
            final repsRaw = set is Map ? set['reps'] : null;
            final restRaw = set is Map ? (set['rest'] ?? set['restTime'] ?? set['rest_seconds']) : null;
            final weight = weightRaw is num
                ? weightRaw.toInt()
                : int.tryParse('$weightRaw') ?? 0;
            final reps = repsRaw is num
                ? repsRaw.toInt()
                : int.tryParse('$repsRaw') ?? (ex['reps'] ?? 10);
            final rest = restRaw is num
                ? restRaw.toInt()
                : int.tryParse('$restRaw') ?? (ex['restTime'] ?? 120);
            final exerciseSet = ExerciseSet(weight: weight, reps: reps);
            exerciseSet.plannedRestSeconds = rest;
            exerciseSet.restStartTime = rest;
            exerciseSet.currentRestTime = rest;
            return exerciseSet;
          }).toList();
        } else {
          final reps = ex['reps'] is num ? (ex['reps'] as num).toInt() : int.tryParse('${ex['reps']}') ?? 10;
          final setsCount = ex['sets'] is num ? (ex['sets'] as num).toInt() : int.tryParse('${ex['sets']}') ?? 3;
          final defaultRest = ex['restTime'] is num
              ? (ex['restTime'] as num).toInt()
              : int.tryParse('${ex['restTime']}') ?? 120;
          plannedSets = List.generate(setsCount, (_) {
            final set = ExerciseSet(weight: 0, reps: reps);
            set.plannedRestSeconds = defaultRest;
            set.restStartTime = defaultRest;
            set.currentRestTime = defaultRest;
            return set;
          });
        }

        return Exercise(
          id: '${DateTime.now().millisecondsSinceEpoch}_${ex['name']}_$index',  // Unique ID with index
          name: ex['name'],
          sets: plannedSets,
          restTime: plannedSets.isNotEmpty
              ? (plannedSets.first.restStartTime > 0
                  ? plannedSets.first.restStartTime
                  : (ex['restTime'] ?? 120))
              : (ex['restTime'] ?? 120),
          notes: (ex['notes'] as String?) ?? '',
          workoutExerciseId: ex['workoutExerciseId'] as String?,
          supabaseExerciseId: ex['exerciseId'] as String?,
          orderIndex: ex['orderIndex'] as int?,
        );
      }).toList();
    }

    Future.microtask(() => _loadPreviousExerciseData());
    
    if (widget.autoStart) {
      // Start workout after build completes
      WidgetsBinding.instance.addPostFrameCallback((_) {
        startWorkout();
      });
    }
  }

  void _onTimerUpdate(int seconds) {
    if (mounted) {
      setState(() {
        workoutTime = seconds;
      });
      widget.onWorkoutStateChanged?.call(true, workoutTime);
    }
  }

  @override
  void didUpdateWidget(WorkoutScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update workout time from service when returning to screen
    if (mounted) {
      setState(() {
        workoutTime = _timerService.elapsedSeconds;
      });
    }
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerUpdate);
    restTimerInstance?.cancel();
    super.dispose();
  }

  Future<void> _loadPreviousExerciseData() async {
    if (!mounted) return;
    if (SupabaseService.instance.currentUserId == null) return;

    for (var i = 0; i < exercises.length; i++) {
      unawaited(_loadPreviousForExercise(exercises[i], i));
    }
  }

  Future<bool> _ensureWorkoutExerciseMetadata(Exercise exercise, int orderIndex, {bool createIfMissing = false}) async {
    if (exercise.supabaseExerciseId == null) {
      try {
        exercise.supabaseExerciseId = await SupabaseService.instance.getOrCreateExerciseId(
          name: exercise.name,
          category: 'Other',
          notes: exercise.notes.isEmpty ? null : exercise.notes,
        );
      } catch (e) {
        print('Failed to ensure exercise id for ${exercise.name}: $e');
      }
    }

    if (widget.workoutId == null) {
      return exercise.supabaseExerciseId != null;
    }

    if (exercise.workoutExerciseId == null && exercise.supabaseExerciseId != null) {
      try {
        final row = await SupabaseService.instance.getWorkoutExerciseRow(
          workoutId: widget.workoutId!,
          exerciseId: exercise.supabaseExerciseId,
          orderIndex: exercise.orderIndex ?? orderIndex,
        );
        if (row != null && row['id'] != null) {
          exercise.workoutExerciseId = row['id'] as String?;
          exercise.orderIndex = row['order_index'] as int? ?? orderIndex;
        }
      } catch (e) {
        print('Failed to look up workout exercise ${exercise.name}: $e');
      }
    }

    if (exercise.workoutExerciseId == null && createIfMissing && exercise.supabaseExerciseId != null) {
      try {
        final inserted = await SupabaseService.instance.addExerciseToWorkout(
          workoutId: widget.workoutId!,
          exerciseId: exercise.supabaseExerciseId!,
          orderIndex: exercise.orderIndex ?? orderIndex,
          targetSets: exercise.sets.length,
          targetReps: exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0,
          restTimeSeconds: exercise.restTime,
          notes: exercise.notes.isEmpty ? null : exercise.notes,
        );
        exercise.workoutExerciseId = inserted['id'] as String?;
        exercise.orderIndex = inserted['order_index'] as int? ?? orderIndex;
      } catch (e) {
        print('Failed to insert workout exercise ${exercise.name}: $e');
      }
    }

    if (widget.workoutId != null && exercise.workoutExerciseId == null) {
      return false;
    }

    return exercise.supabaseExerciseId != null;
  }

  Future<void> _loadPreviousForExercise(Exercise exercise, int orderIndex) async {
    if (SupabaseService.instance.currentUserId == null) {
      if (mounted) {
        _applyLocalHistoryIfMissing(exercise);
      }
      return;
    }
    final ensured = await _ensureWorkoutExerciseMetadata(exercise, orderIndex, createIfMissing: false);
    if (!ensured || exercise.supabaseExerciseId == null) return;

    try {
      final records = await SupabaseService.instance.getLatestExerciseSetsForExercise(
        exercise.supabaseExerciseId!,
        historyLimit: exercise.sets.length + 5,
      );
      if (!mounted) return;
      if (records.isEmpty) {
        setState(() {
          exercise.previousDate = null;
          for (final set in exercise.sets) {
            set.previousWeight = null;
            set.previousReps = null;
          }
        });
        return;
      }

      final Map<int, Map<String, dynamic>> bySetNumber = {};
      for (final record in records) {
        final setNumber = record['set_number'];
        if (setNumber is int) {
          bySetNumber[setNumber] = record;
        } else if (setNumber is num) {
          bySetNumber[setNumber.toInt()] = record;
        }
      }

      final createdAt = records.first['created_at'] as String?;
      setState(() {
        exercise.previousDate = createdAt != null ? DateTime.tryParse(createdAt) : exercise.previousDate;
        for (var i = 0; i < exercise.sets.length; i++) {
          final set = exercise.sets[i];
          final record = bySetNumber[i + 1];
          if (record != null) {
            final weightValue = record['weight_lbs'];
            final previousWeight = weightValue is num ? weightValue.toDouble() : double.tryParse(weightValue?.toString() ?? '');
            set.previousWeight = previousWeight;
            
            // Auto-fill weight with previous weight if current weight is 0
            if (set.weight == 0 && previousWeight != null && previousWeight > 0) {
              set.weight = previousWeight.round();
            }
            
            final repsValue = record['reps'];
            set.previousReps = repsValue is int ? repsValue : int.tryParse(repsValue?.toString() ?? '');
          } else {
            set.previousWeight = null;
            set.previousReps = null;
          }
        }
      });
    } catch (e) {
      print('Failed to load previous sets for ${exercise.name}: $e');
    }

    if (widget.workoutId != null) {
      unawaited(_syncWorkoutExerciseTemplate(exercise, orderIndex));
    }

    if (mounted) {
      _applyLocalHistoryIfMissing(exercise);
    }
  }

  void _applyLocalHistoryIfMissing(Exercise exercise) {
    final hasPrevious = exercise.sets.any((set) => set.previousWeight != null || set.previousReps != null);
    if (hasPrevious) return;

    final localStorage = LocalStorageService.instance;
    final keys = <String>{
      if (exercise.supabaseExerciseId != null) exercise.supabaseExerciseId!,
      if (exercise.name.trim().isNotEmpty) 'name:${exercise.name.trim().toLowerCase()}',
    };

    for (final key in keys) {
      final record = localStorage.getLatestExerciseHistory(key);
      if (record == null) continue;

      final setsData = record['sets'];
      final dateStr = record['date'] as String?;
      setState(() {
        if (dateStr != null) {
          exercise.previousDate = DateTime.tryParse(dateStr) ?? exercise.previousDate;
        }
        if (setsData is List) {
          for (var i = 0; i < exercise.sets.length; i++) {
            if (i >= setsData.length) break;
            final data = setsData[i];
            if (data is Map) {
              final weightRaw = data['weight'];
              final repsRaw = data['reps'];
              final previousWeight = weightRaw is num ? weightRaw.toDouble() : double.tryParse('${weightRaw ?? ''}');
              exercise.sets[i].previousWeight = previousWeight;
              
              // Auto-fill weight with previous weight if current weight is 0
              if (exercise.sets[i].weight == 0 && previousWeight != null && previousWeight > 0) {
                exercise.sets[i].weight = previousWeight.round();
              }
              
              exercise.sets[i].previousReps = repsRaw is int ? repsRaw : int.tryParse('${repsRaw ?? ''}');
            }
          }
        }
      });
      break;
    }
  }

  void startWorkout() {
    setState(() => isWorkoutActive = true);
    _timerService.start();
  }

  void minimizeWorkout() {
    widget.onWorkoutStateChanged?.call(true, workoutTime);
    widget.onNavigate('dashboard');
  }

  void endWorkout() {
    final hasIncompleteSets = exercises.any((exercise) =>
        exercise.sets.any((set) => !set.completed));

    void showFinishDialog({required bool warnIncomplete}) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(warnIncomplete ? 'Unfinished Sets' : 'Finish Workout?'),
          content: Text(
            warnIncomplete
                ? 'Some sets are not marked complete. What would you like to do?'
                : 'Great work! Ready to finish this workout?',
          ),
          actionsAlignment: warnIncomplete ? MainAxisAlignment.center : null,
          actionsPadding: warnIncomplete ? const EdgeInsets.fromLTRB(24, 0, 24, 16) : null,
          actions: warnIncomplete ? [
            // Keep Working - Primary action
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  _timerService.resume();
                  Navigator.pop(dialogContext);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text('Keep Working'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.primaryContainer,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Finish - Secondary action
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  if (mounted) {
                    setState(() {
                      for (final exercise in exercises) {
                        for (final set in exercise.sets) {
                          if (!set.completed) {
                            set.completed = true;
                          }
                        }
                      }
                    });
                  }

                  // Save workout to Supabase
                  final saved = await _saveWorkoutToDatabase();
                  if (saved) {
                    await _maybePromptSaveTemplate();
                  }

                  _timerService.reset();
                  widget.onWorkoutStateChanged?.call(false, 0);
                  widget.onNavigate('dashboard');
                },
                icon: const Icon(Icons.check),
                label: const Text('Finish Anyway'),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(dialogContext).colorScheme.secondaryContainer,
                  foregroundColor: Theme.of(dialogContext).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Cancel Workout - Destructive action
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _timerService.reset();
                  widget.onWorkoutStateChanged?.call(false, 0);
                  widget.onNavigate('dashboard');
                },
                icon: const Icon(Icons.close),
                label: const Text('Cancel Workout'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                  side: BorderSide(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ),
          ] : [
            TextButton(
              onPressed: () {
                _timerService.resume();
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);

                // Save workout to Supabase
                final saved = await _saveWorkoutToDatabase();
                if (saved) {
                  await _maybePromptSaveTemplate();
                }

                _timerService.reset();
                widget.onWorkoutStateChanged?.call(false, 0);
                widget.onNavigate('dashboard');
              },
              child: const Text('Finish'),
            ),
          ],
        ),
      );
    }

    _timerService.pause();
    restTimerInstance?.cancel();

    if (hasIncompleteSets) {
      showFinishDialog(warnIncomplete: true);
    } else {
      showFinishDialog(warnIncomplete: false);
    }
  }

  Future<bool> _saveWorkoutToDatabase() async {
    final endTime = DateTime.now();
    final startTime = endTime.subtract(Duration(seconds: workoutTime));

    try {
      if (widget.workoutId != null) {
        await _syncAllWorkoutExercises();
      }

      // Create workout log
      final workoutLog = await SupabaseService.instance.createWorkoutLog(
        workoutId: widget.workoutId,
        workoutName: widget.workoutName ?? 'Workout',
        startTime: startTime,
        endTime: endTime,
        durationSeconds: workoutTime,
        notes: 'Workout completed',
      );

      // Cache of known exercise IDs keyed by lowercase name
      final Map<String, String> exerciseIdCache = {};
      try {
        final existingExercises = await SupabaseService.instance.getExercises();
        for (final exercise in existingExercises) {
          final name = (exercise['name'] as String?)?.toLowerCase();
          final id = exercise['id'] as String?;
          if (name != null && id != null && name.isNotEmpty) {
            exerciseIdCache[name] = id;
          }
        }
      } catch (e) {
        print('Warning: Failed to preload exercise list: $e');
      }

      // Save each exercise set
      for (var exercise in exercises) {
        final normalizedName = exercise.name.trim().toLowerCase();
        if (normalizedName.isEmpty) {
          continue;
        }

        String? exerciseId = exerciseIdCache[normalizedName];
        if (exerciseId == null) {
          try {
            exerciseId = await SupabaseService.instance.getOrCreateExerciseId(
              name: exercise.name.trim(),
              notes: exercise.notes.isEmpty ? null : exercise.notes,
            );
            exerciseIdCache[normalizedName] = exerciseId;
          } catch (e) {
            print('Error ensuring exercise "${exercise.name}" exists: $e');
            continue;
          }
        }

        for (int i = 0; i < exercise.sets.length; i++) {
          final set = exercise.sets[i];
          if (set.completed) {
            await SupabaseService.instance.addExerciseSet(
              workoutLogId: workoutLog['id'],
              exerciseId: exerciseId,
              exerciseName: exercise.name,
              setNumber: i + 1,
              weightLbs: set.weight > 0 ? set.weight.toDouble() : null,
              reps: set.reps > 0 ? set.reps : null,
              completed: true,
              restTimeSeconds: set.plannedRestSeconds > 0 ? set.plannedRestSeconds : exercise.restTime,
              notes: exercise.notes.isEmpty ? null : exercise.notes,
            );
          }
        }
      }

      // Also save to local storage for offline access
      await LocalStorageService.instance.saveWorkout({
        'id': workoutLog['id'],
        'name': widget.workoutName ?? 'Workout',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'duration': workoutTime,
        'exercises': exercises.length,
      });

      await _saveExerciseHistoryLocally(endTime);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Workout saved successfully! ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      print('Error saving workout: $e');
      
      // Save to local storage if Supabase fails
      try {
        await LocalStorageService.instance.saveWorkout({
          'id': DateTime.now().toString(),
          'name': widget.workoutName ?? 'Workout',
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'duration': workoutTime,
          'exercises': exercises.length,
        });

        await _saveExerciseHistoryLocally(endTime);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Workout saved offline. Will sync when online.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving workout: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    }
  }

  Future<void> _syncAllWorkoutExercises() async {
    if (widget.workoutId == null) return;
    final futures = <Future<void>>[];
    for (var i = 0; i < exercises.length; i++) {
      futures.add(_syncWorkoutExerciseTemplate(exercises[i], i));
    }
    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _syncWorkoutExerciseTemplate(Exercise exercise, int orderIndex) async {
    if (widget.workoutId == null) return;
    final ensured = await _ensureWorkoutExerciseMetadata(exercise, orderIndex, createIfMissing: true);
    if (!ensured || exercise.workoutExerciseId == null) return;

    final targetReps = exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0;
    final restSeconds = exercise.sets.isNotEmpty
        ? (exercise.sets.first.plannedRestSeconds > 0
            ? exercise.sets.first.plannedRestSeconds
            : exercise.restTime)
        : exercise.restTime;
    exercise.restTime = restSeconds;
    try {
      final trimmedNotes = exercise.notes.trim();
      await SupabaseService.instance.updateWorkoutExercise(
        exercise.workoutExerciseId!,
        {
          'target_sets': exercise.sets.length,
          'target_reps': targetReps,
          'rest_time_seconds': restSeconds,
          'notes': trimmedNotes.isEmpty ? null : trimmedNotes,
        },
      );
    } catch (e) {
      print('Failed to sync workout exercise ${exercise.name}: $e');
    }
  }

  Future<void> _saveExerciseHistoryLocally(DateTime date) async {
    final localStorage = LocalStorageService.instance;
    final List<Future<void>> futures = [];

    for (final exercise in exercises) {
      final completedSets = exercise.sets.where((set) => set.completed).toList();
      if (completedSets.isEmpty) continue;

      final normalizedName = exercise.name.trim().toLowerCase();
      final record = <String, dynamic>{
        'date': date.toIso8601String(),
        'sets': completedSets
            .map((set) => {
                  'weight': set.weight,
                  'reps': set.reps,
                  'rest': set.plannedRestSeconds > 0 ? set.plannedRestSeconds : exercise.restTime,
                })
            .toList(),
        if (exercise.notes.trim().isNotEmpty) 'notes': exercise.notes.trim(),
      };

      final keys = <String>{
        if (exercise.supabaseExerciseId != null) exercise.supabaseExerciseId!,
        if (exercise.workoutExerciseId != null) 'workout:${exercise.workoutExerciseId!}',
        if (normalizedName.isNotEmpty) 'name:$normalizedName',
      };

      for (final key in keys) {
        futures.add(localStorage.saveExerciseHistory(key, Map<String, dynamic>.from(record)));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _maybePromptSaveTemplate() async {
    if (widget.workoutId != null) return;
    if (exercises.isEmpty) return;
    final hasLoggedSets = exercises.any((exercise) => exercise.sets.any((set) => set.completed));
    if (!hasLoggedSets) return;
    if (SupabaseService.instance.currentUserId == null) return;
    if (!mounted) return;

    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save as Template?'),
        content: const Text('Would you like to save this workout as a reusable template?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (shouldSave == true && mounted) {
      await _promptTemplateNameAndSave();
    }
  }

  Future<void> _promptTemplateNameAndSave() async {
    if (SupabaseService.instance.currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login required to save templates.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final baseName = (widget.workoutName?.trim().isNotEmpty ?? false)
        ? widget.workoutName!.trim()
        : 'Workout';
    final defaultName = baseName.startsWith('Copy of ')
        ? baseName
        : 'Copy of $baseName';

    final controller = TextEditingController(text: defaultName);
    String? errorText;
    bool isSaving = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: !isSaving,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Save Template'),
              content: TextField(
                controller: controller,
                enabled: !isSaving,
                decoration: InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'e.g., Full Body Routine',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          final name = controller.text.trim();
                          if (name.isEmpty) {
                            setStateDialog(() {
                              errorText = 'Please enter a name';
                            });
                            return;
                          }
                          setStateDialog(() {
                            errorText = null;
                            isSaving = true;
                          });
                          final success = await _saveCurrentWorkoutAsTemplate(name);
                          if (success && context.mounted) {
                            Navigator.pop(dialogContext);
                          } else {
                            setStateDialog(() {
                              isSaving = false;
                              errorText = success ? null : 'Failed to save template';
                            });
                          }
                        },
                  child: isSaving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(context).colorScheme.onPrimary,
                          ),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    controller.dispose();
  }

  Future<bool> _saveCurrentWorkoutAsTemplate(String name) async {
    try {
      final newWorkout = await SupabaseService.instance.createWorkout(
        name: name,
        description: widget.workoutName ?? 'Workout template created from session',
        difficulty: null,
        estimatedDurationMinutes: null,
      );

      for (var i = 0; i < exercises.length; i++) {
        final exercise = exercises[i];
        String? exerciseId = exercise.supabaseExerciseId;
        exerciseId ??= await SupabaseService.instance.getOrCreateExerciseId(
          name: exercise.name,
          category: 'Other',
          notes: exercise.notes.isEmpty ? null : exercise.notes,
        );

        if (exerciseId == null) continue;

        final targetSets = exercise.sets.isNotEmpty ? exercise.sets.length : 3;
        final targetReps = exercise.sets.isNotEmpty ? exercise.sets.first.reps : 10;
        final restSeconds = exercise.sets.isNotEmpty
            ? (exercise.sets.first.plannedRestSeconds > 0
                ? exercise.sets.first.plannedRestSeconds
                : exercise.restTime)
            : exercise.restTime;

        await SupabaseService.instance.addExerciseToWorkout(
          workoutId: newWorkout['id'] as String,
          exerciseId: exerciseId,
          orderIndex: i,
          targetSets: targetSets,
          targetReps: targetReps,
          restTimeSeconds: restSeconds,
          notes: exercise.notes.isEmpty ? null : exercise.notes,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "$name" saved to My Workouts'),
            backgroundColor: Colors.green,
          ),
        );
      }
      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save template: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  void addExercise() {
    final parentContext = context;
    showDialog(
      context: parentContext,
      builder: (dialogContext) => _SelectExerciseDialog(
        onAdd: (name, category) async {
          final newExerciseIndex = exercises.length;
          final normalizedCategory = category.trim().isEmpty ? 'Other' : category.trim();
          final newExercise = Exercise(
            id: DateTime.now().toString(),
            name: name,
            sets: [] ,
            restTime: 120,
            orderIndex: newExerciseIndex,
          );

          final initialSet = ExerciseSet(weight: 0, reps: 10);
          initialSet.plannedRestSeconds = newExercise.restTime;
          initialSet.restStartTime = newExercise.restTime;
          initialSet.currentRestTime = newExercise.restTime;
          newExercise.sets.add(initialSet);

          setState(() {
            exercises.add(newExercise);
          });

          if (widget.workoutId != null) {
            try {
              final exerciseId = await SupabaseService.instance.getOrCreateExerciseId(
                name: name,
                category: normalizedCategory,
                notes: null,
              );

              final insertedWorkoutExercise = await SupabaseService.instance.addExerciseToWorkout(
                workoutId: widget.workoutId!,
                exerciseId: exerciseId,
                orderIndex: newExerciseIndex,
                targetSets: newExercise.sets.length,
                targetReps: newExercise.sets.first.reps,
                restTimeSeconds: newExercise.restTime,
                notes: newExercise.notes.trim().isEmpty ? null : newExercise.notes.trim(),
              );

              newExercise.workoutExerciseId = insertedWorkoutExercise['id'] as String?;
              newExercise.supabaseExerciseId = exerciseId;
              newExercise.orderIndex = insertedWorkoutExercise['order_index'] as int? ?? newExerciseIndex;

              if (mounted) {
                final index = exercises.indexWhere((e) => e.id == newExercise.id);
                if (index != -1) {
                  newExercise.orderIndex = index;
                  unawaited(_syncWorkoutExerciseTemplate(newExercise, index));
                  unawaited(_loadPreviousForExercise(newExercise, index));
                }
              }

              if (mounted) {
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('$name added to workout'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  exercises.removeAt(newExerciseIndex);
                });
                ScaffoldMessenger.of(parentContext).showSnackBar(
                  SnackBar(
                    content: Text('Failed to save $name to workout: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return false;
            }
          }
          return true;
        },
      ),
    );
  }

  void addSet(String exerciseId) {
    final exerciseIndex = exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;

    setState(() {
      final lastSet = exercises[exerciseIndex].sets.last;
      final plannedRest = lastSet.plannedRestSeconds > 0
          ? lastSet.plannedRestSeconds
          : exercises[exerciseIndex].restTime;
      final newSet = ExerciseSet(weight: lastSet.weight, reps: lastSet.reps);
      newSet.plannedRestSeconds = plannedRest;
      newSet.restStartTime = plannedRest;
      newSet.currentRestTime = plannedRest;
      exercises[exerciseIndex].sets.add(newSet);
    });

    if (widget.workoutId != null) {
      unawaited(_syncWorkoutExerciseTemplate(exercises[exerciseIndex], exerciseIndex));
    }
  }

  void updateSet(String exerciseId, int setIndex, String field, int value) {
    final exerciseIndex = exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;

    setState(() {
      if (field == 'weight') {
        exercises[exerciseIndex].sets[setIndex].weight = value;
      } else {
        exercises[exerciseIndex].sets[setIndex].reps = value;
      }
    });

    if (widget.workoutId != null) {
      unawaited(_syncWorkoutExerciseTemplate(exercises[exerciseIndex], exerciseIndex));
    }
  }

  void completeSet(String exerciseId, int setIndex) {
    setState(() {
      final exerciseIndex = exercises.indexWhere((e) => e.id == exerciseId);
      if (exerciseIndex != -1) {
        final set = exercises[exerciseIndex].sets[setIndex];
        
        // Toggle completion state
        if (set.completed) {
          // Undo completion
          set.completed = false;
          set.isResting = false;
          final plannedRest = set.plannedRestSeconds > 0
              ? set.plannedRestSeconds
              : exercises[exerciseIndex].restTime;
          set.restStartTime = plannedRest;
          set.currentRestTime = plannedRest;
          
          // Stop rest timer if this was the active resting set
          if (isResting) {
            isResting = false;
            restTimerInstance?.cancel();
          }
        } else {
          // Add haptic feedback when completing a set
          HapticFeedback.mediumImpact();
          
          // Stop and reset any previous rest timer
          if (isResting) {
            restTimerInstance?.cancel();
            // Find and reset the previously resting set
            for (var ex in exercises) {
              for (var s in ex.sets) {
                if (s.isResting) {
                  s.isResting = false;
                  s.restStartTime = 0;
                  s.currentRestTime = 0;
                }
              }
            }
          }
          
          // Complete the set and set rest times immediately
          set.completed = true;
          final plannedRest = set.plannedRestSeconds > 0
              ? set.plannedRestSeconds
              : exercises[exerciseIndex].restTime;
          set.restStartTime = plannedRest;
          set.currentRestTime = plannedRest; // Set to full time immediately
          set.isResting = true;
          
          // Start rest timer
          restTimer = plannedRest;
          maxRestTime = plannedRest;
          isResting = true;
          
          restTimerInstance?.cancel();
          restTimerInstance = Timer.periodic(const Duration(seconds: 1), (timer) {
            setState(() {
              if (restTimer > 0) {
                restTimer--;
                // Update the specific set's rest time
                if (exerciseIndex < exercises.length && 
                    setIndex < exercises[exerciseIndex].sets.length) {
                  exercises[exerciseIndex].sets[setIndex].currentRestTime = restTimer;
                }
              } else {
                isResting = false;
                if (exerciseIndex < exercises.length && 
                    setIndex < exercises[exerciseIndex].sets.length) {
                  final target = exercises[exerciseIndex].sets[setIndex].plannedRestSeconds > 0
                      ? exercises[exerciseIndex].sets[setIndex].plannedRestSeconds
                      : exercises[exerciseIndex].restTime;
                  exercises[exerciseIndex].sets[setIndex].isResting = false;
                  exercises[exerciseIndex].sets[setIndex].restStartTime = target;
                  exercises[exerciseIndex].sets[setIndex].currentRestTime = target;
                }
                timer.cancel();
              }
            });
          });
        }
      }
    });
  }

  void removeSet(String exerciseId, int setIndex) {
    final exerciseIndex = exercises.indexWhere((e) => e.id == exerciseId);
    if (exerciseIndex == -1) return;
    if (exercises[exerciseIndex].sets.length <= 1) return;

    setState(() {
      exercises[exerciseIndex].sets.removeAt(setIndex);
    });

    if (widget.workoutId != null) {
      unawaited(_syncWorkoutExerciseTemplate(exercises[exerciseIndex], exerciseIndex));
    }
  }

  void removeExercise(String exerciseId) {
    setState(() {
      exercises.removeWhere((e) => e.id == exerciseId);
    });
  }

  void skipRest() {
    setState(() {
      isResting = false;
      restTimer = 0;
    });
    restTimerInstance?.cancel();
  }

  String formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }

  String _formatWeightValue(double? value) {
    if (value == null) return '--';
    final rounded = value.roundToDouble();
    if ((value - rounded).abs() < 0.01) {
      return rounded.toStringAsFixed(0);
    }
    return value.toStringAsFixed(1);
  }

  String _formatShortDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final local = date.toLocal();
    final month = months[local.month - 1];
    return '$month ${local.day}, ${local.year}';
  }

  void _showExerciseInfo(BuildContext context, Exercise exercise) async {
    // Try to fetch full exercise details from Supabase
    try {
      final exercises = await SupabaseService.instance.getExercises();
      final exerciseData = exercises.firstWhere(
        (e) => (e['name'] as String).toLowerCase() == exercise.name.toLowerCase(),
        orElse: () => <String, dynamic>{},
      );

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true, // Allow closing by tapping outside
        enableDrag: true, // Allow closing by dragging down
        backgroundColor: Colors.transparent,
        builder: (context) => _ExerciseInfoSheet(
          exerciseName: exercise.name,
          exerciseData: exerciseData,
        ),
      );
    } catch (e) {
      print('Error loading exercise info: $e');
      // Show basic info if fetch fails
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        isDismissible: true, // Allow closing by tapping outside
        enableDrag: true, // Allow closing by dragging down
        backgroundColor: Colors.transparent,
        builder: (context) => _ExerciseInfoSheet(
          exerciseName: exercise.name,
          exerciseData: {},
        ),
      );
    }
  }

  void _showNotesDialog(BuildContext context, Exercise exercise, ColorScheme colorScheme) {
    final notesController = TextEditingController(text: exercise.notes);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Notes for ${exercise.name}'),
        content: TextField(
          controller: notesController,
          maxLines: 5,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Add notes about form, weight progression, etc...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              notesController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final trimmed = notesController.text.trim();
              setState(() {
                exercise.notes = trimmed;
              });
              if (widget.workoutId != null) {
                final exerciseIndex = exercises.indexWhere((e) => e.id == exercise.id);
                if (exerciseIndex != -1) {
                  unawaited(_syncWorkoutExerciseTemplate(exercise, exerciseIndex));
                }
              }
              notesController.dispose();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showNumberPicker(
    BuildContext context,
    String label,
    int currentValue,
    int min,
    int max,
    int step,
    Function(int) onChanged,
  ) {
    final controller = TextEditingController(text: currentValue.toString());
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set $label'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            suffixText: label == 'Rest' ? 'sec' : null,
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
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = int.tryParse(controller.text);
              if (value != null && value >= min && value <= max) {
                onChanged(value);
              }
              controller.dispose();
              Navigator.pop(context);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final sessionName = widget.workoutName?.trim();

    if (!isWorkoutActive) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => widget.onNavigate('dashboard'),
          ),
          title: Text(
            (sessionName ?? '').isNotEmpty ? sessionName! : 'New Workout',
          ),
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Quick Start',
                style: textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  children: [
                    'Push Day',
                    'Pull Day',
                    'Leg Day',
                    'Upper Body',
                    'Full Body'
                  ].map((template) {
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(template, style: textTheme.titleMedium),
                        subtitle: const Text('Tap to start with this template'),
                        onTap: startWorkout,
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: startWorkout,
                icon: const Icon(Icons.play_arrow),
                label: const Text('Start Empty Workout'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => widget.onNavigate('workout-builder'),
                icon: const Icon(Icons.add),
                label: const Text('Create Custom Workout'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: minimizeWorkout,
        ),
        title: Column(
          children: [
            Text(
              formatTime(workoutTime),
              style: textTheme.headlineSmall?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            Text(
              'Workout Time',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            color: colorScheme.secondary,
            onPressed: endWorkout,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if ((sessionName ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sessionName!,
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current workout template',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          // Exercises
          if (exercises.isEmpty)
            Center(
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 80,
                    color: colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No exercises yet',
                    style: textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap "Add Exercise" below to get started',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ...exercises.map((exercise) {
            return Card(
              margin: const EdgeInsets.only(bottom: 24),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _showExerciseInfo(context, exercise),
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      exercise.name,
                                      style: textTheme.titleMedium?.copyWith(
                                        color: colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                        decorationColor: colorScheme.primary.withOpacity(0.3),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.info_outline,
                                    size: 18,
                                    color: colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert),
                          onSelected: (value) {
                            if (value == 'notes') {
                              _showNotesDialog(context, exercise, colorScheme);
                            } else if (value == 'delete') {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Delete Exercise'),
                                  content: Text(
                                    'Are you sure you want to remove ${exercise.name} from this workout?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        removeExercise(exercise.id);
                                      },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: colorScheme.error,
                                      ),
                                      child: const Text('Delete'),
                                    ),
                                  ],
                                ),
                              );
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'notes',
                              child: Row(
                                children: [
                                  Icon(
                                    exercise.notes.isEmpty ? Icons.note_add : Icons.edit_note,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(exercise.notes.isEmpty ? 'Add Notes' : 'Edit Notes'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline, size: 20),
                                  SizedBox(width: 12),
                                  Text('Delete Exercise'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (exercise.previousDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Last time: ${_formatShortDate(exercise.previousDate!)}',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    // Notes display
                    if (exercise.notes.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.note,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                exercise.notes,
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Column headers
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text(
                              'Set',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 65,
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
                            width: 50,
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
                                  width: 68,
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
                          SizedBox(
                            width: 60,
                            child: Text(
                              'Done',
                              style: textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Stack(
                            children: [
                              // Rest timer progress bar (full width background)
                              if (set.isResting && set.restStartTime > 0)
                                Positioned.fill(
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: set.currentRestTime / set.restStartTime,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary.withOpacity(0.3),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              // Content container
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                decoration: BoxDecoration(
                                  color: set.completed
                                      ? colorScheme.secondaryContainer.withOpacity(0.3)
                                      : colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                      // Set number
                                      SizedBox(
                                  width: 32,
                                        child: Text(
                                          '${setIndex + 1}',
                                          style: textTheme.bodyMedium?.copyWith(
                                            color: set.completed
                                                ? colorScheme.secondary
                                                : colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                const SizedBox(width: 2),
                                // Weight (always editable + previous)
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        EditableNumberField(
                                          value: set.weight,
                                          onChanged: (value) => updateSet(exercise.id, setIndex, 'weight', value),
                                          isHighlighted: set.isResting,
                                          textStyle: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (set.previousWeight != null && set.previousWeight! > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              _formatWeightValue(set.previousWeight),
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Reps (always editable + previous)
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        EditableNumberField(
                                          value: set.reps,
                                          onChanged: (value) => updateSet(exercise.id, setIndex, 'reps', value),
                                          isHighlighted: set.isResting,
                                          textStyle: textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        if (set.previousReps != null && set.previousReps! > 0)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 2),
                                            child: Text(
                                              '${set.previousReps}',
                                              style: textTheme.bodySmall?.copyWith(
                                                color: colorScheme.onSurfaceVariant.withOpacity(0.6),
                                                fontSize: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Rest time (editable when not resting, countdown when resting)
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 4),
                                    child: set.isResting
                                        ? Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            decoration: BoxDecoration(
                                              color: colorScheme.secondaryContainer.withOpacity(0.5),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: colorScheme.secondary.withOpacity(0.5),
                                                width: 2,
                                              ),
                                            ),
                                            child: Center(
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                child: Text(
                                                  formatTime(set.currentRestTime),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: textTheme.bodySmall?.copyWith(
                                                    fontWeight: FontWeight.bold,
                                                    color: colorScheme.secondary,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : EditableNumberField(
                                            value: set.plannedRestSeconds > 0 ? set.plannedRestSeconds : exercise.restTime,
                                            onChanged: (value) {
                                              setState(() {
                                                set.plannedRestSeconds = value;
                                                set.restStartTime = value;
                                                set.currentRestTime = value;
                                              });
                                              if (widget.workoutId != null) {
                                                final exerciseIndex = exercises.indexWhere((e) => e.id == exercise.id);
                                                if (exerciseIndex != -1) {
                                                  unawaited(_syncWorkoutExerciseTemplate(exercise, exerciseIndex));
                                                }
                                              }
                                            },
                                            textStyle: textTheme.bodySmall?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                  ),
                                ),
                                const Spacer(),
                                // Complete button
                                SizedBox(
                                  width: 48,
                                  child: IconButton(
                                    icon: Icon(
                                      set.completed ? Icons.check_circle : Icons.check_circle_outline,
                                      size: 28,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                    color: set.completed
                                        ? colorScheme.secondary
                                        : colorScheme.primary,
                                    onPressed: () => completeSet(exercise.id, setIndex),
                                  ),
                                ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => addSet(exercise.id),
                      icon: const Icon(Icons.add),
                      label: const Text('Add Set'),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),

          // Add Exercise button
          OutlinedButton.icon(
            onPressed: addExercise,
            icon: const Icon(Icons.add),
            label: const Text('Add Exercise'),
          ),
          const SizedBox(height: 16),

          // Finish Workout
          FilledButton.icon(
            onPressed: endWorkout,
            icon: const Icon(Icons.check),
            label: const Text('Finish Workout'),
          ),
        ],
      ),
    );
  }
}

class _ExerciseInfoSheet extends StatelessWidget {
  final String exerciseName;
  final Map<String, dynamic> exerciseData;

  const _ExerciseInfoSheet({
    required this.exerciseName,
    required this.exerciseData,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    
    final category = exerciseData['category'] as String? ?? 'Exercise';
    final difficulty = exerciseData['difficulty'] as String?;
    final equipment = exerciseData['equipment'] as String? ?? 'Various';
    final imageUrl = exerciseData['image_url'] as String? ?? exerciseData['imageUrl'] as String?;
    final instructions = exerciseData['instructions'] as String?;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Exercise name
                    Text(
                      exerciseName,
                      style: textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category badge
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(category),
                          backgroundColor: colorScheme.primaryContainer,
                          labelStyle: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (difficulty != null)
                          Chip(
                            label: Text(difficulty),
                            backgroundColor: _getDifficultyColor(difficulty, colorScheme).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _getDifficultyColor(difficulty, colorScheme),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Exercise image
                    if (imageUrl != null && imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: colorScheme.surfaceVariant,
                                child: Icon(
                                  Icons.fitness_center,
                                  size: 64,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                color: colorScheme.surfaceVariant,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Equipment
                    _InfoSection(
                      icon: Icons.sports_gymnastics,
                      title: 'Equipment',
                      content: equipment,
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 16),
                    // Instructions
                    if (instructions != null && instructions.isNotEmpty)
                      _InfoSection(
                        icon: Icons.article,
                        title: 'Instructions',
                        content: instructions,
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      )
                    else
                      _InfoSection(
                        icon: Icons.info_outline,
                        title: 'About',
                        content: 'This is a $category exercise using $equipment. '
                            'Focus on proper form and controlled movements.',
                        colorScheme: colorScheme,
                        textTheme: textTheme,
                      ),
                    const SizedBox(height: 24),
                    // Close button
                    FilledButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getDifficultyColor(String difficulty, ColorScheme colorScheme) {
    switch (difficulty.toLowerCase()) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.orange;
      case 'advanced':
        return Colors.red;
      default:
        return colorScheme.primary;
    }
  }
}

class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final String content;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.content,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}

class Exercise {
  final String id;
  final String name;
  final List<ExerciseSet> sets;
  int restTime; // Changed from final to mutable
  String notes; // Added notes field
  String? workoutExerciseId;
  String? supabaseExerciseId;
  int? orderIndex;
  DateTime? previousDate;

  Exercise({
    required this.id,
    required this.name,
    required this.sets,
    required this.restTime,
    this.notes = '',
    this.workoutExerciseId,
    this.supabaseExerciseId,
    this.orderIndex,
    this.previousDate,
  });
}

class ExerciseSet {
  int weight;
  int reps;
  bool completed;
  bool isResting;
  int restStartTime;
  int currentRestTime;
  double? previousWeight;
  int? previousReps;
  int plannedRestSeconds;

  ExerciseSet({
    required this.weight,
    required this.reps,
    this.completed = false,
    this.isResting = false,
    this.restStartTime = 0,
    this.currentRestTime = 0,
    this.previousWeight,
    this.previousReps,
    this.plannedRestSeconds = 0,
  });
}

class _SelectExerciseDialog extends StatefulWidget {
  final Future<bool> Function(String name, String category) onAdd;

  const _SelectExerciseDialog({required this.onAdd});

  @override
  State<_SelectExerciseDialog> createState() => _SelectExerciseDialogState();
}

class _SelectExerciseDialogState extends State<_SelectExerciseDialog> {
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
    {'name': 'Decline Bench Press', 'category': 'Chest'},
    {'name': 'Dumbbell Flyes', 'category': 'Chest'},
    {'name': 'Cable Crossover', 'category': 'Chest'},
    {'name': 'Push-ups', 'category': 'Chest'},
    {'name': 'Dips', 'category': 'Chest'},
    {'name': 'Deadlifts', 'category': 'Back'},
    {'name': 'Pull-ups', 'category': 'Back'},
    {'name': 'Barbell Rows', 'category': 'Back'},
    {'name': 'Lat Pulldown', 'category': 'Back'},
    {'name': 'Seated Cable Rows', 'category': 'Back'},
    {'name': 'T-Bar Rows', 'category': 'Back'},
    {'name': 'Face Pulls', 'category': 'Back'},
    {'name': 'Squats', 'category': 'Legs'},
    {'name': 'Front Squats', 'category': 'Legs'},
    {'name': 'Leg Press', 'category': 'Legs'},
    {'name': 'Lunges', 'category': 'Legs'},
    {'name': 'Romanian Deadlifts', 'category': 'Legs'},
    {'name': 'Leg Curls', 'category': 'Legs'},
    {'name': 'Leg Extensions', 'category': 'Legs'},
    {'name': 'Calf Raises', 'category': 'Legs'},
    {'name': 'Overhead Press', 'category': 'Shoulders'},
    {'name': 'Dumbbell Shoulder Press', 'category': 'Shoulders'},
    {'name': 'Lateral Raises', 'category': 'Shoulders'},
    {'name': 'Front Raises', 'category': 'Shoulders'},
    {'name': 'Rear Delt Flyes', 'category': 'Shoulders'},
    {'name': 'Arnold Press', 'category': 'Shoulders'},
    {'name': 'Upright Rows', 'category': 'Shoulders'},
    {'name': 'Bicep Curls', 'category': 'Arms'},
    {'name': 'Hammer Curls', 'category': 'Arms'},
    {'name': 'Preacher Curls', 'category': 'Arms'},
    {'name': 'Tricep Dips', 'category': 'Arms'},
    {'name': 'Tricep Pushdowns', 'category': 'Arms'},
    {'name': 'Skull Crushers', 'category': 'Arms'},
    {'name': 'Cable Curls', 'category': 'Arms'},
    {'name': 'Close-Grip Bench Press', 'category': 'Arms'},
    {'name': 'Planks', 'category': 'Core'},
    {'name': 'Crunches', 'category': 'Core'},
    {'name': 'Russian Twists', 'category': 'Core'},
    {'name': 'Leg Raises', 'category': 'Core'},
    {'name': 'Cable Crunches', 'category': 'Core'},
    {'name': 'Ab Wheel Rollouts', 'category': 'Core'},
    {'name': 'Hanging Leg Raises', 'category': 'Core'},
    {'name': 'Mountain Climbers', 'category': 'Core'},
    {'name': 'Running', 'category': 'Cardio'},
    {'name': 'Cycling', 'category': 'Cardio'},
    {'name': 'Jump Rope', 'category': 'Cardio'},
    {'name': 'Burpees', 'category': 'Cardio'},
    {'name': 'Rowing', 'category': 'Cardio'},
    {'name': 'Stair Climbing', 'category': 'Cardio'},
  ];

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  List<Map<String, String>> get filteredExercises {
    // Combine default exercises with custom exercises
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                  ? const Center(
                      child: Text('No exercises found'),
                    )
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
                            onTap: () async {
                              final success = await widget.onAdd(
                                exercise['name']!,
                                exercise['category']!,
                              );
                              if (success && mounted) {
                                Navigator.pop(context);
                              }
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
