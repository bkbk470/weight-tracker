# Fixing "No Exercises Found" Issue

## Problem

When trying to add exercises to a workout, the app shows "No exercises found" with "0 exercises" displayed. This happens because the Supabase database doesn't have any default exercises seeded.

The app expects exercises in the `exercises` table with `is_default = true`, but the database is currently empty.

## Understanding the Exercise System

The app uses a **three-tier exercise loading system**:

1. **Memory Cache** - Fastest (in-app)
2. **Local Storage (Hive)** - Fast, offline-capable
3. **Supabase Database** - Authoritative source, syncs across devices

When you first install the app, all three are empty, which is why you see "No exercises found."

## Solution: Seed Default Exercises

You have **two options** to populate your database with common exercises:

---

### Option 1: Run SQL Directly in Supabase (Recommended)

This is the fastest and most reliable method.

#### Steps:

1. **Open Supabase SQL Editor**
   - Go to: `https://supabase.com/dashboard/project/YOUR_PROJECT_ID/sql`
   - Or navigate to: Dashboard → SQL Editor

2. **Copy the SQL file**
   - Open the file: `seed_default_exercises.sql` (in the project root)
   - Copy all the contents

3. **Run the SQL**
   - Paste the SQL into the Supabase SQL Editor
   - Click "Run" or press `Cmd/Ctrl + Enter`
   - Wait for completion (should take ~5 seconds)

4. **Verify**
   - You should see output showing exercise counts by category
   - Total: **96 default exercises** across 8 categories

5. **Restart your app**
   - Close and reopen the Flutter app
   - The exercises will now be loaded automatically

#### What This Does:

- Creates the `exercises` table if it doesn't exist
- Sets up Row Level Security (RLS) policies
- Inserts 96 common exercises across all categories:
  - 12 Chest exercises
  - 12 Back exercises
  - 12 Legs exercises
  - 12 Shoulders exercises
  - 12 Arms exercises
  - 12 Core exercises
  - 12 Cardio exercises

---

### Option 2: Run Dart Seeder Script (From Flutter App)

This method seeds the database from within the Flutter app.

#### Steps:

1. **Import the seeder utility**
   - In any Dart file (like `main.dart` or a test file), add:
   ```dart
   import 'package:weight_tracker/utils/seed_exercises.dart';
   ```

2. **Call the seeder function**
   - You can add this as a button in your app, or run it once from `main.dart`:
   ```dart
   // Run once to seed exercises
   await ExerciseSeeder.seedDefaultExercises();
   ```

3. **Example: Add a Debug Button**
   - You can add a button to your settings screen:
   ```dart
   ElevatedButton(
     onPressed: () async {
       await ExerciseSeeder.seedDefaultExercises();
       ScaffoldMessenger.of(context).showSnackBar(
         SnackBar(content: Text('Exercises seeded! Please restart the app.')),
       );
     },
     child: Text('Seed Default Exercises'),
   )
   ```

4. **Restart your app**
   - Close and reopen the Flutter app
   - The exercises will now be loaded automatically

#### Pros & Cons:

**Pros:**
- Can be triggered from within the app
- Useful for development/testing
- No need to access Supabase dashboard

**Cons:**
- Slower than SQL (makes individual API calls)
- Requires authentication
- May fail on network issues

---

## Verification

After seeding, verify exercises are loaded:

1. **Check Supabase Dashboard**
   - Go to: Table Editor → `exercises` table
   - You should see 96 rows with `is_default = true`

2. **Check in App**
   - Open "Add Exercise" dialog in workout builder
   - Search for "bench" or "squat"
   - You should see multiple exercises

3. **Check by Category**
   - Filter by "Chest", "Back", "Legs", etc.
   - Each category should have ~12 exercises

---

## Exercise Categories

The app supports these categories (defined in [workout_builder_screen.dart:28](lib/screens/workout_builder_screen.dart#L28)):

- **Chest** - Pressing movements (bench press, push-ups, flyes)
- **Back** - Pulling movements (rows, pull-ups, deadlifts)
- **Legs** - Lower body (squats, lunges, leg press)
- **Shoulders** - Overhead pressing and raises
- **Arms** - Biceps and triceps isolation
- **Core** - Abs and obliques (planks, crunches)
- **Cardio** - Conditioning exercises (running, bike, rowing)
- **Other** - Miscellaneous exercises

---

## Custom Exercises

After seeding default exercises, users can create their own custom exercises:

1. Go to **Exercises** screen
2. Tap the **"+"** button
3. Fill in exercise details:
   - Name
   - Category
   - Difficulty (Beginner/Intermediate/Advanced)
   - Equipment
   - Notes (optional)
   - Image URL (optional)

Custom exercises have `is_custom = true` and are tied to the user's account.

---

## Database Schema

The `exercises` table structure:

```sql
CREATE TABLE exercises (
  id UUID PRIMARY KEY,
  user_id UUID,              -- NULL for default exercises
  name TEXT NOT NULL,
  category TEXT NOT NULL,    -- Chest, Back, Legs, etc.
  difficulty TEXT NOT NULL,  -- Beginner, Intermediate, Advanced
  equipment TEXT NOT NULL,   -- Barbell, Dumbbells, Machine, etc.
  notes TEXT,                -- Exercise instructions
  image_url TEXT,            -- Exercise image
  is_custom BOOLEAN,         -- User-created exercise
  is_default BOOLEAN,        -- Default exercise (visible to all)
  created_at TIMESTAMP,
  updated_at TIMESTAMP
);
```

---

## Troubleshooting

### Still seeing "No exercises found" after seeding?

1. **Clear app cache**
   ```dart
   // In your app, clear the exercise cache:
   await ExerciseCacheService.instance.clearCache();
   ```

2. **Check Supabase authentication**
   - Ensure you're logged in
   - Check `currentUserId` is not null

3. **Verify RLS policies**
   - Go to Supabase → Authentication → Policies
   - Ensure "Users can view default exercises" policy exists

4. **Check database query**
   - The app queries: `is_default = true OR user_id = currentUserId`
   - Default exercises have `is_default = true` and `user_id = NULL`

5. **Restart app completely**
   - Stop the app (not just hot reload)
   - Clear Hive cache: Delete app data/reinstall
   - Restart

### Database connection issues?

- Check your Supabase URL and anon key in `main.dart`
- Verify internet connection
- Check Supabase project status

---

## Related Files

- **Seed Script (SQL)**: [seed_default_exercises.sql](seed_default_exercises.sql)
- **Seed Script (Dart)**: [lib/utils/seed_exercises.dart](lib/utils/seed_exercises.dart)
- **Supabase Service**: [lib/services/supabase_service.dart](lib/services/supabase_service.dart#L96-L107)
- **Exercise Cache**: [lib/services/exercise_cache_service.dart](lib/services/exercise_cache_service.dart#L23-L50)
- **Workout Builder**: [lib/screens/workout_builder_screen.dart](lib/screens/workout_builder_screen.dart#L28)
- **Exercise Model**: [lib/models/exercise.dart](lib/models/exercise.dart)

---

## Summary

The "No exercises found" issue occurs because your Supabase database is empty. Running the provided SQL seed script (`seed_default_exercises.sql`) will populate it with 96 common exercises across all categories. After seeding, restart your app and exercises will appear in the workout builder.

**Quick Fix:** Run `seed_default_exercises.sql` in Supabase SQL Editor, then restart your Flutter app.
