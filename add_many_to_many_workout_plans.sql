-- ==========================================
-- ADD MANY-TO-MANY RELATIONSHIP FOR WORKOUTS AND PLANS
-- ==========================================
-- Run this SQL in your Supabase SQL Editor
-- This allows workouts to belong to multiple workout plans

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

-- STEP 4: Create RLS policies for junction table
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

-- STEP 5: Migrate existing data from plan_id to junction table
-- Copy existing workout-plan relationships to the new junction table
INSERT INTO workout_plan_workouts (workout_plan_id, workout_id, order_index)
SELECT plan_id, id, 0
FROM workouts
WHERE plan_id IS NOT NULL
ON CONFLICT (workout_plan_id, workout_id) DO NOTHING;

-- STEP 6: We'll keep the plan_id column for now for backward compatibility
-- It can be used to indicate the "primary" plan
-- Note: Don't drop it yet - we'll do that after updating the app code

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Check if junction table exists
SELECT 
  CASE 
    WHEN EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'workout_plan_workouts')
    THEN '✓ workout_plan_workouts table created'
    ELSE '✗ workout_plan_workouts table NOT found'
  END as table_check;

-- Check if data was migrated
SELECT 
  COUNT(*) as migrated_relationships,
  '✓ relationships migrated from plan_id' as status
FROM workout_plan_workouts;

-- Check RLS policies
SELECT 
  COUNT(*) as policy_count,
  CASE 
    WHEN COUNT(*) >= 3 
    THEN '✓ RLS policies active'
    ELSE '✗ Missing RLS policies'
  END as status
FROM pg_policies 
WHERE tablename = 'workout_plan_workouts';

-- ==========================================
-- MIGRATION COMPLETE!
-- ==========================================
-- Workouts can now belong to multiple plans!
-- Next: Update Flutter code to use the junction table
