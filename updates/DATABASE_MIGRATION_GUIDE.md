# Database Migration: Folders → Plans

## Complete Migration Guide

This guide covers the full migration from "folders" to "plans" terminology in both the database and Flutter code.

## Step 1: Run Database Migration

### Execute the SQL Migration:
1. Open your **Supabase Dashboard**
2. Go to **SQL Editor**
3. Open the file: `migrate_folders_to_plans.sql`
4. Click **Run** to execute the migration

### What the Migration Does:
✅ Renames `workout_folders` table → `workout_plans`
✅ Renames `folder_id` column → `plan_id` (in workouts table)
✅ Renames `parent_folder_id` → `parent_plan_id`
✅ Updates all foreign key constraints
✅ Renames all indexes
✅ Updates RLS policies
✅ Updates trigger functions
✅ **Preserves all existing data!**

### Verification:
After running the migration, check the verification queries at the bottom of the SQL file to confirm:
- ✅ `workout_plans` table exists
- ✅ `workout_folders` table no longer exists
- ✅ `plan_id` column exists in workouts
- ✅ `folder_id` column no longer exists
- ✅ All indexes renamed
- ✅ All policies active

## Step 2: Flutter Code Already Updated

The following files have been updated to use the new database schema:

### ✅ `lib/services/supabase_service.dart`
- Now queries `workout_plans` table (not `workout_folders`)
- Uses `plan_id` column (not `folder_id`)
- Uses `parent_plan_id` (not `parent_folder_id`)
- Updated all comments to say "plans"

### ✅ `lib/screens/dashboard_screen.dart`
- Reads `plan_id` from workouts
- UI already says "Workout Plans"

### ✅ `lib/screens/workout_folders_screen.dart`
- Reads `plan_id` from workouts
- UI already says "Manage Workout Plans"

## Complete Changes Summary

### Database Schema:
| Before | After |
|--------|-------|
| `workout_folders` | `workout_plans` |
| `workouts.folder_id` | `workouts.plan_id` |
| `parent_folder_id` | `parent_plan_id` |
| `idx_workout_folders_*` | `idx_workout_plans_*` |
| Policies: "...folders" | Policies: "...plans" |

### Flutter Code:
| File | Changes |
|------|---------|
| `supabase_service.dart` | Uses `workout_plans` table, `plan_id` column |
| `dashboard_screen.dart` | Reads `plan_id`, shows "Workout Plans" |
| `workout_folders_screen.dart` | Reads `plan_id`, shows "Manage Workout Plans" |

### User Interface:
| Screen | Display |
|--------|---------|
| Dashboard | "Workout Plans" with "New Plan" and "Manage" buttons |
| Management | "Manage Workout Plans" screen |
| Dialogs | "Create Workout Plan", "Delete Plan", "Move to Plan" |
| Empty States | "No Workout Plans Yet" |

## Testing After Migration

### 1. Test Plan Creation:
- Click "New Plan" on dashboard
- Create a plan with name, description, color
- Verify it appears in the list

### 2. Test Workout Organization:
- Create a workout
- Click "Manage" → expand a plan
- Move workout into the plan
- Verify it shows in the plan

### 3. Test Plan Display:
- Dashboard should show all plans
- Expand a plan to see workouts
- Each workout shows completion tracking

### 4. Test Plan Management:
- Click "Manage" button
- Expand/collapse plans
- Move workouts between plans
- Delete a plan (workouts move to "Unorganized")

## Rollback (If Needed)

If something goes wrong, the migration file includes a rollback section. Uncomment and run it to revert all changes.

## Benefits of This Migration

### Before (Inconsistent):
- Database: `workout_folders`
- UI: "Workout Plans"
- Code: mix of both terms

### After (Consistent):
- ✅ Database: `workout_plans`
- ✅ UI: "Workout Plans"
- ✅ Code: all use "plans"

This creates a **fully consistent** system where database, code, and UI all use the same terminology!

## Important Notes

1. **No data loss** - All existing folders/plans are preserved
2. **Foreign keys maintained** - All relationships stay intact
3. **RLS policies active** - Security rules still work
4. **Backward compatible** - Old method names still work (we kept them for compatibility)
5. **Zero downtime** - Migration runs quickly

## After Migration Checklist

- [ ] Migration SQL executed successfully
- [ ] Verification queries confirm changes
- [ ] Flutter app restarted (stop and `flutter run`)
- [ ] Can create new plans
- [ ] Can move workouts to plans
- [ ] Can delete plans
- [ ] Existing plans still visible
- [ ] All workouts preserved

Once all boxes are checked, you have successfully migrated to the "plans" terminology throughout your entire application! 🎉

## Support

If you encounter any issues:
1. Check the verification queries in the migration SQL
2. Review Supabase logs for errors
3. Use the rollback script if needed
4. Ensure Flutter app is fully restarted (not just hot reloaded)
