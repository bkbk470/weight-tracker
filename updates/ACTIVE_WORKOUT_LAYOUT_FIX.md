# Active Workout Screen Layout Fix

## Issue
On iPhone, the set line with weight, reps, rest timer, and buttons doesn't fit properly on the screen and gets cut off.

## Root Cause
The row layout has too many fixed-width elements:
- Set number: 50px
- Weight input: 70px  
- Reps input: 60px
- Rest timer: 60px
- Done button: 60px
- Delete button: ~40px
- Spacing between: ~60px

Total minimum width: ~400px, which exceeds some iPhone widths (especially with padding).

## Solution
Make the layout more responsive:
1. Use flexible widths instead of fixed
2. Stack previous data below inputs instead of beside
3. Make buttons more compact
4. Use ScrollView horizontally if needed
5. Reduce padding/spacing

## Files to Update
- `lib/screens/active_workout_screen.dart` - Set row layout

The set row needs to be more compact and flexible for smaller screens.
