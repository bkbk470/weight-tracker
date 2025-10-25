# Weight Tracker Flutter - Comprehensive Refactoring Plan

**Generated:** October 25, 2025
**Project Size:** ~23,690 lines of code across 47 Dart files
**Status:** Production app requiring architectural improvements

---

## Executive Summary

This plan outlines a systematic approach to transform the Weight Tracker Flutter app from a setState-based monolith into a professional, maintainable, and scalable application following industry best practices.

**Timeline:** 6-8 weeks (phased approach)
**Risk:** Low (incremental changes with backward compatibility)
**Impact:** High (improved maintainability, testability, and developer experience)

---

## Phase 1: Foundation & Cleanup (Week 1)

### 1.1 Remove Technical Debt
- [ ] Delete duplicate folders (`constants 2`, `widgets 2`)
- [ ] Remove debug/test files from production:
  - `exercises_screen_debug.dart`
  - `supabase_test_screen.dart`
  - `simple_test_screen.dart`
  - `test_image_screen.dart`
  - `database_debug_screen.dart`
  - `comprehensive_debug_screen.dart`
  - `storage_browser_screen.dart`
- [ ] Consolidate duplicate screens:
  - Merge `workout_detail_screen_fixed.dart` → `workout_detail_screen.dart`
  - Merge `workout_folders_screen_updated.dart` → `workout_folders_screen.dart`

### 1.2 Add Essential Packages
```yaml
dependencies:
  # State Management
  flutter_riverpod: ^2.5.0  # or provider: ^6.1.0

  # Dependency Injection
  get_it: ^7.6.0
  injectable: ^2.3.0

  # Code Generation
  freezed: ^2.5.0
  json_serializable: ^6.7.0

  # Utilities
  logger: ^2.0.0  # Replace print()
  dartz: ^0.10.1  # Functional error handling

dev_dependencies:
  build_runner: ^2.4.0
  injectable_generator: ^2.4.0
  freezed_annotation: ^2.4.0
```

### 1.3 Create Professional Folder Structure
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   ├── api_constants.dart
│   │   ├── storage_keys.dart
│   │   └── exercise_assets.dart (existing)
│   ├── config/
│   │   ├── app_config.dart
│   │   ├── env/
│   │   │   ├── env.dart
│   │   │   ├── env_dev.dart
│   │   │   └── env_prod.dart
│   │   └── theme/
│   │       └── app_theme.dart
│   ├── errors/
│   │   ├── failures.dart
│   │   ├── exceptions.dart
│   │   └── error_handler.dart
│   ├── network/
│   │   └── network_info.dart
│   ├── utils/
│   │   ├── logger.dart
│   │   ├── validators.dart
│   │   ├── extensions/
│   │   │   ├── datetime_extension.dart
│   │   │   ├── string_extension.dart
│   │   │   └── num_extension.dart
│   │   └── (existing utils)
│   └── injection/
│       ├── injection.dart
│       └── injection.config.dart (generated)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── providers/
│   │       ├── screens/
│   │       └── widgets/
│   │
│   ├── workout/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── exercise/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   ├── progress/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   │
│   └── profile/
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/
│   └── widgets/
│       ├── buttons/
│       ├── inputs/
│       ├── cards/
│       └── dialogs/
│
└── main.dart
```

---

## Phase 2: Constants & Configuration (Week 1-2)

### 2.1 Create Constants Files

**`lib/core/constants/app_constants.dart`:**
```dart
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // App Info
  static const String appName = 'Weight Tracker';
  static const String appVersion = '1.0.0';

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration cacheExpiry = Duration(hours: 24);

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxHistoryItems = 50;

  // Defaults
  static const int defaultRestTime = 120; // seconds
  static const int defaultSets = 3;
  static const int defaultReps = 10;
  static const int defaultWeight = 0;

  // Limits
  static const int maxExercisesPerWorkout = 20;
  static const int maxSetsPerExercise = 10;
  static const int minRestTime = 0;
  static const int maxRestTime = 600;
  static const int maxWeight = 9999;
}

class ValidationConstants {
  ValidationConstants._();

  static const int minPasswordLength = 6;
  static const int maxNotesLength = 500;
  static const int minExerciseNameLength = 2;
  static const int maxExerciseNameLength = 50;
}

class UIConstants {
  UIConstants._();

  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 8.0;
  static const double iconSize = 24.0;
}
```

**`lib/core/constants/storage_keys.dart`:**
```dart
class StorageKeys {
  StorageKeys._();

  // Hive Box Names
  static const String workoutsBox = 'workouts';
  static const String exercisesBox = 'exercises';
  static const String exerciseHistoryBox = 'exercise_history';
  static const String settingsBox = 'settings';

  // Shared Preferences Keys
  static const String userIdKey = 'user_id';
  static const String themeKey = 'theme_mode';
  static const String onboardingCompleteKey = 'onboarding_complete';
}
```

**`lib/core/config/env/env.dart`:**
```dart
import 'package:flutter/foundation.dart';

enum Environment { dev, staging, prod }

class Env {
  static Environment current = kDebugMode ? Environment.dev : Environment.prod;

  static String get supabaseUrl {
    switch (current) {
      case Environment.dev:
        return const String.fromEnvironment('SUPABASE_URL_DEV',
            defaultValue: ''); // Load from --dart-define
      case Environment.staging:
        return const String.fromEnvironment('SUPABASE_URL_STAGING',
            defaultValue: '');
      case Environment.prod:
        return const String.fromEnvironment('SUPABASE_URL_PROD',
            defaultValue: '');
    }
  }

  static String get supabaseAnonKey {
    switch (current) {
      case Environment.dev:
        return const String.fromEnvironment('SUPABASE_ANON_KEY_DEV',
            defaultValue: '');
      case Environment.staging:
        return const String.fromEnvironment('SUPABASE_ANON_KEY_STAGING',
            defaultValue: '');
      case Environment.prod:
        return const String.fromEnvironment('SUPABASE_ANON_KEY_PROD',
            defaultValue: '');
    }
  }

  static bool get enableLogging => current != Environment.prod;
  static bool get enableDebugTools => current == Environment.dev;
}
```

### 2.2 Create Logger Utility

**`lib/core/utils/logger.dart`:**
```dart
import 'package:logger/logger.dart';
import '../config/env/env.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 120,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: Env.enableLogging ? Level.debug : Level.error,
  );

  static void d(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  static void i(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  static void w(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  static void e(dynamic message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
```

---

## Phase 3: Models & Entities (Week 2-3)

### 3.1 Create Freezed Models with Validation

**`lib/features/exercise/domain/entities/exercise.dart`:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

@freezed
class Exercise with _$Exercise {
  const Exercise._();

  const factory Exercise({
    required String id,
    required String name,
    required List<ExerciseSet> sets,
    @Default(120) int restTime,
    @Default('') String notes,
    String? workoutExerciseId,
    String? supabaseExerciseId,
    int? orderIndex,
    DateTime? previousDate,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  // Validation
  bool get isValid =>
      name.trim().isNotEmpty &&
      sets.isNotEmpty &&
      restTime >= 0;

  // Business Logic
  int get completedSetsCount =>
      sets.where((set) => set.completed).length;

  double get totalVolume => sets.fold(
      0.0, (sum, set) => sum + (set.weight * set.reps));
}

@freezed
class ExerciseSet with _$ExerciseSet {
  const ExerciseSet._();

  const factory ExerciseSet({
    @Default(0) int weight,
    @Default(0) int reps,
    @Default(false) bool completed,
    @Default(false) bool isResting,
    @Default(0) int restStartTime,
    @Default(0) int currentRestTime,
    double? previousWeight,
    int? previousReps,
    @Default(0) int plannedRestSeconds,
  }) = _ExerciseSet;

  factory ExerciseSet.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSetFromJson(json);

  bool get hasData => weight > 0 || reps > 0;

  ExerciseSet copyWithToggleCompleted() =>
      copyWith(completed: !completed);
}
```

**`lib/features/workout/domain/entities/workout.dart`:**
```dart
@freezed
class Workout with _$Workout {
  const factory Workout({
    required String id,
    required String name,
    String? description,
    String? difficulty,
    int? estimatedDurationMinutes,
    required List<WorkoutExercise> exercises,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Workout;

  factory Workout.fromJson(Map<String, dynamic> json) =>
      _$WorkoutFromJson(json);
}

@freezed
class WorkoutExercise with _$WorkoutExercise {
  const factory WorkoutExercise({
    required String name,
    required List<WorkoutSet> sets,
    @Default('') String notes,
    String? workoutExerciseId,
    String? exerciseId,
    int? orderIndex,
  }) = _WorkoutExercise;

  factory WorkoutExercise.fromJson(Map<String, dynamic> json) =>
      _$WorkoutExerciseFromJson(json);
}

@freezed
class WorkoutSet with _$WorkoutSet {
  const factory WorkoutSet({
    @Default(0) int weight,
    @Default(10) int reps,
    @Default(120) int restSeconds,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSetFromJson(json);
}
```

---

## Phase 4: Error Handling Framework (Week 3)

### 4.1 Create Failure Classes

**`lib/core/errors/failures.dart`:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failures.freezed.dart';

@freezed
class Failure with _$Failure {
  const factory Failure.server(String message) = ServerFailure;
  const factory Failure.network(String message) = NetworkFailure;
  const factory Failure.cache(String message) = CacheFailure;
  const factory Failure.validation(String message) = ValidationFailure;
  const factory Failure.authentication(String message) = AuthenticationFailure;
  const factory Failure.notFound(String message) = NotFoundFailure;
  const factory Failure.unexpected(String message) = UnexpectedFailure;
}

extension FailureX on Failure {
  String get userMessage => when(
    server: (msg) => 'Server error: $msg',
    network: (msg) => 'Network error: Check your connection',
    cache: (msg) => 'Local storage error: $msg',
    validation: (msg) => msg,
    authentication: (msg) => 'Authentication error: $msg',
    notFound: (msg) => 'Not found: $msg',
    unexpected: (msg) => 'Unexpected error: $msg',
  );
}
```

### 4.2 Create Result Type (Either)

**`lib/core/utils/result.dart`:**
```dart
import 'package:dartz/dartz.dart';
import '../errors/failures.dart';

typedef Result<T> = Either<Failure, T>;

extension ResultX<T> on Result<T> {
  T getOrThrow() => fold(
    (failure) => throw Exception(failure.userMessage),
    (value) => value,
  );

  T? getOrNull() => fold(
    (_) => null,
    (value) => value,
  );

  T getOrElse(T Function() defaultValue) => fold(
    (_) => defaultValue(),
    (value) => value,
  );
}
```

---

## Phase 5: Repository Pattern (Week 3-4)

### 5.1 Define Repository Interfaces

**`lib/features/exercise/domain/repositories/exercise_repository.dart`:**
```dart
import 'package:dartz/dartz.dart';
import '../../../../core/errors/failures.dart';
import '../entities/exercise.dart';

abstract class ExerciseRepository {
  Future<Either<Failure, List<Exercise>>> getExercises();
  Future<Either<Failure, Exercise>> getExerciseById(String id);
  Future<Either<Failure, Exercise>> createExercise(Exercise exercise);
  Future<Either<Failure, Exercise>> updateExercise(Exercise exercise);
  Future<Either<Failure, void>> deleteExercise(String id);
  Future<Either<Failure, List<ExerciseSet>>> getLatestSetsForExercise(
    String exerciseId, {
    int limit = 30,
  });
}
```

### 5.2 Implement Repositories

**`lib/features/exercise/data/repositories/exercise_repository_impl.dart`:**
```dart
import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';
import '../datasources/exercise_local_datasource.dart';
import '../datasources/exercise_remote_datasource.dart';
import '../models/exercise_model.dart';

@LazySingleton(as: ExerciseRepository)
class ExerciseRepositoryImpl implements ExerciseRepository {
  final ExerciseRemoteDataSource remoteDataSource;
  final ExerciseLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  ExerciseRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<Exercise>>> getExercises() async {
    if (await networkInfo.isConnected) {
      try {
        final exercises = await remoteDataSource.getExercises();
        await localDataSource.cacheExercises(exercises);
        return Right(exercises.map((e) => e.toEntity()).toList());
      } on ServerException catch (e) {
        AppLogger.e('Failed to fetch exercises from server', e);
        return Left(Failure.server(e.message));
      } catch (e) {
        AppLogger.e('Unexpected error fetching exercises', e);
        return Left(Failure.unexpected(e.toString()));
      }
    } else {
      try {
        final exercises = await localDataSource.getCachedExercises();
        return Right(exercises.map((e) => e.toEntity()).toList());
      } on CacheException catch (e) {
        return Left(Failure.cache(e.message));
      }
    }
  }

  // ... other methods
}
```

---

## Phase 6: Dependency Injection (Week 4)

### 6.1 Setup GetIt with Injectable

**`lib/core/injection/injection.dart`:**
```dart
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit()
void configureDependencies() => getIt.init();
```

**`lib/core/injection/injection.config.dart`:** (Generated by build_runner)

### 6.2 Register Services

**Annotate services with @injectable:**
```dart
@lazySingleton
class SupabaseService {
  // ... existing code
}

@lazySingleton
class LocalStorageService {
  // ... existing code
}

@injectable
class NetworkInfo {
  final Connectivity connectivity;

  NetworkInfo(this.connectivity);

  Future<bool> get isConnected async {
    final result = await connectivity.checkConnectivity();
    return result != ConnectivityResult.none;
  }
}
```

### 6.3 Update main.dart

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Setup dependency injection
  configureDependencies();

  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(
    ProviderScope(
      child: const MyApp(),
    ),
  );
}
```

---

## Phase 7: State Management with Riverpod (Week 4-5)

### 7.1 Create Providers

**`lib/features/exercise/presentation/providers/exercise_provider.dart`:**
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/injection/injection.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/repositories/exercise_repository.dart';

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return getIt<ExerciseRepository>();
});

final exercisesProvider = FutureProvider<List<Exercise>>((ref) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  final result = await repository.getExercises();
  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (exercises) => exercises,
  );
});

final exerciseByIdProvider = FutureProvider.family<Exercise, String>((ref, id) async {
  final repository = ref.watch(exerciseRepositoryProvider);
  final result = await repository.getExerciseById(id);
  return result.fold(
    (failure) => throw Exception(failure.userMessage),
    (exercise) => exercise,
  );
});
```

### 7.2 Use Providers in UI

**Before (setState):**
```dart
class ExercisesScreen extends StatefulWidget {
  @override
  State<ExercisesScreen> createState() => _ExercisesScreenState();
}

class _ExercisesScreenState extends State<ExercisesScreen> {
  List<Map<String, dynamic>> exercises = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    setState(() => isLoading = true);
    try {
      final data = await SupabaseService.instance.getExercises();
      setState(() {
        exercises = data;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) return CircularProgressIndicator();
    return ListView.builder(
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return ListTile(title: Text(exercise['name']));
      },
    );
  }
}
```

**After (Riverpod):**
```dart
class ExercisesScreen extends ConsumerWidget {
  const ExercisesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(exercisesProvider);

    return exercisesAsync.when(
      data: (exercises) => ListView.builder(
        itemCount: exercises.length,
        itemBuilder: (context, index) {
          final exercise = exercises[index];
          return ListTile(title: Text(exercise.name));
        },
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Text('Error: ${error.toString()}'),
      ),
    );
  }
}
```

---

## Phase 8: Refactor Large Screens (Week 5-6)

### 8.1 Break Down active_workout_screen.dart (2,734 lines)

**Create feature-specific widgets:**
```
lib/features/workout/presentation/
├── screens/
│   └── active_workout_screen.dart (reduced to ~300 lines)
├── widgets/
│   ├── workout_timer_widget.dart
│   ├── exercise_card_widget.dart
│   ├── set_row_widget.dart
│   ├── rest_timer_widget.dart
│   ├── workout_controls_widget.dart
│   └── workout_completion_dialog.dart
└── providers/
    ├── active_workout_provider.dart
    └── workout_timer_provider.dart
```

**Extract business logic to providers:**
```dart
@riverpod
class ActiveWorkout extends _$ActiveWorkout {
  @override
  FutureOr<WorkoutState> build(String? workoutId) async {
    // Load workout data
    return WorkoutState.initial();
  }

  void updateSet(String exerciseId, int setIndex, String field, int value) {
    state = state.whenData((data) {
      // Business logic here
      return data.copyWith(/* updated data */);
    });
  }

  void completeSet(String exerciseId, int setIndex) {
    // Business logic
  }

  Future<void> saveWorkout() async {
    // Save logic
  }
}
```

### 8.2 Extract Reusable Widgets

**`lib/shared/widgets/inputs/editable_number_field.dart`:**
```dart
// Already exists - good example!
```

**`lib/shared/widgets/cards/exercise_card.dart`:**
```dart
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // Reusable card UI
  }
}
```

---

## Phase 9: Testing Infrastructure (Week 6-7)

### 9.1 Setup Testing Structure

```
test/
├── core/
│   ├── network/
│   │   └── network_info_test.dart
│   └── utils/
│       └── validators_test.dart
├── features/
│   ├── exercise/
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── exercise_model_test.dart
│   │   │   └── repositories/
│   │   │       └── exercise_repository_impl_test.dart
│   │   ├── domain/
│   │   │   └── usecases/
│   │   │       └── get_exercises_test.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── exercise_provider_test.dart
│   └── workout/
│       └── ...
└── helpers/
    ├── test_helpers.dart
    └── mock_data.dart
```

### 9.2 Example Unit Test

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:dartz/dartz.dart';

void main() {
  late ExerciseRepositoryImpl repository;
  late MockExerciseRemoteDataSource mockRemoteDataSource;
  late MockExerciseLocalDataSource mockLocalDataSource;
  late MockNetworkInfo mockNetworkInfo;

  setUp(() {
    mockRemoteDataSource = MockExerciseRemoteDataSource();
    mockLocalDataSource = MockExerciseLocalDataSource();
    mockNetworkInfo = MockNetworkInfo();
    repository = ExerciseRepositoryImpl(
      remoteDataSource: mockRemoteDataSource,
      localDataSource: mockLocalDataSource,
      networkInfo: mockNetworkInfo,
    );
  });

  group('getExercises', () {
    final tExerciseModels = [
      ExerciseModel(id: '1', name: 'Bench Press', sets: []),
      ExerciseModel(id: '2', name: 'Squat', sets: []),
    ];

    test('should check if device is online', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getExercises())
          .thenAnswer((_) async => tExerciseModels);
      when(mockLocalDataSource.cacheExercises(any))
          .thenAnswer((_) async => Future.value());

      // act
      await repository.getExercises();

      // assert
      verify(mockNetworkInfo.isConnected);
    });

    test('should return exercises when call to remote is successful', () async {
      // arrange
      when(mockNetworkInfo.isConnected).thenAnswer((_) async => true);
      when(mockRemoteDataSource.getExercises())
          .thenAnswer((_) async => tExerciseModels);
      when(mockLocalDataSource.cacheExercises(any))
          .thenAnswer((_) async => Future.value());

      // act
      final result = await repository.getExercises();

      // assert
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not return failure'),
        (exercises) => expect(exercises.length, 2),
      );
    });
  });
}
```

---

## Phase 10: Migration Checklist (Week 7-8)

### 10.1 Screen-by-Screen Migration

- [ ] Login Screen
  - [ ] Extract auth logic to AuthRepository
  - [ ] Create LoginProvider
  - [ ] Update UI to use ConsumerWidget
  - [ ] Add proper error handling
  - [ ] Write tests

- [ ] Dashboard Screen
  - [ ] Break down into widgets
  - [ ] Create DashboardProvider
  - [ ] Extract workout stats logic
  - [ ] Add proper loading states
  - [ ] Write tests

- [ ] Exercises Screen
  - [ ] Use ExerciseProvider
  - [ ] Add search/filter functionality
  - [ ] Implement pagination
  - [ ] Add error boundaries
  - [ ] Write tests

- [ ] Active Workout Screen (Priority!)
  - [ ] Extract to multiple widgets
  - [ ] Create ActiveWorkoutProvider
  - [ ] Create WorkoutTimerProvider
  - [ ] Implement proper state management
  - [ ] Add comprehensive tests

- [ ] ... (continue for all screens)

### 10.2 Service Migration

- [ ] Split SupabaseService into feature-specific services:
  - [ ] AuthService (authentication)
  - [ ] ExerciseService (exercises CRUD)
  - [ ] WorkoutService (workouts CRUD)
  - [ ] MeasurementService (measurements)
  - [ ] StorageService (file uploads)

- [ ] Update all services to use dependency injection
- [ ] Remove `.instance` singleton pattern
- [ ] Add proper interfaces
- [ ] Write comprehensive tests

---

## Implementation Order (Prioritized)

1. **Week 1**: Cleanup + Constants + Logger
2. **Week 2**: Models + Error Handling
3. **Week 3**: Repository Pattern (Exercise feature)
4. **Week 4**: Dependency Injection + Riverpod Setup
5. **Week 5**: Refactor Active Workout Screen
6. **Week 6**: Migrate remaining core screens
7. **Week 7**: Testing + Documentation
8. **Week 8**: Final cleanup + Performance optimization

---

## Success Metrics

### Code Quality Metrics
- **Before:**
  - 60 print statements
  - 245 dynamic types
  - 0 tests
  - Largest file: 2,734 lines
  - 0% type safety

- **After (Targets):**
  - 0 print statements (use logger)
  - <10 dynamic types (only where necessary)
  - >80% test coverage
  - No file >500 lines
  - >95% type safety

### Architecture Metrics
- Separation of concerns (UI/Domain/Data)
- Dependency direction (inward)
- Single Responsibility Principle adherence
- Testability (all business logic tested)
- Maintainability index

---

## Risk Mitigation

1. **Breaking Changes Risk**: Use feature flags to enable/disable new architecture
2. **Performance Risk**: Profile before/after with Flutter DevTools
3. **Bug Introduction Risk**: Comprehensive testing at each phase
4. **Timeline Risk**: Start with non-critical features first

---

## Next Steps

1. **Review this plan** with the team
2. **Setup development branch**: `feature/architecture-refactor`
3. **Start Phase 1**: Remove technical debt
4. **Weekly review meetings**: Track progress against plan
5. **Document as you go**: Update ARCHITECTURE.md

---

## Questions for Team Discussion

1. State Management: Riverpod vs Provider vs BLoC?
2. Should we use Clean Architecture strictly or adapt it?
3. Migration timeline: Can we afford 6-8 weeks?
4. Testing priority: Unit tests first or integration tests?
5. Should we pause new features during refactor?

---

**Document Version:** 1.0
**Last Updated:** October 25, 2025
**Next Review:** Weekly
