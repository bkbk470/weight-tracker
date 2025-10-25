# Migration Examples - Using New Core Utilities

This document shows practical before/after examples of migrating existing code to use the new core utilities.

---

## Example 1: active_workout_screen.dart

### Print Statements → AppLogger

**Before (Lines 166, 186, 204, etc.):**
```dart
print('Previous sets missing for ${exercise.name}, using Supabase');
print('Loaded previous sets for ${exercise.name}: ${records.length}');
print('Failed to load previous sets for ${exercise.name}: $e');
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

AppLogger.d('Previous sets missing for ${exercise.name}, using Supabase', tag: 'ActiveWorkout');
AppLogger.i('Loaded ${records.length} previous sets for ${exercise.name}', tag: 'ActiveWorkout');
AppLogger.e('Failed to load previous sets for ${exercise.name}', error: e, tag: 'ActiveWorkout');
```

**Benefits:**
- ✅ Consistent formatting
- ✅ Automatic filtering (won't show in production)
- ✅ Tags for easy filtering in logs
- ✅ Proper error context

---

### Magic Numbers → Constants

**Before (Line 73, 101, etc.):**
```dart
final rest = restRaw is num ? restRaw.toInt() : int.tryParse('$restRaw') ?? (ex['restTime'] ?? 120);
final reps = repsRaw is num ? repsRaw.toInt() : int.tryParse('$repsRaw') ?? (ex['reps'] ?? 10);
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

final rest = restRaw is num
    ? restRaw.toInt()
    : int.tryParse('$restRaw') ?? (ex['restTime'] ?? AppConstants.defaultRestTime);
final reps = repsRaw is num
    ? repsRaw.toInt()
    : int.tryParse('$repsRaw') ?? (ex['reps'] ?? AppConstants.defaultReps);
```

**Benefits:**
- ✅ Clear intent (what is 120? It's the default rest time!)
- ✅ Single source of truth
- ✅ Easy to change globally

---

### Formatting Improvements

**Before (Line 643-657):**
```dart
final minutes = duration ~/ 60;
final seconds = duration % 60;
final formattedDuration =
    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

final formattedDuration = duration.toTimeString();
```

**Before (Line 658-659):**
```dart
final formattedVolume = '$baseVolume lbs';
```

**After:**
```dart
final formattedVolume = baseVolume.toVolumeString();
```

---

## Example 2: Validation in workout_detail_screen.dart

### Form Validation

**Before (likely scattered validation logic):**
```dart
if (name.isEmpty) {
  showError('Name is required');
  return;
}
if (name.length < 2) {
  showError('Name must be at least 2 characters');
  return;
}
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

TextFormField(
  initialValue: workoutName,
  validator: Validators.workoutName,
  decoration: const InputDecoration(
    labelText: 'Workout Name',
  ),
)
```

---

## Example 3: Error Handling in Services

### supabase_service.dart

**Before (Line 529, 548, etc.):**
```dart
try {
  // ... Supabase call
} catch (e) {
  print('Error ensuring exercise "${exercise.name}" exists: $e');
  continue;
}
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

try {
  final result = await _createExercise(exercise);
  // Handle success
} on PostgrestException catch (e) {
  throw ServerException(
    'Failed to create exercise: ${e.message}',
    code: e.code,
    originalException: e,
  );
} on SocketException catch (e) {
  throw NetworkException(
    'No internet connection',
    originalException: e,
  );
} catch (e) {
  AppLogger.e('Unexpected error creating exercise', error: e);
  throw UnexpectedException(
    'Failed to create exercise',
    originalException: e,
  );
}
```

---

## Example 4: DateTime Formatting

### workout_history_screen.dart

**Before (likely):**
```dart
final date = DateTime.parse(workout['created_at']);
final formatted = DateFormat('MMM d, y').format(date);
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

final date = DateTime.parse(workout['created_at']);
final formatted = date.toFormattedDate();

// Or for relative time
final relative = date.toRelativeTime(); // "2 days ago", "Yesterday", etc.
```

---

## Example 5: Environment Configuration

### main.dart

**Before (Lines 15-19):**
```dart
await Supabase.initialize(
  url: 'https://your-project.supabase.co',
  anonKey: 'your-anon-key-here',
);
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

// Set environment (optional, defaults to dev in debug mode)
AppEnv.current = Environment.prod;

await Supabase.initialize(
  url: AppEnv.supabaseUrl,
  anonKey: AppEnv.supabaseAnonKey,
);
```

**Run with:**
```bash
flutter run --dart-define=SUPABASE_URL_PROD=https://your-project.supabase.co \
            --dart-define=SUPABASE_ANON_KEY_PROD=your-anon-key-here
```

---

## Example 6: Storage Keys

### local_storage_service.dart

**Before (Lines 10-13):**
```dart
static const String _workoutsBox = 'workouts';
static const String _exercisesBox = 'exercises';
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

// Use centralized storage keys
final box = Hive.box(StorageKeys.workoutsBox);
final exercisesBox = Hive.box(StorageKeys.exercisesBox);
```

---

## Example 7: String Manipulation

**Before:**
```dart
final normalized = exerciseName.toLowerCase().trim();
if (normalized.isEmpty) {
  return;
}
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

final normalized = exerciseName.normalize(); // lowercase, trim, remove special chars
if (normalized.isEmptyOrWhitespace) {
  return;
}
```

---

## Example 8: Null Safety with Extensions

**Before:**
```dart
String getName(User? user) {
  if (user == null || user.name == null || user.name!.isEmpty) {
    return 'Guest';
  }
  return user.name!;
}
```

**After:**
```dart
import 'package:weight_tracker/core/core.dart';

String getName(User? user) {
  return user?.name.orDefault('Guest') ?? 'Guest';
}

// Or even simpler
String getName(User? user) => user?.name.orEmpty.isEmpty
    ? 'Guest'
    : user!.name!;
```

---

## Migration Checklist

### Step 1: Import Core Package
```dart
import 'package:weight_tracker/core/core.dart';
```

### Step 2: Replace Print Statements
```bash
# Find all print statements
grep -rn "print(" lib/ | grep -v "debugPrint"

# Replace them with AppLogger
# - Debug info: AppLogger.d()
# - User actions: AppLogger.i()
# - Warnings: AppLogger.w()
# - Errors: AppLogger.e()
```

### Step 3: Replace Magic Numbers
```bash
# Find common magic numbers
grep -rn "120\|60\|10\|9999" lib/

# Replace with constants from AppConstants
```

### Step 4: Add Validators to Forms
```dart
// Any TextFormField with manual validation
validator: Validators.email,
validator: Validators.workoutName,
validator: Validators.weight,
// etc.
```

### Step 5: Use Extensions
```dart
// Anywhere you format dates
date.toFormattedDate()
date.toRelativeTime()

// Anywhere you format numbers
weight.toWeightString()
seconds.toTimeString()

// Anywhere you validate strings
if (email.isValidEmail) { }
if (name.isNullOrWhitespace) { }
```

---

## Testing Your Migration

1. **Run the app** - Ensure no compilation errors
2. **Check logs** - Verify AppLogger is working (look for emoji icons)
3. **Test forms** - Verify validators show correct messages
4. **Test production build** - Ensure debug logs don't appear:
   ```bash
   flutter build apk --release
   flutter install
   # Check that debug logs don't show
   ```

---

## Common Patterns

### Pattern: Safe Number Parsing
```dart
// Before
final weight = int.tryParse(value) ?? 0;

// After (with validation)
final weight = value.toIntOrNull() ?? AppConstants.defaultWeight;
```

### Pattern: Date Comparisons
```dart
// Before
final now = DateTime.now();
final isToday = workout.date.year == now.year &&
                workout.date.month == now.month &&
                workout.date.day == now.day;

// After
final isToday = workout.date.isToday;
```

### Pattern: Error Messages
```dart
// Before
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text('Error: $e')),
);

// After
ScaffoldMessenger.of(context).showSnackBar(
  SnackBar(content: Text(failure.userMessage)),
);
```

---

## Quick Reference

### Most Commonly Used

```dart
// Logging
AppLogger.d('Debug message');
AppLogger.e('Error', error: e);

// Constants
AppConstants.defaultRestTime
AppConstants.maxWeight
StorageKeys.workoutsBox
Routes.dashboard

// Validators
Validators.email
Validators.workoutName
Validators.required

// Extensions
date.toFormattedDate()
date.toRelativeTime()
weight.toWeightString()
seconds.toTimeString()
email.isValidEmail
name.isNullOrEmpty
```

---

**Remember:** Start with one file at a time, test thoroughly, and gradually migrate the entire codebase!
