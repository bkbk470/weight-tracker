-- COMPREHENSIVE FIX for default exercises with user_id
-- Run this in your Supabase SQL Editor

-- Step 1: First, let's see what we're dealing with
SELECT 
  id,
  name,
  user_id,
  is_default,
  is_custom,
  category
FROM exercises 
WHERE user_id IS NOT NULL
ORDER BY name
LIMIT 20;

-- Step 2: Remove user_id from ALL default exercises
UPDATE exercises 
SET user_id = NULL 
WHERE is_default = true;

-- Step 3: Handle duplicates - if there's both a default and custom version with same name
-- Keep the default version, delete the custom version
DELETE FROM exercises 
WHERE id IN (
  SELECT e1.id
  FROM exercises e1
  INNER JOIN exercises e2 ON e1.name = e2.name
  WHERE e1.is_custom = true 
  AND e2.is_default = true
  AND e1.id != e2.id
);

-- Step 4: Fix any exercises that SHOULD be default but have user_id
-- (These are exercises that were inserted from your SQL scripts but got user_id added)
UPDATE exercises
SET 
  user_id = NULL,
  is_default = true,
  is_custom = false
WHERE name IN (
  'Bench Press (Barbell)',
  'Bench Press (Dumbbell)',
  'Squat (Barbell)',
  'Deadlift (Barbell)',
  'Incline Bench Press',
  'Bicycle Crunch',
  'Pull Up',
  'Push Up',
  'Lat Pulldown (Cable)',
  'Overhead Press (Barbell)'
  -- Add more exercise names if needed
)
AND user_id IS NOT NULL;

-- Step 5: Drop the old constraint if it exists
ALTER TABLE exercises 
DROP CONSTRAINT IF EXISTS check_default_no_user;

-- Step 6: Add constraint to prevent user_id on default exercises
ALTER TABLE exercises 
ADD CONSTRAINT check_default_no_user 
CHECK (
  (is_default = true AND user_id IS NULL) OR 
  (is_default = false)
);

-- Step 7: Verify the fix - should show 0 default exercises with user_id
SELECT 
  COUNT(*) FILTER (WHERE is_default = true) as total_default_exercises,
  COUNT(*) FILTER (WHERE is_default = true AND user_id IS NOT NULL) as default_with_user_id,
  COUNT(*) FILTER (WHERE is_custom = true) as total_custom_exercises
FROM exercises;

-- Step 8: Check for any remaining issues
SELECT 
  name,
  COUNT(*) as count,
  ARRAY_AGG(DISTINCT is_default) as is_default_values,
  ARRAY_AGG(DISTINCT user_id) as user_ids
FROM exercises
GROUP BY name
HAVING COUNT(*) > 1
ORDER BY name;

-- Step 9: If you want to fix ALL exercises that should be default
-- (This will convert any exercise without user_id to a default exercise)
UPDATE exercises
SET 
  is_default = true,
  is_custom = false
WHERE user_id IS NULL 
AND is_default = false;
