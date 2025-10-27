# Make All 6000 Exercises Visible to Everyone

## Quick Start (2 minutes)

### Step 1: Open Supabase SQL Editor
Go to: `https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql`

Or navigate: **Dashboard → SQL Editor → New Query**

---

### Step 2: Run the SQL Script

Copy **ALL** contents from: [make_all_exercises_public.sql](make_all_exercises_public.sql)

Paste into SQL Editor and click **"Run"** (or press Cmd/Ctrl + Enter)

---

### Step 3: Verify Success

You should see output showing:
```
✅ Updated 6000 exercises to be default/public
🎉 All exercises are now public/default!
Total default exercises: 6000
```

---

### Step 4: Restart Your Flutter App

**Important:** You must do a **full restart** (not hot reload):
```bash
# Stop the app completely
flutter run
```

Or in VSCode/Android Studio: Stop and restart the app.

---

### Step 5: Test in App

1. Open the app
2. Create a new workout
3. Tap "Add Exercise"
4. Search for "dumb" or "bench"
5. You should see exercises!

---

## What This Does

The SQL script:

1. ✅ **Updates all 6000 exercises** to be default/public:
   - Sets `is_default = true`
   - Sets `is_custom = false`
   - Sets `user_id = NULL`

2. ✅ **Creates Row Level Security (RLS) policies**:
   - All users can **view** default exercises
   - Users can **create** their own custom exercises
   - Users can **edit/delete** only their own custom exercises

3. ✅ **Verifies the update** with diagnostic queries

---

## Understanding the Result

### Before:
```
Exercises: 6000
  - is_default: false
  - is_custom: true
  - user_id: some-specific-user
  → Only that one user could see them
```

### After:
```
Exercises: 6000
  - is_default: true  ✅
  - is_custom: false  ✅
  - user_id: NULL     ✅
  → ALL users can see them!
```

---

## How Your App Uses These Exercises

Your app queries exercises with this filter ([supabase_service.dart:102](lib/services/supabase_service.dart#L102)):

```dart
.or('is_default.eq.true,user_id.eq.$currentUserId')
```

This returns:
- **All default exercises** (`is_default = true`) - Your 6000 exercises
- **User's custom exercises** (`user_id = current_user_id`) - Any exercises they created

---

## User Experience

### All Users Can:
- ✅ See all 6000 default exercises
- ✅ Search and filter exercises by category
- ✅ Add any default exercise to their workouts
- ✅ Create their own custom exercises

### Users Cannot:
- ❌ Edit default exercises (they're read-only for everyone)
- ❌ Delete default exercises
- ❌ See other users' custom exercises

---

## Categories in Your App

Your exercises are organized into these categories ([workout_builder_screen.dart:28](lib/screens/workout_builder_screen.dart#L28)):

- **Chest** - Pressing movements
- **Back** - Pulling movements
- **Legs** - Lower body
- **Shoulders** - Overhead pressing and raises
- **Arms** - Biceps and triceps
- **Core** - Abs and obliques
- **Cardio** - Conditioning
- **Other** - Miscellaneous

The SQL script will show you how many exercises you have in each category!

---

## After Running the Script

Your exercise system will work like this:

### 🌍 Default Exercises (Your 6000)
- Visible to everyone
- Read-only
- Shared across all users
- `is_default = true`

### 👤 Custom Exercises (User-created)
- Visible only to creator
- Editable/deletable by creator
- Personal to each user
- `is_custom = true`

---

## Troubleshooting

### Still not seeing exercises after running script?

1. **Check if script ran successfully**
   - Look for "✅ Updated 6000 exercises" message
   - If you see errors, read the error message

2. **Restart app (full restart, not hot reload)**
   ```bash
   # Stop app completely
   flutter run
   ```

3. **Clear app cache** (if still not working)
   - Uninstall and reinstall the app
   - Or clear app data in device settings

4. **Check authentication**
   - Make sure you're logged in
   - The app requires authentication to see exercises

5. **Check Supabase connection**
   - Verify your Supabase URL and anon key in `main.dart`
   - Check internet connection

---

## Need More Help?

Run the diagnostic script in your Flutter app:

```dart
import 'package:weight_tracker/utils/diagnose_exercises.dart';

await ExerciseDiagnostic.diagnoseExerciseIssue();
```

This will show you exactly what's happening with your exercises.

---

## Summary

**One SQL script makes all 6000 exercises visible to all users.**

1. Copy [make_all_exercises_public.sql](make_all_exercises_public.sql)
2. Run in Supabase SQL Editor
3. Restart your Flutter app
4. Done! ✅

Your users can now browse and choose from all 6000 exercises when building their workouts.
