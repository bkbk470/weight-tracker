# Supabase Service API Reference

Quick reference for using the Supabase service in the Weight Tracker app.

## 🔐 Authentication

### Sign Up
```dart
final response = await SupabaseService.instance.signUp(
  email: 'user@example.com',
  password: 'password123',
  fullName: 'John Doe', // optional
);

if (response.user != null) {
  // Success! User created
}
```

### Sign In
```dart
final response = await SupabaseService.instance.signIn(
  email: 'user@example.com',
  password: 'password123',
);

if (response.user != null) {
  // Success! User logged in
}
```

### Sign Out
```dart
await SupabaseService.instance.signOut();
```

### Get Current User
```dart
final user = SupabaseService.instance.currentUser;
final userId = SupabaseService.instance.currentUserId;
```

### Reset Password
```dart
await SupabaseService.instance.resetPassword('user@example.com');
// User will receive reset email
```

### Update Password
```dart
await SupabaseService.instance.updatePassword('newPassword123');
```

---

## 👤 Profile

### Get Profile
```dart
final profile = await SupabaseService.instance.getProfile();

print(profile['full_name']);
print(profile['email']);
print(profile['height_cm']);
```

### Update Profile
```dart
await SupabaseService.instance.updateProfile({
  'full_name': 'Jane Doe',
  'height_cm': 170.0,
  'weight_goal_lbs': 150.0,
  'experience_level': 'intermediate',
});
```

---

## 💪 Exercises

### Get All Exercises (Default + Custom)
```dart
final exercises = await SupabaseService.instance.getExercises();

for (var exercise in exercises) {
  print('${exercise['name']} - ${exercise['category']}');
}
```

### Get Exercises by Category
```dart
final chestExercises = await SupabaseService.instance
    .getExercisesByCategory('Chest');
```

### Create Custom Exercise
```dart
final exercise = await SupabaseService.instance.createExercise(
  name: 'Cable Chest Press',
  category: 'Chest',
  difficulty: 'Intermediate',
  equipment: 'Cable',
  notes: 'Keep elbows slightly bent',
);
```

### Update Exercise
```dart
await SupabaseService.instance.updateExercise(
  exerciseId,
  {
    'name': 'Updated Name',
    'notes': 'New form tips',
  },
);
```

### Delete Exercise
```dart
await SupabaseService.instance.deleteExercise(exerciseId);
```

---

## 🏋️ Workouts (Templates)

### Get All Workouts
```dart
final workouts = await SupabaseService.instance.getWorkouts();

for (var workout in workouts) {
  print(workout['name']);
  print('Exercises: ${workout['workout_exercises'].length}');
}
```

### Get Single Workout
```dart
final workout = await SupabaseService.instance.getWorkout(workoutId);

print(workout['name']);
print(workout['description']);
```

### Create Workout
```dart
final workout = await SupabaseService.instance.createWorkout(
  name: 'Push Day',
  description: 'Chest, shoulders, and triceps',
  difficulty: 'Intermediate',
  estimatedDurationMinutes: 60,
);
```

### Add Exercise to Workout
```dart
await SupabaseService.instance.addExerciseToWorkout(
  workoutId: workoutId,
  exerciseId: exerciseId,
  orderIndex: 0,
  targetSets: 4,
  targetReps: 8,
  restTimeSeconds: 120,
);
```

### Delete Workout
```dart
await SupabaseService.instance.deleteWorkout(workoutId);
```

---

## 📝 Workout Logs (Completed Workouts)

### Get Workout Logs
```dart
final logs = await SupabaseService.instance.getWorkoutLogs(
  startDate: DateTime(2025, 1, 1),
  endDate: DateTime.now(),
  limit: 50,
);

for (var log in logs) {
  print('${log['workout_name']} - ${log['start_time']}');
  print('Duration: ${log['duration_seconds']}s');
}
```

### Create Workout Log
```dart
final log = await SupabaseService.instance.createWorkoutLog(
  workoutName: 'Push Day',
  startTime: DateTime.now().subtract(Duration(hours: 1)),
  endTime: DateTime.now(),
  durationSeconds: 3600,
  notes: 'Great workout!',
);

final logId = log['id'];
```

### Add Exercise Set to Log
```dart
await SupabaseService.instance.addExerciseSet(
  workoutLogId: logId,
  exerciseId: exerciseId,
  exerciseName: 'Bench Press',
  setNumber: 1,
  weightLbs: 185.0,
  reps: 8,
  completed: true,
  restTimeSeconds: 120,
);
```

### Update Workout Log
```dart
await SupabaseService.instance.updateWorkoutLog(
  logId,
  {
    'end_time': DateTime.now().toIso8601String(),
    'duration_seconds': 4200,
    'notes': 'Updated notes',
  },
);
```

---

## 📏 Measurements

### Get Measurements by Type
```dart
final weights = await SupabaseService.instance
    .getMeasurements('weight');

for (var measurement in weights) {
  print('${measurement['value']} ${measurement['unit']}');
  print('Date: ${measurement['measurement_date']}');
}
```

### Get All Measurements
```dart
final allMeasurements = await SupabaseService.instance
    .getAllMeasurements();
```

### Get Latest Measurement
```dart
final latestWeight = await SupabaseService.instance
    .getLatestMeasurement('weight');

if (latestWeight != null) {
  print('Current weight: ${latestWeight['value']} lbs');
}
```

### Add Measurement
```dart
final measurement = await SupabaseService.instance.addMeasurement(
  measurementType: 'weight',
  value: 185.5,
  unit: 'lbs',
  measurementDate: DateTime.now(),
  notes: 'Morning weight',
);
```

### Update Measurement
```dart
await SupabaseService.instance.updateMeasurement(
  measurementId,
  {
    'value': 184.0,
    'notes': 'Updated weight',
  },
);
```

### Delete Measurement
```dart
await SupabaseService.instance.deleteMeasurement(measurementId);
```

---

## ⚙️ User Settings

### Get Settings
```dart
final settings = await SupabaseService.instance.getUserSettings();

print('Theme: ${settings?['theme_mode']}');
print('Weight unit: ${settings?['weight_unit']}');
```

### Update Settings
```dart
await SupabaseService.instance.updateUserSettings({
  'theme_mode': 'dark',
  'weight_unit': 'kg',
  'notifications_enabled': true,
});
```

---

## 📊 Statistics

### Get Total Workouts Count
```dart
final count = await SupabaseService.instance.getTotalWorkoutsCount();
print('Total workouts logged: $count');
```

### Get Workout History
```dart
final history = await SupabaseService.instance.getWorkoutHistory(
  startDate: DateTime.now().subtract(Duration(days: 30)),
  endDate: DateTime.now(),
);

print('Workouts this month: ${history.length}');
```

---

## 🔄 Complete Example: Log a Workout

```dart
// 1. Start workout
final startTime = DateTime.now();

// 2. Complete workout
final endTime = DateTime.now();
final duration = endTime.difference(startTime).inSeconds;

// 3. Create workout log
final log = await SupabaseService.instance.createWorkoutLog(
  workoutName: 'Push Day',
  startTime: startTime,
  endTime: endTime,
  durationSeconds: duration,
  notes: 'Felt strong today!',
);

// 4. Log exercise sets
await SupabaseService.instance.addExerciseSet(
  workoutLogId: log['id'],
  exerciseId: 'bench-press-id',
  exerciseName: 'Bench Press',
  setNumber: 1,
  weightLbs: 185.0,
  reps: 8,
  completed: true,
);

await SupabaseService.instance.addExerciseSet(
  workoutLogId: log['id'],
  exerciseId: 'bench-press-id',
  exerciseName: 'Bench Press',
  setNumber: 2,
  weightLbs: 185.0,
  reps: 7,
  completed: true,
);

print('Workout logged successfully!');
```

---

## 🛡️ Error Handling

Always wrap Supabase calls in try-catch:

```dart
try {
  final profile = await SupabaseService.instance.getProfile();
  // Use profile data
} catch (e) {
  print('Error getting profile: $e');
  // Show error to user
}
```

Common errors:
- `Not authenticated` - User not logged in
- `Row violates RLS` - Permission denied
- `JWT expired` - Session expired, need to re-login

---

## 🎯 Best Practices

### 1. Check Authentication
```dart
if (SupabaseService.instance.currentUser == null) {
  // Redirect to login
  return;
}
```

### 2. Use Local Storage First (Offline-First)
```dart
// Save locally first (instant)
await LocalStorageService.instance.saveMeasurement(data);

// Then sync to Supabase (background)
try {
  await SupabaseService.instance.addMeasurement(...);
} catch (e) {
  // Will sync later
}
```

### 3. Listen to Auth Changes
```dart
SupabaseService.instance.authStateChanges.listen((state) {
  if (state.event == AuthChangeEvent.signedIn) {
    // Navigate to dashboard
  } else if (state.event == AuthChangeEvent.signedOut) {
    // Navigate to login
  }
});
```

### 4. Handle Network Errors
```dart
try {
  await SupabaseService.instance.createWorkout(...);
} on SocketException {
  // No internet connection
  showSnackbar('No internet. Data saved locally.');
} catch (e) {
  // Other error
  showSnackbar('Error: $e');
}
```

---

## 🔍 Debugging

### Enable Logging
In `main.dart`:
```dart
await Supabase.initialize(
  url: 'YOUR_URL',
  anonKey: 'YOUR_KEY',
  debug: true, // Enable debug logs
);
```

### Check Supabase Logs
1. Go to Supabase Dashboard
2. Click "Logs"
3. View API requests and errors

---

## ✅ Quick Checklist

Before going to production:
- [ ] Remove `debug: true` from Supabase.initialize
- [ ] Use environment variables for URL/key
- [ ] Enable email confirmation
- [ ] Set up proper error logging
- [ ] Test offline sync
- [ ] Verify RLS policies
- [ ] Test with multiple users
- [ ] Back up database

---

**📚 Full Documentation: [SUPABASE_SETUP_GUIDE.md](SUPABASE_SETUP_GUIDE.md)**
