/// Base exception class for all custom exceptions
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalException;

  const AppException(
    this.message, {
    this.code,
    this.originalException,
  });

  @override
  String toString() => 'AppException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Server exception (5xx errors)
class ServerException extends AppException {
  const ServerException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Network exception (connection errors)
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Cache exception (local storage errors)
class CacheException extends AppException {
  const CacheException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Validation exception (invalid input)
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors,
    super.code,
    super.originalException,
  });

  /// Get error for specific field
  String? getFieldError(String field) => fieldErrors?[field];
}

/// Authentication exception
class AuthenticationException extends AppException {
  const AuthenticationException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Authorization exception
class AuthorizationException extends AppException {
  const AuthorizationException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Not found exception
class NotFoundException extends AppException {
  const NotFoundException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Timeout exception
class TimeoutException extends AppException {
  const TimeoutException(
    super.message, {
    super.code,
    super.originalException,
  });
}

/// Conflict exception
class ConflictException extends AppException {
  const ConflictException(
    super.message, {
    super.code,
    super.originalException,
  });
}
