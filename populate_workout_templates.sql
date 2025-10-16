-- =====================================================
-- POPULATE WORKOUT TEMPLATES WITH EXERCISES
-- =====================================================
-- This script adds exercises to the workout templates
-- Make sure to run create_workout_templates_table.sql first

-- Helper function to safely add template exercise
CREATE OR REPLACE FUNCTION add_template_exercise(
  template_name TEXT,
  exercise_name TEXT,
  order_idx INTEGER,
  sets INTEGER DEFAULT 3,
  reps INTEGER DEFAULT 10,
  rest INTEGER DEFAULT 90,
  exercise_notes TEXT DEFAULT NULL
) RETURNS VOID AS $$
BEGIN
  INSERT INTO workout_template_exercises (template_id, exercise_id, order_index, target_sets, target_reps, rest_time_seconds, notes)
  SELECT 
    (SELECT id FROM workout_templates WHERE name = template_name LIMIT 1),
    (SELECT id FROM exercises WHERE name = exercise_name LIMIT 1),
    order_idx, sets, reps, rest, exercise_notes
  WHERE EXISTS (SELECT 1 FROM workout_templates WHERE name = template_name)
    AND EXISTS (SELECT 1 FROM exercises WHERE name = exercise_name);
END;
$$ LANGUAGE plpgsql;

-- =====================================================
-- TEMPLATE 1: Full Body Strength
-- =====================================================
SELECT add_template_exercise('Full Body Strength', 'Squats', 0, 4, 8, 180, 'Focus on depth and form');
SELECT add_template_exercise('Full Body Strength', 'Bench Press', 1, 4, 8, 180, 'Control the descent');
SELECT add_template_exercise('Full Body Strength', 'Deadlifts', 2, 3, 6, 240, 'Keep back straight');
SELECT add_template_exercise('Full Body Strength', 'Overhead Press', 3, 3, 10, 120, 'Engage core throughout');
SELECT add_template_exercise('Full Body Strength', 'Barbell Rows', 4, 3, 10, 120, 'Pull to lower chest');
SELECT add_template_exercise('Full Body Strength', 'Pull-ups', 5, 3, 8, 120, 'Full range of motion');
SELECT add_template_exercise('Full Body Strength', 'Lunges', 6, 3, 12, 90, '12 reps per leg');
SELECT add_template_exercise('Full Body Strength', 'Planks', 7, 3, 60, 60, 'Hold for 60 seconds');

-- =====================================================
-- TEMPLATE 2: Upper Body Power
-- =====================================================
SELECT add_template_exercise('Upper Body Power', 'Bench Press', 0, 3, 12, 120, 'Warm up properly');
SELECT add_template_exercise('Upper Body Power', 'Incline Bench Press', 1, 3, 10, 120, 'Upper chest focus');
SELECT add_template_exercise('Upper Body Power', 'Dumbbell Flyes', 2, 3, 12, 90, 'Stretch at bottom');
SELECT add_template_exercise('Upper Body Power', 'Pull-ups', 3, 3, 10, 120, 'Use assistance if needed');
SELECT add_template_exercise('Upper Body Power', 'Barbell Rows', 4, 3, 10, 120, 'Keep core tight');
SELECT add_template_exercise('Upper Body Power', 'Bicep Curls', 5, 3, 12, 60, 'Control the movement');

-- =====================================================
-- TEMPLATE 3: Lower Body Blast
-- =====================================================
SELECT add_template_exercise('Lower Body Blast', 'Squats', 0, 4, 10, 180, 'Go deep, maintain form');
SELECT add_template_exercise('Lower Body Blast', 'Leg Press', 1, 4, 12, 120, 'Full range of motion');
SELECT add_template_exercise('Lower Body Blast', 'Lunges', 2, 3, 12, 90, 'Alternate legs');
SELECT add_template_exercise('Lower Body Blast', 'Deadlifts', 3, 3, 8, 180, 'Romanian or conventional');
SELECT add_template_exercise('Lower Body Blast', 'Leg Curls', 4, 3, 12, 60, 'Controlled movement');
SELECT add_template_exercise('Lower Body Blast', 'Calf Raises', 5, 4, 15, 60, 'Full extension');
SELECT add_template_exercise('Lower Body Blast', 'Planks', 6, 3, 60, 60, 'Core stability');

-- =====================================================
-- TEMPLATE 4: Core Focus
-- =====================================================
SELECT add_template_exercise('Core Focus', 'Planks', 0, 3, 60, 60, 'Front plank, hold steady');
SELECT add_template_exercise('Core Focus', 'Crunches', 1, 3, 20, 45, 'Controlled movement');
SELECT add_template_exercise('Core Focus', 'Russian Twists', 2, 3, 20, 45, '20 total (10 each side)');
SELECT add_template_exercise('Core Focus', 'Leg Raises', 3, 3, 15, 60, 'Keep lower back down');
SELECT add_template_exercise('Core Focus', 'Mountain Climbers', 4, 3, 20, 45, 'Quick pace');

-- =====================================================
-- TEMPLATE 5: Push Day
-- =====================================================
SELECT add_template_exercise('Push Day', 'Bench Press', 0, 4, 8, 180, 'Heavy weight, good form');
SELECT add_template_exercise('Push Day', 'Incline Bench Press', 1, 3, 10, 150, 'Upper chest focus');
SELECT add_template_exercise('Push Day', 'Dumbbell Flyes', 2, 3, 12, 90, 'Feel the stretch');
SELECT add_template_exercise('Push Day', 'Overhead Press', 3, 3, 10, 120, 'Strict form');
SELECT add_template_exercise('Push Day', 'Lateral Raises', 4, 3, 15, 60, 'Light weight, high reps');
SELECT add_template_exercise('Push Day', 'Tricep Dips', 5, 3, 12, 90, 'Full range of motion');
SELECT add_template_exercise('Push Day', 'Skull Crushers', 6, 3, 12, 60, 'Control the weight');

-- =====================================================
-- TEMPLATE 6: Pull Day
-- =====================================================
SELECT add_template_exercise('Pull Day', 'Deadlifts', 0, 4, 6, 240, 'Heavy compound movement');
SELECT add_template_exercise('Pull Day', 'Pull-ups', 1, 4, 8, 150, 'Wide grip');
SELECT add_template_exercise('Pull Day', 'Barbell Rows', 2, 4, 10, 120, 'Pull to lower chest');
SELECT add_template_exercise('Pull Day', 'Lat Pulldowns', 3, 3, 12, 90, 'Feel the lats work');
SELECT add_template_exercise('Pull Day', 'Face Pulls', 4, 3, 15, 60, 'Rear delts');
SELECT add_template_exercise('Pull Day', 'Bicep Curls', 5, 3, 12, 60, 'Squeeze at top');
SELECT add_template_exercise('Pull Day', 'Hammer Curls', 6, 3, 12, 60, 'Neutral grip');

-- =====================================================
-- TEMPLATE 7: Leg Day
-- =====================================================
SELECT add_template_exercise('Leg Day', 'Squats', 0, 4, 10, 180, 'King of leg exercises');
SELECT add_template_exercise('Leg Day', 'Leg Press', 1, 4, 12, 120, 'Heavy weight');
SELECT add_template_exercise('Leg Day', 'Lunges', 2, 3, 12, 90, 'Walking or stationary');
SELECT add_template_exercise('Leg Day', 'Leg Curls', 3, 4, 12, 60, 'Hamstring focus');
SELECT add_template_exercise('Leg Day', 'Leg Extensions', 4, 3, 15, 60, 'Quad focus');
SELECT add_template_exercise('Leg Day', 'Calf Raises', 5, 4, 20, 45, 'Standing or seated');

-- =====================================================
-- TEMPLATE 8: Quick HIIT
-- =====================================================
SELECT add_template_exercise('Quick HIIT', 'Burpees', 0, 4, 15, 30, '30 sec rest between sets');
SELECT add_template_exercise('Quick HIIT', 'Jump Squats', 1, 4, 20, 30, 'Explosive movement');
SELECT add_template_exercise('Quick HIIT', 'Mountain Climbers', 2, 4, 30, 30, 'Fast pace');
SELECT add_template_exercise('Quick HIIT', 'Push-ups', 3, 4, 15, 30, 'Explosive if possible');
SELECT add_template_exercise('Quick HIIT', 'High Knees', 4, 4, 30, 30, 'Cardio burst');

-- =====================================================
-- TEMPLATE 9: Beginner's Full Body
-- =====================================================
SELECT add_template_exercise('Beginner''s Full Body', 'Squats', 0, 3, 10, 90, 'Learn proper form');
SELECT add_template_exercise('Beginner''s Full Body', 'Push-ups', 1, 3, 10, 90, 'Modify on knees if needed');
SELECT add_template_exercise('Beginner''s Full Body', 'Dumbbell Rows', 2, 3, 10, 90, 'One arm at a time');
SELECT add_template_exercise('Beginner''s Full Body', 'Lunges', 3, 3, 10, 90, '10 per leg');
SELECT add_template_exercise('Beginner''s Full Body', 'Planks', 4, 3, 30, 60, 'Hold for 30 seconds');
SELECT add_template_exercise('Beginner''s Full Body', 'Bicep Curls', 5, 3, 12, 60, 'Light weight');

-- =====================================================
-- TEMPLATE 10: Athletic Performance
-- =====================================================
SELECT add_template_exercise('Athletic Performance', 'Power Cleans', 0, 5, 5, 180, 'Explosive power');
SELECT add_template_exercise('Athletic Performance', 'Box Jumps', 1, 4, 8, 120, 'Maximum height');
SELECT add_template_exercise('Athletic Performance', 'Deadlifts', 2, 4, 6, 180, 'Heavy weight');
SELECT add_template_exercise('Athletic Performance', 'Overhead Press', 3, 4, 8, 120, 'Strict form');
SELECT add_template_exercise('Athletic Performance', 'Bulgarian Split Squats', 4, 3, 10, 90, 'Balance and strength');
SELECT add_template_exercise('Athletic Performance', 'Medicine Ball Slams', 5, 4, 12, 60, 'Full body power');
SELECT add_template_exercise('Athletic Performance', 'Planks', 6, 3, 60, 60, 'Core stability');

-- Clean up helper function
DROP FUNCTION IF EXISTS add_template_exercise(TEXT, TEXT, INTEGER, INTEGER, INTEGER, INTEGER, TEXT);

-- =====================================================
-- Verification Query
-- =====================================================
-- Run this to see all templates with their exercise counts:
-- SELECT 
--   wt.name,
--   wt.difficulty,
--   wt.estimated_duration_minutes,
--   COUNT(wte.id) as exercise_count
-- FROM workout_templates wt
-- LEFT JOIN workout_template_exercises wte ON wt.id = wte.template_id
-- GROUP BY wt.id, wt.name, wt.difficulty, wt.estimated_duration_minutes
-- ORDER BY wt.name;

COMMIT;
