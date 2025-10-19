-- ==========================================
-- ADD is_favorite COLUMN TO workout_plans
-- ==========================================
-- Run this SQL in your Supabase SQL Editor
-- This allows users to pin favorite workout plans to the dashboard

-- Add the is_favorite column (defaults to false)
ALTER TABLE workout_plans 
ADD COLUMN IF NOT EXISTS is_favorite BOOLEAN DEFAULT false NOT NULL;

-- Create an index for faster queries when filtering favorites
CREATE INDEX IF NOT EXISTS idx_workout_plans_is_favorite 
ON workout_plans(user_id, is_favorite) 
WHERE is_favorite = true;

-- Verificatioon
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT FROM information_schema.columns 
      WHERE table_name = 'workout_plans' 
      AND column_name = 'is_favorite'
    )
    THEN '✓ is_favorite column added successfully'
    ELSE '✗ is_favorite column NOT found'
  END as status;

-- ==========================================
-- DONE!
-- ==========================================
-- Now workout plans can be marked as favorites
-- Favorite plans will be prioritized on the dashboard
