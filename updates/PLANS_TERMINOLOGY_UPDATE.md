# Terminology Update: Folders → Plans

## Changes Made

Updated all user-facing terminology from "Folders" to "Plans" for better clarity and understanding.

## What Changed

### Dashboard Screen:
- ✅ Section header: "Workout Plans"
- ✅ Button: "New Plan" (create new workout plan)
- ✅ Button: "Manage" (manage workout plans)
- ✅ Dialog title: "Create Workout Plan"

### Workout Folders Screen (now Manage Plans):
- ✅ Screen title: "Manage Workout Plans"
- ✅ Tooltip: "Create Plan"
- ✅ Dialog title: "Create Workout Plan"
- ✅ All labels: "Plan Name", "Plan Color"
- ✅ Success message: "Workout plan created successfully!"
- ✅ Move dialog: "Move to Plan"
- ✅ Delete dialog: "Delete Plan"
- ✅ Empty state: "No Workout Plans Yet"
- ✅ Unorganized section: "Unorganized" (instead of "My Workouts")
- ✅ Widget renamed: `_PlanSection` (instead of `_FolderSection`)

## Why This Matters

### Before (Confusing):
"Folders" is a tech/file system term that doesn't clearly communicate purpose
- "Create a folder" → Generic
- "My workout folders" → What's a folder?

### After (Clear):
"Plans" clearly indicates organized workout programs
- "Create a workout plan" → Clear purpose!
- "My workout plans" → Organized routines!

## User Experience Improvement

Users now understand they're creating **workout plans** like:
- 🔵 "Upper Body Plan"
- 🟢 "Cardio Mix Plan"
- 🟠 "Leg Day Plan"

Instead of confusing "folders" that sound like file organization.

## Technical Notes

- **No database changes** - still uses `workout_folders` table internally
- **No API changes** - still uses same `createFolder()` methods
- **Only UI text** changed for better UX

## Consistency

All screens now use:
- ✅ "Workout Plans" (not "folders")
- ✅ "Plan" (not "folder")
- ✅ "Unorganized" (for workouts not in a plan)
- ✅ "Manage" (clearer than "Folders" button)

This creates a more professional, fitness-focused app experience! 💪
