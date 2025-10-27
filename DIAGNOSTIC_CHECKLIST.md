# Quick Diagnostic Checklist - No Exercises Showing

## Step 1: Did you run the SQL update?

**Have you run this SQL in Supabase yet?**

```sql
UPDATE exercises
SET is_default = true, is_custom = false, user_id = NULL
WHERE is_default = false;
```

- [ ] YES - I ran it in Supabase SQL Editor
- [ ] NO - I haven't run it yet

**If NO:** That's your problem! Run the SQL first.

**If YES:** Continue to Step 2.

---

## Step 2: Check your Flutter console logs

When you open the "Add Exercise" dialog, you should see print statements in your console.

Look for these messages:
```
🔍 [AddExercise] Starting to load exercises...
✅ [AddExercise] Loaded X exercises from cache
✅ [AddExercise] Set state with X exercises
```

**What do you see?**

### Option A: You see "Loaded 0 exercises"
```
🔍 [AddExercise] Starting to load exercises...
✅ [AddExercise] Loaded 0 exercises from cache
✅ [AddExercise] Set state with 0 exercises
```
→ **Problem:** Exercises aren't in Supabase or aren't being fetched
→ **Go to Step 3**

### Option B: You see "Loaded 6000 exercises"
```
🔍 [AddExercise] Starting to load exercises...
✅ [AddExercise] Loaded 6000 exercises from cache
✅ [AddExercise] Set state with 6000 exercises
```
→ **Problem:** Exercises are loading but filtering is wrong
→ **Go to Step 4**

### Option C: You see an error
```
❌ [AddExercise] Failed to load exercises: ...
```
→ **Problem:** Error loading from database
→ **Go to Step 5**

### Option D: You see nothing
→ **Problem:** App isn't printing logs
→ **Go to Step 6**

---

## Step 3: Exercises aren't being fetched (0 exercises loaded)

Run this diagnostic in Supabase SQL Editor:

```sql
-- How many exercises exist?
SELECT COUNT(*) as total FROM exercises;

-- How many are default?
SELECT COUNT(*) as default_count FROM exercises WHERE is_default = true;

-- Sample of exercises
SELECT name, is_default, is_custom, user_id
FROM exercises
LIMIT 5;
```

**Results:**

- **If total = 0:** You have no exercises in the table at all!
- **If default_count = 0:** Your exercises exist but `is_default = false` - Run the UPDATE SQL!
- **If default_count = 6000:** Exercises are correct in Supabase. Go to Step 7.

---

## Step 4: Exercises loading but not showing (6000 loaded but 0 shown)

This is a filtering/search bug. Check:

1. **Clear the search field** - Make sure search box is empty
2. **Select "All" category** - Don't filter by category
3. **Check if categories match** - Your exercises might have wrong category names

Run this SQL to check category names:

```sql
SELECT DISTINCT category, COUNT(*)
FROM exercises
WHERE is_default = true
GROUP BY category;
```

Valid categories are: `Chest`, `Back`, `Legs`, `Shoulders`, `Arms`, `Core`, `Cardio`, `Other`

If your exercises have different category names (like "chest" lowercase), they won't match!

---

## Step 5: Error loading exercises

Check the error message. Common issues:

- **Authentication error:** You're not logged in
- **Network error:** No internet connection
- **RLS Policy error:** Row Level Security blocking access

Run this in Supabase SQL Editor to check RLS:

```sql
-- Check if RLS is enabled
SELECT tablename, rowsecurity
FROM pg_tables
WHERE tablename = 'exercises';

-- Check policies
SELECT * FROM pg_policies WHERE tablename = 'exercises';
```

If RLS is enabled but no policy allows SELECT, add this policy:

```sql
CREATE POLICY "Users can view default exercises" ON exercises
  FOR SELECT
  USING (is_default = true);
```

---

## Step 6: No console logs appearing

Enable debug logging:

1. **Run in debug mode:** `flutter run --debug`
2. **Check console:** Make sure you're looking at the Flutter console output
3. **Try this test:** Add this to your app and run it:

```dart
print('🧪 TEST: Print is working');
```

If you see this message, prints are working. If not, check your IDE console settings.

---

## Step 7: Everything looks correct but still not working

Clear the app cache and restart:

### Option A: Clear cache manually

Add this button temporarily to your app:

```dart
ElevatedButton(
  onPressed: () async {
    await ExerciseCacheService.instance.clearCache();
    print('✅ Cache cleared! Restart the app.');
  },
  child: Text('Clear Exercise Cache'),
)
```

### Option B: Reinstall the app

```bash
flutter clean
flutter pub get
flutter run
```

---

## Step 8: Still not working? Run comprehensive diagnostic

Create a test button in your app:

```dart
import 'package:weight_tracker/utils/diagnose_exercises.dart';

ElevatedButton(
  onPressed: () async {
    await ExerciseDiagnostic.diagnoseExerciseIssue();
  },
  child: Text('Run Diagnostic'),
)
```

Check the console output for detailed information.

---

## Quick Reference: Common Issues & Solutions

| Symptom | Cause | Solution |
|---------|-------|----------|
| "0 exercises" shown | SQL not run yet | Run UPDATE SQL in Supabase |
| "Loaded 0 exercises" in console | No default exercises | Run UPDATE SQL to set is_default=true |
| "Loaded 6000" but "0 exercises" shown | Category mismatch | Check category names match exactly |
| Error in console | RLS or auth issue | Check RLS policies, verify login |
| No console logs | Debug mode not enabled | Run `flutter run --debug` |
| Everything correct but still broken | Stale cache | Clear cache or reinstall app |

---

## The Nuclear Option (Start Fresh)

If nothing works:

```bash
# 1. Stop the app
# 2. Clean everything
flutter clean

# 3. Uninstall the app from device/emulator

# 4. Verify SQL in Supabase
# Run: SELECT COUNT(*) FROM exercises WHERE is_default = true;
# Should return 6000

# 5. Reinstall
flutter pub get
flutter run

# 6. Log in again

# 7. Try adding exercise
```

---

## Need Help?

Report what you found:
- What step you're on
- What the console logs say
- What the SQL queries return

This will help diagnose the exact issue!
