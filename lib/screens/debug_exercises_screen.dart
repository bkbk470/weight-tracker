import 'package:flutter/material.dart';
import 'package:weight_tracker/utils/diagnose_exercises.dart';

/// Debug screen to diagnose exercise loading issues
class DebugExercisesScreen extends StatefulWidget {
  const DebugExercisesScreen({super.key});

  @override
  State<DebugExercisesScreen> createState() => _DebugExercisesScreenState();
}

class _DebugExercisesScreenState extends State<DebugExercisesScreen> {
  String diagnosticOutput = '';
  bool isRunning = false;

  Future<void> runDiagnostic() async {
    setState(() {
      isRunning = true;
      diagnosticOutput = 'Running diagnostic...\n\n';
    });

    // Capture print output
    final buffer = StringBuffer();
    void capturePrint(String message) {
      buffer.writeln(message);
      setState(() {
        diagnosticOutput = buffer.toString();
      });
    }

    // Override print temporarily
    final originalPrint = print;
    // ignore: avoid_print
    print = capturePrint as dynamic;

    try {
      await ExerciseDiagnostic.diagnoseExerciseIssue();
    } catch (e) {
      buffer.writeln('\n❌ Error: $e');
    } finally {
      print = originalPrint as dynamic;
      setState(() {
        isRunning = false;
        diagnosticOutput = buffer.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Diagnostic'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  'Diagnose why exercises aren\'t showing',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: isRunning ? null : runDiagnostic,
                  child: Text(isRunning ? 'Running...' : 'Run Diagnostic'),
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: SelectableText(
                diagnosticOutput.isEmpty
                    ? 'Tap "Run Diagnostic" to start'
                    : diagnosticOutput,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
