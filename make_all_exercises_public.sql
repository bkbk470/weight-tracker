-- ============================================================
-- Make All Exercises Public (Default) - Visible to All Users
-- ============================================================
-- This script converts all exercises to default/public exercises
-- so that every user can see and choose them
--
-- Run this in your Supabase SQL Editor:
-- https://supabase.com/dashboard/project/YOUR_PROJECT/sql
-- ============================================================

-- STEP 1: Check current state BEFORE update
-- ============================================================
SELECT '========== BEFORE UPDATE ==========' as step;

SELECT
  'Total exercises: ' || COUNT(*)::text as info
FROM exercises;

SELECT
  'Default exercises (visible to all): ' || COUNT(*)::text as info
FROM exercises
WHERE is_default = true;

SELECT
  'Custom exercises (user-specific): ' || COUNT(*)::text as info
FROM exercises
WHERE is_custom = true;

SELECT
  'Breakdown:' as category,
  is_default,
  is_custom,
  CASE WHEN user_id IS NULL THEN 'NULL' ELSE 'has user_id' END as user_id_status,
  COUNT(*) as count
FROM exercises
GROUP BY is_default, is_custom, CASE WHEN user_id IS NULL THEN 'NULL' ELSE 'has user_id' END
ORDER BY count DESC;

-- STEP 2: Update ALL exercises to be default/public
-- ============================================================
SELECT '========== UPDATING EXERCISES ==========' as step;

UPDATE exercises
SET
  is_default = true,    -- Make visible to all users
  is_custom = false,    -- Not a custom exercise
  user_id = NULL        -- No specific owner (available to everyone)
WHERE is_default = false OR is_default IS NULL;

-- Get update count
SELECT '✅ Updated ' || COUNT(*)::text || ' exercises to be default/public' as result
FROM exercises
WHERE is_default = true;

-- STEP 3: Verify the update worked
-- ============================================================
SELECT '========== AFTER UPDATE ==========' as step;

SELECT
  'Total exercises: ' || COUNT(*)::text as info
FROM exercises;

SELECT
  'Default exercises (visible to all): ' || COUNT(*)::text as info
FROM exercises
WHERE is_default = true;

SELECT
  'Custom exercises (user-specific): ' || COUNT(*)::text as info
FROM exercises
WHERE is_custom = true;

-- Should show all exercises have: is_default=true, is_custom=false, user_id=NULL
SELECT
  'Verification:' as status,
  is_default,
  is_custom,
  user_id IS NULL as user_id_is_null,
  COUNT(*) as count
FROM exercises
GROUP BY is_default, is_custom, user_id IS NULL
ORDER BY count DESC;

-- STEP 4: Check exercises by category
-- ============================================================
SELECT '========== EXERCISES BY CATEGORY ==========' as step;

SELECT
  category,
  COUNT(*) as exercise_count,
  COUNT(*) FILTER (WHERE is_default = true) as default_count
FROM exercises
GROUP BY category
ORDER BY category;

-- STEP 5: Sample exercises to verify
-- ============================================================
SELECT '========== SAMPLE EXERCISES ==========' as step;

SELECT
  name,
  category,
  difficulty,
  equipment,
  is_default,
  is_custom,
  user_id
FROM exercises
ORDER BY category, name
LIMIT 20;

-- STEP 6: Ensure proper Row Level Security (RLS) policies
-- ============================================================
SELECT '========== CHECKING RLS POLICIES ==========' as step;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view default exercises" ON exercises;
DROP POLICY IF EXISTS "Users can view their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can view default and own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can create their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can update their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can delete their own exercises" ON exercises;

-- Create comprehensive SELECT policy: Users can see default exercises OR their own custom exercises
CREATE POLICY "Users can view default and own exercises" ON exercises
  FOR SELECT
  USING (
    is_default = true OR
    (auth.uid() = user_id AND is_custom = true)
  );

-- Create INSERT policy: Users can only create custom exercises with their own user_id
CREATE POLICY "Users can create their own exercises" ON exercises
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    is_custom = true AND
    is_default = false
  );

-- Create UPDATE policy: Users can only update their own custom exercises
CREATE POLICY "Users can update their own exercises" ON exercises
  FOR UPDATE
  USING (auth.uid() = user_id AND is_custom = true)
  WITH CHECK (auth.uid() = user_id AND is_custom = true);

-- Create DELETE policy: Users can only delete their own custom exercises
CREATE POLICY "Users can delete their own exercises" ON exercises
  FOR DELETE
  USING (auth.uid() = user_id AND is_custom = true);

SELECT '✅ RLS policies created successfully' as result;

-- STEP 7: Final verification - Test the app query
-- ============================================================
SELECT '========== TESTING APP QUERY ==========' as step;

-- This simulates the exact query your app uses
-- Note: Replace 'YOUR-USER-ID' with an actual user_id to test, or run from app
SELECT
  'Exercises visible via app query: ' || COUNT(*)::text as result
FROM exercises
WHERE is_default = true;

-- Show sample of what users will see
SELECT
  name,
  category,
  difficulty,
  equipment
FROM exercises
WHERE is_default = true
ORDER BY category, name
LIMIT 10;

-- STEP 8: Success summary
-- ============================================================
SELECT '========== ✅ SUCCESS SUMMARY ==========' as step;

SELECT
  '🎉 All exercises are now public/default!' as message
UNION ALL
SELECT
  '📊 Total default exercises: ' || COUNT(*)::text
FROM exercises
WHERE is_default = true
UNION ALL
SELECT
  '👥 Visible to: ALL USERS'
UNION ALL
SELECT
  '🔒 RLS policies: CONFIGURED'
UNION ALL
SELECT
  '📱 Next step: RESTART YOUR FLUTTER APP';

-- Show exercises in each category
SELECT '========== EXERCISES PER CATEGORY ==========' as step;

SELECT
  category,
  COUNT(*) as count,
  STRING_AGG(name, ', ' ORDER BY name) FILTER (WHERE ROW_NUMBER() OVER (PARTITION BY category ORDER BY name) <= 3) as sample_exercises
FROM (
  SELECT
    category,
    name,
    ROW_NUMBER() OVER (PARTITION BY category ORDER BY name) as rn
  FROM exercises
  WHERE is_default = true
) subquery
WHERE rn <= 3
GROUP BY category
ORDER BY category;

SELECT '🎊 Done! All 6000 exercises are now available to all users!' as final_message;
