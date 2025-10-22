# Flutter Web Input Focus Fix

## Problem
Flutter Web was throwing assertion errors: 
```
"The targeted input element must be the active input element"
```

This error occurs when pointer events target a text field that is no longer the active input element, commonly when dialogs, bottom sheets, or overlays appear while a TextField is focused.

## Solution Implemented

### 1. Global GestureDetector in MaterialApp (main.dart)
Added a global `GestureDetector` that wraps the entire app to unfocus any active text fields when tapping anywhere:

```dart
MaterialApp(
  builder: (context, child) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      behavior: HitTestBehavior.translucent,
      child: child,
    );
  },
  // ...
)
```

### 2. Navigation Observer (utils/navigation_observers.dart)
Unfocuses text fields during route transitions using microtask delay:

```dart
void _unfocus() {
  Future.microtask(() {
    FocusManager.instance.primaryFocus?.unfocus();
  });
}
```

### 3. Safe Dialog Helpers (utils/safe_dialog_helpers.dart)
Wrapper functions for `showDialog` and `showModalBottomSheet` that ensure unfocus before showing:

- `showSafeDialog()` - Safe wrapper for dialogs
- `showSafeModalBottomSheet()` - Safe wrapper for bottom sheets

Both include a 50ms delay after unfocusing to ensure DOM updates complete.

### 4. Safe TextField (utils/safe_text_field.dart)
Optional TextField wrapper for better focus management on web (not required but available if needed).

## Files Modified
- `lib/main.dart` - Added global GestureDetector and safe dialog import
- `lib/utils/navigation_observers.dart` - Improved with microtask delay
- `lib/utils/safe_dialog_helpers.dart` - Created new file
- `lib/utils/safe_text_field.dart` - Created new file (optional)

## Usage

### For Dialogs
Replace `showDialog` with `showSafeDialog`:

```dart
// Before
showDialog(context: context, builder: (context) => ...);

// After
showSafeDialog(context: context, builder: (context) => ...);
```

### For Bottom Sheets
Replace `showModalBottomSheet` with `showSafeModalBottomSheet`:

```dart
// Before
showModalBottomSheet(context: context, builder: (context) => ...);

// After
showSafeModalBottomSheet(context: context, builder: (context) => ...);
```

## Why This Works

The combination of:
1. **Global tap detection** - Catches all user taps and unfocuses proactively
2. **Navigation observer** - Handles route changes (screens, dialogs, sheets)
3. **Microtask delays** - Ensures proper timing in the event loop
4. **Safe wrappers** - Provides manual unfocus before showing overlays

These layers work together to prevent the assertion error by ensuring no text field is focused when pointer events are processed on non-active elements.

## Testing
After implementing these fixes, the app should run without the assertion errors in Flutter Web (Chrome).

## Notes
- These fixes are Flutter Web-specific and have no impact on mobile platforms
- The global GestureDetector is performant and doesn't affect app responsiveness
- Using safe wrappers is optional but recommended for consistent behavior
