# 🔧 Complete Database Troubleshooting Guide

## Current Issues
1. ❌ Workouts not saving to database
2. ❌ Exercises not showing in profile
3. ❌ Nothing appears in Supabase

## Step-by-Step Fix

### **STEP 1: Test Database Connection**

Run the app and go to:
```
Profile → Settings → Database Debug → Run Full Test
```

This will show you EXACTLY what's failing.

**Look for these results:**

#### ✅ If you see:
```
✅ Authenticated as: your-email@example.com
✅ Database connected
✅ Workout log created successfully!
✅ Set 1 created: 145 lbs x 8 reps
✅ Set 2 created: 155 lbs x 8 reps
✅ Set 3 created: 165 lbs x 8 reps
✅ Found 1 workout logs
✅ Database is working correctly!
```
**Then:** Database works! Issue is in the workout screen logic.

#### ❌ If you see:
```
❌ NOT AUTHENTICATED!
```
**Fix:** Sign out and sign in again with a real account.

#### ❌ If you see:
```
❌ Database connection failed: relation "public.exercises" does not exist
```
**Fix:** Run the SQL schema (see STEP 2)

#### ❌ If you see:
```
❌ Failed to create workout log: new row violates row-level security
```
**Fix:** Re-run the SQL schema to fix RLS policies (see STEP 2)

---

### **STEP 2: Run SQL Schema (If Database Test Fails)**

1. Go to [https://supabase.com](https://supabase.com)
2. Open your project
3. Click **SQL Editor** (left sidebar)
4. Click **New Query**
5. Open the file: `supabase_schema.sql` from your project
6. Copy **ALL** content (Ctrl+A, Ctrl+C)
7. Paste into SQL Editor
8. Click **Run** (or Ctrl+Enter)
9. Should see: "Success. No rows returned"

**Verify tables exist:**
```
Table Editor → Should see these tables:
- profiles
- exercises  
- workouts
- workout_exercises
- workout_logs
- exercise_sets
- measurements
- user_settings
```

---

### **STEP 3: Test Workout Creation**

After database test passes:

1. **Start a workout:**
   - Go to Workout tab
   - Tap "Start Empty Workout"

2. **Add exercise:**
   - Tap "Add Exercise"
   - Select "Bench Press"

3. **Log sets:**
   - Set 1: 135 lbs x 10 reps → Check ✅
   - Set 2: 145 lbs x 8 reps → Check ✅
   - Set 3: 155 lbs x 6 reps → Check ✅

4. **Finish workout:**
   - Tap "Finish Workout" (top right ✓)
   - Confirm

5. **Look for message:**
   - ✅ Green: "Workout saved successfully! ✅"
   - ⚠️ Orange: "Workout saved offline"
   - ❌ Red: "Error saving workout"

---

### **STEP 4: Verify in Supabase**

1. Go to Supabase Dashboard
2. **Table Editor** → **workout_logs**
3. Should see your workout:
   - workout_name
   - user_id (your ID)
   - duration_seconds
   - start_time
   - end_time

4. **Table Editor** → **exercise_sets**
5. Should see your sets:
   - exercise_name: "Bench Press"
   - weight_lbs: 135, 145, 155
   - reps: 10, 8, 6
   - workout_log_id

---

### **STEP 5: Check Profile**

1. Go to Profile tab
2. Under "Your Stats"
3. Should see "Total Workouts: 1" (or more)

---

## Common Errors & Fixes

### Error: "Not authenticated"
**Cause:** Not signed in or session expired
**Fix:**
1. Profile → Sign Out
2. Sign in again
3. Try creating workout again

### Error: "relation does not exist"
**Cause:** Database tables not created
**Fix:**
1. Run `supabase_schema.sql` in SQL Editor
2. Verify tables exist in Table Editor

### Error: "violates row-level security"
**Cause:** RLS policies not set correctly
**Fix:**
1. Re-run `supabase_schema.sql`
2. This will recreate all policies

### Error: "Invalid exercise_id"
**Cause:** Exercise doesn't exist in database
**Fix:**
1. The app generates temp IDs for exercises
2. This is expected and should still work
3. Check if workout_log was created

### Success message but nothing in database
**Cause:** Might be saving only to local storage
**Check:**
1. Run Database Debug test
2. Check if Supabase URL/key are correct in main.dart
3. Check internet connection

---

## Manual Database Check

Run this in Supabase SQL Editor to see your data:

```sql
-- Check your user ID
SELECT id, email FROM auth.users WHERE email = 'your-email@example.com';

-- Check your workouts
SELECT * FROM workout_logs WHERE user_id = 'your-user-id';

-- Check your exercise sets
SELECT * FROM exercise_sets WHERE workout_log_id IN (
  SELECT id FROM workout_logs WHERE user_id = 'your-user-id'
);

-- Count workouts
SELECT COUNT(*) as total_workouts 
FROM workout_logs 
WHERE user_id = 'your-user-id';
```

Replace `'your-email@example.com'` and `'your-user-id'` with your actual values.

---

## Debug Checklist

Before reporting issues, check:

- [ ] Signed in (Profile shows your email)
- [ ] Database Debug test passes all checks
- [ ] Supabase URL and anon key in main.dart
- [ ] SQL schema ran successfully
- [ ] 8 tables exist in Table Editor
- [ ] Internet connection active
- [ ] No error messages in Flutter console

---

## Test Sequence

**Do these in order:**

1. ✅ **Connection Test** (Profile → Connection Test)
   - Should: "SUCCESS! Connected!"

2. ✅ **Database Debug** (Profile → Database Debug)
   - Should: All tests pass with ✅

3. ✅ **Create Workout** (Workout → Start → Add Exercise → Log Sets → Finish)
   - Should: Green "Workout saved successfully!"

4. ✅ **Check Supabase** (Dashboard → workout_logs table)
   - Should: See your workout row

5. ✅ **Check Profile** (Profile tab → Your Stats)
   - Should: "Total Workouts: 1"

---

## If Nothing Works

**Nuclear option - Reset everything:**

1. **Clear app data:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Re-run schema in Supabase:**
   - SQL Editor → Run supabase_schema.sql

3. **Create new account:**
   - Sign out
   - Sign up with new email
   - Try creating workout

4. **Check Supabase logs:**
   - Dashboard → Logs → API
   - Look for errors when creating workout

---

## Expected Behavior

**When everything works correctly:**

```
1. User starts workout
2. Adds exercises
3. Logs sets with weights/reps
4. Taps "Finish Workout"
5. App shows: "Workout saved successfully! ✅"
6. Supabase → workout_logs: New row appears
7. Supabase → exercise_sets: New rows appear
8. Profile → Total Workouts: Increases by 1
9. Progress → History: Workout appears
```

---

## Get Detailed Logs

To see exactly what's happening:

1. Open Flutter console (terminal where you ran `flutter run`)
2. Create a workout
3. Finish workout
4. Look for these logs:
   - "Error saving workout: ..."
   - "Workout saved successfully"
   - Any Supabase errors

---

## Contact Info

If still not working after all steps:

1. Run Database Debug
2. Screenshot the results
3. Check Supabase logs
4. Check Flutter console errors
5. Share all error messages

**Most likely cause: SQL schema not run or authentication issue**

---

## Quick Diagnostic

Run this simple test:

```
1. Profile → Database Debug → Run Full Test
2. Wait for results
3. Look at first error (if any)
4. That's your issue!
```

The debug screen will tell you exactly what's wrong:
- ❌ Not authenticated → Sign in again
- ❌ Database connection failed → Run schema
- ❌ Tables don't exist → Run schema
- ❌ RLS error → Run schema again
- ✅ All pass → Issue is in workout screen logic

---

**Start with Database Debug - it will tell you everything!** 🔍
