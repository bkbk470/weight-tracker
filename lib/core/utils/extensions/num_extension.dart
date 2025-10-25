extension IntExtension on int {
  /// Format as weight (e.g., '135 lbs')
  String toWeightString({String unit = 'lbs'}) {
    return '$this $unit';
  }

  /// Format as time duration (e.g., '2:30')
  String toTimeString() {
    final minutes = this ~/ 60;
    final seconds = this % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Format as ordinal (1st, 2nd, 3rd, etc.)
  String toOrdinal() {
    if (this >= 11 && this <= 13) {
      return '${this}th';
    }
    switch (this % 10) {
      case 1:
        return '${this}st';
      case 2:
        return '${this}nd';
      case 3:
        return '${this}rd';
      default:
        return '${this}th';
    }
  }

  /// Format with leading zeros
  String toStringWithLeadingZeros(int width) {
    return toString().padLeft(width, '0');
  }

  /// Check if number is in range (inclusive)
  bool inRange(int min, int max) {
    return this >= min && this <= max;
  }

  /// Clamp value between min and max
  int clampValue(int min, int max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}

extension DoubleExtension on double {
  /// Format as weight with precision (e.g., '135.5 lbs')
  String toWeightString({String unit = 'lbs', int decimals = 1}) {
    return '${toStringAsFixed(decimals)} $unit';
  }

  /// Format as percentage (e.g., '75.5%')
  String toPercentageString({int decimals = 1}) {
    return '${toStringAsFixed(decimals)}%';
  }

  /// Round to nearest decimal places
  double roundToDecimal(int decimals) {
    final mod = 10.0.pow(decimals);
    return ((this * mod).round().toDouble() / mod);
  }

  /// Check if number is in range (inclusive)
  bool inRange(double min, double max) {
    return this >= min && this <= max;
  }

  /// Clamp value between min and max
  double clampValue(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Check if number is close to another number within tolerance
  bool isCloseTo(double other, {double tolerance = 0.01}) {
    return (this - other).abs() <= tolerance;
  }

  /// Format as volume (weight × reps)
  String toVolumeString({String unit = 'lbs', int decimals = 0}) {
    if (this <= 0) return '0 $unit';
    if (this >= 1000) {
      return '${(this / 1000).toStringAsFixed(1)}k $unit';
    }
    return '${toStringAsFixed(decimals)} $unit';
  }
}

extension NumExtension on num {
  /// Check if number is zero
  bool get isZero => this == 0;

  /// Check if number is positive
  bool get isPositive => this > 0;

  /// Check if number is negative
  bool get isNegative => this < 0;

  /// Get absolute value
  num get absolute => abs();

  /// Format with commas (e.g., 1,234)
  String toFormattedString() {
    final regex = RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))');
    return toString().replaceAllMapped(regex, (match) => '${match[1]},');
  }
}

// Helper extension class for pow function
extension on double {
  double pow(int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}
