import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const WelcomeScreen({super.key, required this.onNavigate});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int currentSlide = 0;

  final slides = [
    {
      'icon': Icons.fitness_center,
      'title': 'Welcome to FitTrack',
      'subtitle': 'Your ultimate weightlifting companion',
      'description':
          'Track your workouts, monitor progress, and achieve your fitness goals with our intuitive Material 3 design.'
    },
    {
      'icon': Icons.bolt,
      'title': 'Lightning Fast Logging',
      'subtitle': 'Log workouts in seconds',
      'description':
          'Quick set input, intelligent exercise suggestions, and seamless workout flow designed for the gym floor.'
    },
    {
      'icon': Icons.track_changes,
      'title': 'Smart Progress Tracking',
      'subtitle': 'See your strength gains',
      'description':
          'Visualize your progress with detailed charts, PR tracking, and personalized insights to keep you motivated.'
    },
    {
      'icon': Icons.trending_up,
      'title': 'Achieve Your Goals',
      'subtitle': 'Build the physique you want',
      'description':
          'Customizable training programs, rest timers, and analytics to help you reach your fitness potential.'
    },
  ];

  void handleNext() {
    if (currentSlide < slides.length - 1) {
      setState(() => currentSlide++);
    } else {
      widget.onNavigate('dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          // Background gradients
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 384,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.primary.withOpacity(0.05),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 3,
            right: 0,
            child: Container(
              width: 384,
              height: 384,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    colorScheme.secondary.withOpacity(0.03),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 24),
                      Row(
                        children: List.generate(
                          slides.length,
                          (index) => Container(
                            width: index == currentSlide ? 32 : 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: index == currentSlide
                                  ? colorScheme.primary
                                  : colorScheme.outlineVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => widget.onNavigate('dashboard'),
                        child: const Text('Skip'),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 128,
                          height: 128,
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            slides[currentSlide]['icon'] as IconData,
                            size: 64,
                            color: colorScheme.primary,
                          ),
                        ),
                        Text(
                          slides[currentSlide]['title'] as String,
                          style: textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slides[currentSlide]['subtitle'] as String,
                          style: textTheme.titleLarge?.copyWith(
                            color: colorScheme.primary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          slides[currentSlide]['description'] as String,
                          style: textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom actions
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton.icon(
                        onPressed: handleNext,
                        icon: const Icon(Icons.chevron_right),
                        label: Text(
                          currentSlide == slides.length - 1 ? 'Get Started' : 'Next',
                        ),
                      ),
                      if (currentSlide > 0) ...[
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => setState(() => currentSlide--),
                          child: const Text('Back'),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
