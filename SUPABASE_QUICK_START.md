# ⚡ Supabase Setup - Quick Start Checklist

Follow these steps exactly to get your app working with Supabase in 10 minutes!

## ☑️ Step-by-Step Checklist

### □ 1. Create Supabase Project (3 min)
```
1. Go to: https://supabase.com
2. Click "Start your project"
3. Sign up (GitHub/Google/Email)
4. Click "New Project"
5. Enter:
   - Name: weight-tracker
   - Database Password: [create strong password]
   - Region: [choose closest]
6. Click "Create new project"
7. Wait 2-3 minutes ⏳
```

### □ 2. Run Database Schema (2 min)
```
1. In Supabase dashboard, click "SQL Editor" (left sidebar)
2. Click "New query"
3. Open file: supabase_schema.sql
4. Copy ALL content (Ctrl+A, Ctrl+C)
5. Paste in SQL Editor
6. Click "Run" button
7. Should see "Success" message ✅
```

**Verify:**
```
Click "Table Editor" → Should see 8 tables:
✅ profiles
✅ exercises
✅ workouts
✅ workout_exercises
✅ workout_logs
✅ exercise_sets
✅ measurements  
✅ user_settings
```

### □ 3. Enable Email Authentication (1 min)
```
1. Click "Authentication" (left sidebar)
2. Click "Providers"
3. Find "Email" → Toggle to ENABLED
4. Uncheck "Confirm email" (for testing)
5. Click "Save"
```

### □ 4. Get API Keys (1 min)
```
1. Click ⚙️ "Project Settings" (bottom left)
2. Click "API"
3. Copy these values:
   
   Project URL: https://xxxxxxxxxxxxx.supabase.co
   anon/public key: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### □ 5. Update Flutter App (2 min)
```
1. Open file: lib/main.dart
   
2. Find line 30-33:
   await Supabase.initialize(
     url: 'YOUR_SUPABASE_URL',
     anonKey: 'YOUR_SUPABASE_ANON_KEY',
   );

3. Replace with YOUR actual values:
   await Supabase.initialize(
     url: 'https://xxxxxxxxxxxxx.supabase.co',
     anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...',
   );

4. Save file
```

### □ 6. Install and Run (1 min)
```bash
# In terminal:
flutter pub get
flutter run
```

---

## 🧪 Test Your Setup (5 min)

### □ Test 1: Sign Up
```
1. Launch app
2. Tap "Create Account"
3. Enter:
   Email: test@example.com
   Password: Test123456!
4. Tap "Sign Up"
✅ Should show dashboard
```

### □ Test 2: Verify in Supabase
```
1. Go to Supabase → Authentication → Users
✅ Should see test@example.com

2. Go to Table Editor → profiles  
✅ Should see your profile row

3. Go to Table Editor → exercises
✅ Should see 50+ default exercises
```

### □ Test 3: Create Custom Exercise
```
1. In app, go to "Exercises" tab
2. Tap "+" Create Exercise button
3. Enter:
   Name: Test Exercise
   Category: Chest
   Equipment: Dumbbell
4. Tap "Create Exercise"
✅ Should appear in list with "CUSTOM" badge

5. Check Supabase → exercises table
✅ Should see your exercise with is_custom=true
```

### □ Test 4: Log Workout
```
1. In app, go to Home
2. Start a workout
3. Add an exercise
4. Log some sets (weights/reps)
5. Finish workout
✅ Should save successfully

6. Check Supabase → workout_logs table
✅ Should see your workout

7. Check Supabase → exercise_sets table
✅ Should see your logged sets
```

### □ Test 5: Offline Mode
```
1. Turn OFF WiFi
2. Log another workout
✅ Should work offline

3. Turn ON WiFi
4. Go to Profile → Storage & Sync
5. Tap "Sync Now"
✅ Should sync to Supabase
```

---

## ✅ Success Criteria

Your setup is complete when:

**Supabase Dashboard:**
- [x] 8 tables visible
- [x] 50+ exercises in exercises table
- [x] Your user in Authentication → Users
- [x] Your profile in profiles table

**Flutter App:**
- [x] App builds without errors
- [x] Can sign up new users
- [x] Can sign in existing users
- [x] Can create custom exercises
- [x] Can log workouts
- [x] Data appears in Supabase
- [x] Works offline
- [x] Syncs when online

---

## 🚨 Common Issues & Fixes

### Issue: "relation does not exist"
```
Fix: Schema not created properly
1. Go to SQL Editor
2. Re-run supabase_schema.sql
3. Wait for success message
```

### Issue: Can't see default exercises in app
```
Fix: Exercises not inserted
1. Go to SQL Editor
2. Run only the INSERT section (section 13) again
3. Check Table Editor → exercises
```

### Issue: "JWT expired" or "Not authenticated"
```
Fix: Sign out and sign in again
1. In app, go to Profile
2. Sign out
3. Sign in with same credentials
```

### Issue: App crashes on startup
```
Fix: Wrong URL or anon key
1. Double-check you copied FULL URL
2. Double-check you copied FULL anon key
3. Make sure no extra spaces
4. Use ANON key, not service_role key
```

### Issue: Can't sync data
```
Fix: Check internet connection
1. Make sure WiFi is on
2. Open Storage & Sync settings
3. Check "Last Sync" status
4. Tap "Sync Now" manually
```

---

## 📁 Important Files

```
weight_tracker_flutter/
├── supabase_schema.sql              ← Run this in Supabase SQL Editor
├── lib/main.dart                    ← Add your URL and anon key here (line 30-33)
├── lib/services/supabase_service.dart  ← All Supabase API methods
├── SUPABASE_SETUP_GUIDE.md          ← Detailed guide
├── SUPABASE_API_REFERENCE.md        ← Code examples
└── SUPABASE_QUICK_START.md          ← This file
```

---

## 🎯 Next Steps After Setup

1. **Read API Reference**
   - Open `SUPABASE_API_REFERENCE.md`
   - Learn how to use all features

2. **Test with Multiple Users**
   - Create 2-3 test accounts
   - Verify data isolation
   - Test offline sync

3. **Customize**
   - Add more default exercises
   - Create workout templates
   - Customize email templates

4. **Deploy**
   - Test on real devices
   - Enable email confirmation
   - Use environment variables for keys

---

## ⏱️ Time Estimate

- Create Supabase project: **3 minutes**
- Run database schema: **2 minutes**
- Enable authentication: **1 minute**
- Get API keys: **1 minute**
- Update Flutter app: **2 minutes**
- Testing: **5 minutes**

**Total: ~15 minutes** ⚡

---

## 🎉 Done!

Once all checkboxes are complete, your app has:
✅ Real user authentication
✅ Cloud database
✅ Offline support
✅ Data sync
✅ Production-ready backend

**Start using your app!** 🚀

---

## 📞 Need Help?

**Documentation:**
- Detailed guide: `SUPABASE_SETUP_GUIDE.md`
- API examples: `SUPABASE_API_REFERENCE.md`
- Summary: `SUPABASE_COMPLETE.md`

**Supabase:**
- Dashboard: Your project URL
- Docs: https://supabase.com/docs
- Discord: https://discord.supabase.com

**Logs:**
- Supabase Dashboard → Logs
- Flutter console output
- Supabase Table Editor

---

**✅ Checklist complete? Your app is ready to use with a real backend!**
