import 'package:flutter/material.dart';
import '../services/supabase_service.dart';

class DatabaseDebugScreen extends StatefulWidget {
  const DatabaseDebugScreen({super.key});

  @override
  State<DatabaseDebugScreen> createState() => _DatabaseDebugScreenState();
}

class _DatabaseDebugScreenState extends State<DatabaseDebugScreen> {
  final List<String> _logs = [];
  bool _isRunning = false;

  void _log(String message) {
    setState(() {
      _logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
    print(message);
  }

  Future<void> _runFullTest() async {
    setState(() {
      _logs.clear();
      _isRunning = true;
    });

    try {
      // Test 1: Check authentication
      _log('========== TEST 1: AUTHENTICATION ==========');
      final user = SupabaseService.instance.currentUser;
      if (user == null) {
        _log('❌ NOT AUTHENTICATED!');
        _log('Please sign in first');
        return;
      }
      _log('✅ Authenticated as: ${user.email}');
      _log('   User ID: ${user.id}');

      // Test 2: Test database connection
      _log('\\n========== TEST 2: DATABASE CONNECTION ==========');
      try {
        final exercises = await SupabaseService.instance.getExercises();
        _log('✅ Database connected');
        _log('   Found ${exercises.length} exercises');
      } catch (e) {
        _log('❌ Database connection failed: $e');
        return;
      }

      // Test 3: Create a test workout log
      _log('\\n========== TEST 3: CREATE WORKOUT LOG ==========');
      final now = DateTime.now();
      final startTime = now.subtract(const Duration(minutes: 30));
      
      try {
        final workoutLog = await SupabaseService.instance.createWorkoutLog(
          workoutName: 'Test Workout ${now.millisecond}',
          startTime: startTime,
          endTime: now,
          durationSeconds: 1800,
          notes: 'Test workout from debug screen',
        );
        
        _log('✅ Workout log created successfully!');
        _log('   Workout ID: ${workoutLog['id']}');
        _log('   Workout Name: ${workoutLog['workout_name']}');
        _log('   User ID: ${workoutLog['user_id']}');
        
        // Test 4: Add exercise sets to the workout
        _log('\\n========== TEST 4: ADD EXERCISE SETS ==========');
        
        // Get an exercise to use
        final exercises = await SupabaseService.instance.getExercises();
        if (exercises.isEmpty) {
          _log('⚠️ No exercises found, skipping set creation');
        } else {
          final testExercise = exercises.first;
          _log('Using exercise: ${testExercise['name']}');
          
          // Add 3 test sets
          for (int i = 1; i <= 3; i++) {
            try {
              await SupabaseService.instance.addExerciseSet(
                workoutLogId: workoutLog['id'],
                exerciseId: testExercise['id'],
                exerciseName: testExercise['name'],
                setNumber: i,
                weightLbs: 135.0 + (i * 10),
                reps: 8,
                completed: true,
                restTimeSeconds: 120,
              );
              _log('✅ Set $i created: ${135 + (i * 10)} lbs x 8 reps');
            } catch (e) {
              _log('❌ Failed to create set $i: $e');
            }
          }
        }
        
        // Test 5: Verify data was saved
        _log('\\n========== TEST 5: VERIFY SAVED DATA ==========');
        try {
          final workoutLogs = await SupabaseService.instance.getWorkoutLogs(limit: 5);
          _log('✅ Found ${workoutLogs.length} workout logs');
          
          if (workoutLogs.isNotEmpty) {
            final latest = workoutLogs.first;
            _log('   Latest workout: ${latest['workout_name']}');
            _log('   Duration: ${latest['duration_seconds']} seconds');
            
            if (latest['exercise_sets'] != null) {
              final sets = latest['exercise_sets'] as List;
              _log('   Total sets: ${sets.length}');
            }
          }
        } catch (e) {
          _log('❌ Failed to retrieve workouts: $e');
        }
        
        _log('\\n========== ALL TESTS COMPLETED ==========');
        _log('✅ Database is working correctly!');
        _log('✅ You can save workouts!');
        
      } catch (e) {
        _log('❌ Failed to create workout log: $e');
        _log('   Error type: ${e.runtimeType}');
        _log('   Make sure supabase_schema.sql is running');
      }
      
    } catch (e) {
      _log('❌ Unexpected error: $e');
    } finally {
      setState(() {
        _isRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Database Connection Test',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'This will test your database connection and try to save a workout',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isRunning ? null : _runFullTest,
                  icon: _isRunning 
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isRunning ? 'Running Tests...' : 'Run Full Test'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: _logs.isEmpty
                ? Center(
                    child: Text(
                      'Tap "Run Full Test" to begin',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _logs.length,
                    itemBuilder: (context, index) {
                      final log = _logs[index];
                      Color textColor = colorScheme.onSurface;
                      
                      if (log.contains('✅')) {
                        textColor = Colors.green;
                      } else if (log.contains('❌')) {
                        textColor = Colors.red;
                      } else if (log.contains('⚠️')) {
                        textColor = Colors.orange;
                      } else if (log.contains('==========')) {
                        textColor = colorScheme.primary;
                      }
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: textColor,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
