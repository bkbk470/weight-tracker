import 'package:flutter/material.dart';
import '../constants/exercise_assets.dart';
import '../services/supabase_service.dart';

class ComprehensiveImageDebugScreen extends StatefulWidget {
  const ComprehensiveImageDebugScreen({super.key});

  @override
  State<ComprehensiveImageDebugScreen> createState() => _ComprehensiveImageDebugScreenState();
}

class _ComprehensiveImageDebugScreenState extends State<ComprehensiveImageDebugScreen> {
  String? _testResult;
  bool _loading = false;

  Future<void> _runTests() async {
    setState(() {
      _loading = true;
      _testResult = null;
    });

    final results = StringBuffer();
    results.writeln('🔍 COMPREHENSIVE IMAGE DEBUG TEST\n');

    // Test 1: Check constants
    results.writeln('📋 Test 1: Constants');
    results.writeln('  Bucket: $kExerciseStorageBucket');
    results.writeln('  Path: $kDefaultExerciseStoragePath');
    results.writeln('  Full path: $kExercisePlaceholderImage\n');

    // Test 2: List buckets
    results.writeln('📋 Test 2: List all storage buckets');
    try {
      final buckets = await SupabaseService.instance.client.storage.listBuckets();
      results.writeln('  Found ${buckets.length} buckets:');
      for (var bucket in buckets) {
        results.writeln('    - ${bucket.name} (public: ${bucket.public})');
      }
      results.writeln();
    } catch (e) {
      results.writeln('  ❌ Error: $e\n');
    }

    // Test 3: List files in Exercises bucket
    results.writeln('📋 Test 3: List files in Exercises bucket');
    try {
      final files = await SupabaseService.instance.client.storage
          .from('Exercises')
          .list();
      results.writeln('  Found ${files.length} files:');
      for (var file in files) {
        results.writeln('    - ${file.name}');
      }
      results.writeln();
    } catch (e) {
      results.writeln('  ❌ Error: $e\n');
    }

    // Test 4: Try to get signed URL with different variations
    results.writeln('📋 Test 4: Try different file paths\n');
    
    final pathsToTry = [
      'default_exercise.gif',
      'default_excercise.gif',
      'Exercises/default_exercise.gif',
      'exercises/default_exercise.gif',
    ];

    for (var path in pathsToTry) {
      results.write('  Testing: $path... ');
      try {
        final url = await SupabaseService.instance.client.storage
            .from('Exercises')
            .createSignedUrl(path, 60);
        results.writeln('✅ SUCCESS');
        results.writeln('    URL: ${url.substring(0, 50)}...');
      } catch (e) {
        results.writeln('❌ FAILED: $e');
      }
    }
    results.writeln();

    // Test 5: Try using the service method
    results.writeln('📋 Test 5: Using SupabaseService.getSignedUrlForStoragePath');
    try {
      final url = await SupabaseService.instance
          .getSignedUrlForStoragePath(kExercisePlaceholderImage);
      results.writeln('  ✅ SUCCESS');
      results.writeln('  URL: ${url.substring(0, 60)}...\n');
    } catch (e) {
      results.writeln('  ❌ FAILED: $e\n');
    }

    setState(() {
      _testResult = results.toString();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comprehensive Image Debug'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _loading ? null : _runTests,
              icon: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(_loading ? 'Running Tests...' : 'Run Tests'),
            ),
            const SizedBox(height: 16),
            if (_testResult != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _testResult!,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
