-- =====================================================
-- DELETE DUPLICATE CUSTOM EXERCISES
-- =====================================================
-- This script removes custom exercises that duplicate default ones
-- so that default exercises are visible to all users
-- =====================================================

-- Delete custom exercises that duplicate default ones
DELETE FROM public.exercises
WHERE user_id = '1167db04-7c58-4351-a94a-954a61dbed52'
AND is_custom = true
AND name IN (
  'Pull-ups',
  'Barbell Rows',
  'Leg Press',
  'Deadlifts',
  'Dumbbell Flyes'
);

-- Verify deletion
SELECT
  name,
  user_id,
  is_custom,
  is_default,
  CASE
    WHEN user_id IS NULL THEN 'Available to everyone'
    ELSE 'Only for specific user'
  END as availability
FROM public.exercises
WHERE name IN ('Pull-ups', 'Barbell Rows', 'Leg Press', 'Deadlifts', 'Dumbbell Flyes',
               'Bent Over Row (Barbell)', 'Leg Press (Machine)', 'Deadlift (Barbell)', 'Chin Up')
ORDER BY name, is_default DESC;
