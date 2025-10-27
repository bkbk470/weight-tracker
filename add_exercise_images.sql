-- Check and Add Exercise Images
-- Run this in Supabase SQL Editor to add placeholder images to exercises
-- =====================================================

-- STEP 1: Check current state of image_url
-- =====================================================
SELECT '=== STEP 1: Current Image Status ===' as step;

SELECT
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as has_image_url,
  COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as missing_image_url
FROM exercises
WHERE is_default = true;

-- Show sample
SELECT name, category, image_url
FROM exercises
WHERE is_default = true
LIMIT 10;

-- STEP 2: Add placeholder images based on category
-- =====================================================
SELECT '=== STEP 2: Adding Category-Based Images ===' as step;

-- Update exercises with category-specific placeholder images
UPDATE exercises
SET image_url = CASE category
  WHEN 'Chest' THEN 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=400&h=400&fit=crop'
  WHEN 'Back' THEN 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=400&h=400&fit=crop'
  WHEN 'Legs' THEN 'https://images.unsplash.com/photo-1574680096145-d05b474e2155?w=400&h=400&fit=crop'
  WHEN 'Shoulders' THEN 'https://images.unsplash.com/photo-1571019613576-2b22c76fd955?w=400&h=400&fit=crop'
  WHEN 'Arms' THEN 'https://images.unsplash.com/photo-1581009146145-b5ef050c2e1e?w=400&h=400&fit=crop'
  WHEN 'Core' THEN 'https://images.unsplash.com/photo-1598632640487-6ea4a4e8b6f3?w=400&h=400&fit=crop'
  WHEN 'Cardio' THEN 'https://images.unsplash.com/photo-1538805060514-97d9cc17730c?w=400&h=400&fit=crop'
  WHEN 'Other' THEN 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&h=400&fit=crop'
  ELSE 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400&h=400&fit=crop'
END
WHERE is_default = true
  AND (image_url IS NULL OR image_url = '');

-- STEP 3: Verify the update
-- =====================================================
SELECT '=== STEP 3: After Update ===' as step;

SELECT
  COUNT(*) as total_exercises,
  COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as has_image_url,
  COUNT(*) FILTER (WHERE image_url IS NULL OR image_url = '') as missing_image_url
FROM exercises
WHERE is_default = true;

-- Show samples by category
SELECT
  category,
  COUNT(*) as count,
  MAX(image_url) as sample_image_url
FROM exercises
WHERE is_default = true
GROUP BY category
ORDER BY category;

-- STEP 4: Show sample exercises with images
-- =====================================================
SELECT '=== STEP 4: Sample Exercises ===' as step;

SELECT name, category, image_url
FROM exercises
WHERE is_default = true
ORDER BY category, name
LIMIT 20;

-- Success message
SELECT '✅ Exercise images updated! Restart your app to see them.' as message;
