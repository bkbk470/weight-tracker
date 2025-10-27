-- Option 2: Store storage paths instead of full URLs
-- This uses your existing getSignedUrlForStoragePath method
-- The app will convert "Exercises/default_exercise.gif" to signed URLs automatically
-- =====================================================

-- Check current image status
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE image_url IS NOT NULL AND image_url != '') as with_image
FROM exercises
WHERE is_default = true;

-- Update all exercises to use storage path format
UPDATE exercises
SET image_url = 'Exercises/default_exercise.gif'
WHERE is_default = true;

-- Verify the update
SELECT
  COUNT(*) as total,
  COUNT(*) FILTER (WHERE image_url = 'Exercises/default_exercise.gif') as using_bucket_path
FROM exercises
WHERE is_default = true;

-- Show sample
SELECT name, category, image_url
FROM exercises
WHERE is_default = true
LIMIT 10;

SELECT '✅ All exercises now use bucket storage path!' as message;
SELECT 'Note: App will convert these to signed URLs automatically' as note;
