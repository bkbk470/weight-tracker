# 🚀 Supabase Setup Guide - Weight Tracker App

This guide will walk you through setting up Supabase for your Weight Tracker app with full authentication and database functionality.

## 📋 Table of Contents
1. [Create Supabase Project](#1-create-supabase-project)
2. [Run Database Schema](#2-run-database-schema)
3. [Configure Authentication](#3-configure-authentication)
4. [Get API Keys](#4-get-api-keys)
5. [Update Flutter App](#5-update-flutter-app)
6. [Test Everything](#6-test-everything)

---

## 1. Create Supabase Project

### Step 1: Sign Up for Supabase
1. Go to [https://supabase.com](https://supabase.com)
2. Click **"Start your project"**
3. Sign up with GitHub, Google, or Email
4. Verify your email if required

### Step 2: Create New Project
1. Click **"New Project"**
2. Choose your organization (or create one)
3. Enter project details:
   - **Name**: `weight-tracker` (or your preferred name)
   - **Database Password**: Create a strong password (save it!)
   - **Region**: Choose closest to your users
   - **Pricing Plan**: Free tier is perfect for development
4. Click **"Create new project"**
5. Wait 2-3 minutes for setup to complete ⏳

---

## 2. Run Database Schema

### Step 1: Open SQL Editor
1. In your Supabase project dashboard
2. Click **"SQL Editor"** in the left sidebar
3. Click **"New query"**

### Step 2: Execute Schema
1. Open the file `supabase_schema.sql` from your project
2. Copy **ALL** the content (Ctrl+A, Ctrl+C)
3. Paste into the Supabase SQL Editor
4. Click **"Run"** button (or press Ctrl+Enter)
5. Wait for success message ✅

### What This Creates:
- ✅ 8 database tables
- ✅ Row Level Security policies
- ✅ Indexes for performance
- ✅ 50+ default exercises
- ✅ Automatic triggers
- ✅ User profile creation

### Verify Tables Were Created:
1. Click **"Table Editor"** in left sidebar
2. You should see these tables:
   - `profiles`
   - `exercises`
   - `workouts`
   - `workout_exercises`
   - `workout_logs`
   - `exercise_sets`
   - `measurements`
   - `user_settings`

---

## 3. Configure Authentication

### Step 1: Enable Email Authentication
1. Go to **"Authentication"** in left sidebar
2. Click **"Providers"**
3. Find **"Email"** provider
4. Toggle it to **ENABLED** ✅
5. Settings to configure:
   ```
   ☑ Enable email confirmations (optional - uncheck for testing)
   ☑ Enable email signup
   ☑ Enable email login
   ```
6. Click **"Save"**

### Step 2: Configure Email Templates (Optional)
1. Click **"Email Templates"** tab
2. Customize these templates:
   - **Confirm signup**: Welcome email
   - **Magic Link**: Passwordless login
   - **Change Email Address**: Email change confirmation
   - **Reset Password**: Password reset email

### Step 3: Set Auth Settings
1. Click **"Settings"** tab
2. Configure:
   ```
   Site URL: http://localhost:3000 (for development)
   Redirect URLs: http://localhost:3000/** (for development)
   JWT Expiry: 3600 (1 hour)
   ```
3. Click **"Save"**

---

## 4. Get API Keys

### Step 1: Find Your Credentials
1. Go to **"Project Settings"** (gear icon ⚙️ bottom left)
2. Click **"API"** in the settings menu
3. You'll see your credentials:

```
Project URL: https://xxxxxxxxxxxxx.supabase.co
anon/public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
service_role key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9... (keep secret!)
```

### ⚠️ Important:
- **anon key** = Safe for mobile app (use this one!)
- **service_role key** = NEVER use in mobile app (admin only)

---

## 5. Update Flutter App

### Step 1: Add Supabase URL and Key
1. Open `lib/main.dart`
2. Find these lines:
   ```dart
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );
   ```

3. Replace with YOUR actual values:
   ```dart
   await Supabase.initialize(
     url: 'https://xxxxxxxxxxxxx.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
   );
   ```

### Step 2: Install Packages
```bash
flutter pub get
```

### Step 3: Restart App
```bash
flutter run
```

---

## 6. Test Everything

### ✅ Test 1: Authentication

**Sign Up:**
1. Launch app
2. Click **"Create Account"**
3. Enter email and password
4. Click **"Sign Up"**
5. ✅ Should create account and redirect to dashboard

**Sign In:**
1. Sign out
2. Enter same credentials
3. Click **"Sign In"**
4. ✅ Should log in successfully

**Profile:**
1. Go to Profile tab
2. ✅ Should see your email
3. ✅ Profile auto-created

### ✅ Test 2: Create Custom Exercise

1. Go to **Exercises** tab
2. Tap **"+ Create Exercise"**
3. Fill in:
   - Name: "Test Exercise"
   - Category: Chest
   - Equipment: Dumbbell
   - Difficulty: Beginner
4. Tap **"Create Exercise"**
5. ✅ Should appear in exercises list with "CUSTOM" badge

**Verify in Supabase:**
1. Go to Table Editor → `exercises`
2. ✅ Should see your exercise
3. ✅ Check `user_id` matches your user
4. ✅ `is_custom` should be `true`

### ✅ Test 3: Log a Workout

1. Go to **Home** tab
2. Start a new workout
3. Add an exercise
4. Log some sets (weights/reps)
5. Complete the workout
6. ✅ Workout should be saved

**Verify in Supabase:**
1. Table Editor → `workout_logs`
2. ✅ Should see your workout
3. Table Editor → `exercise_sets`
4. ✅ Should see your logged sets

### ✅ Test 4: Add Measurement

1. Go to **Profile** → **Measurements**
2. Add a weight measurement
3. Enter value and date
4. Save
5. ✅ Should appear in measurements list

**Verify in Supabase:**
1. Table Editor → `measurements`
2. ✅ Should see your measurement
3. ✅ Check `measurement_type` is correct

### ✅ Test 5: Offline Sync

1. Turn off WiFi
2. Log a workout
3. Add exercises
4. ✅ Should work offline (local storage)
5. Turn WiFi back on
6. Open **Storage & Sync** settings
7. Tap **"Sync Now"**
8. ✅ Data should sync to Supabase

---

## 🔒 Security Features

### Row Level Security (RLS)
All tables have RLS enabled. Users can only:
- ✅ View their own data
- ✅ Create their own data
- ✅ Update their own data
- ✅ Delete their own data
- ✅ View default exercises (not edit/delete)

### Authentication
- ✅ JWT tokens expire after 1 hour
- ✅ Passwords hashed with bcrypt
- ✅ Email verification (optional)
- ✅ Password reset flow

---

## 📊 Database Structure

```
Users (auth.users)
  ↓
profiles (user info)
  ↓
├─ exercises (custom exercises)
├─ workouts (workout templates)
│   └─ workout_exercises (exercises in template)
├─ workout_logs (completed workouts)
│   └─ exercise_sets (logged sets)
├─ measurements (body measurements)
└─ user_settings (app preferences)
```

---

## 🛠️ Useful SQL Queries

### Check Total Users
```sql
SELECT COUNT(*) FROM auth.users;
```

### View All Exercises (Default + Custom)
```sql
SELECT name, category, is_custom, is_default 
FROM exercises 
ORDER BY category, name;
```

### Get User's Workout Count
```sql
SELECT 
  u.email,
  COUNT(wl.id) as total_workouts
FROM auth.users u
LEFT JOIN workout_logs wl ON wl.user_id = u.id
GROUP BY u.email;
```

### View Recent Workouts
```sql
SELECT 
  u.email,
  wl.workout_name,
  wl.start_time,
  wl.duration_seconds
FROM workout_logs wl
JOIN auth.users u ON u.id = wl.user_id
ORDER BY wl.start_time DESC
LIMIT 10;
```

---

## 🐛 Troubleshooting

### Issue: "relation does not exist"
**Solution:** Run the schema SQL again. Tables weren't created.

### Issue: "new row violates row-level security"
**Solution:** Check you're logged in. RLS prevents unauthorized access.

### Issue: "JWT expired"
**Solution:** Sign out and sign in again. Tokens expire after 1 hour.

### Issue: Can't see default exercises
**Solution:** Check `exercises` table has `is_default=true` rows. Re-run schema insert section.

### Issue: Profile not created on signup
**Solution:** Check the trigger exists:
```sql
SELECT * FROM pg_trigger WHERE tgname = 'on_auth_user_created';
```

### Issue: Supabase URL/Key not working
**Solution:** 
1. Verify you copied the FULL URL and key
2. Check for extra spaces
3. Use the **anon** key, not service_role

---

## 📱 Test Accounts

For testing, create multiple accounts:

```
Test User 1:
Email: test1@example.com
Password: Test123456!

Test User 2:
Email: test2@example.com
Password: Test123456!
```

Each user's data is completely isolated! ✅

---

## 🎉 Success Checklist

Before considering setup complete, verify:

- [ ] ✅ All 8 tables created in Supabase
- [ ] ✅ Default exercises visible in app (50+)
- [ ] ✅ Can sign up new user
- [ ] ✅ Can sign in existing user
- [ ] ✅ Profile auto-created on signup
- [ ] ✅ Can create custom exercise
- [ ] ✅ Can log a workout
- [ ] ✅ Can add measurements
- [ ] ✅ Data syncs online
- [ ] ✅ Works offline
- [ ] ✅ Each user sees only their data

---

## 🚀 Next Steps

Your Supabase backend is now fully configured! 

**What works now:**
- ✅ User authentication (sign up, sign in, sign out)
- ✅ User profiles
- ✅ Custom exercises
- ✅ Workout logging
- ✅ Body measurements
- ✅ Offline mode with sync
- ✅ Data security (RLS)
- ✅ Default exercise library

**Start using your app with a real backend!** 🎊

---

## 📞 Need Help?

**Supabase Documentation:**
- [Supabase Docs](https://supabase.com/docs)
- [Flutter Guide](https://supabase.com/docs/guides/getting-started/tutorials/with-flutter)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

**Check Supabase Logs:**
1. Go to your project dashboard
2. Click "Logs" in sidebar
3. View API, Database, and Auth logs

---

**🎉 Congratulations! Your Weight Tracker app now has a fully functional Supabase backend!**
