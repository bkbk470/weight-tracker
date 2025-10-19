# Workout Folders Feature - Implementation Guide

## Overview
This feature allows users to organize their workouts into folders with custom colors and names, similar to organizing files on a computer.

## What's Included

### ✅ Files Added
1. **`lib/screens/workout_folders_screen.dart`** - Main folders management UI
2. **`setup_workout_folders.sql`** - Database setup script

### ✅ Files Modified
1. **`lib/services/supabase_service.dart`** - Added folder CRUD methods
2. **`lib/main.dart`** - Added navigation route
3. **`lib/screens/workout_library_screen.dart`** - Added folder icon button

---

## Installation Steps

### Step 1: Run Database Setup
1. Open your Supabase Dashboard
2. Navigate to **SQL Editor**
3. Copy and paste the contents of `setup_workout_folders.sql`
4. Click **Run** to execute the script
5. Verify success by checking the verification queries at the bottom

### Step 2: Code is Ready!
All code changes have been made. The feature is now fully integrated into your app.

---

## Features

### 📁 Folder Management
- **Create folders** with custom names, descriptions, and colors
- **Color coding**: Choose from blue, green, orange, purple, or red
- **View workouts by folder**: Expandable/collapsible folder sections
- **My Workouts section**: Workouts without a folder automatically appear here

### 🔄 Workout Organization
- **Move workouts** between folders with a simple dialog
- **View workout count** on each folder
- **Navigate to workouts** directly from folder view
- **Delete folders**: Workouts automatically move to "My Workouts"

### 🎨 User Interface
- Clean, modern Material Design 3 UI
- Empty state with helpful prompts
- Folder icon in workout library for easy access
- Expandable sections to hide/show folder contents

---

## How to Use

### Access Folders
1. Navigate to the **Workout** tab (bottom navigation)
2. Tap the **folder icon** in the top-right corner
3. You'll see the Workout Folders screen

### Create a Folder
1. Tap the **folder icon** in the app bar
2. Enter a name (required)
3. Optionally add a description
4. Choose a color
5. Tap **Create**

### Organize Workouts
1. Tap on a folder to expand it
2. See all workouts in that folder
3. Tap the **move icon** next to any workout
4. Select the destination folder or "My Workouts"

### Delete a Folder
1. Expand a folder
2. Tap the **delete icon** on the folder header
3. Confirm the deletion
4. **Note**: Workouts will move to "My Workouts," not be deleted

---

## Database Schema

### `workout_folders` Table
```sql
- id: UUID (Primary Key)
- user_id: UUID (Foreign Key to auth.users)
- name: TEXT (Folder name)
- description: TEXT (Optional description)
- color: TEXT (Color name: blue, green, orange, purple, red)
- icon: TEXT (Icon name, defaults to 'folder')
- parent_folder_id: UUID (For future nested folders feature)
- order_index: INTEGER (For custom ordering)
- created_at: TIMESTAMP
- updated_at: TIMESTAMP
```

### `workouts` Table (Modified)
```sql
- folder_id: UUID (Foreign Key to workout_folders)
  - NULL = Workout shows in My Workouts
  - CASCADE DELETE SET NULL = If folder deleted, workout stays but becomes part of My Workouts
```

---

## API Methods Added to `SupabaseService`

### Folder Operations
```dart
// Get all folders
Future<List<Map<String, dynamic>>> getWorkoutFolders()

// Create folder
Future<Map<String, dynamic>> createFolder({
  required String name,
  String? description,
  String? color,
  String? icon,
  String? parentFolderId,
})

// Update folder
Future<void> updateFolder(String folderId, Map<String, dynamic> updates)

// Delete folder
Future<void> deleteFolder(String folderId)

// Move workout to folder
Future<void> moveWorkoutToFolder(String workoutId, String? folderId)

// Get workouts by folder
Future<List<Map<String, dynamic>>> getWorkoutsByFolder(String? folderId)
```

---

## Future Enhancements (Not Yet Implemented)

### Potential Features
- **Nested folders** (subfolders) - Database already supports this via `parent_folder_id`
- **Folder sharing** with other users
- **Drag and drop** reordering
- **Bulk operations** (move multiple workouts at once)
- **Folder templates** (pre-made folder structures)
- **Custom icons** (beyond the default folder icon)
- **Folder statistics** (total sets, volume, etc.)
- **Export/Import** folder structures

---

## Troubleshooting

### Folders not showing up?
- Check that you ran the SQL setup script
- Verify RLS policies are in place
- Ensure you're logged in

### Can't move workouts?
- Check that the workout belongs to you
- Verify the `folder_id` column exists in `workouts` table
- Check Supabase logs for any errors

### Folder icon not visible in workout library?
- Make sure you saved all code changes
- Restart your app (hot restart might not be enough)
- Check that the navigation route 'workout-folders' is defined

---

## Color Reference

The following colors are available for folders:
- **blue** → Blue theme
- **green** → Green theme  
- **orange** → Orange theme
- **purple** → Purple theme
- **red** → Red theme

Colors are used for visual organization and have no functional impact.

---

## Security

### Row Level Security (RLS)
All folder operations are protected by RLS policies:
- Users can only view their own folders
- Users can only create folders for themselves
- Users can only update/delete their own folders

### Permissions
- Folder deletion uses `CASCADE DELETE` to clean up orphaned data
- Workout folder assignment uses `SET NULL` to preserve workouts when folders are deleted

---

## Testing Checklist

- [ ] Run SQL setup script successfully
- [ ] Create a new folder
- [ ] View folder in the folders list
- [ ] Move a workout into a folder
- [ ] Expand/collapse folders
- [ ] Navigate to workout from folder view
- [ ] Move workout to different folder
- [ ] Move workout to "My Workouts"
- [ ] Delete a folder (verify workouts become My Workouts)
- [ ] Try each color option
- [ ] Check empty state appears when no folders exist

---

## Support

If you encounter issues:
1. Check the Supabase logs for errors
2. Verify all SQL commands ran successfully
3. Ensure RLS policies are active
4. Check that imports are correct in modified files
5. Try a full app rebuild (not just hot reload)

---

**That's it! Your workout folders feature is now fully implemented and ready to use! 🎉**
