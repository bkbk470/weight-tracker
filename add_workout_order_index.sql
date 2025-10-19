-- ==========================================
-- ADD ORDER_INDEX TO WORKOUTS TABLE
-- ==========================================
-- Run this SQL in your Supabase SQL Editor
-- This allows users to customize the order of their workout plans

-- Add order_index column to workouts table if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 
    FROM information_schema.columns 
    WHERE table_name = 'workouts' 
    AND column_name = 'order_index'
  ) THEN
    ALTER TABLE workouts 
    ADD COLUMN order_index INTEGER DEFAULT 0;
    
    -- Initialize order_index based on created_at (oldest = 0)
    WITH ordered_workouts AS (
      SELECT 
        id,
        ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at) - 1 as new_order
      FROM workouts
    )
    UPDATE workouts w
    SET order_index = ow.new_order
    FROM ordered_workouts ow
    WHERE w.id = ow.id;
    
    RAISE NOTICE 'Added order_index column to workouts table';
  ELSE
    RAISE NOTICE 'order_index column already exists in workouts table';
  END IF;
END $$;

-- Create index for better performance
CREATE INDEX IF NOT EXISTS idx_workouts_user_order 
ON workouts(user_id, order_index);

-- ==========================================
-- VERIFICATION
-- ==========================================

-- Check if column exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM information_schema.columns 
      WHERE table_name = 'workouts' 
      AND column_name = 'order_index'
    )
    THEN '✓ order_index column exists in workouts table'
    ELSE '✗ order_index column NOT found'
  END as column_check;

-- Check index exists
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM pg_indexes 
      WHERE tablename = 'workouts' 
      AND indexname = 'idx_workouts_user_order'
    )
    THEN '✓ Index idx_workouts_user_order created'
    ELSE '✗ Index NOT found'
  END as index_check;

-- Show sample data
SELECT 
  id, 
  name, 
  order_index,
  user_id,
  created_at
FROM workouts 
ORDER BY user_id, order_index
LIMIT 10;

-- ==========================================
-- MIGRATION COMPLETE!
-- ==========================================
-- Workouts can now be reordered by users!
