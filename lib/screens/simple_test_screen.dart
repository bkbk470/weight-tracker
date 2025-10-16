import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleTestScreen extends StatefulWidget {
  const SimpleTestScreen({super.key});

  @override
  State<SimpleTestScreen> createState() => _SimpleTestScreenState();
}

class _SimpleTestScreenState extends State<SimpleTestScreen> {
  String _status = 'Testing...';
  bool _isLoading = true;
  Color _statusColor = Colors.orange;

  @override
  void initState() {
    super.initState();
    _testConnection();
  }

  Future<void> _testConnection() async {
    try {
      // Test 1: Check if Supabase is initialized
      setState(() {
        _status = 'Step 1: Checking Supabase initialization...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      
      final client = Supabase.instance.client;
      
      setState(() {
        _status = 'Step 2: Supabase initialized ✅\nTesting database connection...';
      });
      
      await Future.delayed(const Duration(seconds: 1));
      
      // Test 2: Try to query the database
      final response = await client
          .from('exercises')
          .select()
          .limit(5);
      
      setState(() {
        _status = 'SUCCESS! ✅\n\n'
            'Supabase is connected!\n'
            'Found ${response.length} exercises in database.\n\n'
            'Everything is working correctly!';
        _statusColor = Colors.green;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _status = 'ERROR ❌\n\n$e\n\n'
            'Possible issues:\n'
            '1. Database schema not created (run supabase_schema.sql)\n'
            '2. Wrong URL or anon key\n'
            '3. Network connection issue';
        _statusColor = Colors.red;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Connection Test'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Icon(
                  _statusColor == Colors.green
                      ? Icons.check_circle
                      : Icons.error,
                  size: 64,
                  color: _statusColor,
                ),
              const SizedBox(height: 32),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: _statusColor,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _statusColor = Colors.orange;
                  });
                  _testConnection();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Test Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
