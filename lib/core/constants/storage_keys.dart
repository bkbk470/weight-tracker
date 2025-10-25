/// Storage keys for local persistence
class StorageKeys {
  StorageKeys._();

  // Hive Box Names
  static const String workoutsBox = 'workouts';
  static const String exercisesBox = 'exercises';
  static const String exerciseHistoryBox = 'exercise_history';
  static const String settingsBox = 'settings';
  static const String measurementsBox = 'measurements';
  static const String goalsBox = 'goals';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String lastSyncTimestampKey = 'last_sync_timestamp';
  static const String isFirstLaunchKey = 'is_first_launch';

  // Cache Keys
  static const String exercisesCacheKey = 'exercises_cache';
  static const String workoutsCacheKey = 'workouts_cache';
  static const String profileCacheKey = 'profile_cache';
}
