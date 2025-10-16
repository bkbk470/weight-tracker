import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  final Function(String) onNavigate;

  const AboutScreen({super.key, required this.onNavigate});

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
        title: const Text('About'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // App Logo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.fitness_center,
                size: 60,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 24),

            // App Name
            Text(
              'FitTrack',
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),

            // Version
            Text(
              'Version 1.0.0',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Description Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'About FitTrack',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'FitTrack is your ultimate weightlifting companion, designed to help you track your workouts, monitor progress, and achieve your fitness goals.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Built with Material Design 3 for a beautiful, modern, and intuitive user experience.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.star_outline,
                          color: colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Key Features',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FeatureItem(
                      icon: Icons.fitness_center,
                      text: 'Track workouts with ease',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.trending_up,
                      text: 'Monitor your progress with charts',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.timer,
                      text: 'Built-in rest timers',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.emoji_events,
                      text: 'Track personal records',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                    const SizedBox(height: 12),
                    _FeatureItem(
                      icon: Icons.local_fire_department,
                      text: 'Maintain workout streaks',
                      colorScheme: colorScheme,
                      textTheme: textTheme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Technology Stack
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.code,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Built With',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _TechItem(
                      label: 'Framework',
                      value: 'Flutter',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),
                    _TechItem(
                      label: 'Design System',
                      value: 'Material Design 3',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(height: 12),
                    _TechItem(
                      label: 'Charts',
                      value: 'FL Chart',
                      textTheme: textTheme,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Credits Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.favorite_outline,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Credits',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Design inspired by Material Design 3 guidelines',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Icons from Material Icons',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Charts powered by FL Chart',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Contact Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Get in Touch',
                          style: textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _ContactButton(
                      icon: Icons.email,
                      label: 'Email Support',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _ContactButton(
                      icon: Icons.bug_report,
                      label: 'Report a Bug',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _ContactButton(
                      icon: Icons.rate_review,
                      label: 'Rate the App',
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Legal Links
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Privacy Policy'),
                ),
                Text(
                  '•',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Terms of Service'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Copyright
            Text(
              '© 2024 FitTrack. All rights reserved.',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Made with ❤️ for fitness enthusiasts',
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _FeatureItem({
    required this.icon,
    required this.text,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}

class _TechItem extends StatelessWidget {
  final String label;
  final String value;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  const _TechItem({
    required this.label,
    required this.value,
    required this.textTheme,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ContactButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: textTheme.bodyMedium,
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
