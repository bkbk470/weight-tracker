import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const PrivacyPolicyScreen({super.key, required this.onNavigate});

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
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          // Header
          Text(
            'FitTrack Privacy Policy',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Last Updated: October 10, 2025',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Introduction
          Card(
            color: colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your privacy is important to us. This policy explains how we collect, use, and protect your personal information.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 1
          _PolicySection(
            title: '1. Information We Collect',
            content: '''We collect the following types of information:

• Personal Information: Name, email address, date of birth, gender
• Physical Data: Height, weight, body measurements
• Workout Data: Exercise routines, sets, reps, weights, workout duration
• Progress Data: Personal records, achievements, workout history
• Device Information: Device type, operating system, app version
• Usage Data: How you interact with the app, features used

This information helps us provide personalized workout tracking and improve your experience.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 2
          _PolicySection(
            title: '2. How We Use Your Information',
            content: '''We use your information to:

• Provide and maintain workout tracking services
• Personalize your fitness experience
• Generate progress reports and analytics
• Send workout reminders and notifications
• Improve app features and performance
• Provide customer support
• Ensure app security and prevent fraud
• Comply with legal obligations

We will never sell your personal information to third parties.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 3
          _PolicySection(
            title: '3. Data Storage and Security',
            content: '''We take data security seriously:

• All data is encrypted in transit and at rest
• Secure servers with regular security audits
• Access controls and authentication
• Regular backups to prevent data loss
• Industry-standard security protocols
• Secure password storage with hashing

While we strive to protect your data, no method of transmission over the internet is 100% secure.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 4
          _PolicySection(
            title: '4. Data Sharing',
            content: '''We do not sell your personal information. We may share data only in these circumstances:

• With your explicit consent
• With service providers who help operate our app (under strict confidentiality agreements)
• To comply with legal obligations or court orders
• To protect our rights, safety, or property
• In connection with a business transfer or merger

All third-party partners are required to maintain data confidentiality.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 5
          _PolicySection(
            title: '5. Your Rights',
            content: '''You have the following rights regarding your data:

• Access: Request a copy of your personal data
• Correction: Update or correct inaccurate data
• Deletion: Request deletion of your account and data
• Export: Download your workout data
• Opt-out: Unsubscribe from marketing communications
• Restrict Processing: Limit how we use your data

To exercise these rights, contact us at privacy@fittrack.com''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 6
          _PolicySection(
            title: '6. Cookies and Tracking',
            content: '''We use cookies and similar technologies to:

• Remember your preferences and settings
• Analyze app usage and performance
• Provide personalized content
• Ensure security and prevent fraud

You can control cookie preferences in your device settings.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 7
          _PolicySection(
            title: '7. Third-Party Services',
            content: '''Our app may integrate with third-party services:

• Analytics providers (e.g., Google Analytics)
• Cloud storage providers
• Authentication services (Google, Apple)
• Payment processors

These services have their own privacy policies. We recommend reviewing them.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 8
          _PolicySection(
            title: '8. Children\'s Privacy',
            content: '''FitTrack is not intended for users under 13 years of age. We do not knowingly collect information from children under 13.

If you believe we have collected information from a child under 13, please contact us immediately at privacy@fittrack.com and we will delete it.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 9
          _PolicySection(
            title: '9. International Data Transfers',
            content: '''Your data may be transferred to and processed in countries other than your own. We ensure appropriate safeguards are in place to protect your data in compliance with applicable laws.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 10
          _PolicySection(
            title: '10. Changes to This Policy',
            content: '''We may update this Privacy Policy from time to time. We will notify you of significant changes via:

• In-app notification
• Email notification
• Notice on our website

Continued use of the app after changes constitutes acceptance of the updated policy.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          // Section 11
          _PolicySection(
            title: '11. Contact Us',
            content: '''If you have questions or concerns about this Privacy Policy:

Email: privacy@fittrack.com
Website: www.fittrack.com/privacy
Address: 123 Fitness Street, Health City, HC 12345

We will respond to your inquiry within 30 days.''',
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: 24),

          // Action Buttons
          FilledButton.icon(
            onPressed: () {
              // Download privacy policy
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Privacy Policy downloaded'),
                ),
              );
            },
            icon: const Icon(Icons.download),
            label: const Text('Download Policy (PDF)'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Request data
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Request Your Data'),
                  content: const Text(
                    'We will send a copy of all your personal data to your registered email address within 30 days.',
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
                          const SnackBar(
                            content: Text('Data request submitted'),
                          ),
                        );
                      },
                      child: const Text('Request'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.folder_open),
            label: const Text('Request My Data'),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              // Delete account
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Delete Account'),
                  content: const Text(
                    'Are you sure you want to delete your account? This will permanently delete all your data and cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onNavigate('login');
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                      ),
                      child: const Text('Delete Account'),
                    ),
                  ],
                ),
              );
            },
            icon: Icon(Icons.delete_forever, color: colorScheme.error),
            label: Text(
              'Delete My Account',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
          const SizedBox(height: 32),

          // Footer
          Center(
            child: Text(
              '© 2024 FitTrack. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String title;
  final String content;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _PolicySection({
    required this.title,
    required this.content,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleLarge?.copyWith(
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              content,
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                height: 1.6,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
