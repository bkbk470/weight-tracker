-- Update all exercises to use the default image from your Supabase bucket
-- =====================================================
-- IMPORTANT: Replace YOUR_PROJECT_REF with your actual Supabase project reference
-- You can find it in your Supabase project URL: https://YOUR_PROJECT_REF.supabase.co
-- =====================================================

-- Check current image status
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as with_image
FROM exercises
WHERE is_default = true;

-- Update all exercises to use the default exercise image from bucket
UPDATE exercises
SET image_url = 'https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/Exercises/default_exercise.gif'
WHERE is_default = true;

-- Verify the update
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE image_url LIKE '%default_exercise.gif%') as using_default_image
FROM exercises
WHERE is_default = true;

-- Show sample
SELECT name, category, image_url
FROM exercises
WHERE is_default = true
LIMIT 10;

SELECT '✅ All exercises now use your bucket default image!' as message;
