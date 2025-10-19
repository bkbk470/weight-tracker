# Favorite Workout Plans Feature

## Overview
Added the ability to mark workout plans as "favorites" to prioritize them on the dashboard.

## Database Changes

### New Column: `is_favorite`
- **Table**: `workout_plans`
- **Type**: `BOOLEAN`
- **Default**: `false`
- **Purpose**: Mark plans to show prominently on dashboard

### Migration File
Run: `add_is_favorite_column.sql` in Supabase SQL Editor

## Features Added

### 1. Star Icon on Plans
Users can click the star icon to toggle favorite status:
- ⭐ **Filled star** = Favorite plan
- ☆ **Empty star** = Not favorite

### 2. Automatic Sorting
Favorite plans appear **first** in lists:
- Dashboard shows favorites at the top
- Management screen shows favorites first
- Non-favorites appear below in regular order

### 3. Visual Indicator
- Star icon is **amber/gold** when favorited
- Tooltip shows "Add to favorites" or "Remove from favorites"

## User Experience

### Dashboard:
```
Workout Plans                [New Plan] [Manage]

⭐ 📁 Upper Body Split        (favorite - shows first)
   5 workouts

⭐ 📁 Leg Day                 (favorite - shows first)
   3 workouts

☆ 📁 Cardio Mix               (not favorite)
   4 workouts
```

### How to Use:
1. **Mark as Favorite**: Click the ⭐ star icon next to any plan
2. **Remove Favorite**: Click the ⭐ filled star again
3. **Favorites First**: Favorited plans automatically move to the top

## Benefits

✅ **Quick Access** - Pin frequently used plans to the top
✅ **Better Organization** - Separate active plans from archived ones
✅ **Personalized** - Each user can choose their own favorites
✅ **Visual Clarity** - Gold star makes favorites obvious
✅ **No Limit** - Mark as many plans as favorites as you want

## Technical Details

### SupabaseService Methods:
```dart
// Get all plans (favorites first)
getWorkoutFolders() // Now orders by is_favorite DESC

// Get only favorite plans
getFavoritePlans() 

// Toggle favorite status
togglePlanFavorite(String planId, bool isFavorite)
```

### Database Query:
```sql
SELECT * FROM workout_plans
WHERE user_id = current_user_id
ORDER BY is_favorite DESC, order_index ASC;
```

This ensures:
1. Favorites appear first (`is_favorite DESC`)
2. Then sorted by custom order (`order_index ASC`)

## Implementation Steps

### Step 1: Add Database Column
```bash
# Run in Supabase SQL Editor:
add_is_favorite_column.sql
```

### Step 2: Restart Flutter App
```bash
# Stop and restart (not just hot reload)
flutter run
```

### Step 3: Test
1. Open dashboard
2. Click star on any plan
3. See it move to the top
4. Click star again to remove favorite

## Use Cases

### Scenario 1: Active Training Split
Mark your current training plan as favorite:
- ⭐ **PPL - Push Pull Legs** (currently following)
- ☆ Full Body Routine (not using now)
- ☆ Home Workout Plan (backup)

### Scenario 2: Multiple Goals
Favorite plans for different goals:
- ⭐ **Strength Building** (primary goal)
- ⭐ **Cardio Conditioning** (secondary goal)
- ☆ Recovery Workouts (occasional use)

### Scenario 3: Seasonal Plans
Rotate favorites by season:
- Winter: ⭐ Gym Heavy Lifting
- Summer: ⭐ Outdoor Running Plan

## Visual Design

### Star Button:
- **Position**: Next to plan name, before expand arrow
- **Size**: 22px (dashboard), 20px (management screen)
- **Color**: 
  - Filled: Amber/Gold (#FFC107)
  - Empty: Default icon color
- **Animation**: Immediate toggle on tap

### Tooltips:
- Hover/long-press shows helpful text
- "Add to favorites" or "Remove from favorites"

## Future Enhancements (Ideas)

- 🔜 Show only favorites toggle on dashboard
- 🔜 Limit dashboard to show only favorite plans
- 🔜 Quick actions on favorite plans
- 🔜 Statistics: "Most used favorite plan"

---

This feature gives users control over which plans they see first, making the app more personalized and efficient! ⭐
