# Quick Setup Guide - Workout Templates

## Step-by-Step Setup

### Option 1: Using Supabase Dashboard (Recommended)

1. **Open Supabase Dashboard**
   - Go to https://supabase.com/dashboard
   - Select your project

2. **Navigate to SQL Editor**
   - Click on "SQL Editor" in the left sidebar
   - Click "New Query"

3. **Create Tables and Templates**
   - Open `create_workout_templates_table.sql` in a text editor
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - Click "Run" or press Ctrl+Enter (Cmd+Enter on Mac)
   - Wait for success message

4. **Populate Templates with Exercises**
   - Click "New Query" again
   - Open `populate_workout_templates.sql` in a text editor
   - Copy the entire contents
   - Paste into Supabase SQL Editor
   - Click "Run" or press Ctrl+Enter (Cmd+Enter on Mac)
   - Wait for success message

5. **Verify Installation**
   - Click "New Query"
   - Paste and run this verification query:
   
   ```sql
   SELECT 
     wt.name,
     wt.difficulty,
     wt.estimated_duration_minutes,
     COUNT(wte.id) as exercise_count
   FROM workout_templates wt
   LEFT JOIN workout_template_exercises wte ON wt.id = wte.template_id
   GROUP BY wt.id, wt.name, wt.difficulty, wt.estimated_duration_minutes
   ORDER BY wt.name;
   ```
   
   - You should see 10 workout templates with exercise counts

### Option 2: Using Command Line

If you have PostgreSQL client installed:

```bash
# Set your database connection string
export DATABASE_URL="postgresql://user:password@host:port/database"

# Run the scripts
psql $DATABASE_URL -f create_workout_templates_table.sql
psql $DATABASE_URL -f populate_workout_templates.sql

# Verify
psql $DATABASE_URL -c "SELECT COUNT(*) FROM workout_templates;"
```

## Expected Results

After running both scripts, you should have:

- ✅ 2 new tables: `workout_templates` and `workout_template_exercises`
- ✅ 10 workout templates with various difficulty levels
- ✅ 50-70 exercise associations across all templates
- ✅ Proper indexes and RLS policies
- ✅ Auto-updating timestamps

### Template Summary

| Template Name | Difficulty | Duration | Exercises | Featured |
|---------------|------------|----------|-----------|----------|
| Full Body Strength | Intermediate | 60 min | 8 | ⭐ |
| Upper Body Power | Beginner | 45 min | 6 | ⭐ |
| Lower Body Blast | Advanced | 50 min | 7 | ⭐ |
| Core Focus | Beginner | 30 min | 5 | |
| Push Day | Intermediate | 45 min | 7 | ⭐ |
| Pull Day | Intermediate | 45 min | 7 | ⭐ |
| Leg Day | Intermediate | 50 min | 6 | ⭐ |
| Quick HIIT | Intermediate | 20 min | 5 | |
| Beginner's Full Body | Beginner | 35 min | 6 | ⭐ |
| Athletic Performance | Advanced | 55 min | 7 | |

## Troubleshooting

### Error: "relation exercises does not exist"
**Solution**: Make sure your `exercises` table exists first. The templates reference exercises from this table.

### Error: "function uuid_generate_v4() does not exist"
**Solution**: Enable the UUID extension:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
```

### Warning: "Some exercises were not found"
**Solution**: This is normal. The script only adds exercises that exist in your database. You may need to add default exercises first or modify the exercise names in the populate script to match your database.

### No templates showing in the app
**Checklist:**
1. ✅ Verify tables were created successfully
2. ✅ Check RLS policies are enabled
3. ✅ Confirm templates exist: `SELECT COUNT(*) FROM workout_templates;`
4. ✅ Restart your Flutter app
5. ✅ Check app logs for errors

## Testing in the App

1. **Launch the app**
2. **Navigate to Workouts tab**
3. **Tap "Templates" segment**
4. **Verify templates load**
5. **Tap on a template to view details**
6. **Try duplicating a template to "My Workouts"**
7. **Verify the workout appears in "My Workouts" tab**

## Next Steps

After successful setup:

1. ✅ Templates are ready to use
2. ✅ Users can browse and add templates
3. ✅ Templates can be customized after duplication
4. Consider adding more custom templates for your users
5. Monitor usage to see which templates are most popular

## Need Help?

If you encounter issues:
1. Check the database logs in Supabase Dashboard
2. Review the app console logs
3. Verify your database schema matches expectations
4. Ensure all prerequisite tables exist (exercises, workout_exercises, etc.)

## Rollback (If Needed)

To remove the templates feature:

```sql
-- Drop tables (this will delete all templates!)
DROP TABLE IF EXISTS workout_template_exercises CASCADE;
DROP TABLE IF EXISTS workout_templates CASCADE;

-- Drop indexes (if tables weren't dropped)
DROP INDEX IF EXISTS idx_workout_templates_category;
DROP INDEX IF EXISTS idx_workout_templates_difficulty;
DROP INDEX IF EXISTS idx_workout_templates_featured;
DROP INDEX IF EXISTS idx_workout_template_exercises_template_id;
DROP INDEX IF EXISTS idx_workout_template_exercises_exercise_id;
```

⚠️ **Warning**: This will permanently delete all templates and cannot be undone!
