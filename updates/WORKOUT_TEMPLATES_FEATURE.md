# Workout Templates Feature

## Overview
The workout templates feature provides users with pre-made, professionally designed workout routines that they can browse, view, and add to their personal workout library. Templates are stored in a separate database table and are accessible to all users.

## Database Schema

### New Tables

#### `workout_templates`
Stores the template workout information.

**Columns:**
- `id` (UUID, PK) - Unique identifier
- `name` (TEXT) - Template name
- `description` (TEXT) - Detailed description
- `category` (TEXT) - Category (e.g., 'Strength', 'Cardio', 'Athletic')
- `difficulty` (TEXT) - 'Beginner', 'Intermediate', or 'Advanced'
- `estimated_duration_minutes` (INTEGER) - Expected workout duration
- `target_muscle_groups` (TEXT[]) - Array of muscle groups targeted
- `equipment_needed` (TEXT[]) - Array of required equipment
- `is_featured` (BOOLEAN) - Whether to feature this template
- `created_at` (TIMESTAMP) - Creation timestamp
- `updated_at` (TIMESTAMP) - Last update timestamp

#### `workout_template_exercises`
Links exercises to templates (similar to `workout_exercises` for user workouts).

**Columns:**
- `id` (UUID, PK) - Unique identifier
- `template_id` (UUID, FK) - References workout_templates
- `exercise_id` (UUID, FK) - References exercises
- `order_index` (INTEGER) - Exercise order in the template
- `target_sets` (INTEGER) - Recommended number of sets
- `target_reps` (INTEGER) - Recommended number of reps
- `rest_time_seconds` (INTEGER) - Recommended rest time
- `notes` (TEXT) - Exercise-specific notes/tips
- `created_at` (TIMESTAMP) - Creation timestamp

### Indexes
- `idx_workout_templates_category` - Fast category filtering
- `idx_workout_templates_difficulty` - Fast difficulty filtering
- `idx_workout_templates_featured` - Fast featured template queries
- `idx_workout_template_exercises_template_id` - Fast template exercise lookups
- `idx_workout_template_exercises_exercise_id` - Fast exercise reference lookups

### Row Level Security (RLS)
- **Read Access**: All authenticated users can view templates
- **Write Access**: Only admins can create/update/delete templates (not implemented in app)

## Pre-loaded Templates

The database includes 10 pre-made workout templates:

1. **Full Body Strength** (Intermediate, 60 min) ⭐ Featured
   - 8 exercises targeting all major muscle groups
   
2. **Upper Body Power** (Beginner, 45 min) ⭐ Featured
   - 6 exercises for chest, back, shoulders, and arms
   
3. **Lower Body Blast** (Advanced, 50 min) ⭐ Featured
   - 7 exercises for legs, glutes, and core
   
4. **Core Focus** (Beginner, 30 min)
   - 5 exercises for abs and stability
   
5. **Push Day** (Intermediate, 45 min) ⭐ Featured
   - 7 exercises for chest, shoulders, and triceps
   
6. **Pull Day** (Intermediate, 45 min) ⭐ Featured
   - 7 exercises for back and biceps
   
7. **Leg Day** (Intermediate, 50 min) ⭐ Featured
   - 6 exercises for complete lower body
   
8. **Quick HIIT** (Intermediate, 20 min)
   - 5 high-intensity exercises
   
9. **Beginner's Full Body** (Beginner, 35 min) ⭐ Featured
   - 6 basic exercises for newcomers
   
10. **Athletic Performance** (Advanced, 55 min)
    - 7 exercises for power and explosiveness

## API Methods (SupabaseService)

### New Methods Added

```dart
// Get all workout templates
Future<List<Map<String, dynamic>>> getWorkoutTemplates()

// Get only featured templates
Future<List<Map<String, dynamic>>> getFeaturedWorkoutTemplates()

// Get templates by category
Future<List<Map<String, dynamic>>> getWorkoutTemplatesByCategory(String category)

// Get templates by difficulty
Future<List<Map<String, dynamic>>> getWorkoutTemplatesByDifficulty(String difficulty)

// Get single template with exercises
Future<Map<String, dynamic>?> getWorkoutTemplate(String templateId)

// Duplicate a template as a user workout
Future<Map<String, dynamic>> duplicateTemplateToWorkout(String templateId)
```

## User Interface

### Templates Tab
Located in the Workout Library screen alongside "My Workouts" tab.

**Features:**
- Displays all available workout templates
- Shows template name, description, exercise count, duration, and difficulty
- Color-coded difficulty badges (Beginner, Intermediate, Advanced)
- Tap to view full template details
- Duplicate button to add template to "My Workouts"

**States:**
- **Loading**: Shows circular progress indicator
- **Empty**: Shows friendly message if no templates available
- **Loaded**: Displays template cards with all information

### Duplicating Templates

Users can add templates to their personal workouts:

1. **From Templates Tab**: Tap the duplicate button on any template card
2. **From Template Detail**: Tap the "Duplicate" button (if viewing template details)

**Process:**
- Creates a new workout in user's "My Workouts"
- Copies all exercises with their configurations (sets, reps, rest times, notes)
- Shows success message with option to view in "My Workouts"
- Template name is preserved (not prefixed with "Copy of")

## Setup Instructions

### 1. Run Database Migrations

Execute the SQL scripts in order:

```bash
# 1. Create tables and insert templates
psql -U your_user -d your_database -f create_workout_templates_table.sql

# 2. Populate templates with exercises
psql -U your_user -d your_database -f populate_workout_templates.sql
```

**Or via Supabase Dashboard:**
1. Go to SQL Editor
2. Copy contents of `create_workout_templates_table.sql`
3. Execute
4. Copy contents of `populate_workout_templates.sql`
5. Execute

### 2. Verify Installation

Run this query to verify templates were created:

```sql
SELECT 
  wt.name,
  wt.difficulty,
  wt.estimated_duration_minutes,
  wt.is_featured,
  COUNT(wte.id) as exercise_count
FROM workout_templates wt
LEFT JOIN workout_template_exercises wte ON wt.id = wte.template_id
GROUP BY wt.id, wt.name, wt.difficulty, wt.estimated_duration_minutes, wt.is_featured
ORDER BY wt.is_featured DESC, wt.name;
```

Expected result: 10 templates with exercise counts ranging from 5-8 exercises.

### 3. Code Changes

All necessary code changes have been applied:
- ✅ `supabase_service.dart` - Added template methods
- ✅ `workout_library_screen.dart` - Updated to load and display templates
- ✅ Template duplication functionality
- ✅ Error handling and loading states

## User Workflow

### Viewing Templates
1. Open app → Navigate to "Workout" tab
2. Select "Templates" segment button
3. Browse available workout templates
4. Tap on any template to view full details

### Adding Template to My Workouts
1. Browse templates
2. Tap duplicate icon on desired template
3. Template is added to "My Workouts"
4. Success message appears with "View" action
5. Template can now be edited, started, or duplicated

### Using a Template
1. Add template to "My Workouts"
2. Go to "My Workouts" tab
3. Tap on the workout
4. Tap "Start Workout" to begin
5. Customize as needed (weights, reps, etc.)

## Benefits

### For Users
- **Quick Start**: Get started immediately with proven workout routines
- **Variety**: 10 different workout styles to choose from
- **Learning Tool**: See how workouts are structured
- **Customizable**: Can modify templates after adding to personal library
- **Progressive**: Range from Beginner to Advanced difficulty

### For Development
- **Separation of Concerns**: Templates separate from user workouts
- **Scalability**: Easy to add more templates without affecting user data
- **Flexibility**: Can add more categories, filters, and features
- **Data Integrity**: RLS ensures templates can't be accidentally modified

## Future Enhancements

### Potential Features
- [ ] Search and filter templates by category, difficulty, duration
- [ ] User ratings and reviews for templates
- [ ] Community-submitted templates (with approval system)
- [ ] Favorite/bookmark templates
- [ ] Template recommendations based on user goals
- [ ] Weekly featured templates
- [ ] Template usage statistics
- [ ] Video demonstrations for template exercises
- [ ] Print/export template details
- [ ] Share templates with friends

### Admin Features (Future)
- [ ] Admin panel to create/edit templates
- [ ] Template analytics (views, duplications)
- [ ] A/B testing different template variations
- [ ] Seasonal or themed template collections

## Troubleshooting

### Templates Not Loading
1. Check database connection
2. Verify tables exist: `SELECT * FROM workout_templates LIMIT 1;`
3. Check RLS policies are properly configured
4. Review app logs for error messages

### Exercises Missing from Templates
1. Verify exercises exist in `exercises` table
2. Check `workout_template_exercises` table has records
3. Ensure exercise names in SQL script match database exactly
4. Run verification query to check exercise counts

### Duplication Fails
1. Ensure user is authenticated
2. Check user has permission to create workouts
3. Verify template ID is valid
4. Check for foreign key constraint errors in logs

## File Reference

### SQL Files
- `create_workout_templates_table.sql` - Creates tables and inserts templates
- `populate_workout_templates.sql` - Adds exercises to templates

### Modified Dart Files
- `lib/services/supabase_service.dart` - Template API methods
- `lib/screens/workout_library_screen.dart` - Template UI and interaction

### Documentation
- `WORKOUT_TEMPLATES_FEATURE.md` - This file
- `WORKOUT_DUPLICATION_FIX.md` - Related duplication feature docs
- `WORKOUT_DUPLICATION_FEATURE.md` - Original duplication docs

## Summary

The workout templates feature provides a complete library of professionally designed workouts that users can browse and add to their personal collection. With 10 pre-loaded templates covering various training styles and difficulty levels, users can quickly get started with proven workout routines while maintaining the flexibility to customize them to their needs.
