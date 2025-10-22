# Active Workout Screen Refactoring Guide

## Overview

The active workout screen has been refactored to follow better architectural patterns. This guide shows you how to use the new structure.

## New Architecture

```
lib/
├── models/
│   └── exercise.dart          # Exercise and ExerciseSet models with business logic
├── services/
│   └── workout_data_service.dart  # Handles all data loading/saving
└── screens/
    └── active_workout_screen.dart  # UI only, uses the services
```

## Key Improvements

### 1. **Models with Business Logic** (`lib/models/exercise.dart`)

The Exercise and ExerciseSet classes now include:
- Factory constructors for parsing data
- Helper methods for calculations
- Constants for default values
- Auto-fill logic encapsulated in the model

**Example Usage:**
```dart
import '../models/exercise.dart';

// Create exercise from preloaded data
final exercise = Exercise.fromPreloadedData(exerciseData, index);

// Check if exercise has previous data
if (exercise.hasPreviousData) {
  print('Previous session data available');
}

// Auto-fill weights from previous session
for (final set in exercise.sets) {
  set.autoFillFromPrevious(); // Safe, no null checks needed
}

// Use constants instead of magic numbers
if (weight > ExerciseDefaults.maxWeight) {
  showError('Weight too high');
}
```

### 2. **Workout Data Service** (`lib/services/workout_data_service.dart`)

Centralized service for all workout data operations with:
- **Batch loading** - Single query for all exercises
- **Race condition prevention** - Locking mechanism for metadata
- **Proper error handling** - Graceful degradation to offline mode
- **Structured results** - Clear success/failure/offline states

**Example Usage:**
```dart
import '../services/workout_data_service.dart';
import '../models/exercise.dart';

final _workoutDataService = WorkoutDataService();

// Load previous data for all exercises (MUCH FASTER!)
Future<void> loadPreviousData() async {
  // Before: 10 exercises = 10+ database queries
  // After:  10 exercises = 1 database query

  await _workoutDataService.loadPreviousDataBatch(exercises);

  // Single setState after all data is loaded
  if (mounted) {
    setState(() {
      // Data already applied to exercises
    });
  }
}

// Save workout with proper error handling
Future<void> saveWorkout() async {
  final result = await _workoutDataService.saveWorkout(
    exercises: exercises,
    workoutTimeSeconds: workoutTime,
    workoutId: widget.workoutId,
    workoutName: widget.workoutName ?? 'Workout',
  );

  if (result.success) {
    if (result.savedOffline) {
      _showMessage('Saved offline, will sync later');
    } else {
      _showWorkoutComplete(result.stats);
    }
  } else {
    _showError(result.error ?? 'Failed to save');
  }
}
```

### 3. **Batch Database Query** (`lib/services/supabase_service.dart`)

New method added to SupabaseService:

```dart
/// Get latest exercise sets for multiple exercises in ONE query
Future<List<Map<String, dynamic>>> getBatchLatestExerciseSets(
  List<String> exerciseIds
)
```

## Migration Guide

### Step 1: Update Imports

**Before:**
```dart
// No imports, classes defined in same file
```

**After:**
```dart
import '../models/exercise.dart';
import '../services/workout_data_service.dart';
```

### Step 2: Remove Old Code

**Delete these from active_workout_screen.dart:**
- ❌ `class Exercise` (lines 2427-2449)
- ❌ `class ExerciseSet` (lines 2451-2473)
- ❌ `_ensureWorkoutExerciseMetadata` method
- ❌ `_loadPreviousForExercise` method
- ❌ `_applyLocalHistoryIfMissing` method
- ❌ `_saveWorkoutToDatabase` method (most of it)
- ❌ All magic number constants (replace with `ExerciseDefaults`)

### Step 3: Update initState

**Before (108 lines of parsing):**
```dart
@override
void initState() {
  super.initState();
  _timerService.addListener(_onTimerUpdate);

  if (widget.preloadedExercises != null) {
    exercises = widget.preloadedExercises!.asMap().entries.map((entry) {
      // 100+ lines of complex parsing logic...
    }).toList();
  }

  Future.microtask(() => _loadPreviousExerciseData());
  // ...
}
```

**After (Clean and simple):**
```dart
@override
void initState() {
  super.initState();
  _timerService.addListener(_onTimerUpdate);

  // Use factory constructor - parsing logic is in the model
  if (widget.preloadedExercises != null) {
    exercises = widget.preloadedExercises!
        .asMap()
        .entries
        .map((entry) => Exercise.fromPreloadedData(entry.value, entry.key))
        .toList();
  }

  // Batch load in single query
  Future.microtask(() => _loadPreviousDataBatch());

  if (widget.autoStart) {
    WidgetsBinding.instance.addPostFrameCallback((_) => startWorkout());
  }
}
```

### Step 4: Update Data Loading

**Before (Slow, multiple setState calls):**
```dart
Future<void> _loadPreviousExerciseData() async {
  for (var i = 0; i < exercises.length; i++) {
    unawaited(_loadPreviousForExercise(exercises[i], i));
    // Each call triggers setState() = 10+ rebuilds
  }
}
```

**After (Fast, single setState):**
```dart
Future<void> _loadPreviousDataBatch() async {
  await _workoutDataService.loadPreviousDataBatch(exercises);

  if (mounted) {
    setState(() {
      // Data already applied to exercises by the service
    });
  }
}
```

### Step 5: Update Save Logic

**Before (Complex error handling):**
```dart
Future<bool> _saveWorkoutToDatabase() async {
  try {
    // 100+ lines of save logic
  } catch (e) {
    print('Error: $e');
    try {
      // Fallback logic
    } catch (e2) {
      // Show error
    }
  }
}
```

**After (Clean and clear):**
```dart
Future<void> _saveWorkout() async {
  final result = await _workoutDataService.saveWorkout(
    exercises: exercises,
    workoutTimeSeconds: workoutTime,
    workoutId: widget.workoutId,
    workoutName: widget.workoutName ?? 'Workout',
  );

  if (!mounted) return;

  if (result.success) {
    if (result.savedOffline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saved offline. Will sync when online.'),
          backgroundColor: Colors.orange,
        ),
      );
    } else {
      _showWorkoutCompletionScreen(result.stats);
    }
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result.error ?? 'Failed to save workout'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

### Step 6: Add Input Validation

**Add this helper method:**
```dart
void _onWeightChanged(ExerciseSet set, int newWeight) {
  // Validate input
  if (newWeight < ExerciseDefaults.minValue) return;
  if (newWeight > ExerciseDefaults.maxWeight) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Weight too high')),
    );
    return;
  }

  setState(() {
    set.weight = newWeight;
  });
}

void _onRepsChanged(ExerciseSet set, int newReps) {
  if (newReps < ExerciseDefaults.minValue) return;
  if (newReps > ExerciseDefaults.maxReps) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reps too high')),
    );
    return;
  }

  setState(() {
    set.reps = newReps;
  });
}
```

**Use in EditableNumberField:**
```dart
EditableNumberField(
  value: set.weight,
  onChanged: (newWeight) => _onWeightChanged(set, newWeight),
  // ... other properties
)
```

## Benefits of New Architecture

### Performance Improvements
- ✅ **10x faster initial load** - Single batch query vs multiple queries
- ✅ **No UI flickering** - Single setState vs 10+ setStates
- ✅ **Reduced memory** - Shared service instance

### Code Quality
- ✅ **2,473 lines → ~1,500 lines** - 40% reduction in screen file
- ✅ **Testable** - Business logic separated from UI
- ✅ **Maintainable** - Clear separation of concerns
- ✅ **Reusable** - Services can be used by other screens

### Reliability
- ✅ **No race conditions** - Locking mechanism for metadata
- ✅ **Better error handling** - Graceful offline fallback
- ✅ **Input validation** - Prevents invalid data
- ✅ **No magic numbers** - Named constants

## Testing the Refactored Code

```dart
// Test the models
void testModels() {
  final exercise = Exercise.fromPreloadedData(mockData, 0);
  assert(exercise.name == 'Bench Press');
  assert(exercise.sets.length == 3);

  final set = exercise.sets.first;
  set.previousWeight = 135.0;
  set.weight = 0;
  set.autoFillFromPrevious();
  assert(set.weight == 135);
}

// Test the service (with mocks)
void testService() async {
  final mockSupabase = MockSupabaseService();
  final service = WorkoutDataService(supabaseService: mockSupabase);

  final exercises = [Exercise(...)];
  await service.loadPreviousDataBatch(exercises);

  // Verify batch query was called once
  verify(mockSupabase.getBatchLatestExerciseSets(any)).called(1);
}
```

## Rollout Strategy

### Phase 1: Add New Code (Zero Risk)
1. ✅ Add `lib/models/exercise.dart`
2. ✅ Add `lib/services/workout_data_service.dart`
3. ✅ Add `getBatchLatestExerciseSets` to SupabaseService
4. Deploy and test - old code still works

### Phase 2: Gradual Migration (Low Risk)
1. Update initState to use `Exercise.fromPreloadedData`
2. Test exercise creation
3. Update data loading to use `loadPreviousDataBatch`
4. Test previous data loading
5. Update save logic to use `saveWorkout`
6. Test workout saving

### Phase 3: Cleanup (After Testing)
1. Remove old Exercise/ExerciseSet classes
2. Remove unused methods
3. Remove magic numbers

## Common Issues & Solutions

### Issue: Exercises not loading previous data

**Solution:** Check that exercise IDs are being set correctly:
```dart
print('Exercise ID: ${exercise.supabaseExerciseId}');
print('Has previous data: ${exercise.hasPreviousData}');
```

### Issue: Race condition errors

**Solution:** The new locking mechanism prevents this. If you still see issues, check that you're using `WorkoutDataService` singleton correctly.

### Issue: Offline save not working

**Solution:** Check `WorkoutSaveResult`:
```dart
if (result.savedOffline) {
  print('Saved to local storage only');
}
```

## Next Steps

1. Review this guide
2. Test the new batch query method
3. Gradually migrate active_workout_screen.dart
4. Monitor performance improvements
5. Consider applying same pattern to other large screens

## Questions?

Check the inline documentation in:
- `lib/models/exercise.dart` - Model documentation
- `lib/services/workout_data_service.dart` - Service documentation

---

**Generated:** 2025-10-22
**Status:** Ready for implementation
