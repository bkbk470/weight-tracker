-- =====================================================
-- FIX: Change measurement_date from DATE to TIMESTAMP
-- =====================================================
-- This migration will allow storing time information
-- with measurements instead of just the date

-- Step 1: Add a new column with timestamp type
ALTER TABLE public.measurements 
ADD COLUMN measurement_timestamp TIMESTAMP WITH TIME ZONE;

-- Step 2: Copy existing date values to the new column
-- (Sets time to 00:00:00 for existing records)
UPDATE public.measurements 
SET measurement_timestamp = measurement_date::timestamp with time zone;

-- Step 3: Drop the old date column
ALTER TABLE public.measurements 
DROP COLUMN measurement_date;

-- Step 4: Rename the new column to measurement_date
ALTER TABLE public.measurements 
RENAME COLUMN measurement_timestamp TO measurement_date;

-- Step 5: Make the column NOT NULL
ALTER TABLE public.measurements 
ALTER COLUMN measurement_date SET NOT NULL;

-- Step 6: Update the index to use the new column type
DROP INDEX IF EXISTS idx_measurements_type_date;
CREATE INDEX idx_measurements_type_date 
ON public.measurements(measurement_type, measurement_date DESC);

-- =====================================================
-- MIGRATION COMPLETE!
-- =====================================================
-- Now measurements will store the full date and time
-- All new measurements will include hours and minutes
-- =====================================================
