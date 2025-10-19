# Workout Plans Feature - Enhanced Dashboard

## Overview
Enhanced the dashboard to make workout plan folders (the existing folder system) more prominent and user-friendly.

## What Changed

### 1. Renamed Section
- **Before**: "My Workouts"
- **After**: "Workout Plans"

### 2. New Header Buttons
- **"New Plan"** button - Quickly create a new workout plan folder
- **"Manage"** button - Access the full folder management screen

### 3. Create Workout Plan Dialog
Users can now create workout plan folders directly from the dashboard with:
- **Plan Name** - Name for the workout plan (e.g., "Strength Training")
- **Description** - Optional description
- **Color** - Choose from blue, green, orange, purple, or red

## How It Works

### Creating a Workout Plan:
1. Click **"New Plan"** button on dashboard
2. Enter plan name (required)
3. Add description (optional)
4. Choose a color
5. Click **"Create"**

### The workout plan folder appears immediately on the dashboard!

### Adding Workouts to Plans:
1. Create your workout using "Start Workout" or workout builder
2. Click "Manage" or go to workout folders screen
3. Move workouts into your workout plan folders

### Dashboard Display:
- All workout plan folders are shown as expandable cards
- Each plan shows:
  - Folder icon with chosen color
  - Plan name and description
  - Number of workouts in the plan
  - List of workouts (when expanded) with completion tracking

## Benefits

✅ **Quick Access** - Create plans directly from dashboard
✅ **Visual Organization** - Color-coded plans for easy identification  
✅ **Flexible Structure** - Group related workouts together (e.g., "Arm Day", "Leg Day", "Full Body")
✅ **Track Progress** - See last completed date for each workout in the plan
✅ **Better UX** - More intuitive than generic "folders"

## Example Use Cases

### Scenario 1: Weekly Split
- **Monday - Push Day** (Chest, Shoulders, Triceps workouts)
- **Wednesday - Pull Day** (Back, Biceps workouts)
- **Friday - Leg Day** (Squats, Lunges, Leg Press)

### Scenario 2: Goal-Based
- **Strength Building** (Heavy compound movements)
- **Hypertrophy** (Muscle building workouts)
- **Conditioning** (HIIT and cardio)

### Scenario 3: Time-Based
- **Quick Workouts** (30 min or less)
- **Full Sessions** (60+ minutes)
- **Recovery** (Light workouts and stretching)

## UI Layout

```
Workout Plans                [New Plan] [Manage]

┌─────────────────────────────────────┐
│ 📁 Strength Training                │
│    5 workouts                        │
│    ▼                                 │
├─────────────────────────────────────┤
│   💪 Push Day                        │
│      3 exercises • 45 min             │
│      ✓ 2 days ago at 6:00 PM         │
│   ─────────────────────────────────  │
│   💪 Pull Day                        │
│      4 exercises • 50 min             │
│      ✓ Yesterday at 7:30 AM          │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ 📁 Cardio Mix                       │
│    3 workouts                        │
│    ▶                                 │
└─────────────────────────────────────┘
```

## Database Structure

Uses the existing `workout_folders` table:
- `name` - Plan name
- `description` - Plan description
- `color` - Visual color coding
- `icon` - Folder icon
- Workouts link to folders via `folder_id`

**No database changes needed!** This feature uses the existing folder infrastructure.

## Next Steps

After creating workout plans:
1. Create workouts (using workout builder or templates)
2. Organize them into your plans (via Manage screen)
3. Track completion from the dashboard
4. Expand/collapse plans to see workouts

## Tips

- Use descriptive names: "Upper Body" vs "Workout 1"
- Color code by type: Blue for strength, Green for cardio, etc.
- Keep plans focused: 3-5 related workouts per plan
- Review and update plans regularly

---

This makes the app feel more organized and professional, turning generic "folders" into purposeful "workout plans"! 🎯
