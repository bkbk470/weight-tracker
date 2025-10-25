# Fix: Workout Template Persistence

**Issue:** When you finish a workout with specific weights, reps, and rest times, those values don't persist in the workout template. Next time you start the same workout, you see old/default values instead of your last workout's data.

**Root Cause:** The `workout_exercises` database table only stores:
- `target_sets` (number of sets)
- `target_reps` (single value for all sets)
- `rest_time_seconds` (single value for all sets)

But it doesn't store **individual set details** (weight, reps, rest for each set).

---

## Solution: Add `set_details` JSON Column

### Step 1: Update Database Schema

**Run this SQL in your Supabase SQL Editor:**

```sql
ALTER TABLE workout_exercises
ADD COLUMN IF NOT EXISTS set_details JSONB;

COMMENT ON COLUMN workout_exercises.set_details IS
'Stores array of set details: [{"weight": 135, "reps": 12, "rest": 150}, ...]';

CREATE INDEX IF NOT EXISTS idx_workout_exercises_set_details
ON workout_exercises USING GIN (set_details);
```

**How to run:**
1. Go to https://supabase.com/dashboard/project/YOUR_PROJECT/sql
2. Paste the SQL above
3. Click "Run"

Alternatively, run the migration file: `SUPABASE_MIGRATION_SET_DETAILS.sql`

---

### Step 2: Code Changes (Already Done!)

#### File 1: `active_workout_screen.dart`

**Changes made to `_syncWorkoutExerciseTemplate()` (lines 889-906):**

```dart
// Build set details JSON to save individual set data
final setDetails = exercise.sets.map((set) => {
  'weight': set.weight,
  'reps': set.reps,
  'rest': set.plannedRestSeconds > 0 ? set.plannedRestSeconds : exercise.restTime,
}).toList();

await SupabaseService.instance.updateWorkoutExercise(
  exercise.workoutExerciseId!,
  {
    'target_sets': exercise.sets.length,
    'target_reps': targetReps,
    'rest_time_seconds': restSeconds,
    'notes': trimmedNotes.isEmpty ? null : trimmedNotes,
    'set_details': setDetails,  // ← NEW: Save all set details as JSON
  },
);
```

**What this does:**
- During a workout, when you change weights/reps/rest, it now saves **ALL set details** to the template
- Saves as JSON array: `[{weight: 135, reps: 12, rest: 150}, {weight: 185, reps: 8, rest: 180}, ...]`

#### File 2: `main.dart`

**Changes made to `_buildWorkoutExercises()` (lines 679-706):**

```dart
// Try to load set details from JSON field if available
final setDetailsRaw = exerciseMap['set_details'];
List<WorkoutExerciseSet> sets;

if (setDetailsRaw is List && setDetailsRaw.isNotEmpty) {
  // Load individual set details from database
  sets = setDetailsRaw.map((setData) {
    final weight = setData is Map ? (setData['weight'] ... ) : 0;
    final reps = setData is Map ? (setData['reps'] ... ) : repsValue;
    final rest = setData is Map ? (setData['rest'] ... ) : restTimeValue;
    return WorkoutExerciseSet(
      weight: weight,
      reps: reps,
      restSeconds: rest,
    );
  }).toList();
} else {
  // Fallback: generate default sets (old behavior)
  sets = List.generate(numSets, (_) => WorkoutExerciseSet(...));
}
```

**What this does:**
- When loading a workout template, it checks for `set_details`
- If found, loads individual weight/reps/rest for each set
- If not found, falls back to old behavior (default values)

---

## How It Works Now

### 1. During Workout
When you change any value (weight, reps, or rest), `_syncWorkoutExerciseTemplate()` is called automatically and saves:
- ✅ All set details to `set_details` JSON column
- ✅ Template metadata (`target_sets`, `target_reps`, `rest_time_seconds`)

### 2. Finishing Workout
When you finish a workout:
- ✅ Saves workout log to `workout_logs`
- ✅ Saves individual sets to `exercise_sets`
- ✅ Updates template with latest set details
- ✅ Saves to local storage

### 3. Next Time You Open Workout
When you open the workout template again:
- ✅ Loads `set_details` from database
- ✅ Populates weight/reps/rest for each set
- ✅ Shows your last workout's data
- ✅ Falls back to Supabase history if template doesn't have set_details

---

## Example Flow

**Workout 1:**
```json
Set 1: {weight: 135, reps: 12, rest: 150}
Set 2: {weight: 185, reps: 8, rest: 180}
Set 3: {weight: 205, reps: 6, rest: 180}
Set 4: {weight: 205, reps: 6, rest: 180}
```

**Saves to database:**
```sql
UPDATE workout_exercises
SET set_details = [
  {"weight": 135, "reps": 12, "rest": 150},
  {"weight": 185, "reps": 8, "rest": 180},
  {"weight": 205, "reps": 6, "rest": 180},
  {"weight": 205, "reps": 6, "rest": 180}
]
WHERE id = '...';
```

**Next time you open this workout:**
```
Weight | Reps | Rest
  135  |  12  | 150  ← From set_details
  185  |   8  | 180  ← From set_details
  205  |   6  | 180  ← From set_details
  205  |   6  | 180  ← From set_details
```

**User increases weight:**
```
Weight | Reps | Rest
  140  |  12  | 150  ← Changed!
  190  |   8  | 180  ← Changed!
  210  |   6  | 180  ← Changed!
  210  |   6  | 180  ← Changed!
```

**Finish workout → Saves back to `set_details` with new values**

---

## Testing Checklist

### ✅ Step 1: Run Database Migration
- [ ] Go to Supabase SQL Editor
- [ ] Run the migration SQL
- [ ] Verify column exists: `SELECT * FROM workout_exercises LIMIT 1;`

### ✅ Step 2: Test Saving
- [ ] Start a workout from a template
- [ ] Change weights, reps, or rest times
- [ ] Check console logs for: "Failed to sync workout exercise" (should NOT appear)
- [ ] Finish the workout
- [ ] Check database: `SELECT set_details FROM workout_exercises WHERE id = '...';`
- [ ] Should see JSON array with your data

### ✅ Step 3: Test Loading
- [ ] Restart the app (full restart, not hot reload)
- [ ] Go to workout detail screen
- [ ] Click "Start Workout"
- [ ] Verify weight, reps, and rest fields show your last workout's values

### ✅ Step 4: Test Progression
- [ ] Start workout again
- [ ] Increase weights
- [ ] Finish workout
- [ ] Reopen workout
- [ ] Verify it shows the new increased weights

---

## Backward Compatibility

**Existing templates without `set_details`:**
- ✅ Will still work
- ✅ Falls back to generating sets with defaults
- ✅ Once you run a workout and save, it will populate `set_details`

**Existing workouts:**
- ✅ Not affected
- ✅ Workout logs (`workout_logs` and `exercise_sets`) unchanged
- ✅ Only template storage is enhanced

---

## Troubleshooting

### Issue: "column set_details does not exist"
**Solution:** Run the database migration SQL

### Issue: Values still not persisting
**Solutions:**
1. Check console logs for errors during sync
2. Verify `widget.workoutId != null` (only saves to templates, not quick workouts)
3. Check Supabase permissions (ensure user can UPDATE workout_exercises)
4. Restart app fully (not hot reload)

### Issue: Some sets persist, others don't
**Solution:** Check that all sets have data (weight > 0 or reps > 0) before finishing

---

## Summary

**Before:**
- ❌ Weights always reset to 0
- ❌ Reps reset to template default (usually 10)
- ❌ Rest times reset to template default
- ❌ Had to manually enter values every time

**After:**
- ✅ Weights persist from last workout
- ✅ Reps persist from last workout
- ✅ Rest times persist from last workout
- ✅ Progressive overload is automatic!
- ✅ Only change what you want to increase

---

**Implementation Date:** October 25, 2025
**Status:** ✅ Code Updated | ⏳ Database Migration Required

**Next Step:** Run the SQL migration in Supabase!
