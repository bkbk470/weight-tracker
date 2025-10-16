import 'package:flutter/material.dart';

class NotificationsScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const NotificationsScreen({super.key, required this.onNavigate});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool workoutReminders = true;
  bool restTimerAlerts = true;
  bool achievementNotifications = true;
  bool weeklyReports = false;
  bool motivationalMessages = true;
  
  TimeOfDay workoutReminderTime = const TimeOfDay(hour: 18, minute: 0);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => widget.onNavigate('profile'),
        ),
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            'Workout Notifications',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Workout Reminders'),
                  subtitle: const Text('Get reminded to workout'),
                  value: workoutReminders,
                  onChanged: (value) {
                    setState(() => workoutReminders = value);
                  },
                ),
                if (workoutReminders)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: const Text('Reminder Time'),
                    subtitle: Text(workoutReminderTime.format(context)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: workoutReminderTime,
                      );
                      if (time != null) {
                        setState(() => workoutReminderTime = time);
                      }
                    },
                  ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Rest Timer Alerts'),
                  subtitle: const Text('Sound when rest time is up'),
                  value: restTimerAlerts,
                  onChanged: (value) {
                    setState(() => restTimerAlerts = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Progress Notifications',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Achievement Notifications'),
                  subtitle: const Text('Celebrate your milestones'),
                  value: achievementNotifications,
                  onChanged: (value) {
                    setState(() => achievementNotifications = value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Weekly Reports'),
                  subtitle: const Text('Summary of your week'),
                  value: weeklyReports,
                  onChanged: (value) {
                    setState(() => weeklyReports = value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Motivation',
            style: textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: SwitchListTile(
              title: const Text('Motivational Messages'),
              subtitle: const Text('Daily inspiration and tips'),
              value: motivationalMessages,
              onChanged: (value) {
                setState(() => motivationalMessages = value);
              },
            ),
          ),
          const SizedBox(height: 32),
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Notification settings may require app permissions. Check your device settings if notifications are not working.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
