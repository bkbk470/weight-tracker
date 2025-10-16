-- =====================================================
-- ADD NEW BODY MEASUREMENT TYPES
-- =====================================================
-- This migration adds support for more detailed body measurements:
-- - Neck, Shoulders
-- - Left/Right Bicep, Left/Right Forearm
-- - Upper Abs, Lower Abs
-- - Left/Right Thigh, Left/Right Calf

-- Drop the old constraint
ALTER TABLE public.measurements 
DROP CONSTRAINT IF EXISTS measurements_measurement_type_check;

-- Add the new constraint with all measurement types
ALTER TABLE public.measurements 
ADD CONSTRAINT measurements_measurement_type_check 
CHECK (measurement_type IN (
    'weight', 'body_fat',
    'neck', 'shoulders', 'chest',
    'left_bicep', 'right_bicep', 'left_forearm', 'right_forearm',
    'upper_abs', 'waist', 'lower_abs', 'hips',
    'left_thigh', 'right_thigh', 'left_calf', 'right_calf',
    'biceps', 'thighs', 'calves',  -- Keep old types for backward compatibility
    'other'
));

-- =====================================================
-- MIGRATION COMPLETE!
-- =====================================================
-- The measurements table now supports:
-- - General: weight, body_fat
-- - Upper Body: neck, shoulders, chest
-- - Arms: left_bicep, right_bicep, left_forearm, right_forearm
-- - Core: upper_abs, waist, lower_abs, hips
-- - Lower Body: left_thigh, right_thigh, left_calf, right_calf
-- 
-- Old measurement types (biceps, thighs, calves) are still supported
-- for backward compatibility with existing data
-- =====================================================
