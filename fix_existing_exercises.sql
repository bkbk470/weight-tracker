-- Fix Existing Exercises to Show in App
-- Run this in your Supabase SQL Editor to make your 6000 exercises visible
--
-- Problem: Exercises exist but have is_default = false or NULL
-- Solution: Update them to is_default = true so they appear in the app

-- Step 1: Check current state
SELECT
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE is_default = true) as default_true,
  COUNT(*) FILTER (WHERE is_default = false) as default_false,
  COUNT(*) FILTER (WHERE is_default IS NULL) as default_null
FROM exercises;

-- Step 2: Update all exercises to be default exercises
-- This makes them visible to all users in the app
UPDATE exercises
SET
  is_default = true,
  is_custom = false,
  user_id = NULL  -- NULL means available to everyone
WHERE is_default IS NOT TRUE;

-- Step 3: Verify the update
SELECT
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE is_default = true) as default_true,
  COUNT(*) FILTER (WHERE is_default = false) as default_false,
  COUNT(*) FILTER (WHERE is_default IS NULL) as default_null
FROM exercises;

-- Step 4: Check category breakdown
SELECT
  category,
  COUNT(*) as exercise_count
FROM exercises
WHERE is_default = true
GROUP BY category
ORDER BY category;

-- Success message
SELECT 'Exercises updated successfully! Restart your Flutter app.' as message;
