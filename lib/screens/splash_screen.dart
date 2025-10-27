import 'package:flutter/material.dart';
import 'dart:async';
import '../services/supabase_service.dart';
import '../services/workout_session_service.dart';
import '../services/exercise_cache_service.dart';

class SplashScreen extends StatefulWidget {
  final Function(String) onNavigate;

  const SplashScreen({super.key, required this.onNavigate});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  String _loadingStatus = 'Loading...';

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
    ));

    _controller.forward();

    // Check authentication and navigate
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    // Start preloading exercises in parallel with splash animation
    if (mounted) {
      setState(() => _loadingStatus = 'Loading exercises...');
    }

    final exercisePreloadFuture = ExerciseCacheService.instance.getExercises();

    // Wait for minimum splash duration
    await Future.delayed(const Duration(milliseconds: 2500));

    if (!mounted) return;

    // Check if user is already logged in
    try {
      final user = SupabaseService.instance.currentUser;

      // Ensure exercises are loaded before navigating (but don't wait too long)
      try {
        final exercises = await exercisePreloadFuture.timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print('Exercise preload timed out, will load in background');
            return <Map<String, dynamic>>[];
          },
        );
        if (mounted) {
          setState(() => _loadingStatus = 'Ready! ${exercises.length} exercises loaded');
        }
        print('✅ Exercises preloaded: ${ExerciseCacheService.instance.getCacheStats()}');
      } catch (e) {
        print('⚠️ Exercise preload error (non-critical): $e');
        if (mounted) {
          setState(() => _loadingStatus = 'Ready!');
        }
        // Continue anyway - exercises will load on demand
      }

      if (user != null) {
        // User is logged in
        // Check if there's an active workout session before navigating
        final hasActiveWorkout = await WorkoutSessionService.instance.hasActiveWorkout();

        if (hasActiveWorkout) {
          // There's an active workout, go directly to it
          widget.onNavigate('active-workout');
        } else {
          // No active workout, go to dashboard
          widget.onNavigate('dashboard');
        }
      } else {
        // Not logged in, go to login
        widget.onNavigate('login');
      }
    } catch (e) {
      // Error checking auth, go to login
      widget.onNavigate('login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final backgroundColor = isDark ? const Color(0xFF050505) : Colors.white;
    final foregroundColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        color: backgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Icon(
                        Icons.fitness_center,
                        size: 120,
                        color: foregroundColor,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(
                          width: 200,
                          child: LinearProgressIndicator(
                            backgroundColor: foregroundColor.withOpacity(0.1),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              colorScheme.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _loadingStatus,
                          style: TextStyle(
                            color: foregroundColor.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
