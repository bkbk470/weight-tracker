import 'package:flutter/foundation.dart';

/// Environment configuration for the app
enum Environment { dev, staging, prod }

/// Application environment configuration
///
/// Usage:
/// ```dart
/// // Set environment before running app
/// AppEnv.current = Environment.prod;
///
/// // Access configuration
/// final url = AppEnv.supabaseUrl;
/// ```
class AppEnv {
  /// Current environment
  static Environment current = kDebugMode ? Environment.dev : Environment.prod;

  /// Supabase URL based on environment
  static String get supabaseUrl {
    switch (current) {
      case Environment.dev:
        return const String.fromEnvironment(
          'SUPABASE_URL_DEV',
          defaultValue: '', // Set via --dart-define during build
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_URL_STAGING',
          defaultValue: '',
        );
      case Environment.prod:
        return const String.fromEnvironment(
          'SUPABASE_URL_PROD',
          defaultValue: '',
        );
    }
  }

  /// Supabase anonymous key based on environment
  static String get supabaseAnonKey {
    switch (current) {
      case Environment.dev:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY_DEV',
          defaultValue: '',
        );
      case Environment.staging:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY_STAGING',
          defaultValue: '',
        );
      case Environment.prod:
        return const String.fromEnvironment(
          'SUPABASE_ANON_KEY_PROD',
          defaultValue: '',
        );
    }
  }

  /// Whether logging is enabled
  static bool get enableLogging => current != Environment.prod;

  /// Whether debug tools are enabled
  static bool get enableDebugTools => current == Environment.dev;

  /// Whether verbose logging is enabled
  static bool get enableVerboseLogging => current == Environment.dev;

  /// API timeout duration
  static Duration get apiTimeout => const Duration(seconds: 30);

  /// Environment name as string
  static String get environmentName {
    switch (current) {
      case Environment.dev:
        return 'Development';
      case Environment.staging:
        return 'Staging';
      case Environment.prod:
        return 'Production';
    }
  }
}
