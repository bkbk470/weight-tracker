import 'package:flutter/material.dart';
import '../services/exercise_cache_service.dart';
import '../services/supabase_service.dart';
import '../services/local_storage_service.dart';

/// Debug screen to diagnose exercise loading issues
class ExerciseDebugScreen extends StatefulWidget {
  const ExerciseDebugScreen({super.key});

  @override
  State<ExerciseDebugScreen> createState() => _ExerciseDebugScreenState();
}

class _ExerciseDebugScreenState extends State<ExerciseDebugScreen> {
  String _status = 'Ready to test...';
  Map<String, dynamic> _results = {};
  bool _isLoading = false;

  Future<void> _runDiagnostics() async {
    setState(() {
      _isLoading = true;
      _status = 'Running diagnostics...';
      _results = {};
    });

    try {
      // Test 1: Check authentication
      setState(() => _status = 'Test 1/5: Checking authentication...');
      await Future.delayed(const Duration(milliseconds: 500));
      final user = SupabaseService.instance.currentUser;
      _results['auth'] = {
        'loggedIn': user != null,
        'userId': user?.id ?? 'Not logged in',
      };

      // Test 2: Check Supabase direct query
      setState(() => _status = 'Test 2/5: Querying Supabase directly...');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final supabaseExercises = await SupabaseService.instance.getExercises();
        _results['supabase'] = {
          'success': true,
          'count': supabaseExercises.length,
          'sample': supabaseExercises.take(3).map((e) => e['name']).toList(),
        };
      } catch (e) {
        _results['supabase'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      // Test 3: Check local storage
      setState(() => _status = 'Test 3/5: Checking local storage...');
      await Future.delayed(const Duration(milliseconds: 500));
      final localStorage = LocalStorageService.instance;
      final localExercises = localStorage.getAllExercises();
      _results['localStorage'] = {
        'count': localExercises.length,
        'sample': localExercises.take(3).map((e) => e['name']).toList(),
      };

      // Test 4: Check cache service
      setState(() => _status = 'Test 4/5: Testing cache service...');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final cacheExercises = await ExerciseCacheService.instance.getExercises();
        _results['cache'] = {
          'success': true,
          'count': cacheExercises.length,
          'sample': cacheExercises.take(3).map((e) => e['name']).toList(),
          'stats': ExerciseCacheService.instance.getCacheStats(),
        };
      } catch (e) {
        _results['cache'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      // Test 5: Test dialog data format
      setState(() => _status = 'Test 5/5: Testing data format...');
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final exercises = await ExerciseCacheService.instance.getExercises();
        final mapped = exercises.map((e) => {
          'name': e['name']?.toString() ?? 'Unknown',
          'category': e['category']?.toString() ?? 'Other',
        }).toList();
        _results['mapping'] = {
          'success': true,
          'count': mapped.length,
          'sample': mapped.take(3).toList(),
        };
      } catch (e) {
        _results['mapping'] = {
          'success': false,
          'error': e.toString(),
        };
      }

      setState(() {
        _status = 'Diagnostics complete!';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Loading Debug'),
        backgroundColor: colorScheme.primaryContainer,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Diagnostic Status',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(_status),
                    if (_isLoading) ...[
                      const SizedBox(height: 16),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isLoading ? null : _runDiagnostics,
              icon: const Icon(Icons.bug_report),
              label: const Text('Run Diagnostics'),
            ),
            const SizedBox(height: 16),
            if (_results.isNotEmpty)
              Expanded(
                child: Card(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Results',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Divider(),
                        ..._results.entries.map((entry) => _buildResultSection(entry.key, entry.value)),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultSection(String title, dynamic data) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _formatData(data),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  String _formatData(dynamic data) {
    if (data is Map) {
      return data.entries
          .map((e) => '${e.key}: ${_formatData(e.value)}')
          .join('\n');
    } else if (data is List) {
      return '[\n  ${data.join(',\n  ')}\n]';
    }
    return data.toString();
  }
}
