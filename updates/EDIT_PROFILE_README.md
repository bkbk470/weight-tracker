# Edit Profile Feature

## Overview
The Edit Profile screen now properly loads user data from the database and saves all changes to both local storage and Supabase.

## Features

### Profile Data Fields
The following information can be edited:

#### Personal Information
- **Full Name** - User's display name
- **Date of Birth** - With date picker for easy selection
- **Gender** - Options: Male, Female, Other, Prefer not to say

#### Physical Stats
- **Height** - Automatically uses user's preferred unit (cm or inches)
- **Weight Goal** - Target weight in user's preferred unit (lbs or kg)
- **Experience Level** - Beginner, Intermediate, or Advanced

#### Account
- **Change Password** - Link to password change screen

## How It Works

### Data Loading
1. **On Screen Open**:
   - Loads unit preferences (cm/in, kg/lbs) from settings
   - Tries to fetch profile from Supabase
   - Falls back to local storage if offline
   - Converts stored values to user's preferred units
   - Populates form fields

### Data Storage
All measurements are stored in standard units in the database:
- **Height**: Always stored in centimeters (cm)
- **Weight Goal**: Always stored in pounds (lbs)

When displaying or editing:
- Values are converted to user's preferred units
- When saving, values are converted back to standard units

### Saving Profile
1. **Validation**:
   - Checks that name is not empty
   - Validates numeric fields (height, weight)

2. **Data Conversion**:
   - Converts height to cm (if user entered in inches)
   - Converts weight to lbs (if user entered in kg)

3. **Dual Save**:
   - Saves to **Supabase** for cloud sync
   - Saves to **Local Storage** for offline access
   - If Supabase fails, still saves locally

4. **User Feedback**:
   - Success message if saved to cloud
   - Warning message if saved locally only (will sync when online)
   - Error message if save completely fails

## Database Schema

### profiles Table
```sql
full_name TEXT
date_of_birth DATE
gender TEXT CHECK (gender IN ('male', 'female', 'other', 'prefer_not_to_say'))
height_cm DECIMAL(5,2)
weight_goal_lbs DECIMAL(5,2)
experience_level TEXT CHECK (experience_level IN ('beginner', 'intermediate', 'advanced'))
```

## User Experience

### Editing Profile
1. Open Profile screen
2. Tap "Edit Profile"
3. Modify any fields
4. Tap "Save" (in top right or bottom button)
5. Changes are saved immediately
6. Returns to Profile screen

### Date of Birth Selection
- Tap the Date of Birth field
- Calendar picker appears
- Select date
- Date is formatted as MM/DD/YYYY

### Units Handling
- Height and weight fields automatically show correct units
- If you change unit preferences in settings, values convert automatically
- Conversions:
  - **Height**: 1 inch = 2.54 cm
  - **Weight**: 1 lb = 0.45359237 kg

## Offline Support

### Works Offline
- ✅ Can view profile data
- ✅ Can edit profile data
- ✅ Changes save locally
- ✅ Syncs to cloud when connection restored

### Loading Priority
1. Try Supabase (cloud)
2. Fall back to local storage
3. Show error if both fail

### Saving Priority
1. Save to local storage (guaranteed)
2. Save to Supabase (if online)
3. Sync happens in background

## Validation

### Required Fields
- **Full Name**: Cannot be empty

### Optional Fields
- All other fields are optional
- Empty fields are not saved to database

### Format Validation
- **Height**: Must be a valid number if provided
- **Weight Goal**: Must be a valid number if provided
- **Date of Birth**: Must be a valid date in the past

## Error Handling

### Common Errors
1. **Network Error**: Saves locally, will sync later
2. **Invalid Data**: Shows validation error
3. **Database Error**: Shows error message, data not saved

### User Messages
- ✅ "Profile updated successfully!" - Saved to cloud
- ⚠️ "Profile saved locally. Will sync when online." - Offline save
- ❌ "Error saving profile: [error]" - Save failed

## Integration with Profile Screen

After saving, the Profile screen automatically shows:
- Updated name
- Current stats (if entered)
- Experience level badge

## Code Structure

### Key Methods
- `_loadProfileData()` - Loads profile from database
- `_loadUnits()` - Loads user's unit preferences
- `_saveProfile()` - Validates and saves profile data
- `_selectDateOfBirth()` - Shows date picker
- Unit conversion helpers

### State Management
- Form validation with GlobalKey
- Loading state for initial data fetch
- Saving state for submit feedback
- Text controllers for all input fields

## Testing Checklist

- [ ] Load profile - verify data appears correctly
- [ ] Edit name - verify it saves
- [ ] Select date of birth - verify picker works
- [ ] Change gender - verify dropdown works
- [ ] Enter height in cm - verify it saves
- [ ] Enter height in inches - verify it converts and saves
- [ ] Enter weight goal in lbs - verify it saves
- [ ] Enter weight goal in kg - verify it converts and saves
- [ ] Change experience level - verify it saves
- [ ] Save while online - verify cloud sync
- [ ] Save while offline - verify local save
- [ ] Go online after offline save - verify sync
- [ ] Leave fields empty - verify optional fields work
- [ ] Enter invalid height - verify validation
- [ ] Enter invalid weight - verify validation

## Future Enhancements

Potential improvements:
- Profile photo upload (camera/gallery)
- More physical stats (body fat %, BMI)
- Fitness goals beyond weight
- Activity level tracking
- Preferred workout days/times
- Notification preferences
