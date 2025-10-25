/// Application-wide constants
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Weight Tracker';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 24);
  static const Duration shortDebounce = Duration(milliseconds: 300);
  static const Duration longDebounce = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxHistoryItems = 50;

  // Workout Defaults
  static const int defaultRestTime = 120; // seconds
  static const int defaultSets = 3;
  static const int defaultReps = 10;
  static const int defaultWeight = 0;

  // Limits
  static const int maxExercisesPerWorkout = 20;
  static const int maxSetsPerExercise = 10;
  static const int minRestTime = 0;
  static const int maxRestTime = 600; // 10 minutes
  static const int maxWeight = 9999;
  static const int maxReps = 999;

  // Timer
  static const int timerUpdateInterval = 1; // seconds
}

/// Validation-related constants
class ValidationConstants {
  ValidationConstants._();

  // Authentication
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 128;
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';

  // Exercise/Workout
  static const int minExerciseNameLength = 2;
  static const int maxExerciseNameLength = 50;
  static const int minWorkoutNameLength = 2;
  static const int maxWorkoutNameLength = 50;
  static const int maxNotesLength = 500;
  static const int maxDescriptionLength = 200;
}

/// UI-related constants
class UIConstants {
  UIConstants._();

  // Spacing
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double mediumPadding = 12.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // Sizing
  static const double borderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 18.0;
  static const double largeIconSize = 32.0;

  // Elevation
  static const double cardElevation = 2.0;
  static const double dialogElevation = 8.0;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
}

/// Route names for navigation
class Routes {
  Routes._();

  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String login = '/login';
  static const String dashboard = '/dashboard';
  static const String exercises = '/exercises';
  static const String exerciseDetail = '/exercise-detail';
  static const String createExercise = '/create-exercise';
  static const String workout = '/workout';
  static const String workoutDetail = '/workout-detail';
  static const String workoutFolders = '/workout-folders';
  static const String activeWorkout = '/active-workout';
  static const String activeWorkoutStart = '/active-workout-start';
  static const String workoutHistory = '/workout-history';
  static const String progress = '/progress';
  static const String profile = '/profile';
  static const String editProfile = '/edit-profile';
  static const String changePassword = '/change-password';
  static const String measurements = '/measurements';
  static const String goals = '/goals';
  static const String notifications = '/notifications';
  static const String storageSettings = '/storage-settings';
  static const String helpSupport = '/help-support';
  static const String about = '/about';
  static const String privacyPolicy = '/privacy-policy';
}
