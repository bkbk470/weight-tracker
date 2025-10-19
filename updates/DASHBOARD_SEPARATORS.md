# Dashboard Workout Separators Added

## Update

Added visual separators (divider lines) between each workout in the "My Workouts" folders to create a boxed, organized look.

## Visual Change

### Before:
```
My Workouts (4 workouts)
  💪 Pish Day
     1 exercises • 6 min • ✓ 2 days ago
  💪 Pull Day
     1 exercises • 6 min • ⚠ Never completed
```

### After:
```
My Workouts (4 workouts)
  💪 Pish Day
     1 exercises • 6 min • ✓ 2 days ago
  ─────────────────────────────────────
  💪 Pull Day
     1 exercises • 6 min • ⚠ Never completed
  ─────────────────────────────────────
```

## Technical Details

- Added `Divider` widgets between each workout item
- Dividers have:
  - Thickness: 1px
  - Left indent: 56px (aligned with workout text)
  - Right indent: 16px
  - Semi-transparent color matching theme

## Effect

Each workout now appears in its own "box" separated by thin lines, making it easier to:
- Distinguish between different workouts
- Scan the list quickly
- See where one workout ends and another begins

## To See Changes:

```bash
# Hot restart
# Press 'R' or Shift+R
```

The workouts will now have clear visual separators creating a boxed layout!
