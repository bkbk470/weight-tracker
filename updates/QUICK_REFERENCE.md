# Quick Reference - Workout Templates

## 🚀 Quick Start (5 Minutes)

### Step 1: Run SQL Scripts
```bash
# In Supabase SQL Editor, run these in order:
1. create_workout_templates_table.sql
2. populate_workout_templates.sql
```

### Step 2: Verify
```sql
SELECT COUNT(*) FROM workout_templates; -- Should be 10
```

### Step 3: Test
1. Restart Flutter app
2. Go to Workouts → Templates tab
3. See 10 workout templates
4. Tap duplicate to add to My Workouts

## 📋 Available Templates

| # | Name | Level | Duration | Exercises |
|---|------|-------|----------|-----------|
| 1 | Full Body Strength ⭐ | Intermediate | 60 min | 8 |
| 2 | Upper Body Power ⭐ | Beginner | 45 min | 6 |
| 3 | Lower Body Blast ⭐ | Advanced | 50 min | 7 |
| 4 | Core Focus | Beginner | 30 min | 5 |
| 5 | Push Day ⭐ | Intermediate | 45 min | 7 |
| 6 | Pull Day ⭐ | Intermediate | 45 min | 7 |
| 7 | Leg Day ⭐ | Intermediate | 50 min | 6 |
| 8 | Quick HIIT | Intermediate | 20 min | 5 |
| 9 | Beginner's Full Body ⭐ | Beginner | 35 min | 6 |
| 10 | Athletic Performance | Advanced | 55 min | 7 |

⭐ = Featured Template

## 🔧 Common Commands

### View All Templates
```sql
SELECT name, difficulty, estimated_duration_minutes 
FROM workout_templates 
ORDER BY is_featured DESC, name;
```

### View Template with Exercises
```sql
SELECT 
  wt.name as template_name,
  e.name as exercise_name,
  wte.target_sets,
  wte.target_reps,
  wte.rest_time_seconds
FROM workout_templates wt
JOIN workout_template_exercises wte ON wt.id = wte.template_id
JOIN exercises e ON wte.exercise_id = e.id
WHERE wt.name = 'Push Day'
ORDER BY wte.order_index;
```

### Count Exercises Per Template
```sql
SELECT 
  wt.name,
  COUNT(wte.id) as exercise_count
FROM workout_templates wt
LEFT JOIN workout_template_exercises wte ON wt.id = wte.template_id
GROUP BY wt.id, wt.name
ORDER BY wt.name;
```

## 🐛 Troubleshooting

### Templates Not Loading
```bash
# Check if tables exist
SELECT COUNT(*) FROM workout_templates;

# Check RLS policies
SELECT * FROM pg_policies WHERE tablename = 'workout_templates';

# Restart app and check logs
flutter run
```

### Duplication Not Working
```bash
# Verify user is authenticated
# Check workout ID is present
# Review error logs in app console
```

### Some Exercises Missing
```sql
-- Check which exercises are missing
SELECT DISTINCT e.name 
FROM exercises e
WHERE e.name IN (
  'Squats', 'Bench Press', 'Deadlifts', 'Pull-ups',
  'Lunges', 'Bicep Curls', 'Planks'
)
ORDER BY e.name;
```

## 📱 User Actions

### Browse Templates
**Workout** → **Templates** → Browse list

### Add Template
Tap **duplicate icon** on template card

### View Template Details
Tap on template card

### Start Template Workout
Add to My Workouts → Tap workout → **Start Workout**

## 💡 Tips

1. **Featured templates** show first (⭐ icon)
2. **Duplicate multiple times** - templates can be duplicated as many times as needed
3. **Edit after duplicating** - customize templates in My Workouts
4. **No limit** - add as many templates as you want

## 📚 Documentation Files

- `WORKOUT_TEMPLATES_COMPLETE.md` - Full overview
- `WORKOUT_TEMPLATES_FEATURE.md` - Detailed feature docs
- `WORKOUT_TEMPLATES_SETUP.md` - Setup instructions
- `WORKOUT_DUPLICATION_FIX.md` - Duplication fix details
- `create_workout_templates_table.sql` - Database setup
- `populate_workout_templates.sql` - Template data

## ✅ Success Indicators

✓ 10 templates in database
✓ Templates tab loads successfully
✓ Can view template details
✓ Can duplicate templates
✓ Templates appear in My Workouts
✓ Can start workouts from templates

## 🆘 Quick Help

**Problem**: Templates tab is empty
**Solution**: Check if SQL scripts ran successfully

**Problem**: Duplication shows error
**Solution**: Verify user is logged in and has internet connection

**Problem**: Exercises missing from template
**Solution**: Ensure exercises exist in database with exact names

**Problem**: App crashes on Templates tab
**Solution**: Check app logs, verify database schema matches

## 🎯 Next Steps

After setup is complete:

1. ✅ Browse templates in app
2. ✅ Add a template to My Workouts
3. ✅ Start a workout from a template
4. ✅ Duplicate a user workout
5. ✅ Test all features work correctly

## 📊 Quick Stats

- **10** pre-loaded templates
- **5** difficulty levels (Beginner to Advanced)
- **50-70** exercise associations
- **4** workout categories
- **20-60** min duration range

---

**Need more help?** See full documentation in other MD files.
**Ready to code?** All code changes are already applied! Just run the SQL scripts.
