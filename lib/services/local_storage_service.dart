import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/exercise_assets.dart';

class LocalStorageService {
  static const String _workoutsBox = 'workouts';
  static const String _exercisesBox = 'exercises';
  static const String _measurementsBox = 'measurements';
  static const String _exerciseHistoryBox = 'exercise_history';
  static const String _userBox = 'user';
  static const String _settingsBox = 'settings';

  static LocalStorageService? _instance;
  static LocalStorageService get instance {
    _instance ??= LocalStorageService._();
    return _instance!;
  }

  LocalStorageService._();

  // Initialize Hive
  Future<void> init() async {
    await Hive.initFlutter();

    // Open boxes
    await Hive.openBox(_workoutsBox);
    await Hive.openBox(_exercisesBox);
    await Hive.openBox(_measurementsBox);
    await Hive.openBox(_userBox);
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_exerciseHistoryBox);
  }

  // ==================== WORKOUTS ====================

  // Save workout
  Future<void> saveWorkout(Map<String, dynamic> workout) async {
    final box = Hive.box(_workoutsBox);
    final id =
        workout['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    workout['id'] = id;
    workout['lastModified'] = DateTime.now().toIso8601String();
    workout['syncStatus'] = 'pending'; // pending, synced, failed
    await box.put(id, workout);
  }

  // Get all workouts
  List<Map<String, dynamic>> getAllWorkouts() {
    final box = Hive.box(_workoutsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Get workout by ID
  Map<String, dynamic>? getWorkout(String id) {
    final box = Hive.box(_workoutsBox);
    final workout = box.get(id);
    return workout != null ? Map<String, dynamic>.from(workout as Map) : null;
  }

  // Delete workout
  Future<void> deleteWorkout(String id) async {
    final box = Hive.box(_workoutsBox);
    await box.delete(id);
  }

  // Get workouts pending sync
  List<Map<String, dynamic>> getPendingSyncWorkouts() {
    final box = Hive.box(_workoutsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((workout) => workout['syncStatus'] == 'pending')
        .toList();
  }

  // Mark workout as synced
  Future<void> markWorkoutSynced(String id) async {
    final box = Hive.box(_workoutsBox);
    final workout = box.get(id);
    if (workout != null) {
      final updatedWorkout = Map<String, dynamic>.from(workout as Map);
      updatedWorkout['syncStatus'] = 'synced';
      updatedWorkout['lastSynced'] = DateTime.now().toIso8601String();
      await box.put(id, updatedWorkout);
    }
  }

  // ==================== EXERCISES ====================

  // Save exercise
  Future<void> saveExercise(Map<String, dynamic> exercise) async {
    final box = Hive.box(_exercisesBox);
    final id =
        exercise['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    exercise['id'] = id;
    if (exercise['imageUrl'] == null && exercise['image_url'] != null) {
      exercise['imageUrl'] = exercise['image_url'];
    }
    if (exercise['image_url'] == null && exercise['imageUrl'] != null) {
      exercise['image_url'] = exercise['imageUrl'];
    }
    exercise['imageUrl'] ??= kExercisePlaceholderImage;
    exercise['image_url'] ??= kExercisePlaceholderImage;
    exercise['lastModified'] = DateTime.now().toIso8601String();
    exercise['syncStatus'] = 'pending';
    await box.put(id, exercise);
  }

  // Get all exercises
  List<Map<String, dynamic>> getAllExercises() {
    final box = Hive.box(_exercisesBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Get exercise by ID
  Map<String, dynamic>? getExercise(String id) {
    final box = Hive.box(_exercisesBox);
    final exercise = box.get(id);
    return exercise != null ? Map<String, dynamic>.from(exercise as Map) : null;
  }

  // Delete exercise
  Future<void> deleteExercise(String id) async {
    final box = Hive.box(_exercisesBox);
    await box.delete(id);
  }

  // ==================== MEASUREMENTS ====================

  // Save measurement
  Future<void> saveMeasurement(Map<String, dynamic> measurement) async {
    final box = Hive.box(_measurementsBox);
    final id =
        measurement['id'] ?? DateTime.now().millisecondsSinceEpoch.toString();
    measurement['id'] = id;
    measurement['date'] =
        measurement['date'] ?? DateTime.now().toIso8601String();
    measurement['lastModified'] = DateTime.now().toIso8601String();
    measurement['syncStatus'] = measurement['syncStatus'] ?? 'pending';
    await box.put(id, measurement);
  }

  // Get all measurements
  List<Map<String, dynamic>> getAllMeasurements() {
    final box = Hive.box(_measurementsBox);
    return box.values.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // Get measurements by type
  List<Map<String, dynamic>> getMeasurementsByType(String type) {
    final box = Hive.box(_measurementsBox);
    return box.values
        .map((e) => Map<String, dynamic>.from(e as Map))
        .where((m) => m['type'] == type)
        .toList()
      ..sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
  }

  // Get latest measurement by type
  Map<String, dynamic>? getLatestMeasurement(String type) {
    final measurements = getMeasurementsByType(type);
    return measurements.isNotEmpty ? measurements.first : null;
  }

  // Delete measurement
  Future<void> deleteMeasurement(String id) async {
    final box = Hive.box(_measurementsBox);
    await box.delete(id);
  }

  // ==================== USER DATA ====================

  // Save user profile
  Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    final box = Hive.box(_userBox);
    profile['lastModified'] = DateTime.now().toIso8601String();
    await box.put('profile', profile);
  }

  // Get user profile
  Map<String, dynamic>? getUserProfile() {
    final box = Hive.box(_userBox);
    final profile = box.get('profile');
    return profile != null ? Map<String, dynamic>.from(profile as Map) : null;
  }

  // ==================== DASHBOARD CACHE ====================

  // Cache dashboard data for faster loading
  Future<void> cacheDashboardData({
    required List<Map<String, dynamic>> folders,
    required Map<String?, List<Map<String, dynamic>>> workoutsByFolder,
    required Map<String, DateTime?> lastCompletedDates,
  }) async {
    final box = Hive.box(_userBox);
    await box.put('dashboard_cache', {
      'folders': folders,
      'workoutsByFolder': workoutsByFolder.map((key, value) => MapEntry(key?.toString() ?? 'null', value)),
      'lastCompletedDates': lastCompletedDates.map((key, value) => MapEntry(key, value?.toIso8601String())),
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get cached dashboard data
  Map<String, dynamic>? getCachedDashboardData() {
    final box = Hive.box(_userBox);
    final cached = box.get('dashboard_cache');
    if (cached == null) return null;

    final data = Map<String, dynamic>.from(cached as Map);

    // Parse back the data structures
    final folders = (data['folders'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList() ?? [];

    final workoutsByFolderRaw = data['workoutsByFolder'] as Map?;
    final workoutsByFolder = <String?, List<Map<String, dynamic>>>{};
    if (workoutsByFolderRaw != null) {
      workoutsByFolderRaw.forEach((key, value) {
        final folderKey = key == 'null' ? null : key.toString();
        workoutsByFolder[folderKey] = (value as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
      });
    }

    final lastCompletedDatesRaw = data['lastCompletedDates'] as Map?;
    final lastCompletedDates = <String, DateTime?>{};
    if (lastCompletedDatesRaw != null) {
      lastCompletedDatesRaw.forEach((key, value) {
        lastCompletedDates[key.toString()] = value != null ? DateTime.parse(value as String) : null;
      });
    }

    return {
      'folders': folders,
      'workoutsByFolder': workoutsByFolder,
      'lastCompletedDates': lastCompletedDates,
      'cachedAt': data['cachedAt'],
    };
  }

  // Cache recent workouts
  Future<void> cacheRecentWorkouts(List<Map<String, dynamic>> workouts) async {
    final box = Hive.box(_userBox);
    await box.put('recent_workouts_cache', {
      'workouts': workouts,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get cached recent workouts
  List<Map<String, dynamic>>? getCachedRecentWorkouts() {
    final box = Hive.box(_userBox);
    final cached = box.get('recent_workouts_cache');
    if (cached == null) return null;

    final data = Map<String, dynamic>.from(cached as Map);
    return (data['workouts'] as List?)?.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  // ==================== MEASUREMENTS CACHE ====================

  // Cache all measurements data
  Future<void> cacheMeasurementsData(Map<String, dynamic> measurementData) async {
    final box = Hive.box(_measurementsBox);
    await box.put('measurements_cache', {
      'data': measurementData,
      'cachedAt': DateTime.now().toIso8601String(),
    });
  }

  // Get cached measurements data
  Map<String, dynamic>? getCachedMeasurementsData() {
    final box = Hive.box(_measurementsBox);
    final cached = box.get('measurements_cache');
    if (cached == null) return null;

    return Map<String, dynamic>.from(cached as Map);
  }

  // ==================== SETTINGS ====================

  // Save setting
  Future<void> saveSetting(String key, dynamic value) async {
    final box = Hive.box(_settingsBox);
    await box.put(key, value);
  }

  // Get setting
  dynamic getSetting(String key, {dynamic defaultValue}) {
    final box = Hive.box(_settingsBox);
    return box.get(key, defaultValue: defaultValue);
  }

  // Get theme mode
  String getThemeMode() {
    return getSetting('themeMode', defaultValue: 'system');
  }

  // Save theme mode
  Future<void> saveThemeMode(String mode) async {
    await saveSetting('themeMode', mode);
  }

  // Get expanded folders
  List<String>? getExpandedFolders() {
    final value = getSetting('expandedFolders');
    if (value is List) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }

  // Save expanded folders
  Future<void> saveExpandedFolders(List<String> folderIds) async {
    await saveSetting('expandedFolders', folderIds);
  }

  // ==================== EXERCISE HISTORY ====================

  Future<void> saveExerciseHistory(
    String key,
    Map<String, dynamic> entry, {
    int maxEntries = 50,
  }) async {
    if (key.trim().isEmpty) return;
    final box = Hive.box(_exerciseHistoryBox);
    final clonedEntry = Map<String, dynamic>.from(entry);
    clonedEntry['date'] =
        clonedEntry['date'] ?? DateTime.now().toIso8601String();
    final setsRaw = clonedEntry['sets'];
    if (setsRaw is List) {
      clonedEntry['sets'] = setsRaw
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    final history = (box.get(key) as List?)
            ?.map((item) => Map<String, dynamic>.from(item as Map))
            .toList() ??
        <Map<String, dynamic>>[];

    final existingIndex =
        history.indexWhere((item) => item['date'] == clonedEntry['date']);
    if (existingIndex >= 0) {
      history[existingIndex] = clonedEntry;
    } else {
      history.insert(0, clonedEntry);
    }

    if (history.length > maxEntries) {
      history.removeRange(maxEntries, history.length);
    }

    await box.put(key, history);
  }

  List<Map<String, dynamic>> getExerciseHistory(String key) {
    if (key.trim().isEmpty) return [];
    final box = Hive.box(_exerciseHistoryBox);
    final raw = box.get(key);
    if (raw is List) {
      return raw.map((item) => Map<String, dynamic>.from(item as Map)).toList();
    }
    return [];
  }

  Map<String, dynamic>? getLatestExerciseHistory(String key) {
    final history = getExerciseHistory(key);
    return history.isNotEmpty ? history.first : null;
  }

  // ==================== SYNC STATUS ====================

  // Get last sync time
  DateTime? getLastSyncTime() {
    final timestamp = getSetting('lastSyncTime');
    return timestamp != null ? DateTime.parse(timestamp) : null;
  }

  // Update last sync time
  Future<void> updateLastSyncTime() async {
    await saveSetting('lastSyncTime', DateTime.now().toIso8601String());
  }

  // Check if data needs sync
  bool needsSync() {
    final lastSync = getLastSyncTime();
    if (lastSync == null) return true;

    // Check if there's any pending data
    final pendingWorkouts = getPendingSyncWorkouts();
    return pendingWorkouts.isNotEmpty;
  }

  // ==================== CLEAR DATA ====================

  // Clear all local data
  Future<void> clearAllData() async {
    await Hive.box(_workoutsBox).clear();
    await Hive.box(_exercisesBox).clear();
    await Hive.box(_measurementsBox).clear();
    await Hive.box(_userBox).clear();
  }

  // Clear only synced data (keep pending)
  Future<void> clearSyncedData() async {
    final workoutsBox = Hive.box(_workoutsBox);
    final keysToDelete = <String>[];

    for (var key in workoutsBox.keys) {
      final workout = workoutsBox.get(key);
      if (workout != null) {
        final workoutMap = Map<String, dynamic>.from(workout as Map);
        if (workoutMap['syncStatus'] == 'synced') {
          keysToDelete.add(key.toString());
        }
      }
    }

    for (var key in keysToDelete) {
      await workoutsBox.delete(key);
    }
  }

  // ==================== STATISTICS ====================

  // Get storage stats
  Map<String, int> getStorageStats() {
    return {
      'workouts': Hive.box(_workoutsBox).length,
      'exercises': Hive.box(_exercisesBox).length,
      'measurements': Hive.box(_measurementsBox).length,
      'pendingSync': getPendingSyncWorkouts().length,
    };
  }
}
