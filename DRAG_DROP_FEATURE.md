# Drag and Drop Workout Plans Feature

## Overview
This feature allows users to customize the order of their workout plans by dragging and dropping them. The app remembers the user's preferred sequence and displays workouts in that order.

## What's New

### 1. Reorderable Workouts
- Users can now reorder their workout plans by long-pressing and dragging
- A dedicated "Reorder" button in the app bar toggles reordering mode
- Visual drag handle appears when in reordering mode
- Changes are automatically saved to the database

### 2. Visual Feedback
- Drag handle icon (☰) appears during reordering mode
- Information banner explains how to reorder
- Smooth animations during drag and drop
- Instant visual feedback when items are moved

### 3. Persistent Order
- Workout order is saved to the database using an `order_index` field
- Order persists across app restarts and device changes
- Syncs automatically with Supabase backend

## Files Modified

### 1. `lib/services/supabase_service.dart`
**New Methods Added:**
```dart
// Update a single workout's order
Future<void> updateWorkoutOrder(String workoutId, int newOrderIndex)

// Update all workouts with new order after drag-drop
Future<void> reorderWorkouts(List<Map<String, dynamic>> orderedWorkouts)
```

**Modified Methods:**
- `getWorkouts()` - Now orders results by `order_index` first, then by `created_at`

### 2. `lib/screens/workout_library_screen.dart`
**New Features:**
- `isReordering` state flag to toggle between normal and reordering modes
- `_reorderWorkouts()` method to handle drag-drop logic
- `_buildReorderableWorkoutList()` - Renders workouts in reorderable list
- `_buildNormalWorkoutList()` - Renders workouts in normal mode
- Reorder button in app bar (only visible when workouts exist)
- Information banner during reordering mode

**Modified Features:**
- `_WorkoutCard` now accepts `showDragHandle` parameter
- Conditional rendering based on `isReordering` state
- Drag handle icon replaces chevron during reordering

### 3. `add_workout_order_index.sql`
**Database Migration:**
- Adds `order_index` column to `workouts` table
- Initializes existing workouts with order based on `created_at`
- Creates index for better query performance
- Includes verification queries

## How to Use

### For Users:
1. Open the Workout Library screen
2. Tap the drag handle icon (☰) in the app bar
3. An information banner will appear explaining how to reorder
4. Long-press on any workout card and drag it to a new position
5. Release to drop the workout in the new position
6. The order is automatically saved
7. Tap the checkmark (✓) to exit reordering mode

### For Developers:

#### Initial Setup:
1. Run the SQL migration in your Supabase SQL Editor:
   ```bash
   # Execute the contents of add_workout_order_index.sql
   ```

2. Ensure your Flutter project dependencies are up to date:
   ```bash
   flutter pub get
   ```

3. The feature will automatically work for all users

#### Customization:
You can customize the reordering behavior by modifying:
- `_reorderWorkouts()` in `workout_library_screen.dart` for custom drag logic
- `updateWorkoutOrder()` in `supabase_service.dart` for custom save logic
- Adjust visual styling in `_WorkoutCard` widget

## Technical Details

### Database Schema
```sql
ALTER TABLE workouts 
ADD COLUMN order_index INTEGER DEFAULT 0;

CREATE INDEX idx_workouts_user_order 
ON workouts(user_id, order_index);
```

### Query Ordering
Workouts are now fetched with this order:
1. Primary: `order_index` (ascending)
2. Secondary: `created_at` (descending)

This ensures:
- User-defined order takes precedence
- New workouts (with order_index = 0) appear in chronological order

### Reordering Logic
1. User initiates drag by long-pressing a workout card
2. `ReorderableListView` handles the visual drag-drop interaction
3. `_reorderWorkouts()` updates the local list immediately for smooth UX
4. `reorderWorkouts()` saves all workout positions to database
5. If save fails, list is reloaded from database to maintain consistency

### Error Handling
- Network errors during save trigger a snackbar notification
- Failed saves automatically reload the correct order from database
- All database operations are wrapped in try-catch blocks

## Benefits

1. **Better User Experience**: Users can organize workouts in their preferred order
2. **Intuitive Interface**: Standard long-press-and-drag interaction pattern
3. **Data Persistence**: Order syncs across all user devices
4. **Performance**: Indexed queries ensure fast loading even with many workouts
5. **Flexible**: Easy to extend to other list-based features

## Future Enhancements

Potential improvements for this feature:
- [ ] Add workout grouping/categories with separate ordering
- [ ] Implement batch reordering operations
- [ ] Add "Move to Top/Bottom" quick actions
- [ ] Support reordering within workout folders
- [ ] Add undo/redo functionality for reordering
- [ ] Implement drag-and-drop across workout folders

## Troubleshooting

### Workouts not reordering
1. Check if SQL migration was run successfully
2. Verify `order_index` column exists in `workouts` table
3. Check Supabase RLS policies allow updates to `order_index`

### Order not persisting
1. Verify network connection when reordering
2. Check Supabase service logs for errors
3. Ensure user is authenticated

### Performance issues with many workouts
1. Verify index `idx_workouts_user_order` exists
2. Consider pagination for users with 100+ workouts
3. Monitor Supabase query performance

## Testing Checklist

- [ ] Drag workout from top to bottom
- [ ] Drag workout from bottom to top
- [ ] Drag workout to middle position
- [ ] Reorder multiple times in succession
- [ ] Test with 1, 5, 20, and 50+ workouts
- [ ] Test offline behavior (should show error and reload)
- [ ] Test across different devices (order should sync)
- [ ] Verify search doesn't interfere with reordering
- [ ] Test tab switching during reordering mode

## Support

For issues or questions:
1. Check the SQL migration ran successfully
2. Verify your Supabase schema matches expected structure
3. Check Flutter logs for error messages
4. Review Supabase logs for database errors
