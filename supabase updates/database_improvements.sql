-- DATABASE IMPROVEMENTS - Safe adjustments to existing schema
-- Run these in order in your Supabase SQL Editor

-- ============================================
-- STEP 1: Clean up existing data issues
-- ============================================

-- Fix exercises with user_id that should be default
UPDATE exercises 
SET user_id = NULL,
    is_default = true,
    is_custom = false
WHERE is_default = true;

-- Remove duplicate custom exercises that match default ones
DELETE FROM exercises 
WHERE id IN (
  SELECT e1.id
  FROM exercises e1
  INNER JOIN exercises e2 ON e1.name = e2.name
  WHERE e1.is_custom = true 
  AND e2.is_default = true
  AND e1.id != e2.id
);

-- ============================================
-- STEP 2: Add better constraints
-- ============================================

-- Drop old constraint if exists
ALTER TABLE exercises 
DROP CONSTRAINT IF EXISTS check_default_no_user;

-- Enforce: default exercises MUST have user_id = NULL
-- Enforce: custom exercises MUST have user_id
ALTER TABLE exercises 
ADD CONSTRAINT check_exercise_ownership CHECK (
  (is_default = true AND is_custom = false AND user_id IS NULL) OR
  (is_default = false AND is_custom = true AND user_id IS NOT NULL)
);

-- Ensure exercises are either default OR custom, not both or neither
ALTER TABLE exercises 
ADD CONSTRAINT check_exercise_type_exclusive CHECK (
  (is_default = true AND is_custom = false) OR
  (is_default = false AND is_custom = true)
);

-- ============================================
-- STEP 3: Add unique constraints
-- ============================================

-- Drop existing indexes if they exist
DROP INDEX IF EXISTS unique_default_exercise_name;
DROP INDEX IF EXISTS unique_custom_exercise_per_user;

-- Default exercises must have unique names globally
CREATE UNIQUE INDEX unique_default_exercise_name 
ON exercises (name) 
WHERE is_default = true;

-- Custom exercises must have unique names per user
CREATE UNIQUE INDEX unique_custom_exercise_per_user
ON exercises (user_id, name) 
WHERE is_custom = true;

-- ============================================
-- STEP 4: Add performance indexes
-- ============================================

-- Speed up queries for getting user's exercises
DROP INDEX IF EXISTS idx_exercises_user_default_lookup;
CREATE INDEX idx_exercises_user_default_lookup 
ON exercises (user_id, is_default, is_custom)
WHERE user_id IS NOT NULL OR is_default = true;

-- Speed up category filtering
DROP INDEX IF EXISTS idx_exercises_category;
CREATE INDEX idx_exercises_category 
ON exercises (category, is_default);

-- Speed up workout logs queries
DROP INDEX IF EXISTS idx_workout_logs_user_date;
CREATE INDEX idx_workout_logs_user_date 
ON workout_logs (user_id, start_time DESC);

-- Speed up exercise sets queries
DROP INDEX IF EXISTS idx_exercise_sets_workout_log;
CREATE INDEX idx_exercise_sets_workout_log 
ON exercise_sets (workout_log_id, set_number);

-- Speed up measurements queries
DROP INDEX IF EXISTS idx_measurements_user_type_date;
CREATE INDEX idx_measurements_user_type_date 
ON measurements (user_id, measurement_type, measurement_date DESC);

-- ============================================
-- STEP 5: Add helpful defaults
-- ============================================

-- Make equipment nullable for bodyweight exercises
ALTER TABLE exercises 
ALTER COLUMN equipment DROP NOT NULL;

ALTER TABLE exercises 
ALTER COLUMN equipment SET DEFAULT 'Bodyweight';

-- Add default for workout difficulty
ALTER TABLE workouts 
ALTER COLUMN difficulty SET DEFAULT 'Intermediate';

-- ============================================
-- STEP 6: Add cascading deletes (OPTIONAL - be careful!)
-- ============================================

-- WARNING: This will auto-delete related records when parent is deleted
-- Only uncomment if you want this behavior

/*
-- When workout is deleted, delete its exercises
ALTER TABLE workout_exercises 
DROP CONSTRAINT IF EXISTS workout_exercises_workout_id_fkey;

ALTER TABLE workout_exercises
ADD CONSTRAINT workout_exercises_workout_id_fkey 
FOREIGN KEY (workout_id) 
REFERENCES workouts(id) 
ON DELETE CASCADE;

-- When workout log is deleted, delete its sets
ALTER TABLE exercise_sets 
DROP CONSTRAINT IF EXISTS exercise_sets_workout_log_id_fkey;

ALTER TABLE exercise_sets
ADD CONSTRAINT exercise_sets_workout_log_id_fkey 
FOREIGN KEY (workout_log_id) 
REFERENCES workout_logs(id) 
ON DELETE CASCADE;

-- When template is deleted, delete its exercises
ALTER TABLE workout_template_exercises 
DROP CONSTRAINT IF EXISTS workout_template_exercises_template_id_fkey;

ALTER TABLE workout_template_exercises
ADD CONSTRAINT workout_template_exercises_template_id_fkey 
FOREIGN KEY (template_id) 
REFERENCES workout_templates(id) 
ON DELETE CASCADE;
*/

-- ============================================
-- STEP 7: Improve RLS Policies (OPTIONAL)
-- ============================================

-- Drop existing policies if they exist
DROP POLICY IF EXISTS exercises_select_policy ON exercises;
DROP POLICY IF EXISTS exercises_insert_policy ON exercises;
DROP POLICY IF EXISTS exercises_update_policy ON exercises;
DROP POLICY IF EXISTS exercises_delete_policy ON exercises;

-- Better RLS for exercises table
CREATE POLICY exercises_select_policy ON exercises
FOR SELECT 
USING (
  is_default = true OR 
  user_id = auth.uid()
);

CREATE POLICY exercises_insert_policy ON exercises
FOR INSERT 
WITH CHECK (
  is_custom = true AND 
  is_default = false AND
  user_id = auth.uid()
);

CREATE POLICY exercises_update_policy ON exercises
FOR UPDATE 
USING (
  is_custom = true AND 
  user_id = auth.uid()
)
WITH CHECK (
  is_custom = true AND 
  is_default = false AND
  user_id = auth.uid()
);

CREATE POLICY exercises_delete_policy ON exercises
FOR DELETE 
USING (
  is_custom = true AND 
  user_id = auth.uid()
);

-- ============================================
-- STEP 8: Add helpful functions
-- ============================================

-- Function to get user's exercises (default + custom)
CREATE OR REPLACE FUNCTION get_user_exercises(p_user_id uuid)
RETURNS TABLE (
  id uuid,
  name text,
  category text,
  difficulty text,
  equipment text,
  image_url text,
  is_custom boolean
)
LANGUAGE sql
STABLE
AS $$
  SELECT 
    id, 
    name, 
    category, 
    difficulty, 
    equipment, 
    image_url,
    is_custom
  FROM exercises
  WHERE is_default = true 
     OR user_id = p_user_id
  ORDER BY name;
$$;

-- Function to check if exercise name exists (for validation)
CREATE OR REPLACE FUNCTION exercise_name_exists(
  p_name text, 
  p_user_id uuid
)
RETURNS boolean
LANGUAGE sql
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 
    FROM exercises
    WHERE name = p_name
    AND (is_default = true OR user_id = p_user_id)
  );
$$;

-- ============================================
-- STEP 9: Add automatic timestamp updates
-- ============================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Add triggers for tables that have updated_at
DROP TRIGGER IF EXISTS update_exercises_updated_at ON exercises;
CREATE TRIGGER update_exercises_updated_at
BEFORE UPDATE ON exercises
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workouts_updated_at ON workouts;
CREATE TRIGGER update_workouts_updated_at
BEFORE UPDATE ON workouts
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_logs_updated_at ON workout_logs;
CREATE TRIGGER update_workout_logs_updated_at
BEFORE UPDATE ON workout_logs
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_measurements_updated_at ON measurements;
CREATE TRIGGER update_measurements_updated_at
BEFORE UPDATE ON measurements
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_profiles_updated_at ON profiles;
CREATE TRIGGER update_profiles_updated_at
BEFORE UPDATE ON profiles
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_user_settings_updated_at ON user_settings;
CREATE TRIGGER update_user_settings_updated_at
BEFORE UPDATE ON user_settings
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_workout_templates_updated_at ON workout_templates;
CREATE TRIGGER update_workout_templates_updated_at
BEFORE UPDATE ON workout_templates
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- STEP 10: Verification queries
-- ============================================

-- Check exercises are properly configured
SELECT 
  'Exercises Summary' as check_name,
  COUNT(*) FILTER (WHERE is_default = true) as default_exercises,
  COUNT(*) FILTER (WHERE is_default = true AND user_id IS NOT NULL) as invalid_defaults,
  COUNT(*) FILTER (WHERE is_custom = true) as custom_exercises,
  COUNT(*) FILTER (WHERE is_custom = true AND user_id IS NULL) as invalid_customs
FROM exercises;

-- Check for duplicate exercise names
SELECT 
  'Duplicate Check' as check_name,
  COUNT(*) as duplicate_count
FROM (
  SELECT name
  FROM exercises
  GROUP BY name, is_default, user_id
  HAVING COUNT(*) > 1
) dups;

-- Show table sizes
SELECT 
  schemaname,
  tablename,
  pg_size_pretty(pg_total_relation_size(schemaname||'.'||tablename)) AS size
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(schemaname||'.'||tablename) DESC;

-- ============================================
-- SUCCESS MESSAGE
-- ============================================

DO $$
BEGIN
  RAISE NOTICE '✅ Database improvements completed successfully!';
  RAISE NOTICE '📊 Check the verification queries above for results.';
  RAISE NOTICE '🔒 Your exercises are now properly protected with constraints.';
END $$;
