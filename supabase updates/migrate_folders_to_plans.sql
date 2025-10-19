-- ==========================================
-- MIGRATION: Rename Folders to Plans
-- ==========================================
-- This script renames workout_folders to workout_plans for better clarity
-- Run this SQL in your Supabase SQL Editor

-- IMPORTANT: This migration will:
-- 1. Rename the table from workout_folders to workout_plans
-- 2. Update all foreign key references
-- 3. Rename all related indexes and constraints
-- 4. Update RLS policies
-- 5. Preserve all existing data

-- ==========================================
-- STEP 1: Rename the main table
-- ==========================================

ALTER TABLE IF EXISTS workout_folders RENAME TO workout_plans;

-- ==========================================
-- STEP 2: Rename the column in workouts table
-- ==========================================

ALTER TABLE IF EXISTS workouts RENAME COLUMN folder_id TO plan_id;

-- ==========================================
-- STEP 3: Update foreign key constraint name
-- ==========================================

-- First, drop the old constraint
ALTER TABLE workout_plans DROP CONSTRAINT IF EXISTS workout_folders_user_id_fkey;
ALTER TABLE workout_plans DROP CONSTRAINT IF EXISTS workout_folders_parent_folder_id_fkey;

-- Recreate with new names
ALTER TABLE workout_plans 
  ADD CONSTRAINT workout_plans_user_id_fkey 
  FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

ALTER TABLE workout_plans 
  ADD CONSTRAINT workout_plans_parent_plan_id_fkey 
  FOREIGN KEY (parent_folder_id) REFERENCES workout_plans(id) ON DELETE CASCADE;

-- Update workouts table foreign key
ALTER TABLE workouts DROP CONSTRAINT IF EXISTS workouts_folder_id_fkey;
ALTER TABLE workouts 
  ADD CONSTRAINT workouts_plan_id_fkey 
  FOREIGN KEY (plan_id) REFERENCES workout_plans(id) ON DELETE SET NULL;

-- ==========================================
-- STEP 4: Rename column parent_folder_id to parent_plan_id
-- ==========================================

ALTER TABLE workout_plans RENAME COLUMN parent_folder_id TO parent_plan_id;

-- Update the foreign key constraint after renaming
ALTER TABLE workout_plans DROP CONSTRAINT IF EXISTS workout_plans_parent_plan_id_fkey;
ALTER TABLE workout_plans 
  ADD CONSTRAINT workout_plans_parent_plan_id_fkey 
  FOREIGN KEY (parent_plan_id) REFERENCES workout_plans(id) ON DELETE CASCADE;

-- ==========================================
-- STEP 5: Rename indexes
-- ==========================================

ALTER INDEX IF EXISTS idx_workout_folders_user_id RENAME TO idx_workout_plans_user_id;
ALTER INDEX IF EXISTS idx_workout_folders_parent_folder_id RENAME TO idx_workout_plans_parent_plan_id;
ALTER INDEX IF EXISTS idx_workouts_folder_id RENAME TO idx_workouts_plan_id;

-- ==========================================
-- STEP 6: Update RLS policies
-- ==========================================

-- Drop old policies
DROP POLICY IF EXISTS "Users can view their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can create their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can update their own folders" ON workout_plans;
DROP POLICY IF EXISTS "Users can delete their own folders" ON workout_plans;

-- Create new policies with updated names
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

-- ==========================================
-- STEP 7: Update trigger function name
-- ==========================================

-- Drop old trigger first
DROP TRIGGER IF EXISTS workout_folders_updated_at ON workout_plans;

-- Rename the trigger function (correct syntax)
DO $
BEGIN
  IF EXISTS (SELECT 1 FROM pg_proc WHERE proname = 'update_workout_folders_updated_at') THEN
    ALTER FUNCTION update_workout_folders_updated_at() RENAME TO update_workout_plans_updated_at;
  END IF;
END $;

-- Create new trigger
CREATE TRIGGER workout_plans_updated_at
  BEFORE UPDATE ON workout_plans
  FOR EACH ROW
  EXECUTE FUNCTION update_workout_plans_updated_at();

-- ==========================================
-- VERIFICATION QUERIES
-- ==========================================

-- Check if table was renamed
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'workout_plans'
) AS workout_plans_exists;

-- Check if old table no longer exists
SELECT EXISTS (
  SELECT FROM information_schema.tables 
  WHERE table_schema = 'public' 
  AND table_name = 'workout_folders'
) AS workout_folders_still_exists;

-- Check if plan_id column exists in workouts
SELECT EXISTS (
  SELECT FROM information_schema.columns 
  WHERE table_schema = 'public' 
  AND table_name = 'workouts' 
  AND column_name = 'plan_id'
) AS plan_id_column_exists;

-- Check if old folder_id column still exists
SELECT EXISTS (
  SELECT FROM information_schema.columns 
  WHERE table_schema = 'public' 
  AND table_name = 'workouts' 
  AND column_name = 'folder_id'
) AS folder_id_still_exists;

-- Check new indexes
SELECT indexname FROM pg_indexes 
WHERE tablename IN ('workout_plans', 'workouts') 
AND schemaname = 'public'
AND indexname LIKE '%plan%'
ORDER BY tablename, indexname;

-- Check RLS policies
SELECT policyname, cmd 
FROM pg_policies 
WHERE tablename = 'workout_plans'
ORDER BY policyname;

-- Check trigger
SELECT trigger_name, event_manipulation, event_object_table
FROM information_schema.triggers
WHERE event_object_table = 'workout_plans';

-- ==========================================
-- ROLLBACK SCRIPT (if needed)
-- ==========================================
-- If something goes wrong, uncomment and run this section:

/*
-- Rename table back
ALTER TABLE IF EXISTS workout_plans RENAME TO workout_folders;

-- Rename column back
ALTER TABLE IF EXISTS workouts RENAME COLUMN plan_id TO folder_id;

-- Rename parent column back
ALTER TABLE IF EXISTS workout_folders RENAME COLUMN parent_plan_id TO parent_folder_id;

-- Rename indexes back
ALTER INDEX IF EXISTS idx_workout_plans_user_id RENAME TO idx_workout_folders_user_id;
ALTER INDEX IF EXISTS idx_workout_plans_parent_plan_id RENAME TO idx_workout_folders_parent_folder_id;
ALTER INDEX IF EXISTS idx_workouts_plan_id RENAME TO idx_workouts_folder_id;

-- Rename function back
ALTER FUNCTION IF EXISTS update_workout_plans_updated_at() RENAME TO update_workout_folders_updated_at();
*/

-- ==========================================
-- MIGRATION COMPLETE!
-- ==========================================
-- Your database now uses "plans" terminology instead of "folders"
-- All data has been preserved
-- Next step: Update your Flutter code to use the new table/column names
