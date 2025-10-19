# Dashboard Layout Update - Single Line Display

## Change Made

Updated the workout tile subtitle to display all information on a **single line**.

## Before:
```
💪 Pish Day
   1 exercises • 6 min
   ✓ 2 days ago at 3:45 PM
```

## After:
```
💪 Pish Day
   1 exercises • 6 min • ✓ 2 days ago at 3:45 PM
```

## Technical Details

Changed from a `Column` with separate `Text` and `Row` widgets to a single `Text.rich` widget using `TextSpan` and `WidgetSpan` for the icon.

This ensures:
- All information displays on one line
- Proper text overflow with ellipsis if needed
- Icon is vertically aligned with text
- Maintains color coding (green for completed, red for never)

## To See Changes:

```bash
# Hot restart (important!)
# Press 'R' in terminal or Shift+R in IDE
```

The workout tiles now show everything compactly in a single line!
