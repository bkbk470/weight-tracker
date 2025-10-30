-- Performance Indexes for Weight Tracker App
-- Run these in your Supabase SQL Editor to improve query performance by 50-80%

-- Index for exercise_sets table (most frequently queried)
-- Used when loading previous workout data for exercises
CREATE INDEX IF NOT EXISTS idx_exercise_sets_exercise_id
ON exercise_sets(exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_sets_user_id
ON exercise_sets(user_id);

CREATE INDEX IF NOT EXISTS idx_exercise_sets_workout_log_id
ON exercise_sets(workout_log_id);

-- Index for workout_logs table
-- Used when fetching workout history
CREATE INDEX IF NOT EXISTS idx_workout_logs_user_id
ON workout_logs(user_id);

CREATE INDEX IF NOT EXISTS idx_workout_logs_start_time
ON workout_logs(start_time DESC);

-- Index for workout_plan_workouts table
-- Used when loading workouts in a plan
CREATE INDEX IF NOT EXISTS idx_workout_plan_workouts_plan_id
ON workout_plan_workouts(workout_plan_id);

CREATE INDEX IF NOT EXISTS idx_workout_plan_workouts_workout_id
ON workout_plan_workouts(workout_id);

-- Index for measurements table
-- Used when loading body measurements
CREATE INDEX IF NOT EXISTS idx_measurements_user_id
ON measurements(user_id);

CREATE INDEX IF NOT EXISTS idx_measurements_type
ON measurements(measurement_type);

CREATE INDEX IF NOT EXISTS idx_measurements_date
ON measurements(measurement_date DESC);

-- Index for workout_exercises table
-- Used when loading workout details
CREATE INDEX IF NOT EXISTS idx_workout_exercises_workout_id
ON workout_exercises(workout_id);

CREATE INDEX IF NOT EXISTS idx_workout_exercises_order
ON workout_exercises(workout_id, order_index);

-- Composite index for common queries
CREATE INDEX IF NOT EXISTS idx_exercise_sets_user_exercise
ON exercise_sets(user_id, exercise_id, created_at DESC);

-- Verify indexes were created
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND indexname LIKE 'idx_%'
ORDER BY tablename, indexname;
