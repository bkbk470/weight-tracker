/// Base class for all failures in the application
///
/// Usage with pattern matching:
/// ```dart
/// result.fold(
///   (failure) {
///     final message = failure.when(
///       server: (msg) => 'Server error: $msg',
///       network: (msg) => 'Check your connection',
///       // ...
///     );
///   },
///   (data) => // handle success
/// );
/// ```
abstract class Failure {
  final String message;
  final StackTrace? stackTrace;

  const Failure(this.message, [this.stackTrace]);

  /// Get user-friendly error message
  String get userMessage;

  @override
  String toString() => 'Failure: $message';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message;

  @override
  int get hashCode => message.hashCode;
}

/// Server-side error (5xx errors, server exceptions)
class ServerFailure extends Failure {
  const ServerFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Server error. Please try again later.';
}

/// Network error (no connection, timeout)
class NetworkFailure extends Failure {
  const NetworkFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Network error. Please check your internet connection.';
}

/// Local storage error (cache, database)
class CacheFailure extends Failure {
  const CacheFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Local storage error. Please try clearing app data.';
}

/// Validation error (invalid input)
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => message; // Show actual validation error
}

/// Authentication error (login, token expired)
class AuthenticationFailure extends Failure {
  const AuthenticationFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Authentication failed. Please login again.';
}

/// Authorization error (permission denied)
class AuthorizationFailure extends Failure {
  const AuthorizationFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'You don\'t have permission to perform this action.';
}

/// Not found error (resource doesn't exist)
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Resource not found.';
}

/// Unexpected error (unknown error)
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'An unexpected error occurred. Please try again.';
}

/// Conflict error (duplicate, concurrent modification)
class ConflictFailure extends Failure {
  const ConflictFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'This action conflicts with existing data.';
}

/// Timeout error
class TimeoutFailure extends Failure {
  const TimeoutFailure(super.message, [super.stackTrace]);

  @override
  String get userMessage => 'Request timed out. Please try again.';
}
