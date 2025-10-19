# 🔧 Database Not Updating - Troubleshooting Guide

If your database is not updating when creating users, exercises, or other data, follow this step-by-step guide.

## 🧪 Step 1: Run Connection Test

**In the app:**
1. Go to **Profile** → **Settings** → **Connection Test**
2. Wait for tests to complete
3. Check which tests are failing

The test will check:
- ✅ Configuration (URL and anon key)
- ✅ Authentication (logged in user)
- ✅ Database Connection
- ✅ Tables Exist

---

## ❌ Common Issues & Fixes

### Issue 1: "Missing URL or Key"

**Problem:** Supabase URL and anon key not configured

**Fix:**
1. Open `lib/main.dart`
2. Find lines 30-33:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```
3. Replace with YOUR actual values from Supabase:
   - Go to [https://supabase.com](https://supabase.com)
   - Open your project
   - Go to **Project Settings** → **API**
   - Copy **Project URL** and **anon/public key**
4. Update main.dart:
   ```dart
   await Supabase.initialize(
     url: 'https://xxxxxxxxxxxxx.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
   );
   ```
5. Save and restart app

---

### Issue 2: "Not authenticated"

**Problem:** No user logged in

**Fix:**
1. In app, go to Profile
2. If logged in, sign out
3. Click **"Create Account"**
4. Enter:
   - Email: test@example.com  
   - Password: Test123456!
5. Sign up
6. Should redirect to dashboard
7. Run connection test again

**OR sign in with existing account:**
1. Click **"Sign In"**
2. Enter your credentials
3. Should redirect to dashboard

---

### Issue 3: "relation does not exist" or "Tables don't exist"

**Problem:** Database schema not created

**Fix:**
1. Go to [https://supabase.com](https://supabase.com)
2. Open your project
3. Click **"SQL Editor"** in left sidebar
4. Click **"New query"**
5. Open the file `supabase_schema.sql` from your project folder
6. Copy **ALL** the content (Ctrl+A, Ctrl+C)
7. Paste into SQL Editor
8. Click **"Run"** button (or press Ctrl+Enter)
9. Should see "Success. No rows returned"
10. Go to **Table Editor**
11. Should see these tables:
    - profiles
    - exercises
    - workouts
    - workout_exercises
    - workout_logs
    - exercise_sets
    - measurements
    - user_settings

**Verify tables:**
```sql
-- Run this in SQL Editor to check tables
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public';
```

Should see all 8 tables listed.

---

### Issue 4: "JWT expired" or "Invalid token"

**Problem:** Session expired

**Fix:**
1. Sign out from app
2. Sign in again
3. Try creating exercise again

---

### Issue 5: Email auth not enabled

**Problem:** Can't create account

**Fix:**
1. Go to Supabase Dashboard
2. Click **"Authentication"** → **"Providers"**
3. Find **"Email"** provider
4. Toggle to **ENABLED**
5. Settings:
   - ☑ Enable email signup
   - ☑ Enable email login
   - ☐ Confirm email (uncheck for testing)
6. Click **"Save"**
7. Try signing up again

---

### Issue 6: "new row violates row-level security"

**Problem:** RLS policies not set correctly

**Fix:**
Re-run the schema SQL:
1. Go to SQL Editor
2. Copy content from `supabase_schema.sql`
3. Run it again
4. This will recreate all RLS policies

**Or check policies manually:**
1. Go to **Authentication** → **Policies**
2. Each table should have policies like:
   - `Users can view own data`
   - `Users can create own data`
   - `Users can update own data`
   - `Users can delete own data`

---

## ✅ Complete Setup Checklist

Go through this checklist step-by-step:

### Supabase Setup:
- [ ] Created Supabase project
- [ ] Ran `supabase_schema.sql` in SQL Editor
- [ ] Verified 8 tables exist in Table Editor
- [ ] Enabled Email auth in Authentication → Providers
- [ ] Copied Project URL from Project Settings → API
- [ ] Copied anon key from Project Settings → API

### Flutter App Setup:
- [ ] Pasted URL into `main.dart` line 31
- [ ] Pasted anon key into `main.dart` line 32
- [ ] Ran `flutter pub get`
- [ ] Restarted app
- [ ] Created account or signed in
- [ ] Ran Connection Test (all tests pass)

### Test Functionality:
- [ ] Create custom exercise
- [ ] Check Supabase Table Editor → exercises
- [ ] Should see your exercise
- [ ] Create another user account
- [ ] Each user sees only their own data

---

## 🔍 Manual Database Check

### Check if data is in Supabase:

**1. Check Users:**
```
Dashboard → Authentication → Users
✅ Should see your email
```

**2. Check Profiles:**
```
Dashboard → Table Editor → profiles
✅ Should see your profile row
```

**3. Check Exercises:**
```
Dashboard → Table Editor → exercises

Filter: is_default = true
✅ Should see 50+ default exercises

Filter: is_custom = true, user_id = [your-user-id]
✅ Should see your custom exercises
```

**4. Check Workout Logs:**
```
Dashboard → Table Editor → workout_logs
✅ Should see logged workouts
```

---

## 🐛 Debug Mode

Enable debug mode to see errors:

**In `main.dart` line 31:**
```dart
await Supabase.initialize(
  url: 'YOUR_URL',
  anonKey: 'YOUR_KEY',
  debug: true,  // Add this line
);
```

Then check Flutter console for errors when:
- Creating account
- Creating exercise
- Logging workout

---

## 📊 Quick Verification

### Test 1: Can you see default exercises?
```
App → Exercises tab
✅ Should see: Bench Press, Squats, Deadlifts, etc.
```

If YES: Database connection works!  
If NO: Database not connected properly

### Test 2: Can you create account?
```
App → Create Account
Enter email and password
✅ Should create account and redirect
```

If YES: Auth works!  
If NO: Email auth not enabled

### Test 3: Does exercise appear in database?
```
1. App → Create exercise "Test Exercise"
2. Supabase → Table Editor → exercises
3. ✅ Should see "Test Exercise" row
```

If YES: Everything works!  
If NO: Check connection test results

---

## 💡 Quick Fixes

### Nothing works at all?
```bash
# Reset and try again:
flutter clean
flutter pub get
flutter run
```

### URL/Key not working?
```
Make sure you copied the FULL key:
- It's very long (100+ characters)
- Starts with: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9
- No spaces before or after
- Use ANON key, NOT service_role key
```

### Tables don't exist?
```
1. SQL Editor → New Query
2. Paste supabase_schema.sql
3. Run
4. Check Table Editor
```

### Can't authenticate?
```
1. Authentication → Providers → Email
2. Enable it
3. Save
4. Try again
```

---

## 📞 Getting Help

### Check Logs:

**Supabase Logs:**
```
Dashboard → Logs → API / Database / Auth
Look for errors when creating data
```

**Flutter Console:**
```
Look for error messages like:
- "relation does not exist"
- "JWT expired"  
- "Not authenticated"
- "Network error"
```

### Common Error Messages:

**"relation 'public.exercises' does not exist"**
→ Run supabase_schema.sql

**"JWT expired"**
→ Sign out and sign in again

**"Not authenticated"**  
→ Create account or sign in

**"new row violates row-level security"**
→ Re-run schema SQL to fix policies

---

## ✅ Success Criteria

Your setup is complete when:

**Connection Test shows:**
- ✅ Configuration: OK
- ✅ Authentication: Authenticated as [your-email]
- ✅ Database Connection: Connected! Found 50+ exercises
- ✅ Database Tables: Tables exist

**And you can:**
- ✅ Create custom exercise
- ✅ See it in app immediately
- ✅ See it in Supabase Table Editor
- ✅ Log workouts
- ✅ Add measurements

---

## 🎯 Step-by-Step Fix

If still not working, follow this exact order:

**1. Verify Supabase Project:**
```
- Go to supabase.com
- Open your project
- Project Settings → General
- Note your project name
```

**2. Get Credentials:**
```
- Project Settings → API
- Copy Project URL
- Copy anon/public key
- DO NOT copy service_role key
```

**3. Update App:**
```dart
// main.dart lines 30-33
await Supabase.initialize(
  url: 'https://[your-project].supabase.co',
  anonKey: 'eyJhbGci...[your-anon-key]',
);
```

**4. Run Schema:**
```
- SQL Editor → New Query
- Copy ALL of supabase_schema.sql
- Paste and Run
- Check Table Editor for 8 tables
```

**5. Enable Auth:**
```
- Authentication → Providers
- Email → Enable
- Save
```

**6. Test:**
```
- Restart app
- Create account
- Profile → Connection Test
- All tests should pass ✅
```

---

## 📧 Still Having Issues?

1. Run Connection Test in app
2. Take screenshot of results
3. Check Supabase Logs for errors
4. Check Flutter console for errors
5. Verify all steps above completed

**Most common fix:** Making sure URL and anon key are correctly added to main.dart!

---

**Once Connection Test shows all green checkmarks, everything will work!** ✅
