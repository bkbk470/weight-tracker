-- =====================================================
-- UPDATE DEFAULT REST TIME TO 55 SECONDS
-- =====================================================
-- This script:
-- 1. Changes the default rest time in workout_exercises table
-- 2. Updates all existing workout exercises to 55 seconds
-- =====================================================

-- Update the default value for new workout exercises
ALTER TABLE workout_exercises
ALTER COLUMN rest_time_seconds SET DEFAULT 55;

-- Update all existing workout exercises to 55 seconds
UPDATE workout_exercises
SET rest_time_seconds = 55;

-- Verify the changes
SELECT
    'Updated all workout exercises' as message,
    COUNT(*) as total_exercises,
    COUNT(*) FILTER (WHERE rest_time_seconds = 55) as exercises_with_55_seconds
FROM workout_exercises;

-- Show sample of updated exercises
SELECT
    w.name as workout_name,
    e.name as exercise_name,
    we.target_sets,
    we.target_reps,
    we.rest_time_seconds
FROM workout_exercises we
JOIN workouts w ON w.id = we.workout_id
JOIN exercises e ON e.id = we.exercise_id
ORDER BY w.name, we.order_index
LIMIT 20;

RAISE NOTICE 'Default rest time changed to 55 seconds for all future and existing workout exercises';
