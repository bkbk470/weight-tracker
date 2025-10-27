import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to persist and restore active workout sessions
class WorkoutSessionService {
  static const String _keyWorkoutActive = 'active_workout_session';
  static const String _keyWorkoutName = 'active_workout_name';
  static const String _keyWorkoutId = 'active_workout_id';
  static const String _keyWorkoutExercises = 'active_workout_exercises';
  static const String _keyWorkoutStartTime = 'active_workout_start_time';

  static final WorkoutSessionService _instance = WorkoutSessionService._internal();
  static WorkoutSessionService get instance => _instance;

  WorkoutSessionService._internal();

  SharedPreferences? _prefs;

  Future<void> _ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save the current workout session
  Future<void> saveWorkoutSession({
    required String? workoutName,
    required String? workoutId,
    required List<Map<String, dynamic>>? exercises,
    DateTime? startTime,
  }) async {
    await _ensureInitialized();

    print('💾 WorkoutSessionService: Saving workout session - $workoutName');
    await _prefs!.setBool(_keyWorkoutActive, true);

    if (workoutName != null) {
      await _prefs!.setString(_keyWorkoutName, workoutName);
    } else {
      await _prefs!.remove(_keyWorkoutName);
    }

    if (workoutId != null) {
      await _prefs!.setString(_keyWorkoutId, workoutId);
    } else {
      await _prefs!.remove(_keyWorkoutId);
    }

    if (exercises != null) {
      await _prefs!.setString(_keyWorkoutExercises, jsonEncode(exercises));
    } else {
      await _prefs!.remove(_keyWorkoutExercises);
    }

    // Save the start time (use provided startTime or current time for initial save)
    final timeToSave = startTime ?? DateTime.now();
    await _prefs!.setInt(_keyWorkoutStartTime, timeToSave.millisecondsSinceEpoch);
  }

  /// Update the workout session with current exercise state (for live updates)
  Future<void> updateWorkoutSession({
    required List<Map<String, dynamic>> exercises,
  }) async {
    await _ensureInitialized();

    // Only update exercises if workout is active
    final isActive = _prefs!.getBool(_keyWorkoutActive) ?? false;
    if (!isActive) return;

    await _prefs!.setString(_keyWorkoutExercises, jsonEncode(exercises));
  }

  /// Load the saved workout session
  Future<Map<String, dynamic>?> loadWorkoutSession() async {
    await _ensureInitialized();

    final isActive = _prefs!.getBool(_keyWorkoutActive) ?? false;
    print('📖 WorkoutSessionService: Loading workout session - isActive: $isActive');
    if (!isActive) {
      return null;
    }

    final workoutName = _prefs!.getString(_keyWorkoutName);
    final workoutId = _prefs!.getString(_keyWorkoutId);
    final exercisesJson = _prefs!.getString(_keyWorkoutExercises);
    final startTime = _prefs!.getInt(_keyWorkoutStartTime);

    List<Map<String, dynamic>>? exercises;
    if (exercisesJson != null) {
      try {
        final decoded = jsonDecode(exercisesJson);
        if (decoded is List) {
          exercises = decoded.cast<Map<String, dynamic>>();
        }
      } catch (e) {
        print('Error decoding workout exercises: $e');
      }
    }

    return {
      'workoutName': workoutName,
      'workoutId': workoutId,
      'exercises': exercises,
      'startTime': startTime != null ? DateTime.fromMillisecondsSinceEpoch(startTime) : null,
    };
  }

  /// Check if there's an active workout session
  Future<bool> hasActiveWorkout() async {
    await _ensureInitialized();
    return _prefs!.getBool(_keyWorkoutActive) ?? false;
  }

  /// Clear the workout session
  Future<void> clearWorkoutSession() async {
    await _ensureInitialized();

    print('🗑️  WorkoutSessionService: Clearing workout session');
    await _prefs!.remove(_keyWorkoutActive);
    await _prefs!.remove(_keyWorkoutName);
    await _prefs!.remove(_keyWorkoutId);
    await _prefs!.remove(_keyWorkoutExercises);
    await _prefs!.remove(_keyWorkoutStartTime);
  }
}
