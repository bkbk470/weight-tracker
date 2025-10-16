import 'package:flutter/material.dart';
import '../services/supabase_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTestScreen extends StatefulWidget {
  const SupabaseTestScreen({super.key});

  @override
  State<SupabaseTestScreen> createState() => _SupabaseTestScreenState();
}

class _SupabaseTestScreenState extends State<SupabaseTestScreen> {
  bool _isTesting = false;
  Map<String, dynamic> _testResults = {};

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() {
      _isTesting = true;
      _testResults = {};
    });

    Map<String, dynamic> results = {};

    // Test 1: Check Supabase Configuration
    try {
      // Try to check if Supabase is initialized
      final client = Supabase.instance.client;
      final isInitialized = client != null;
      
      results['config'] = {
        'success': isInitialized,
        'message': isInitialized
            ? 'Supabase client initialized' 
            : 'Supabase not initialized',
      };
    } catch (e) {
      results['config'] = {
        'success': false,
        'message': 'Error: $e',
      };
    }

    // Test 2: Check Authentication
    try {
      final user = SupabaseService.instance.currentUser;
      results['auth'] = {
        'success': user != null,
        'userId': user?.id,
        'email': user?.email,
        'message': user != null 
            ? 'Authenticated as ${user.email}' 
            : 'Not authenticated',
      };
    } catch (e) {
      results['auth'] = {
        'success': false,
        'message': 'Error: $e',
      };
    }

    // Test 3: Check Database Connection
    try {
      final exercises = await SupabaseService.instance.getExercises();
      results['database'] = {
        'success': true,
        'count': exercises.length,
        'message': 'Connected! Found ${exercises.length} exercises',
      };
    } catch (e) {
      results['database'] = {
        'success': false,
        'message': 'Error: $e',
      };
    }

    // Test 4: Check Tables Exist
    try {
      await Supabase.instance.client
          .from('profiles')
          .select()
          .limit(1);
      results['tables'] = {
        'success': true,
        'message': 'Tables exist',
      };
    } catch (e) {
      results['tables'] = {
        'success': false,
        'message': 'Error: $e',
      };
    }

    setState(() {
      _testResults = results;
      _isTesting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTests,
          ),
        ],
      ),
      body: _isTesting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Header
                Text(
                  'Connection Diagnostics',
                  style: textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Testing your Supabase connection...',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),

                // Test Results
                if (_testResults.isNotEmpty) ...[
                  _buildTestCard(
                    'Configuration',
                    _testResults['config'],
                    Icons.settings,
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildTestCard(
                    'Authentication',
                    _testResults['auth'],
                    Icons.person,
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildTestCard(
                    'Database Connection',
                    _testResults['database'],
                    Icons.storage,
                    colorScheme,
                    textTheme,
                  ),
                  const SizedBox(height: 16),
                  _buildTestCard(
                    'Database Tables',
                    _testResults['tables'],
                    Icons.table_chart,
                    colorScheme,
                    textTheme,
                  ),
                ],

                const SizedBox(height: 32),

                // Summary
                if (_testResults.isNotEmpty)
                  _buildSummary(colorScheme, textTheme),

                const SizedBox(height: 32),

                // Actions
                FilledButton.icon(
                  onPressed: _runTests,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Run Tests Again'),
                ),
              ],
            ),
    );
  }

  Widget _buildTestCard(
    String title,
    Map<String, dynamic>? result,
    IconData icon,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    if (result == null) return const SizedBox();

    final success = result['success'] ?? false;
    final message = result['message'] ?? 'Unknown';

    return Card(
      color: success
          ? colorScheme.primaryContainer
          : colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  success ? Icons.check_circle : Icons.error,
                  color: success
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      color: success
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                Icon(
                  icon,
                  color: success
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: textTheme.bodyMedium?.copyWith(
                color: success
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onErrorContainer,
              ),
            ),
            if (result.containsKey('url')) ...[
              const SizedBox(height: 8),
              Text(
                'URL: ${result['url']}',
                style: textTheme.bodySmall?.copyWith(
                  color: success
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                  fontFamily: 'monospace',
                ),
              ),
            ],
            if (result.containsKey('email')) ...[
              const SizedBox(height: 4),
              Text(
                'Email: ${result['email'] ?? 'Not logged in'}',
                style: textTheme.bodySmall?.copyWith(
                  color: success
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                ),
              ),
            ],
            if (result.containsKey('count')) ...[
              const SizedBox(height: 4),
              Text(
                'Exercises found: ${result['count']}',
                style: textTheme.bodySmall?.copyWith(
                  color: success
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onErrorContainer,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(ColorScheme colorScheme, TextTheme textTheme) {
    final allSuccess = _testResults.values.every((r) => r['success'] == true);
    
    return Card(
      color: allSuccess ? Colors.green : Colors.orange,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  allSuccess ? Icons.check_circle : Icons.warning,
                  color: Colors.white,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    allSuccess ? 'All Tests Passed!' : 'Issues Found',
                    style: textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              allSuccess
                  ? 'Supabase is properly configured and connected!'
                  : 'Please fix the issues above to connect to Supabase.',
              style: textTheme.bodyMedium?.copyWith(
                color: Colors.white,
              ),
            ),
            if (!allSuccess) ...[
              const SizedBox(height: 16),
              const Text(
                'Common fixes:',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '1. Add Supabase URL and anon key to main.dart\n'
                '2. Run supabase_schema.sql in Supabase SQL Editor\n'
                '3. Enable Email auth in Supabase dashboard\n'
                '4. Sign up/Sign in to authenticate',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
