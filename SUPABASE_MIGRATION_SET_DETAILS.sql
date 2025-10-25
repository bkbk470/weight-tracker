-- Migration: Add set_details column to workout_exercises table
-- This allows storing individual set data (weight, reps, rest) for each set in a workout template
--
-- Run this in your Supabase SQL Editor:
-- 1. Go to https://supabase.com/dashboard/project/YOUR_PROJECT/sql
-- 2. Paste and run this SQL

ALTER TABLE workout_exercises
ADD COLUMN IF NOT EXISTS set_details JSONB;

-- Add a comment to document the column
COMMENT ON COLUMN workout_exercises.set_details IS
'Stores array of set details: [{"weight": 135, "reps": 12, "rest": 150}, ...]';

-- Optional: Create an index on the JSONB column for better query performance
CREATE INDEX IF NOT EXISTS idx_workout_exercises_set_details
ON workout_exercises USING GIN (set_details);

-- Verify the column was added
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_name = 'workout_exercises'
AND column_name = 'set_details';
