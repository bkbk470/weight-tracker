import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/exercise.dart';
import 'supabase_service.dart';
import 'local_storage_service.dart';

/// Service responsible for loading and saving workout data
class WorkoutDataService {
  final SupabaseService _supabaseService;
  final LocalStorageService _localStorageService;

  // Lock to prevent concurrent metadata operations
  final Map<String, Completer<void>> _metadataLocks = {};

  WorkoutDataService({
    SupabaseService? supabaseService,
    LocalStorageService? localStorageService,
  })  : _supabaseService = supabaseService ?? SupabaseService.instance,
        _localStorageService = localStorageService ?? LocalStorageService.instance;

  /// Load previous exercise data for all exercises in batch
  Future<void> loadPreviousDataBatch(List<Exercise> exercises) async {
    if (_supabaseService.currentUserId == null) {
      // Apply local history for all exercises
      for (final exercise in exercises) {
        _applyLocalHistoryIfMissing(exercise);
      }
      return;
    }

    // Ensure metadata for all exercises first
    await Future.wait(
      exercises.asMap().entries.map((entry) =>
          _ensureWorkoutExerciseMetadata(entry.value, entry.key, createIfMissing: false)),
    );

    // Collect all exercise IDs that have metadata
    final exerciseIdsMap = <String, Exercise>{};
    for (final exercise in exercises) {
      if (exercise.supabaseExerciseId != null) {
        exerciseIdsMap[exercise.supabaseExerciseId!] = exercise;
      }
    }

    if (exerciseIdsMap.isEmpty) {
      // Apply local history fallback
      for (final exercise in exercises) {
        _applyLocalHistoryIfMissing(exercise);
      }
      return;
    }

    try {
      // Batch load all previous sets
      final allRecords = await _supabaseService.getBatchLatestExerciseSets(
        exerciseIdsMap.keys.toList(),
      );

      // Group records by exercise ID
      final recordsByExerciseId = <String, List<Map<String, dynamic>>>{};
      for (final record in allRecords) {
        final exerciseId = record['exercise_id'] as String?;
        if (exerciseId != null) {
          recordsByExerciseId.putIfAbsent(exerciseId, () => []).add(record);
        }
      }

      // Apply data to each exercise
      for (final entry in exerciseIdsMap.entries) {
        final exerciseId = entry.key;
        final exercise = entry.value;
        final records = recordsByExerciseId[exerciseId] ?? [];

        if (records.isEmpty) {
          exercise.previousDate = null;
          for (final set in exercise.sets) {
            set.previousWeight = null;
            set.previousReps = null;
          }
          _applyLocalHistoryIfMissing(exercise);
          continue;
        }

        // Map records by set number
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
        exercise.previousDate = createdAt != null
            ? DateTime.tryParse(createdAt)
            : exercise.previousDate;

        for (var i = 0; i < exercise.sets.length; i++) {
          final set = exercise.sets[i];
          final record = bySetNumber[i + 1];

          if (record != null) {
            final weightValue = record['weight_lbs'];
            final previousWeight = weightValue is num
                ? weightValue.toDouble()
                : double.tryParse(weightValue?.toString() ?? '');
            set.previousWeight = previousWeight;

            final repsValue = record['reps'];
            set.previousReps = repsValue is int
                ? repsValue
                : int.tryParse(repsValue?.toString() ?? '');

            // Auto-fill weight if current is zero
            set.autoFillFromPrevious();
          } else {
            set.previousWeight = null;
            set.previousReps = null;
          }
        }

        _applyLocalHistoryIfMissing(exercise);
      }
    } catch (e) {
      debugPrint('Failed to load previous sets batch: $e');
      // Apply local history fallback for all
      for (final exercise in exercises) {
        _applyLocalHistoryIfMissing(exercise);
      }
    }
  }

  /// Apply local history data if no online data is available
  void _applyLocalHistoryIfMissing(Exercise exercise) {
    if (exercise.hasPreviousData) return;

    final keys = <String>{
      if (exercise.supabaseExerciseId != null) exercise.supabaseExerciseId!,
      if (exercise.name.trim().isNotEmpty)
        'name:${exercise.name.trim().toLowerCase()}',
    };

    for (final key in keys) {
      final record = _localStorageService.getLatestExerciseHistory(key);
      if (record == null) continue;

      final setsData = record['sets'];
      final dateStr = record['date'] as String?;

      if (dateStr != null) {
        exercise.previousDate =
            DateTime.tryParse(dateStr) ?? exercise.previousDate;
      }

      if (setsData is List) {
        for (var i = 0; i < exercise.sets.length; i++) {
          if (i >= setsData.length) break;
          final data = setsData[i];
          if (data is Map) {
            final weightRaw = data['weight'];
            final repsRaw = data['reps'];
            final previousWeight = weightRaw is num
                ? weightRaw.toDouble()
                : double.tryParse('${weightRaw ?? ''}');
            exercise.sets[i].previousWeight = previousWeight;

            exercise.sets[i].previousReps =
                repsRaw is int ? repsRaw : int.tryParse('${repsRaw ?? ''}');

            // Auto-fill weight if current is zero
            exercise.sets[i].autoFillFromPrevious();
          }
        }
      }
      break;
    }
  }

  /// Ensure exercise has proper metadata (with locking to prevent race conditions)
  Future<bool> _ensureWorkoutExerciseMetadata(
    Exercise exercise,
    int orderIndex, {
    bool createIfMissing = false,
  }) async {
    // Create a lock key for this exercise
    final lockKey = exercise.id;

    // Wait if another operation is in progress for this exercise
    if (_metadataLocks.containsKey(lockKey)) {
      await _metadataLocks[lockKey]!.future;
    }

    // Create new lock
    final completer = Completer<void>();
    _metadataLocks[lockKey] = completer;

    try {
      // Ensure exercise ID exists
      if (exercise.supabaseExerciseId == null) {
        try {
          exercise.supabaseExerciseId =
              await _supabaseService.getOrCreateExerciseId(
            name: exercise.name,
            category: 'Other',
            notes: exercise.notes.isEmpty ? null : exercise.notes,
          );
        } catch (e) {
          debugPrint('Failed to ensure exercise id for ${exercise.name}: $e');
        }
      }

      // If no workout context, we're done
      if (exercise.supabaseExerciseId == null) {
        return false;
      }

      // No further work needed if no workout ID
      final workoutId = _currentWorkoutId;
      if (workoutId == null) {
        return true;
      }

      // Lookup or create workout_exercise relationship
      if (exercise.workoutExerciseId == null &&
          exercise.supabaseExerciseId != null) {
        try {
          final row = await _supabaseService.getWorkoutExerciseRow(
            workoutId: workoutId,
            exerciseId: exercise.supabaseExerciseId,
            orderIndex: exercise.orderIndex ?? orderIndex,
          );

          if (row != null && row['id'] != null) {
            exercise.workoutExerciseId = row['id'] as String?;
            exercise.orderIndex = row['order_index'] as int? ?? orderIndex;
          } else if (createIfMissing) {
            final inserted = await _supabaseService.addExerciseToWorkout(
              workoutId: workoutId,
              exerciseId: exercise.supabaseExerciseId!,
              orderIndex: exercise.orderIndex ?? orderIndex,
              targetSets: exercise.sets.length,
              targetReps: exercise.sets.isNotEmpty ? exercise.sets.first.reps : 0,
              restTimeSeconds: exercise.restTime,
              notes: exercise.notes.isEmpty ? null : exercise.notes,
            );
            exercise.workoutExerciseId = inserted['id'] as String?;
            exercise.orderIndex = inserted['order_index'] as int? ?? orderIndex;
          }
        } catch (e) {
          debugPrint('Failed to manage workout exercise ${exercise.name}: $e');
        }
      }

      return exercise.supabaseExerciseId != null;
    } finally {
      // Release lock
      completer.complete();
      _metadataLocks.remove(lockKey);
    }
  }

  /// Save workout to database with full error handling
  Future<WorkoutSaveResult> saveWorkout({
    required List<Exercise> exercises,
    required int workoutTimeSeconds,
    required String? workoutId,
    required String workoutName,
  }) async {
    final endTime = DateTime.now();
    final startTime = endTime.subtract(Duration(seconds: workoutTimeSeconds));

    // Calculate stats
    final stats = _calculateWorkoutStats(exercises);

    try {
      // Sync metadata if needed
      if (workoutId != null) {
        await _syncAllWorkoutExercises(exercises, workoutId);
      }

      // Create workout log
      final workoutLog = await _supabaseService.createWorkoutLog(
        workoutId: workoutId,
        workoutName: workoutName,
        startTime: startTime,
        endTime: endTime,
        durationSeconds: workoutTimeSeconds,
        notes: 'Workout completed',
      );

      // Cache exercise IDs
      final exerciseIdCache = await _buildExerciseIdCache();

      // Save all sets
      await _saveAllExerciseSets(
        exercises: exercises,
        workoutLogId: workoutLog['id'],
        exerciseIdCache: exerciseIdCache,
      );

      // Save to local storage
      await _saveToLocalStorage(
        workoutLog: workoutLog,
        workoutName: workoutName,
        startTime: startTime,
        endTime: endTime,
        workoutTimeSeconds: workoutTimeSeconds,
        exercises: exercises,
      );

      return WorkoutSaveResult.success(
        workoutLogId: workoutLog['id'],
        stats: stats,
      );
    } catch (e) {
      debugPrint('Error saving workout to Supabase: $e');

      // Fallback to local storage only
      try {
        await _saveToLocalStorage(
          workoutLog: {'id': DateTime.now().toString()},
          workoutName: workoutName,
          startTime: startTime,
          endTime: endTime,
          workoutTimeSeconds: workoutTimeSeconds,
          exercises: exercises,
        );

        return WorkoutSaveResult.savedOffline(stats: stats);
      } catch (localError) {
        debugPrint('Error saving workout locally: $localError');
        return WorkoutSaveResult.failed(
          error: 'Failed to save workout: $localError',
          stats: stats,
        );
      }
    }
  }

  WorkoutStats _calculateWorkoutStats(List<Exercise> exercises) {
    final totalExercises = exercises.length;
    final totalSetsCompleted = exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum + exercise.sets.where((set) => set.completed).length,
    );
    final totalReps = exercises.fold<int>(
      0,
      (sum, exercise) =>
          sum +
          exercise.sets.where((set) => set.completed).fold<int>(
                0,
                (repSum, set) => repSum + set.reps,
              ),
    );
    final totalVolume = exercises.fold<double>(
      0.0,
      (sum, exercise) =>
          sum +
          exercise.sets.where((set) => set.completed).fold<double>(
                0.0,
                (volSum, set) => volSum + (set.weight * set.reps),
              ),
    );

    return WorkoutStats(
      totalExercises: totalExercises,
      totalSetsCompleted: totalSetsCompleted,
      totalReps: totalReps,
      totalVolume: totalVolume,
    );
  }

  Future<void> _syncAllWorkoutExercises(
      List<Exercise> exercises, String workoutId) async {
    _currentWorkoutId = workoutId;
    await Future.wait(
      exercises.asMap().entries.map(
            (entry) => _ensureWorkoutExerciseMetadata(
              entry.value,
              entry.key,
              createIfMissing: true,
            ),
          ),
    );
  }

  Future<Map<String, String>> _buildExerciseIdCache() async {
    final Map<String, String> cache = {};
    try {
      final existingExercises = await _supabaseService.getExercises();
      for (final exercise in existingExercises) {
        final name = (exercise['name'] as String?)?.toLowerCase();
        final id = exercise['id'] as String?;
        if (name != null && id != null && name.isNotEmpty) {
          cache[name] = id;
        }
      }
    } catch (e) {
      debugPrint('Warning: Failed to preload exercise list: $e');
    }
    return cache;
  }

  Future<void> _saveAllExerciseSets({
    required List<Exercise> exercises,
    required String workoutLogId,
    required Map<String, String> exerciseIdCache,
  }) async {
    for (final exercise in exercises) {
      final normalizedName = exercise.name.trim().toLowerCase();
      if (normalizedName.isEmpty) continue;

      String? exerciseId = exerciseIdCache[normalizedName];
      if (exerciseId == null) {
        try {
          exerciseId = await _supabaseService.getOrCreateExerciseId(
            name: exercise.name.trim(),
            notes: exercise.notes.isEmpty ? null : exercise.notes,
          );
          exerciseIdCache[normalizedName] = exerciseId;
        } catch (e) {
          debugPrint('Error ensuring exercise "${exercise.name}" exists: $e');
          continue;
        }
      }

      for (int i = 0; i < exercise.sets.length; i++) {
        final set = exercise.sets[i];
        if (set.completed) {
          await _supabaseService.addExerciseSet(
            workoutLogId: workoutLogId,
            exerciseId: exerciseId,
            exerciseName: exercise.name,
            setNumber: i + 1,
            weightLbs: set.weight > 0 ? set.weight.toDouble() : null,
            reps: set.reps > 0 ? set.reps : null,
            completed: true,
            restTimeSeconds: set.plannedRestSeconds > 0
                ? set.plannedRestSeconds
                : exercise.restTime,
            notes: exercise.notes.isEmpty ? null : exercise.notes,
          );
        }
      }
    }
  }

  Future<void> _saveToLocalStorage({
    required Map<String, dynamic> workoutLog,
    required String workoutName,
    required DateTime startTime,
    required DateTime endTime,
    required int workoutTimeSeconds,
    required List<Exercise> exercises,
  }) async {
    await _localStorageService.saveWorkout({
      'id': workoutLog['id'],
      'name': workoutName,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'duration': workoutTimeSeconds,
      'exercises': exercises.length,
    });

    await _saveExerciseHistoryLocally(exercises, endTime);
  }

  Future<void> _saveExerciseHistoryLocally(
    List<Exercise> exercises,
    DateTime completedAt,
  ) async {
    for (final exercise in exercises) {
      final completedSets = exercise.sets.where((s) => s.completed).toList();
      if (completedSets.isEmpty) continue;

      final historyData = {
        'date': completedAt.toIso8601String(),
        'sets': completedSets
            .map((s) => {
                  'weight': s.weight,
                  'reps': s.reps,
                })
            .toList(),
      };

      if (exercise.supabaseExerciseId != null) {
        await _localStorageService.saveExerciseHistory(
          exercise.supabaseExerciseId!,
          historyData,
        );
      }

      final nameKey = 'name:${exercise.name.trim().toLowerCase()}';
      await _localStorageService.saveExerciseHistory(nameKey, historyData);
    }
  }

  String? _currentWorkoutId;
}

/// Result of saving a workout
class WorkoutSaveResult {
  final bool success;
  final bool savedOffline;
  final String? workoutLogId;
  final String? error;
  final WorkoutStats stats;

  WorkoutSaveResult.success({
    required this.workoutLogId,
    required this.stats,
  })  : success = true,
        savedOffline = false,
        error = null;

  WorkoutSaveResult.savedOffline({
    required this.stats,
  })  : success = true,
        savedOffline = true,
        workoutLogId = null,
        error = null;

  WorkoutSaveResult.failed({
    required this.error,
    required this.stats,
  })  : success = false,
        savedOffline = false,
        workoutLogId = null;
}

/// Workout statistics
class WorkoutStats {
  final int totalExercises;
  final int totalSetsCompleted;
  final int totalReps;
  final double totalVolume;

  WorkoutStats({
    required this.totalExercises,
    required this.totalSetsCompleted,
    required this.totalReps,
    required this.totalVolume,
  });
}
