# Use Your Supabase Bucket Images

I've updated your app to use images from your Supabase storage bucket!

## What I Changed:

### 1. Created StorageImage Widget ✅
**File:** [lib/widgets/storage_image.dart](lib/widgets/storage_image.dart)

This smart widget:
- Handles storage paths like `Exercises/default_exercise.gif`
- Automatically converts them to signed URLs
- Works with full URLs too (https://...)
- Shows loading spinner while fetching
- Falls back to fitness icon if image fails

### 2. Updated Workout Builder ✅
**File:** [lib/screens/workout_builder_screen.dart](lib/screens/workout_builder_screen.dart#L440-L445)

Now uses `StorageImage` widget instead of complex `Image.network` code.

### 3. Updated Add Exercise Dialog ✅
**File:** [lib/screens/workout_detail_screen.dart](lib/screens/workout_detail_screen.dart#L1459-L1464)

Dialog also uses `StorageImage` for consistency.

---

## How to Use Your Bucket Images:

### Step 1: Run SQL to Set Image Paths

Run this in **Supabase SQL Editor:**

```sql
-- Update all exercises to use your bucket's default image
UPDATE exercises
SET image_url = 'Exercises/default_exercise.gif'
WHERE is_default = true;
```

This sets the **storage path format** (not full URL). The app will automatically:
1. Detect it's a storage path
2. Call `getSignedUrlForStoragePath()`
3. Get a signed URL from your bucket
4. Display the image

---

### Step 2: Clear Cache & Restart

**Option A: Hot Reload**
```bash
r  # in terminal
```

**Option B: Full Restart**
```bash
flutter run
```

**Option C: Force Refresh Exercises**

Add this button temporarily to your app:
```dart
ElevatedButton(
  onPressed: () async {
    await ExerciseCacheService.instance.refreshExercises();
    setState(() {});
    print('✅ Exercises refreshed!');
  },
  child: Text('Refresh Exercises'),
)
```

---

### Step 3: Verify Images Load

Open "Add Exercise" dialog and you should see:
- 🔄 Loading spinner initially
- 📸 Your default_exercise.gif image
- Or 💪 Fitness icon if image fails to load

---

## Advanced: Different Images Per Exercise

If you want different images for different exercises:

### Upload Images to Bucket

1. Go to Supabase → Storage → `Exercises` bucket
2. Upload images with descriptive names:
   - `bench_press.jpg`
   - `squat.jpg`
   - `deadlift.jpg`
   - etc.

### Update SQL with Specific Images

```sql
-- Bench press exercises
UPDATE exercises
SET image_url = 'Exercises/bench_press.jpg'
WHERE name ILIKE '%bench%press%' AND is_default = true;

-- Squat exercises
UPDATE exercises
SET image_url = 'Exercises/squat.jpg'
WHERE name ILIKE '%squat%' AND is_default = true;

-- Deadlift exercises
UPDATE exercises
SET image_url = 'Exercises/deadlift.jpg'
WHERE name ILIKE '%deadlift%' AND is_default = true;

-- All others use default
UPDATE exercises
SET image_url = 'Exercises/default_exercise.gif'
WHERE image_url IS NULL AND is_default = true;
```

---

## Alternative: Use Full Public URLs

If your bucket is **public**, you can use full URLs instead:

### Step 1: Get Your Project Reference

From your Supabase dashboard URL:
```
https://YOUR_PROJECT_REF.supabase.co
```

### Step 2: Run This SQL

```sql
UPDATE exercises
SET image_url = 'https://YOUR_PROJECT_REF.supabase.co/storage/v1/object/public/Exercises/default_exercise.gif'
WHERE is_default = true;
```

Replace `YOUR_PROJECT_REF` with your actual project reference!

---

## File Paths Reference

### Storage Path Format (Recommended)
```
Exercises/default_exercise.gif
Exercises/bench_press.jpg
Exercises/squat.jpg
```

The app automatically converts these to signed URLs.

### Full URL Format (Alternative)
```
https://YOUR_PROJECT.supabase.co/storage/v1/object/public/Exercises/default_exercise.gif
```

Works too, but storage paths are better for security (uses signed URLs).

---

## Troubleshooting

### Images not showing?

1. **Check SQL ran successfully**
   ```sql
   SELECT name, image_url FROM exercises LIMIT 5;
   ```
   Should show `Exercises/default_exercise.gif`

2. **Check bucket exists**
   - Supabase → Storage → Look for `Exercises` bucket

3. **Check file exists**
   - Open bucket → Look for `default_exercise.gif`

4. **Check bucket is accessible**
   - Go to bucket settings
   - Make sure it's either:
     - Public, OR
     - Has proper RLS policies for signed URLs

5. **Check console logs**
   ```
   Error resolving image URL: ...
   ```
   This will tell you what went wrong.

6. **Try force refresh**
   - Stop app completely
   - Run `flutter clean`
   - Run `flutter run`

---

## Summary

**Quick Steps:**
1. ✅ Code is already updated
2. 📝 Run SQL: `UPDATE exercises SET image_url = 'Exercises/default_exercise.gif' WHERE is_default = true;`
3. 🔄 Restart your app
4. 📸 See your bucket images!

The `StorageImage` widget now handles everything automatically! 🎉
