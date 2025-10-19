# Template Duplication Error Fix

## Issue
When duplicating a workout template, the app shows this error:
```
Failed to duplicate workout: PostgrestException(message: Cannot coerce the result to a single JSON object, code: PGRST116, details: The result contains 0 rows, hint: null)
```

## Root Cause
The error occurs because some query methods were using `.single()` which throws an error when:
- The query returns 0 rows
- The query returns more than 1 row

This is too strict for our use case where we want to handle missing data gracefully.

## Solution Applied

Changed three methods in `supabase_service.dart` to use `.maybeSingle()` instead of `.single()`:

### 1. `getWorkout()` Method
**Before:**
```dart
final response = await client
    .from('workouts')
    .select(...)
    .eq('id', workoutId)
    .single();  // ❌ Throws error if not found
```

**After:**
```dart
try {
  final response = await client
      .from('workouts')
      .select(...)
      .eq('id', workoutId)
      .maybeSingle();  // ✅ Returns null if not found
  
  return response;
} catch (e) {
  print('Error fetching workout: $e');
  return null;
}
```

### 2. `getWorkoutTemplate()` Method
**Before:**
```dart
final response = await client
    .from('workout_templates')
    .select(...)
    .eq('id', templateId)
    .single();  // ❌ Throws error if not found
```

**After:**
```dart
try {
  final response = await client
      .from('workout_templates')
      .select(...)
      .eq('id', templateId)
      .maybeSingle();  // ✅ Returns null if not found
  
  return response;
} catch (e) {
  print('Error fetching workout template: $e');
  return null;
}
```

### 3. `duplicateTemplateToWorkout()` Method
**Before:**
```dart
// ... create workout and add exercises ...

return newWorkout;  // ❌ Returns incomplete data
```

**After:**
```dart
// ... create workout and add exercises ...

// Fetch the complete workout with exercises to return
final completeWorkout = await getWorkout(newWorkout['id'] as String);
return completeWorkout ?? newWorkout;  // ✅ Returns complete data
```

## Benefits

1. **Graceful Error Handling**: No more crashes when data isn't found
2. **Better User Experience**: Shows meaningful error messages instead of technical errors
3. **Safer Queries**: Uses `maybeSingle()` which is more forgiving
4. **Complete Data**: Returns full workout data after duplication

## Testing

After applying this fix:

1. ✅ Navigate to Workouts → Templates
2. ✅ Tap duplicate on any template
3. ✅ Workout should be added to "My Workouts"
4. ✅ Success message should appear
5. ✅ No errors in console

## Difference Between single() and maybeSingle()

| Method | Returns 0 rows | Returns 1 row | Returns 2+ rows |
|--------|---------------|---------------|-----------------|
| `.single()` | ❌ **Error** | ✅ Returns row | ❌ **Error** |
| `.maybeSingle()` | ✅ Returns null | ✅ Returns row | ❌ **Error** |

For our use case, `maybeSingle()` is better because:
- We can check if the result is null
- We can provide user-friendly error messages
- We don't crash the app unnecessarily

## Files Modified

- `lib/services/supabase_service.dart` - Updated 3 methods

## Additional Notes

If you still see errors after this fix:

1. **Check SQL scripts were run**: Ensure both SQL scripts executed successfully
2. **Verify template IDs**: Make sure templates exist in database
3. **Check RLS policies**: Ensure user has read access to templates
4. **Review console logs**: Check for any other error messages

## Related Issues

This fix also improves:
- Workout detail duplication
- Template viewing
- General error handling throughout the app
