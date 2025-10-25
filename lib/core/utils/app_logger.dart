import 'package:flutter/foundation.dart';
import '../config/env/app_env.dart';

/// Log levels for the application logger
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Application logger with environment-aware logging
///
/// Usage:
/// ```dart
/// AppLogger.d('Debug message');
/// AppLogger.i('Info message');
/// AppLogger.w('Warning message');
/// AppLogger.e('Error message', error: exception, stackTrace: stackTrace);
/// ```
class AppLogger {
  AppLogger._();

  /// Log debug message
  static void d(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(LogLevel.debug, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log info message
  static void i(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(LogLevel.info, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log warning message
  static void w(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(LogLevel.warning, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Log error message
  static void e(
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace, tag: tag);
  }

  /// Internal logging method
  static void _log(
    LogLevel level,
    String message, {
    dynamic error,
    StackTrace? stackTrace,
    String? tag,
  }) {
    // Don't log debug messages in production
    if (!AppEnv.enableLogging && level == LogLevel.debug) {
      return;
    }

    // Only log errors in production
    if (AppEnv.current == Environment.prod && level != LogLevel.error) {
      return;
    }

    final timestamp = DateTime.now().toIso8601String();
    final levelStr = _getLevelString(level);
    final tagStr = tag != null ? '[$tag]' : '';
    final fullMessage = '[$timestamp] $levelStr $tagStr $message';

    if (kDebugMode) {
      // Use debugPrint for debug mode to avoid log truncation
      debugPrint(fullMessage);

      if (error != null) {
        debugPrint('Error: $error');
      }

      if (stackTrace != null && AppEnv.enableVerboseLogging) {
        debugPrint('StackTrace:\n$stackTrace');
      }
    }

    // In production, you might want to send errors to a crash reporting service
    if (level == LogLevel.error && AppEnv.current == Environment.prod) {
      // TODO: Send to crash reporting service (e.g., Sentry, Firebase Crashlytics)
      // CrashReporting.logError(message, error, stackTrace);
    }
  }

  /// Get string representation of log level
  static String _getLevelString(LogLevel level) {
    switch (level) {
      case LogLevel.debug:
        return '🔍 DEBUG';
      case LogLevel.info:
        return 'ℹ️  INFO ';
      case LogLevel.warning:
        return '⚠️  WARN ';
      case LogLevel.error:
        return '❌ ERROR';
    }
  }

  /// Log a network request
  static void logRequest(String method, String url, {Map<String, dynamic>? data}) {
    if (!AppEnv.enableVerboseLogging) return;
    d('🌐 $method $url', tag: 'Network');
    if (data != null) {
      d('Request data: $data', tag: 'Network');
    }
  }

  /// Log a network response
  static void logResponse(String url, int statusCode, {dynamic data}) {
    if (!AppEnv.enableVerboseLogging) return;
    d('✅ Response from $url - Status: $statusCode', tag: 'Network');
    if (data != null) {
      d('Response data: $data', tag: 'Network');
    }
  }

  /// Log navigation events
  static void logNavigation(String from, String to) {
    if (!AppEnv.enableVerboseLogging) return;
    d('🧭 Navigating: $from → $to', tag: 'Navigation');
  }

  /// Log performance metrics
  static void logPerformance(String operation, Duration duration) {
    if (!AppEnv.enableVerboseLogging) return;
    i('⚡ $operation took ${duration.inMilliseconds}ms', tag: 'Performance');
  }
}
