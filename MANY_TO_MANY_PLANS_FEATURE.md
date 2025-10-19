# Many-to-Many Workout Plans Feature

## Overview
Updated the system so workouts can belong to **multiple workout plans** instead of just one. This provides much more flexibility in organizing workouts.

## Database Changes

### New Table: `workout_plan_workouts`
Junction table for many-to-many relationship:
- `workout_plan_id` - References workout_plans
- `workout_id` - References workouts  
- `order_index` - For custom ordering within a plan
- Unique constraint prevents duplicates

### Migration
Run: `add_many_to_many_workout_plans.sql` in Supabase SQL Editor

This migration:
1. Creates the junction table
2. Migrates existing plan_id relationships
3. Sets up RLS policies
4. Creates indexes for performance

## How It Works Now

### Before (One Plan Only):
```
Workout "Push Day" → belongs to "Upper Body" plan only
```

### After (Multiple Plans):
```
Workout "Push Day" → belongs to:
  - "Upper Body" plan
  - "Full Body" plan  
  - "Monday Routine" plan
```

## Use Cases

### Scenario 1: Different Weekly Splits
```
"Bench Press" workout appears in:
- Monday - Push Day
- Thursday - Upper Body Focus
- Full Body Friday
```

### Scenario 2: Progressive Programs
```
"Squat Workout" appears in:
- Beginner Plan (lighter weight)
- Intermediate Plan  
- Advanced Plan
```

### Scenario 3: Goal-Based Organization
```
"HIIT Cardio" appears in:
- Weight Loss Plan
- Endurance Building
- Quick 30-Min Workouts
```

## Updated Methods

### SupabaseService:
```dart
// Add workout to a plan (can add to multiple)
addWorkoutToPlan(workoutId, planId)

// Remove workout from a plan (stays in other plans)
removeWorkoutFromPlan(workoutId, planId)

// Get all plans containing a workout
getPlansForWorkout(workoutId)

// Get workouts in a plan
getWorkoutsByFolder(planId) // Uses junction table now
```

### Key Changes:
- `addWorkoutToPlan()` - Adds to plan without removing from others
- `getWorkoutsByFolder()` - Now queries junction table
- "Unorganized" shows workouts in NO plans (not just plan_id = null)

## User Experience

### Adding Workouts to Plans:
1. Click "Add Workout" on any plan
2. See list of all workouts NOT yet in this plan
3. Click [+] to add
4. Workout can be added to multiple plans!

### Dashboard Display:
- Plans show workouts added via junction table
- Same workout can appear in multiple expanded plans
- "Unorganized" shows workouts in zero plans

### Managing Plans Screen:
- Move workout between plans (updates junction table)
- Edit/delete plans
- Star favorites

## Benefits

✅ **Flexibility** - One workout, many plans
✅ **No Duplication** - Same workout data, multiple contexts
✅ **Easy Organization** - Categorize workouts multiple ways
✅ **Backward Compatible** - Keeps plan_id for primary plan

## Technical Details

### Database Structure:
```
workouts (1) ←→ (many) workout_plan_workouts (many) ←→ (1) workout_plans
```

### RLS Security:
- Users can only see/modify their own plan-workout associations
- Cascading deletes: Delete plan → removes associations
- Unique constraint: Can't add same workout to plan twice

## Migration Steps

### Step 1: Run SQL Migration
```bash
# In Supabase SQL Editor:
add_many_to_many_workout_plans.sql
```

### Step 2: Restart Flutter App
```bash
# Full restart (not just hot reload)
flutter run
```

### Step 3: Test
1. Create a workout plan
2. Add a workout to it
3. Create another plan
4. Add the SAME workout to the second plan
5. Both plans now show the workout!

## Future Enhancements

Possible additions:
- 🔜 Reorder workouts within a plan (using order_index)
- 🔜 Show workout's plan badges in workout list
- 🔜 Bulk add multiple workouts to a plan
- 🔜 Copy entire plans with all workouts

## Notes

- The old `plan_id` column is kept for backward compatibility
- It represents the "primary" plan for a workout
- Junction table is the source of truth for plan membership
- Deleting a plan removes it from junction table (workouts stay)

---

Now your workouts can be organized in multiple ways simultaneously! 🎯📋

