import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'services/local_storage_service.dart';
import 'services/supabase_service.dart';
import 'services/sync_service.dart';
import 'services/notification_service.dart';
import 'services/workout_session_service.dart';
import 'services/exercise_cache_service.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/welcome_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/workout_library_screen.dart';
import 'screens/active_workout_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/about_screen.dart';
import 'screens/workout_builder_screen.dart' as workout_builder;
import 'screens/exercise_detail_screen.dart';
import 'screens/goals_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/privacy_policy_screen.dart';
import 'screens/exercises_screen.dart';
import 'screens/workout_detail_screen.dart';
import 'screens/change_password_screen.dart';
import 'screens/measurements_screen.dart';
import 'screens/storage_settings_screen.dart';
import 'screens/create_exercise_screen.dart';
import 'screens/supabase_test_screen.dart';
import 'screens/simple_test_screen.dart';
import 'screens/database_debug_screen.dart';
import 'screens/workout_history_screen.dart';
import 'screens/test_image_screen.dart';
import 'screens/storage_browser_screen.dart';
import 'screens/workout_folders_screen.dart';
import 'screens/comprehensive_debug_screen.dart';
import 'services/workout_timer_service.dart';
import 'utils/navigation_observers.dart';
import 'utils/safe_dialog_helpers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone database - CRITICAL for scheduled notifications!
  tz.initializeTimeZones();
  tz.setLocalLocation(tz.getLocation('America/New_York')); // Or use your timezone

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://rpfgqwkvvnhcjayzodmn.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJwZmdxd2t2dm5oY2pheXpvZG1uIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAxOTA5MTMsImV4cCI6MjA3NTc2NjkxM30.XWh2yxp4AcKWlgDHpLNhB7H7LQpzFEFbEZ-Y4T-CDcU',
  );

  // Initialize local storage
  await LocalStorageService.instance.init();

  // Initialize notification service and request permissions
  await NotificationService.instance.initialize();
  await NotificationService.instance.requestPermissions();

  // Pre-load exercises in background (non-blocking)
  ExerciseCacheService.instance.preloadExercises();

  runApp(const WeightTrackerApp());
}

class WeightTrackerApp extends StatefulWidget {
  const WeightTrackerApp({super.key});

  @override
  State<WeightTrackerApp> createState() => _WeightTrackerAppState();
}

class _WeightTrackerAppState extends State<WeightTrackerApp> {
  ThemeMode _themeMode = ThemeMode.system;
  bool _isLoadingTheme = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  Future<void> _loadThemePreference() async {
    try {
      // Always load from local storage first for immediate application
      String themeModeString = LocalStorageService.instance.getThemeMode();
      
      // Convert string to ThemeMode
      ThemeMode mode;
      switch (themeModeString.toLowerCase()) {
        case 'light':
          mode = ThemeMode.light;
          break;
        case 'dark':
          mode = ThemeMode.dark;
          break;
        case 'system':
        default:
          mode = ThemeMode.system;
          break;
      }

      if (mounted) {
        setState(() {
          _themeMode = mode;
          _isLoadingTheme = false;
        });
      }

      // Try to sync from Supabase in the background if user is logged in
      _syncThemeFromSupabase();
    } catch (e) {
      print('Error loading theme preference: $e');
      if (mounted) {
        setState(() {
          _themeMode = ThemeMode.system;
          _isLoadingTheme = false;
        });
      }
    }
  }

  Future<void> _syncThemeFromSupabase() async {
    try {
      if (SupabaseService.instance.currentUserId != null) {
        final settings = await SupabaseService.instance.getUserSettings();
        if (settings != null) {
          final themeModeString = settings['theme_mode'] as String?;
          if (themeModeString != null) {
            // Check if Supabase theme differs from local
            final localTheme = LocalStorageService.instance.getThemeMode();
            if (themeModeString != localTheme) {
              // Update local storage to match Supabase
              await LocalStorageService.instance.saveThemeMode(themeModeString);
              
              // Update UI
              ThemeMode mode;
              switch (themeModeString.toLowerCase()) {
                case 'light':
                  mode = ThemeMode.light;
                  break;
                case 'dark':
                  mode = ThemeMode.dark;
                  break;
                case 'system':
                default:
                  mode = ThemeMode.system;
                  break;
              }
              
              if (mounted) {
                setState(() {
                  _themeMode = mode;
                });
              }
            }
          }
        }
      }
    } catch (e) {
      print('Error syncing theme from Supabase: $e');
      // Not critical, local theme is already loaded
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    setState(() {
      _themeMode = mode;
    });

    // Convert ThemeMode to string
    String modeString;
    switch (mode) {
      case ThemeMode.light:
        modeString = 'light';
        break;
      case ThemeMode.dark:
        modeString = 'dark';
        break;
      case ThemeMode.system:
      default:
        modeString = 'system';
        break;
    }

    // Save to local storage
    try {
      await LocalStorageService.instance.saveThemeMode(modeString);
    } catch (e) {
      print('Error saving theme to local storage: $e');
    }

    // Try to save to Supabase
    try {
      if (SupabaseService.instance.currentUserId != null) {
        await SupabaseService.instance.upsertUserSettings({
          'theme_mode': modeString,
        });
      }
    } catch (e) {
      print('Error saving theme to Supabase: $e');
      // Don't show error to user, local storage is sufficient
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      navigatorObservers: [UnfocusOnNavigateObserver()],
      builder: (context, child) {
        return GestureDetector(
          onTap: () {
            // Global unfocus on any tap
            FocusManager.instance.primaryFocus?.unfocus();
          },
          behavior: HitTestBehavior.translucent,
          child: child,
        );
      },
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0891b2),
          secondary: const Color(0xFF16a34a),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFEFEFE),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00d4ff),
          secondary: const Color(0xFF39ff14),
          brightness: Brightness.dark,
          surface: const Color(0xFF1a1a1a),
        ),
        scaffoldBackgroundColor: const Color(0xFF0a0a0a),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
      ),
      home: AppNavigator(
        onThemeChanged: setThemeMode,
        currentThemeMode: _themeMode,
        onThemeReload: _syncThemeFromSupabase,
      ),
    );
  }
}

class AppNavigator extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  final ThemeMode currentThemeMode;
  final VoidCallback onThemeReload;

  const AppNavigator({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
    required this.onThemeReload,
  });

  @override
  State<AppNavigator> createState() => _AppNavigatorState();
}

class _AppNavigatorState extends State<AppNavigator> {
  String currentScreen = 'splash';
  String? _previousScreen;
  int selectedBottomNavIndex = 0;
  bool autoStartWorkout = false;
  bool hasActiveWorkout = false;
  int activeWorkoutTime = 0;
  WorkoutScreen? _activeWorkoutScreen;
  WorkoutDetailScreen? _cachedWorkoutDetailScreen;
  Map<String, dynamic>? _cachedWorkoutDetailData;
  Timer? _bannerUpdateTimer;
  List<Map<String, dynamic>>? _workoutExercises;
  String? _activeWorkoutId;
  String? _activeWorkoutName;
  Map<String, dynamic>? _selectedWorkout;
  List<Map<String, dynamic>>? _lastWorkoutExercises;
  String? _lastWorkoutId;
  String? _lastWorkoutName;
  String? _workoutLibraryTab; // Add this to track which tab to show
  Map<String, dynamic>? _selectedExercise;

  @override
  void initState() {
    super.initState();
    _loadPersistedWorkoutSession();
  }

  @override
  void dispose() {
    _bannerUpdateTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPersistedWorkoutSession() async {
    final session = await WorkoutSessionService.instance.loadWorkoutSession();

    if (session != null && mounted) {
      setState(() {
        hasActiveWorkout = true;
        _activeWorkoutName = session['workoutName'] as String?;
        _activeWorkoutId = session['workoutId'] as String?;
        _lastWorkoutName = _activeWorkoutName;
        _lastWorkoutId = _activeWorkoutId;

        final exercises = session['exercises'] as List<Map<String, dynamic>>?;
        if (exercises != null) {
          _lastWorkoutExercises = exercises;
          _workoutExercises = List<Map<String, dynamic>>.from(exercises);
        }

        // Restore the timer service state if we have a start time
        final startTime = session['startTime'] as DateTime?;
        if (startTime != null) {
          final elapsedSeconds = DateTime.now().difference(startTime).inSeconds;
          WorkoutTimerService.instance.start();
          // Set the elapsed time based on how long ago the workout started
          activeWorkoutTime = elapsedSeconds;
        }
      });

      // Only navigate if we're not already on active-workout or splash screen
      // (splash screen will handle navigation to active-workout)
      if (currentScreen != 'active-workout' && currentScreen != 'splash') {
        navigate('active-workout');
      }
    }
  }

  void navigate(String screen, [BuildContext? context, Map<String, dynamic>? data]) {
    // Check if trying to start a new workout while one is active
    if (screen == 'active-workout-start' && hasActiveWorkout) {
      if (context != null) {
        _showNewWorkoutDialog(context);
      }
      return;
    }
    
    setState(() {
      if (data != null) {
        // Check for selectedTab in data
        if (data.containsKey('selectedTab')) {
          _workoutLibraryTab = data['selectedTab'] as String?;
        }
        if (data.containsKey('exercises')) {
          final exercisesList = List<Map<String, dynamic>>.from(data['exercises']);
          _workoutExercises = exercisesList;
          _lastWorkoutExercises = List<Map<String, dynamic>>.from(data['exercises']);
        }
        if (data.containsKey('workoutId')) {
          final providedId = data['workoutId'] as String?;
          _activeWorkoutId = providedId;
          _lastWorkoutId = providedId;
        }
        if (data.containsKey('workoutName')) {
          final providedName = (data['workoutName'] as String?)?.trim();
          if (providedName != null && providedName.isNotEmpty) {
            _activeWorkoutName = providedName;
            _lastWorkoutName = providedName;
          }
        }
        if (data.containsKey('workout')) {
          _selectedWorkout = data['workout'] as Map<String, dynamic>?;
          final workoutName = (_selectedWorkout?['name'] as String?)?.trim();
          if (workoutName != null && workoutName.isNotEmpty) {
            _activeWorkoutName = workoutName;
            _lastWorkoutName = workoutName;
          }
        }
        if (data.containsKey('exercise')) {
          final exerciseData = data['exercise'];
          if (exerciseData is Map<String, dynamic>) {
            _selectedExercise = Map<String, dynamic>.from(exerciseData);
          }
        }
      }
      if (screen == 'workout-detail' && (data == null || !data.containsKey('workout'))) {
        _selectedWorkout = null;
      }
      if (screen == 'exercise-detail' && (data == null || !data.containsKey('exercise'))) {
        _selectedExercise = null;
      }

      if (currentScreen != screen) {
        _previousScreen = currentScreen;

        // Clear workout detail cache when leaving that screen
        if (currentScreen == 'workout-detail') {
          _cachedWorkoutDetailScreen = null;
          _cachedWorkoutDetailData = null;
        }
      }

      // Don't reset active workout when navigating to active-workout
      if (screen == 'active-workout') {
        currentScreen = screen;
        return;
      }

      currentScreen = screen;
      
      // Reload theme when navigating to dashboard (after login)
      if (screen == 'dashboard') {
        widget.onThemeReload();
        selectedBottomNavIndex = 0;
      } else if (screen == 'exercises') {
        selectedBottomNavIndex = 1;
      } else if (screen == 'workout') {
        selectedBottomNavIndex = 2;
        // Reset tab selection when navigating to workout normally (not from Templates button)
        if (data == null || !data.containsKey('selectedTab')) {
          _workoutLibraryTab = null;
        }
      } else if (screen == 'progress') {
        selectedBottomNavIndex = 3;
      } else if (screen == 'profile') {
        selectedBottomNavIndex = 4;
      }
      
      // Reset autostart flag when changing screens
      if (screen != 'active-workout') {
        autoStartWorkout = false;
      }
      // Set autostart when coming from workout detail/start
      if (screen == 'active-workout-start') {
        currentScreen = 'active-workout';
        autoStartWorkout = true;
        hasActiveWorkout = true;
        if (_activeWorkoutName == null || _activeWorkoutName!.isEmpty) {
          _activeWorkoutName = (_lastWorkoutName != null && _lastWorkoutName!.isNotEmpty)
              ? _lastWorkoutName
              : 'Workout';
        }
      }
    });
  }

  void _showNewWorkoutDialog(BuildContext context) {
    // Unfocus immediately
    FocusManager.instance.primaryFocus?.unfocus();
    
    showSafeDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Active Workout'),
        content: const Text(
          'You have a workout in progress. What would you like to do?',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Continue existing workout
              navigate('active-workout');
            },
            child: const Text('Continue Current'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              // Cancel existing and start new
              final restartExercises = _lastWorkoutExercises != null
                  ? List<Map<String, dynamic>>.from(_lastWorkoutExercises!)
                  : null;
              final restartData = <String, dynamic>{};
              if (restartExercises != null) {
                restartData['exercises'] = restartExercises;
              }
              if (_lastWorkoutName != null) {
                restartData['workoutName'] = _lastWorkoutName;
              }
              if (_lastWorkoutId != null) {
                restartData['workoutId'] = _lastWorkoutId;
              }

              setState(() {
                _activeWorkoutScreen = null;
                hasActiveWorkout = false;
                activeWorkoutTime = 0;
                autoStartWorkout = true;
                _workoutExercises = restartExercises;
                _activeWorkoutId = _lastWorkoutId;
                _activeWorkoutName = (_lastWorkoutName != null && _lastWorkoutName!.isNotEmpty)
                    ? _lastWorkoutName
                    : 'Workout';
              });
              WorkoutTimerService.instance.reset();
              navigate('active-workout-start', context, restartData.isNotEmpty ? restartData : null);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Start New'),
          ),
        ],
      ),
    );
  }

  void setActiveWorkout(bool active, int time) {
    setState(() {
      hasActiveWorkout = active;
      activeWorkoutTime = time;
      // Clear the workout screen when workout ends
      if (!active) {
        _activeWorkoutScreen = null;
        _bannerUpdateTimer?.cancel();
        _bannerUpdateTimer = null;
        _workoutExercises = null;
        _activeWorkoutId = null;
        _activeWorkoutName = null;
        _selectedWorkout = null;
        // Clear persisted workout session
        WorkoutSessionService.instance.clearWorkoutSession();
      } else if (_bannerUpdateTimer == null) {
        // Start a timer to update the banner every second
        _bannerUpdateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted && hasActiveWorkout) {
            setState(() {
              activeWorkoutTime = WorkoutTimerService.instance.elapsedSeconds;
            });
          } else {
            timer.cancel();
          }
        });
        // Save workout session when it starts
        // Calculate start time based on current elapsed time
        final elapsedSeconds = WorkoutTimerService.instance.elapsedSeconds;
        final startTime = DateTime.now().subtract(Duration(seconds: elapsedSeconds));
        WorkoutSessionService.instance.saveWorkoutSession(
          workoutName: _activeWorkoutName,
          workoutId: _activeWorkoutId,
          exercises: _lastWorkoutExercises,
          startTime: startTime,
        );
      }
    });
  }

  Widget getScreen() {
    switch (currentScreen) {
      case 'splash':
        return SplashScreen(onNavigate: (screen) => navigate(screen, context));
      case 'login':
        return LoginScreen(onNavigate: (screen) => navigate(screen, context));
      case 'welcome':
        return WelcomeScreen(onNavigate: (screen) => navigate(screen, context));
      case 'dashboard':
        return DashboardScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
          hasActiveWorkout: hasActiveWorkout,
          activeWorkoutTime: activeWorkoutTime,
        );
      case 'workout':
        final initialTab = _workoutLibraryTab;
        _workoutLibraryTab = null; // Reset after using
        return WorkoutLibraryScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
          initialTab: initialTab,
        );
      case 'active-workout':
        // Return existing workout screen if it exists, otherwise create new one
        if (_activeWorkoutScreen != null && hasActiveWorkout) {
          return _activeWorkoutScreen!;
        }

        // When restoring a workout session, use the exercises and workout data
        final exercisesToUse = _workoutExercises ?? _lastWorkoutExercises;
        final workoutIdToUse = _activeWorkoutId ?? _lastWorkoutId;
        final workoutNameToUse = _activeWorkoutName ?? _lastWorkoutName;

        _activeWorkoutScreen = WorkoutScreen(
          onNavigate: (screen) => navigate(screen, context),
          autoStart: autoStartWorkout,
          workoutName: workoutNameToUse,
          workoutId: workoutIdToUse,
          onWorkoutStateChanged: setActiveWorkout,
          preloadedExercises: exercisesToUse,
        );

        // Only clear if not restoring from a persisted session
        if (!hasActiveWorkout) {
          _workoutExercises = null;
          _activeWorkoutId = null;
        }

        return _activeWorkoutScreen!;
      case 'progress':
        return ProgressScreen(onNavigate: (screen) => navigate(screen, context));
      case 'profile':
        return ProfileScreen(
          onNavigate: (screen) => navigate(screen, context),
          onThemeChanged: widget.onThemeChanged,
          currentThemeMode: widget.currentThemeMode,
        );
      case 'about':
        return AboutScreen(onNavigate: (screen) => navigate(screen, context));
      case 'workout-builder':
        return workout_builder.WorkoutBuilderScreen(onNavigate: (screen) => navigate(screen, context));
      case 'exercise-detail':
        return ExerciseDetailScreen(
          onNavigate: (screen) => navigate(screen, context),
          returnScreen: _previousScreen,
          exercise: _selectedExercise,
        );
      case 'goals':
        return GoalsScreen(onNavigate: (screen) => navigate(screen, context));
      case 'notifications':
        return NotificationsScreen(onNavigate: (screen) => navigate(screen, context));
      case 'edit-profile':
        return EditProfileScreen(onNavigate: (screen) => navigate(screen, context));
      case 'help-support':
        return HelpSupportScreen(onNavigate: (screen) => navigate(screen, context));
      case 'privacy-policy':
        return PrivacyPolicyScreen(onNavigate: (screen) => navigate(screen, context));
      case 'exercises':
        return ExercisesScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
        );
      case 'workout-detail':
        // Cache the workout detail screen to prevent reloading
        if (_cachedWorkoutDetailScreen != null && _selectedWorkout == _cachedWorkoutDetailData) {
          return _cachedWorkoutDetailScreen!;
        }

        final workout = _selectedWorkout;

        // Refetch workout from database to get latest set_details
        if (workout != null && workout['id'] != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: SupabaseService.instance.getWorkout(workout['id'] as String),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final freshWorkout = snapshot.data ?? workout;
              final workoutExercises = _buildWorkoutExercises(freshWorkout);
              final durationMinutes = freshWorkout['estimated_duration_minutes'] as int?;

              final screen = WorkoutDetailScreen(
                onNavigate: (screen, [data]) => navigate(screen, context, data),
                workoutId: freshWorkout['id'] as String?,
                workoutName: freshWorkout['name'] as String? ?? 'Workout',
                workoutDescription: freshWorkout['description'] as String? ?? 'Custom workout',
                duration: durationMinutes != null ? '$durationMinutes min' : '45 min',
                difficulty: freshWorkout['difficulty'] as String? ?? 'Intermediate',
                initialExercises: workoutExercises,
                workoutData: freshWorkout,
              );

              // Cache the screen
              _cachedWorkoutDetailScreen = screen;
              _cachedWorkoutDetailData = _selectedWorkout;

              return screen;
            },
          );
        }

        // Fallback for workout without ID
        final workoutExercises = _buildWorkoutExercises(workout);
        final durationMinutes = workout?['estimated_duration_minutes'] as int?;
        final screen = WorkoutDetailScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
          workoutId: workout?['id'] as String?,
          workoutName: workout?['name'] as String? ?? 'Workout',
          workoutDescription: workout?['description'] as String? ?? 'Custom workout',
          duration: durationMinutes != null ? '$durationMinutes min' : '45 min',
          difficulty: workout?['difficulty'] as String? ?? 'Intermediate',
          initialExercises: workoutExercises,
          workoutData: workout,
        );

        // Cache the screen
        _cachedWorkoutDetailScreen = screen;
        _cachedWorkoutDetailData = _selectedWorkout;

        return screen;
      case 'change-password':
        return ChangePasswordScreen(onNavigate: (screen) => navigate(screen, context));
      case 'measurements':
        return MeasurementsScreen(onNavigate: (screen) => navigate(screen, context));
      case 'storage-settings':
        return StorageSettingsScreen(onNavigate: (screen) => navigate(screen, context));
      case 'create-exercise':
        return CreateExerciseScreen(onNavigate: (screen) => navigate(screen, context));
      case 'supabase-test':
        return const SupabaseTestScreen();
      case 'simple-test':
        return const SimpleTestScreen();
      case 'database-debug':
        return const DatabaseDebugScreen();
      case 'workout-folders':
        return WorkoutFoldersScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
        );
      case 'workout-history':
        return WorkoutHistoryScreen(
          onNavigate: (screen, [data]) => navigate(screen, context, data),
        );
      case 'test-image':
        return const TestImageScreen();
      case 'storage-browser':
        return const StorageBrowserScreen();
      case 'comprehensive-debug':
        return const ComprehensiveImageDebugScreen();
      default:
        return LoginScreen(onNavigate: (screen) => navigate(screen, context));
    }
  }

  List<WorkoutExercise>? _buildWorkoutExercises(Map<String, dynamic>? workout) {
    if (workout == null) return null;
    final rawExercises = workout['workout_exercises'] as List<dynamic>? ?? [];
    if (rawExercises.isEmpty) return []; // Return empty list for workouts with no exercises

    return List<WorkoutExercise>.generate(rawExercises.length, (index) {
      final exerciseMap = rawExercises[index] as Map<String, dynamic>;
      final exerciseInfo = exerciseMap['exercise'] as Map<String, dynamic>? ?? {};
      final name = (exerciseInfo['name'] ?? exerciseMap['exercise_name'] ?? 'Exercise') as String;
      final setsValue = exerciseMap['target_sets'] ?? exerciseMap['sets'] ?? 3;
      final repsValue = exerciseMap['target_reps'] ?? exerciseMap['reps'] ?? 10;
      final restTimeValue = exerciseMap['rest_time_seconds'] is int
          ? exerciseMap['rest_time_seconds'] as int
          : int.tryParse('${exerciseMap['rest_time_seconds']}') ?? 120;
      final notesValue = exerciseMap['notes'] as String? ?? '';
      final workoutExerciseId = exerciseMap['id'] as String?;
      final exerciseId = exerciseMap['exercise_id'] as String? ?? exerciseInfo['id'] as String?;
      final orderIndex = exerciseMap['order_index'] is int
          ? exerciseMap['order_index'] as int
          : int.tryParse('${exerciseMap['order_index']}') ?? index;

      // Try to load set details from JSON field if available
      final setDetailsRaw = exerciseMap['set_details'];
      List<WorkoutExerciseSet> sets;

      if (setDetailsRaw is List && setDetailsRaw.isNotEmpty) {
        debugPrint('📥 Loading $name from set_details: $setDetailsRaw');
        // Load individual set details from database
        sets = setDetailsRaw.map((setData) {
          final weight = setData is Map ? (setData['weight'] is int ? setData['weight'] as int : int.tryParse('${setData['weight']}') ?? 0) : 0;
          final reps = setData is Map ? (setData['reps'] is int ? setData['reps'] as int : int.tryParse('${setData['reps']}') ?? repsValue) : repsValue;
          final rest = setData is Map ? (setData['rest'] is int ? setData['rest'] as int : int.tryParse('${setData['rest']}') ?? restTimeValue) : restTimeValue;
          return WorkoutExerciseSet(
            weight: weight,
            reps: reps,
            restSeconds: rest,
          );
        }).toList();
        debugPrint('✅ Loaded ${sets.length} sets from set_details for $name');
      } else {
        debugPrint('⚠️  No set_details for $name, using defaults (weight=0, reps=$repsValue)');
        // Fallback: generate default sets (old behavior)
        final numSets = setsValue is int ? setsValue : int.tryParse('$setsValue') ?? 3;
        sets = List.generate(
          numSets,
          (_) => WorkoutExerciseSet(
            weight: 0,
            reps: repsValue is int ? repsValue : int.tryParse('$repsValue') ?? 10,
            restSeconds: restTimeValue,
          ),
        );
      }

      return WorkoutExercise(
        name: name,
        sets: sets,
        notes: notesValue,
        workoutExerciseId: workoutExerciseId,
        exerciseId: exerciseId,
        orderIndex: orderIndex,
      );
    });
  }

  bool showBottomNav() {
    return ['dashboard', 'exercises', 'workout', 'progress', 'profile'].contains(currentScreen);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: getScreen(),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Active Workout Banner
          if (showBottomNav() && hasActiveWorkout)
            InkWell(
              onTap: () => navigate('active-workout', context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  border: Border(
                    top: BorderSide(
                      color: colorScheme.secondary.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.secondary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.fitness_center,
                        color: colorScheme.onSecondary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            (_activeWorkoutName != null && _activeWorkoutName!.isNotEmpty)
                                ? 'Workout in Progress (${_activeWorkoutName!})'
                                : 'Workout in Progress',
                            style: textTheme.labelLarge?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            _formatTime(activeWorkoutTime),
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          // Navigation Bar
          if (showBottomNav())
            SafeArea(
              top: false,
              child: NavigationBar(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                height: 72,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                selectedIndex: selectedBottomNavIndex,
                onDestinationSelected: (index) {
                  setState(() {
                    selectedBottomNavIndex = index;
                    switch (index) {
                      case 0:
                        currentScreen = 'dashboard';
                        break;
                      case 1:
                        currentScreen = 'exercises';
                        break;
                      case 2:
                        currentScreen = 'workout';
                        break;
                      case 3:
                        currentScreen = 'progress';
                        break;
                      case 4:
                        currentScreen = 'profile';
                        break;
                    }
                  });
                },
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: 'Home',
                    tooltip: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.list_alt),
                    selectedIcon: Icon(Icons.list_alt),
                    label: 'Exercises',
                    tooltip: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.fitness_center_outlined),
                    selectedIcon: Icon(Icons.fitness_center),
                    label: 'Workout',
                    tooltip: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.trending_up_outlined),
                    selectedIcon: Icon(Icons.trending_up),
                    label: 'Progress',
                    tooltip: '',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(Icons.person),
                    label: 'Profile',
                    tooltip: '',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '$mins:${secs.toString().padLeft(2, '0')}';
  }
}
