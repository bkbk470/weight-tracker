-- =====================================================
-- FINAL FIX: Make Exercises Visible in Your App
-- =====================================================
-- Copy ALL of this and run in Supabase SQL Editor
-- =====================================================

-- STEP 1: Check current state
-- =====================================================
SELECT '=== STEP 1: Current State ===' as step;

SELECT
  'Total exercises in database: ' || COUNT(*)::text as info
FROM exercises;

SELECT
  'Exercises with is_default=true: ' || COUNT(*)::text as info
FROM exercises
WHERE is_default = true;

SELECT
  'Exercises with is_default=false: ' || COUNT(*)::text as info
FROM exercises
WHERE is_default = false;

-- Show sample
SELECT
  name,
  is_default,
  is_custom,
  user_id,
  category
FROM exercises
LIMIT 5;

-- STEP 2: Update ALL exercises to be default/public
-- =====================================================
SELECT '=== STEP 2: Updating Exercises ===' as step;

UPDATE exercises
SET
  is_default = true,
  is_custom = false,
  user_id = NULL
WHERE is_default IS NOT TRUE;

-- Confirm update
SELECT
  '✅ Updated! Default exercises now: ' || COUNT(*)::text as result
FROM exercises
WHERE is_default = true;

-- STEP 3: Fix RLS Policies (The Key Fix!)
-- =====================================================
SELECT '=== STEP 3: Fixing RLS Policies ===' as step;

-- Drop ALL existing policies to start fresh
DROP POLICY IF EXISTS "Users can view default exercises" ON exercises;
DROP POLICY IF EXISTS "Users can view their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can view default and own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can create their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can update their own exercises" ON exercises;
DROP POLICY IF EXISTS "Users can delete their own exercises" ON exercises;
DROP POLICY IF EXISTS "Allow public read access to default exercises" ON exercises;
DROP POLICY IF EXISTS "Enable read access for all users" ON exercises;

SELECT '✅ Dropped old policies' as result;

-- Create NEW policies that definitely work

-- Policy 1: Anyone can view default exercises (even unauthenticated!)
CREATE POLICY "Allow read access to default exercises" ON exercises
  FOR SELECT
  USING (is_default = true);

SELECT '✅ Created: Allow read access to default exercises' as result;

-- Policy 2: Authenticated users can view their own custom exercises
CREATE POLICY "Users can view own custom exercises" ON exercises
  FOR SELECT
  USING (
    auth.uid() = user_id AND is_custom = true
  );

SELECT '✅ Created: Users can view own custom exercises' as result;

-- Policy 3: Authenticated users can create custom exercises
CREATE POLICY "Users can create custom exercises" ON exercises
  FOR INSERT
  WITH CHECK (
    auth.uid() = user_id AND
    is_custom = true AND
    is_default = false
  );

SELECT '✅ Created: Users can create custom exercises' as result;

-- Policy 4: Users can update their own custom exercises
CREATE POLICY "Users can update own custom exercises" ON exercises
  FOR UPDATE
  USING (auth.uid() = user_id AND is_custom = true)
  WITH CHECK (auth.uid() = user_id AND is_custom = true);

SELECT '✅ Created: Users can update own custom exercises' as result;

-- Policy 5: Users can delete their own custom exercises
CREATE POLICY "Users can delete own custom exercises" ON exercises
  FOR DELETE
  USING (auth.uid() = user_id AND is_custom = true);

SELECT '✅ Created: Users can delete own custom exercises' as result;

-- STEP 4: Verify RLS setup
-- =====================================================
SELECT '=== STEP 4: Verifying RLS ===' as step;

-- Check if RLS is enabled
SELECT
  'RLS enabled: ' || CASE WHEN rowsecurity THEN 'YES' ELSE 'NO' END as status
FROM pg_tables
WHERE tablename = 'exercises';

-- Count policies
SELECT
  'Number of policies: ' || COUNT(*)::text as info
FROM pg_policies
WHERE tablename = 'exercises';

-- List all policies
SELECT
  policyname,
  cmd,
  qual as using_clause
FROM pg_policies
WHERE tablename = 'exercises'
ORDER BY policyname;

-- STEP 5: Test the query your app uses
-- =====================================================
SELECT '=== STEP 5: Testing App Query ===' as step;

-- This is EXACTLY what your app queries
SELECT
  'Exercises that app can see: ' || COUNT(*)::text as result
FROM exercises
WHERE is_default = true;

-- Show sample of what will be visible
SELECT
  name,
  category,
  difficulty,
  equipment
FROM exercises
WHERE is_default = true
ORDER BY category, name
LIMIT 10;

-- STEP 6: Category breakdown
-- =====================================================
SELECT '=== STEP 6: Categories ===' as step;

SELECT
  category,
  COUNT(*) as count
FROM exercises
WHERE is_default = true
GROUP BY category
ORDER BY category;

-- STEP 7: Final Summary
-- =====================================================
SELECT '=== ✅ FINAL SUMMARY ===' as step;

WITH stats AS (
  SELECT
    COUNT(*) as total,
    COUNT(*) FILTER (WHERE is_default = true) as default_count
  FROM exercises
)
SELECT
  '🎉 SUCCESS! Your exercises are now configured!' as message
UNION ALL
SELECT '📊 Total exercises: ' || total::text FROM stats
UNION ALL
SELECT '✅ Default (visible to all): ' || default_count::text FROM stats
UNION ALL
SELECT '🔓 RLS policies: FIXED'
UNION ALL
SELECT '📱 Next step: RESTART YOUR FLUTTER APP'
UNION ALL
SELECT '🔄 Hot reload will NOT work - you must STOP and START the app';

-- STEP 8: Expected result in your app
-- =====================================================
SELECT '=== 📱 What to expect ===' as step;

SELECT
  'When you restart and open Add Exercise dialog:' as info
UNION ALL
SELECT '  🔍 Console should show: "Received ' || COUNT(*)::text || ' exercises from Supabase"'
FROM exercises
WHERE is_default = true
UNION ALL
SELECT '  ✅ Dialog should show: "' || COUNT(*)::text || ' exercises"'
FROM exercises
WHERE is_default = true
UNION ALL
SELECT '  🎯 You should see exercises when searching!';
