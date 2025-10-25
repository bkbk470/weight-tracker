extension StringExtension on String {
  /// Capitalize first letter
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Capitalize first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Check if string is a valid email
  bool get isValidEmail {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Check if string is a valid phone number (basic check)
  bool get isValidPhoneNumber {
    final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
    return phoneRegex.hasMatch(this) && length >= 10;
  }

  /// Check if string is numeric
  bool get isNumeric {
    return double.tryParse(this) != null;
  }

  /// Remove all whitespace
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Truncate string to max length with ellipsis
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Convert to snake_case
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => '_${match.group(0)!.toLowerCase()}',
    ).replaceFirst(RegExp(r'^_'), '');
  }

  /// Convert to camelCase
  String toCamelCase() {
    if (isEmpty) return this;
    final words = split(RegExp(r'[_\s]+'));
    if (words.isEmpty) return this;

    return words.first.toLowerCase() +
        words.skip(1).map((word) => word.capitalize()).join();
  }

  /// Convert to PascalCase
  String toPascalCase() {
    if (isEmpty) return this;
    final words = split(RegExp(r'[_\s]+'));
    return words.map((word) => word.capitalize()).join();
  }

  /// Check if string contains only letters
  bool get isAlpha {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Check if string contains only alphanumeric characters
  bool get isAlphanumeric {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Parse to int safely
  int? toIntOrNull() {
    return int.tryParse(this);
  }

  /// Parse to double safely
  double? toDoubleOrNull() {
    return double.tryParse(this);
  }

  /// Check if string is empty or whitespace only
  bool get isEmptyOrWhitespace {
    return trim().isEmpty;
  }

  /// Reverse string
  String reverse() {
    return split('').reversed.join();
  }

  /// Count occurrences of substring
  int countOccurrences(String substring) {
    if (isEmpty || substring.isEmpty) return 0;
    int count = 0;
    int index = indexOf(substring);
    while (index != -1) {
      count++;
      index = indexOf(substring, index + substring.length);
    }
    return count;
  }

  /// Remove special characters
  String removeSpecialCharacters() {
    return replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '');
  }

  /// Normalize for search/comparison (lowercase, trim, remove special chars)
  String normalize() {
    return toLowerCase().trim().removeSpecialCharacters();
  }
}

extension NullableStringExtension on String? {
  /// Check if string is null or empty
  bool get isNullOrEmpty {
    return this == null || this!.isEmpty;
  }

  /// Check if string is null, empty, or whitespace only
  bool get isNullOrWhitespace {
    return this == null || this!.trim().isEmpty;
  }

  /// Get value or default
  String orDefault(String defaultValue) {
    return this ?? defaultValue;
  }

  /// Get value or empty string
  String get orEmpty {
    return this ?? '';
  }
}
