import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  static NotificationService get instance => _instance;

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  NotificationService._internal();

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // iOS settings
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Android settings
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        iOS: iosSettings,
        android: androidSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions (especially important for iOS)
  Future<bool> requestPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final bool? result = await _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return result ?? false;
    }
    return true; // Android doesn't need runtime permission for local notifications
  }

  /// Schedule a notification for when rest timer completes (works in background!)
  Future<void> scheduleRestTimerNotification(int durationSeconds) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing rest timer notifications first
      await _notifications.cancel(0);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Notifications for rest timer completion',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentBanner: true,
        presentList: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification for exact time in the future - THIS WORKS EVEN WHEN PHONE IS LOCKED!
      final scheduledTime = tz.TZDateTime.now(tz.local).add(Duration(seconds: durationSeconds));

      await _notifications.zonedSchedule(
        0, // Notification ID
        'Rest Time Complete!',
        'Your rest period is over. Ready for the next set?',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Rest timer notification scheduled for ${durationSeconds}s from now (${scheduledTime})');
    } catch (e) {
      debugPrint('Error scheduling rest timer notification: $e');
    }
  }

  /// Cancel the scheduled rest timer notification
  Future<void> cancelRestTimerNotification() async {
    try {
      await _notifications.cancel(0);
      debugPrint('Rest timer notification cancelled');
    } catch (e) {
      debugPrint('Error cancelling rest timer notification: $e');
    }
  }

  /// Test notification - schedules a notification for 10 seconds from now
  Future<void> scheduleTestNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      // Cancel any existing test notifications
      await _notifications.cancel(999);

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'test_channel',
        'Test Notifications',
        channelDescription: 'Test notifications to verify notification settings',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
        presentBanner: true,
        presentList: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Schedule notification for 10 seconds from now
      final scheduledTime = tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));

      await _notifications.zonedSchedule(
        999, // Notification ID for test
        'Test Notification',
        'If you see this, notifications are working! Lock your phone to test lock screen.',
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Test notification scheduled for 10 seconds from now');
    } catch (e) {
      debugPrint('Error scheduling test notification: $e');
      rethrow; // Re-throw so UI can show error
    }
  }

  /// Show a notification when rest timer completes (immediate)
  Future<void> showRestTimerCompleteNotification() async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'rest_timer_channel',
        'Rest Timer',
        channelDescription: 'Notifications for rest timer completion',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        // Use time sensitive for better lock screen visibility
        interruptionLevel: InterruptionLevel.timeSensitive,
        // Ensure alert shows immediately
        presentBanner: true,
        presentList: true,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Use zonedSchedule with immediate time - this works better for lock screen on iOS
      await _notifications.zonedSchedule(
        0, // Notification ID
        'Rest Time Complete!',
        'Your rest period is over. Ready for the next set?',
        tz.TZDateTime.now(tz.local), // Schedule for right now using timezone
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );

      debugPrint('Rest timer notification scheduled');
    } catch (e) {
      debugPrint('Error showing rest timer notification: $e');

      // Fallback to regular show if zonedSchedule fails
      try {
        const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
          'rest_timer_channel',
          'Rest Timer',
          channelDescription: 'Notifications for rest timer completion',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        );

        const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
          interruptionLevel: InterruptionLevel.timeSensitive,
        );

        const NotificationDetails notificationDetails = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        await _notifications.show(
          0,
          'Rest Time Complete!',
          'Your rest period is over. Ready for the next set?',
          notificationDetails,
        );
      } catch (fallbackError) {
        debugPrint('Fallback notification also failed: $fallbackError');
      }
    }
  }

  /// Show a custom notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'workout_channel',
        'Workout Notifications',
        channelDescription: 'General workout notifications',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: 'default',
        interruptionLevel: InterruptionLevel.timeSensitive,
      );

      const NotificationDetails notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _notifications.show(id, title, body, notificationDetails);
    } catch (e) {
      debugPrint('Error showing notification: $e');
    }
  }

  /// Cancel a specific notification
  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // You can add custom handling here if needed
  }
}
