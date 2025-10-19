-- ==========================================
-- MIGRATION: Rename Folders to Plans (SIMPLE VERSION)
-- ==========================================
-- Run this SQL in your Supabase SQL Editor

-- STEP 1: Rename the main table
ALTER TABLE IF EXISTS workout_folders RENAME TO workout_plans;

-- STEP 2: Rename the column in workouts table
ALTER TABLE IF EXISTS workouts RENAME COLUMN folder_id TO plan_id;

-- STEP 3: Rename parent column
ALTER TABLE workout_plans RENAME COLUMN parent_folder_id TO parent_plan_id;

-- STEP 4: Drop old foreign key constraints
ALTER TABLE workout_plans DROP CONSTRAINT IF EXISTS workout_folders_user_id_fkey;
ALTER TABLE workout_plans DROP CONSTRAINT IF EXISTS workout_folders_parent_folder_id_fkey;
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_folder_id_fkey;

-- STEP 5: Add new foreign key constraints
ALTER TABLE workout_plans 
  ADD CONSTRAINT workout_plans_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE workout_plans 
  ADD CONSTRAINT workout_plans_parent_plan_id_fkey 
  FOREIGN KEY (parent_plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE;

ALTER TABLE workouts 
  ADD CONSTRAINT workouts_plan_id_fkey 
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL;

-- STEP 6: Rename indexes
ALTER INDEX IF EXISTS idx_workout_folders_user_id RENAME TO idx_workout_plans_user_id;
ALTER INDEX IF EXISTS idx_workout_folders_parent_folder_id RENAME TO idx_workout_plans_parent_plan_id;
ALTER INDEX IF EXISTS idx_workouts_folder_id RENAME TO idx_workouts_plan_id;

-- STEP 7: Drop old RLS policies
DROP POLICY IF EXISTS "Users can view their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can create their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can update their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can delete their own folders" ON workout_plans;

-- STEP 8: Create new RLS policies
CREATE POLICY "Users can view their own plans"
  ON workout_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own plans"
  ON workout_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own plans"
  ON workout_plans FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own plans"
  ON workout_plans FOR DELETE
  USING (auth.uid() = user_id);

-- STEP 9: Drop and recreate trigger with new name
DROP TRIGGER IF EXISTS workout_folders_updated_at ON workout_plans;

-- Only rename function if it exists
ALTER FUNCTION update_workout_folders_updated_at() RENAME TO update_workout_plans_updated_at;

-- Create new trigger
CREATE TRIGGER workout_plans_updated_at
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_plans_updated_at();

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Check table exists
SELECT 'workout_plans table exists' as status
WHERE EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_name = 'workout_plans'
);

-- Check column exists
SELECT 'plan_id column exists' as status
WHERE EXISTS (
  SELECT FROM information_schema.columns 
  WHERE table_name = 'workouts' 
  AND column_name = 'plan_id'
);

-- Migration complete!
