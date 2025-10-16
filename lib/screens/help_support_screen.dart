import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const HelpSupportScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => onNavigate('profile'),
        ),
        title: const Text('Help & Support'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Contact Support Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.support_agent,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Contact Support',
                        style: textTheme.titleLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Need help? Our support team is here to assist you.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _ContactOption(
                    icon: Icons.email,
                    title: 'Email Support',
                    subtitle: 'support@fittrack.com',
                    onTap: () {
                      // Open email client
                    },
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.chat_bubble_outline,
                    title: 'Live Chat',
                    subtitle: 'Chat with our team',
                    onTap: () {
                      // Open live chat
                    },
                  ),
                  const SizedBox(height: 12),
                  _ContactOption(
                    icon: Icons.phone,
                    title: 'Phone Support',
                    subtitle: '+1 (555) 123-4567',
                    onTap: () {
                      // Open phone dialer
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // FAQs
          Text(
            'Frequently Asked Questions',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _FAQItem(
            question: 'How do I track my workouts?',
            answer: 'Tap on the "Workout" tab in the bottom navigation, select a workout template or create a custom one, then tap "Start Workout". You can add exercises, track sets, reps, and weight, and the app will automatically track your rest times.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'How do I view my progress?',
            answer: 'Navigate to the "Progress" tab to see detailed charts and statistics about your workouts. You can view your progress over different time periods (1M, 3M, 6M, 1Y) and see achievements, PRs, and workout streaks.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'Can I create custom workout routines?',
            answer: 'Yes! Tap on "Create Custom Workout" from the workout screen. You can add exercises from our library, organize them in any order, and save your routine for future use.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'How do I set fitness goals?',
            answer: 'Goals can be accessed from your profile settings. You can set goals for strength, frequency, consistency, and more. Track your progress with visual indicators.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'How do rest timers work?',
            answer: 'When you complete a set, the app automatically starts a rest timer based on your preferences. You\'ll see a countdown with visual feedback. You can skip the rest timer at any time.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'Can I export my workout data?',
            answer: 'Data export functionality is coming soon! You\'ll be able to export your workout history to CSV, PDF, or sync with other fitness apps.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'Is my data secure?',
            answer: 'Yes, we take your privacy seriously. All data is encrypted and stored securely. We never share your personal information with third parties. Read our Privacy Policy for more details.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          _FAQItem(
            question: 'How do I change units (kg/lbs)?',
            answer: 'Go to Profile > Edit Profile, and select your preferred unit system (Metric or Imperial). All your data will be converted automatically.',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),
          const SizedBox(height: 24),

          // Quick Actions
          Text(
            'Quick Actions',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.bug_report, color: colorScheme.primary),
                  title: const Text('Report a Bug'),
                  subtitle: const Text('Found an issue? Let us know'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showReportDialog(context, 'Report a Bug');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.lightbulb_outline, color: colorScheme.primary),
                  title: const Text('Request a Feature'),
                  subtitle: const Text('Suggest improvements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showReportDialog(context, 'Request a Feature');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.feedback_outlined, color: colorScheme.primary),
                  title: const Text('Send Feedback'),
                  subtitle: const Text('Share your thoughts'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showReportDialog(context, 'Send Feedback');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined, color: colorScheme.primary),
                  title: const Text('View Tutorials'),
                  subtitle: const Text('Learn how to use FitTrack'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Open tutorials
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Resources
          Text(
            'Resources',
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.book_outlined),
                  title: const Text('User Guide'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.video_library_outlined),
                  title: const Text('Video Tutorials'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.forum_outlined),
                  title: const Text('Community Forum'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Response Time Info
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Response Time',
                          style: textTheme.titleSmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'We typically respond within 24 hours during business days.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
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

  void _showReportDialog(BuildContext context, String title) {
    final messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: messageController,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Describe your ${title.toLowerCase()}...',
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$title submitted. Thank you!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
}

class _ContactOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, color: colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleSmall,
                  ),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FAQItem extends StatefulWidget {
  final String question;
  final String answer;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _FAQItem({
    required this.question,
    required this.answer,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => isExpanded = !isExpanded),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: widget.textTheme.titleSmall,
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: widget.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Text(
                  widget.answer,
                  style: widget.textTheme.bodyMedium?.copyWith(
                    color: widget.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
