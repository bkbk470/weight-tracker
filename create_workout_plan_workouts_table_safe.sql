-- ==========================================
-- CREATE MANY-TO-MANY RELATIONSHIP FOR WORKOUTS AND PLANS
-- ==========================================
-- Run this SQL in your Supabase SQL Editor
-- This version safely handles existing tables and policies

-- STEP 1: Create junction table for many-to-many relationship
CREATE TABLE IF NOT EXISTS workout_plan_workouts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  workout_plan_id UUID NOT NULL REFERENCES workout_plans(id) ON DELETE CASCADE,
  workout_id UUID NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
  order_index INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(workout_plan_id, workout_id)
);

-- STEP 2: Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_workout_plan_workouts_plan_id
ON workout_plan_workouts(workout_plan_id);

CREATE INDEX IF NOT EXISTS idx_workout_plan_workouts_workout_id
ON workout_plan_workouts(workout_id);

-- STEP 3: Enable RLS on the junction table
ALTER TABLE workout_plan_workouts ENABLE ROW LEVEL SECURITY;

-- STEP 4: Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their workout-plan associations" ON workout_plan_workouts;
DROP POLICY IF EXISTS "Users can create workout-plan associations" ON workout_plan_workouts;
DROP POLICY IF EXISTS "Users can delete workout-plan associations" ON workout_plan_workouts;
DROP POLICY IF EXISTS "Users can update workout-plan associations" ON workout_plan_workouts;

-- STEP 5: Create RLS policies for junction table
-- Users can view workout-plan associations if they own the plan
CREATE POLICY "Users can view their workout-plan associations"
  ON workout_plan_workouts FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = workout_plan_workouts.workout_plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

-- Users can create workout-plan associations for their own plans
CREATE POLICY "Users can create workout-plan associations"
  ON workout_plan_workouts FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = workout_plan_workouts.workout_plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

-- Users can update workout-plan associations for their own plans
CREATE POLICY "Users can update workout-plan associations"
  ON workout_plan_workouts FOR UPDATE
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = workout_plan_workouts.workout_plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

-- Users can delete workout-plan associations for their own plans
CREATE POLICY "Users can delete workout-plan associations"
  ON workout_plan_workouts FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM workout_plans
      WHERE workout_plans.id = workout_plan_workouts.workout_plan_id
      AND workout_plans.user_id = auth.uid()
    )
  );

-- STEP 6: Migrate existing data from plan_id to junction table (if plan_id exists)
-- This safely handles both cases - whether plan_id column exists or not
DO $$
BEGIN
  -- Check if plan_id column exists in workouts table
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workouts' AND column_name = 'plan_id'
  ) THEN
    -- Migrate existing relationships
    INSERT INTO workout_plan_workouts (workout_plan_id, workout_id, order_index)
    SELECT plan_id, id, 0
    FROM workouts
    WHERE plan_id IS NOT NULL
    ON CONFLICT (workout_plan_id, workout_id) DO NOTHING;

    RAISE NOTICE 'Migrated existing workout-plan relationships';
  ELSE
    RAISE NOTICE 'No plan_id column found - skipping migration';
  END IF;
END $$;

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Check if junction table exists
SELECT
  CASE
    WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'workout_plan_workouts')
    THEN '✓ workout_plan_workouts table created'
    ELSE '✗ workout_plan_workouts table NOT found'
  END as status;

-- Check how many relationships were created
SELECT
  COUNT(*) as total_relationships
FROM workout_plan_workouts;

-- Check RLS policies
SELECT
  schemaname,
  tablename,
  policyname,
  cmd as command
FROM pg_policies
WHERE tablename = 'workout_plan_workouts'
ORDER BY policyname;

-- ==========================================
-- DONE!
-- ==========================================
-- The workout_plan_workouts table is now ready to use!
-- Workouts can now belong to multiple plans
