import 'dart:async';
import 'package:flutter/widgets.dart';

class WorkoutTimerService with WidgetsBindingObserver {
  static final WorkoutTimerService _instance = WorkoutTimerService._internal();
  static WorkoutTimerService get instance => _instance;

  WorkoutTimerService._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _isRunning = false;
  DateTime? _startTime;
  DateTime? _pauseTime;
  bool _wasRunningBeforePause = false;
  
  // Callbacks for UI updates
  final List<Function(int)> _listeners = [];

  // Getters
  bool get isRunning => _isRunning;
  int get elapsedSeconds => _elapsedSeconds;
  
  // Start the timer
  void start() {
    if (_isRunning) return;
    
    _isRunning = true;
    _startTime = DateTime.now().subtract(Duration(seconds: _elapsedSeconds));
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
      _notifyListeners();
    });
  }

  // Pause the timer
  void pause() {
    if (!_isRunning) return;
    
    _isRunning = false;
    _pauseTime = DateTime.now();
    _timer?.cancel();
    _timer = null;
  }

  // Resume the timer
  void resume() {
    if (_isRunning) return;
    start();
  }

  // Reset the timer
  void reset() {
    _timer?.cancel();
    _timer = null;
    _elapsedSeconds = 0;
    _isRunning = false;
    _startTime = null;
    _pauseTime = null;
    _notifyListeners();
  }

  // Stop and reset
  void stop() {
    reset();
  }

  // Add listener for UI updates
  void addListener(Function(int) listener) {
    _listeners.add(listener);
  }

  // Remove listener
  void removeListener(Function(int) listener) {
    _listeners.remove(listener);
  }

  // Notify all listeners
  void _notifyListeners() {
    for (var listener in _listeners) {
      listener(_elapsedSeconds);
    }
  }

  // Format time as HH:MM:SS
  String formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
    }
  }

  // Handle app lifecycle changes (screen lock/unlock)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App went to background (screen locked)
      _wasRunningBeforePause = _isRunning;
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground (screen unlocked)
      if (_wasRunningBeforePause && _startTime != null) {
        // Recalculate elapsed time based on start time
        _elapsedSeconds = DateTime.now().difference(_startTime!).inSeconds;
        _notifyListeners();
      }
    }
  }

  // Dispose
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _listeners.clear();
  }
}
