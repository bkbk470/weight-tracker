-- SIMPLE FIX: Remove user_id from ALL exercises that should be default
-- Run this in Supabase SQL Editor

-- Step 1: Show current problem
SELECT 
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as exercises_with_user_id,
  COUNT(*) FILTER (WHERE is_default = true) as default_exercises,
  COUNT(*) FILTER (WHERE is_default = true AND user_id IS NOT NULL) as defaults_with_user_id
FROM exercises;

-- Step 2: Fix ALL exercises - make them default without user_id
UPDATE exercises
SET 
  user_id = NULL,
  is_default = true,
  is_custom = false
WHERE user_id IS NOT NULL;

-- Step 3: Verify fix
SELECT 
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE user_id IS NOT NULL) as exercises_with_user_id,
  COUNT(*) FILTER (WHERE is_default = true) as default_exercises,
  COUNT(*) FILTER (WHERE is_default = true AND user_id IS NOT NULL) as defaults_with_user_id
FROM exercises;

-- Step 4: Add constraint to PREVENT user_id on exercises
ALTER TABLE exercises 
DROP CONSTRAINT IF EXISTS check_default_no_user;

ALTER TABLE exercises 
ADD CONSTRAINT check_default_no_user 
CHECK (
  (is_default = true AND user_id IS NULL) OR 
  (is_default = false AND user_id IS NOT NULL)
);

-- Step 5: Show sample of exercises to confirm
SELECT id, name, category, user_id, is_default, is_custom
FROM exercises
ORDER BY name
LIMIT 20;
