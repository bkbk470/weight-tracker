import 'dart:async';
import 'package:flutter/widgets.dart';

class WorkoutTimerService with ChangeNotifier, WidgetsBindingObserver {
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

  // Legacy callbacks for backwards compatibility (deprecated - use ChangeNotifier instead)
  final List<Function(int)> _legacyListeners = [];

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

  // Set elapsed seconds (for restoring from saved state)
  void setElapsedSeconds(int seconds) {
    _elapsedSeconds = seconds;
    _notifyListeners();
  }

  // Legacy listener methods for backwards compatibility
  void addListener(Function(int) listener) {
    if (listener is VoidCallback) {
      // If it's a VoidCallback, use the proper ChangeNotifier method
      super.addListener(listener);
    } else {
      // Legacy listener
      _legacyListeners.add(listener);
    }
  }

  void removeListener(Function(int) listener) {
    if (listener is VoidCallback) {
      super.removeListener(listener);
    } else {
      _legacyListeners.remove(listener);
    }
  }

  // Notify all listeners (both ChangeNotifier and legacy)
  void _notifyListeners() {
    // Notify ChangeNotifier listeners (for AnimatedBuilder, ValueListenableBuilder, etc.)
    notifyListeners();

    // Notify legacy listeners for backwards compatibility
    for (var listener in _legacyListeners) {
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
