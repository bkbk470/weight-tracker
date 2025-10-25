# Debug Guide: Weight Not Saving to Workout Template

## Issue
When you finish a workout, the weights/reps/rest times don't persist to the workout template. Next time you start the same workout, values are reset.

---

## Diagnostic Steps

### Step 1: Check if set_details Column Exists

**Run this SQL in Supabase SQL Editor:**
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'workout_exercises'
AND column_name = 'set_details';
```

**Expected Result:**
```
column_name   | data_type
set_details   | jsonb
```

**If empty:** You need to run the migration! See `SUPABASE_MIGRATION_SET_DETAILS.sql`

---

### Step 2: Check Console Logs During Workout

**Start a workout and watch the Flutter console/terminal for these messages:**

#### When you finish the workout:
```
🔄 Syncing all workout exercises to template...
💾 Syncing Bench Press template:
   - Sets: 4
   - Set details: [{weight: 135, reps: 12, rest: 150}, {weight: 185, reps: 8, rest: 180}, ...]
✅ Successfully synced Bench Press template
✅ All exercises synced to template
```

**If you see:**
- `⚠️  Not syncing to template: no workoutId (quick workout)` → You're doing a **quick workout**, not a template workout. Templates must be started from the workout library.
- `❌ Cannot sync: no workoutExerciseId` → Database issue, workout_exercise row not created
- `❌ Failed to sync workout exercise: ...` → Check the error message

#### When you reopen the workout:
```
📥 Loading Bench Press from set_details: [{weight: 135, reps: 12, rest: 150}, ...]
✅ Loaded 4 sets from set_details for Bench Press
```

**If you see:**
- `⚠️  No set_details for Bench Press, using defaults (weight=0, reps=10)` → The data wasn't saved OR the column doesn't exist

---

### Step 3: Verify Data in Database

**After finishing a workout, run this SQL:**
```sql
SELECT
  we.id,
  e.name as exercise_name,
  we.target_sets,
  we.target_reps,
  we.set_details
FROM workout_exercises we
JOIN exercises e ON we.exercise_id = e.id
WHERE we.workout_id = 'YOUR_WORKOUT_ID'
ORDER BY we.order_index;
```

**Replace `YOUR_WORKOUT_ID` with your actual workout template ID.**

**Expected Result:**
```
id   | exercise_name | target_sets | target_reps | set_details
---  | Bench Press   | 4           | 12          | [{"weight":135,"reps":12,"rest":150},{"weight":185,"reps":8,"rest":180},...]
```

**If set_details is NULL:** The save didn't work. Check:
1. Did you run the migration?
2. Check console for error messages
3. Check Supabase permissions

---

### Step 4: Check Supabase Permissions

**Run this to check if you can UPDATE workout_exercises:**
```sql
-- Try to update a test row
UPDATE workout_exercises
SET set_details = '[{"weight": 100, "reps": 10, "rest": 120}]'::jsonb
WHERE id = 'TEST_ID';
```

**If this fails:** Your user doesn't have UPDATE permission on `workout_exercises` table.

**Fix:** Add RLS policy in Supabase:
```sql
CREATE POLICY "Users can update their own workout exercises"
ON workout_exercises
FOR UPDATE
USING (
  workout_id IN (
    SELECT id FROM workouts WHERE user_id = auth.uid()
  )
);
```

---

## Common Issues & Solutions

### Issue 1: "No workoutId" Warning

**Problem:** You're doing a quick workout, not a template workout

**Solution:**
1. Go to Workout Library
2. Select a saved workout template
3. Click "Start Workout"
4. Make changes
5. Finish workout
6. Reopen the same template

---

### Issue 2: set_details Column Doesn't Exist

**Problem:** Database migration not run

**Solution:**
```sql
ALTER TABLE workout_exercises
ADD COLUMN IF NOT EXISTS set_details JSONB;

CREATE INDEX IF NOT EXISTS idx_workout_exercises_set_details
ON workout_exercises USING GIN (set_details);
```

---

### Issue 3: Data Saves but Doesn't Load

**Problem:** App cache or hot reload issue

**Solution:**
1. **Stop the app completely** (not just hot reload)
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. **Full restart**: `flutter run`

---

### Issue 4: Only Some Exercises Save

**Problem:** Some exercises don't have `workoutExerciseId`

**Check console for:**
```
❌ Cannot sync Squats: no workoutExerciseId
```

**Solution:** This exercise wasn't properly linked to the template. Try:
1. Remove the exercise from workout
2. Save the workout
3. Add it back
4. Start workout again

---

## Test Scenario

**Follow these exact steps to test:**

1. **Create/Open a workout template**
   - Go to Workout Library
   - Select "Day 1 - Push" (or any saved workout)

2. **Start the workout**
   - Click "Start Workout"
   - Console should show: **no** "Not syncing to template: no workoutId"

3. **Change some values**
   - Set 1: Change weight to 140
   - Set 2: Change reps to 10
   - Set 3: Change rest to 200

4. **Finish the workout**
   - Click "Finish"
   - Console should show:
     ```
     🔄 Syncing all workout exercises to template...
     💾 Syncing Bench Press template:
        - Set details: [{weight: 140, reps: 12, rest: 150}, {weight: 185, reps: 10, rest: 180}, ...]
     ✅ Successfully synced Bench Press template
     ```

5. **Go back to dashboard**

6. **Open the same workout again** (DON'T start it yet)
   - Just view the workout detail screen
   - Check if the values show correctly

7. **Start the workout again**
   - Console should show:
     ```
     📥 Loading Bench Press from set_details: [{weight: 140, ...}, ...]
     ✅ Loaded 4 sets from set_details for Bench Press
     ```
   - UI should show weight=140, reps=10, rest=200 for those sets

---

## Still Not Working?

### Capture Full Logs

1. Start workout
2. Make changes
3. Finish workout
4. Copy ALL console output
5. Look for:
   - Any error messages (❌)
   - Warning messages (⚠️)
   - "set_details" mentions
   - "Failed to sync" messages

### Check Database Directly

Run in Supabase SQL Editor:
```sql
-- Get your user ID
SELECT auth.uid();

-- Get your workout IDs
SELECT id, name FROM workouts WHERE user_id = auth.uid();

-- Get workout exercises with set_details
SELECT
  we.*,
  e.name as exercise_name
FROM workout_exercises we
JOIN exercises e ON we.exercise_id = e.id
WHERE we.workout_id = 'YOUR_WORKOUT_ID';
```

Look at the `set_details` column - is it populated with JSON data?

---

## Quick Checklist

- [ ] Ran database migration (`set_details` column exists)
- [ ] Starting workout FROM a template (not quick workout)
- [ ] Console shows "Syncing all workout exercises to template"
- [ ] Console shows "Successfully synced" for each exercise
- [ ] No error messages in console
- [ ] Full app restart (not hot reload)
- [ ] Database has `set_details` data (check with SQL)
- [ ] Supabase permissions allow UPDATE on workout_exercises

---

**If all steps pass but it still doesn't work, there may be a timing/caching issue. Try:**
```bash
flutter clean
rm -rf build/
flutter pub get
flutter run
```

Then test the complete scenario again.
