# Troubleshooting: Measurement Times Showing 00:00

## The Problem
Body measurements are showing `00:00` for all times instead of the actual time when the measurement was taken (e.g., "Oct 15, 2025 • 00:00" instead of "Oct 15, 2025 • 14:30").

## Root Cause
The Supabase database column `measurement_date` is defined as `DATE` type instead of `TIMESTAMP WITH TIME ZONE`. This means the database can only store dates, not times.

## Solution Steps

### Step 1: Check Your Database Column Type

1. Go to your Supabase Dashboard
2. Navigate to **Table Editor**
3. Select the `measurements` table
4. Look at the `measurement_date` column definition

**If it says `date`:** You need to run the migration (Step 2)  
**If it says `timestamp with time zone` or `timestamptz`:** The database is correct, skip to Step 3

### Step 2: Run the Database Migration

**IMPORTANT:** This will change your database schema. Make sure you have a backup if you have important data.

1. Open Supabase Dashboard
2. Go to **SQL Editor**
3. Click **New Query**
4. Copy and paste the following SQL:

```sql
-- Change measurement_date from DATE to TIMESTAMP WITH TIME ZONE

-- Step 1: Add a new column with timestamp type
ALTER TABLE public.measurements 
ADD COLUMN measurement_timestamp TIMESTAMP WITH TIME ZONE;

-- Step 2: Copy existing date values to the new column
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

-- Step 6: Update the index
DROP INDEX IF EXISTS idx_measurements_type_date;
CREATE INDEX idx_measurements_type_date 
ON public.measurements(measurement_type, measurement_date DESC);
```

5. Click **Run** or press `Ctrl+Enter` / `Cmd+Enter`
6. Verify it says "Success. No rows returned"

### Step 3: Verify the Code Changes

Make sure these files have been updated (they should already be fixed):

**File: `lib/services/supabase_service.dart`**
Around line 470, it should be:
```dart
'measurement_date': measurementDate.toIso8601String(),
```

NOT:
```dart
'measurement_date': measurementDate.toIso8601String().split('T')[0],  // ❌ WRONG
```

**File: `lib/screens/measurements_screen.dart`**
Should have debug logging (lines 467-473):
```dart
// Debug: Print the raw date from Supabase
debugPrint('DEBUG: Raw date from Supabase for ${def.typeKey}: $dateRaw');
```

### Step 4: Test the Fix

1. **Hot Restart** your app (not just hot reload)
2. Add a **NEW** measurement (e.g., add a weight measurement)
3. Check the console/debug output for lines like:
   ```
   DEBUG: Raw date from Supabase for weight: 2025-10-15T14:30:25.123Z
   DEBUG: Parsed DateTime: 2025-10-15 14:30:25.123Z
   ```
4. Look at the measurement history - new measurements should show the correct time

## Expected Results

### After Migration:
- **New measurements:** Will show correct time (e.g., "Oct 15, 2025 • 14:30")
- **Old measurements:** Will still show 00:00 because they only have date data

### Debug Output:
When viewing measurements, you should see in the console:
```
DEBUG: Raw date from Supabase for weight: 2025-10-15T14:30:25.123456Z
DEBUG: Parsed DateTime: 2025-10-15 14:30:25.123456Z
```

If you see:
```
DEBUG: Raw date from Supabase for weight: 2025-10-15
DEBUG: Parsed DateTime: 2025-10-15 00:00:00.000Z
```
This means the database migration hasn't been applied yet.

## Common Issues

### Issue 1: Still showing 00:00 after migration
**Cause:** You're looking at old measurements  
**Solution:** Add a NEW measurement and check that one

### Issue 2: Error running migration SQL
**Cause:** Syntax error or column already exists  
**Solution:** Check if the column is already `timestamp with time zone` type

### Issue 3: App crashes after migration
**Cause:** App needs to be restarted  
**Solution:** Do a full hot restart (or stop and restart the app)

## Verification Checklist

- [ ] Database column type changed to `TIMESTAMP WITH TIME ZONE`
- [ ] Code updated in `supabase_service.dart` (no `.split('T')[0]`)
- [ ] App hot restarted
- [ ] New measurement added
- [ ] Debug output shows full timestamp with time
- [ ] New measurements display correct time in history

## If It Still Doesn't Work

1. Check the debug output in the console
2. Verify the SQL migration ran successfully
3. Confirm you're adding a **new** measurement (not looking at old ones)
4. Try deleting all measurements and adding a fresh one
5. Check Supabase dashboard to see what's actually stored in the database

## Contact
If you've followed all steps and it still doesn't work, provide:
1. The debug console output
2. A screenshot of the measurement history
3. The column type from Supabase Table Editor
