# iOS Push Notification Setup for Rest Timer

This app now includes local push notifications that trigger when the rest timer completes during a workout.

## Features

- Local notifications (no server required)
- Automatic notification when rest timer reaches zero
- Customizable notification title and message
- iOS and Android support

## Implementation Details

### Files Modified/Created

1. **pubspec.yaml** - Added `flutter_local_notifications: ^17.0.0` package
2. **lib/services/notification_service.dart** - New notification service singleton
3. **lib/main.dart** - Initialize notification service on app startup
4. **lib/screens/active_workout_screen.dart** - Trigger notification when rest timer completes
5. **ios/Runner/Info.plist** - Added background audio mode for notifications

### How It Works

1. When the app starts, the NotificationService initializes and requests permissions
2. During a workout, when a set is completed and rest timer starts
3. When the rest timer countdown reaches 0, a notification is triggered
4. The notification shows: "Rest Time Complete! Your rest period is over. Ready for the next set?"

### iOS Permissions

The app will automatically request notification permissions on first launch for iOS devices. The user must grant permission for notifications to appear.

### Testing

To test the notification:
1. Start a workout
2. Complete a set (this starts the rest timer)
3. Wait for the rest timer to complete
4. A notification should appear even if the app is in the background

### Customization

To customize the notification message, edit the `showRestTimerCompleteNotification()` method in `lib/services/notification_service.dart`:

```dart
await _notifications.show(
  0, // Notification ID
  'Custom Title Here',
  'Custom message here',
  notificationDetails,
);
```

### Additional Features

The NotificationService also includes:
- `showNotification()` - Show custom notifications with any title/body
- `cancelNotification(id)` - Cancel a specific notification
- `cancelAllNotifications()` - Cancel all pending notifications

## iOS Build Requirements

When building for iOS:
1. Ensure Xcode is up to date
2. The Info.plist has been configured with UIBackgroundModes
3. No additional setup needed - local notifications don't require APNs certificates

## Android

Local notifications work on Android without any additional configuration. The app uses the default Android notification channel.
