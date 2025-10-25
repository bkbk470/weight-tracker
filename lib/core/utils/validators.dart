import '../constants/app_constants.dart';
import 'extensions/string_extension.dart';

/// Form validators for the application
class Validators {
  Validators._();

  /// Validate email address
  static String? email(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Email is required';
    }
    if (!value!.trim().isValidEmail) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validate password
  static String? password(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Password is required';
    }
    if (value!.length < ValidationConstants.minPasswordLength) {
      return 'Password must be at least ${ValidationConstants.minPasswordLength} characters';
    }
    return null;
  }

  /// Validate password confirmation
  static String? passwordConfirmation(String? value, String password) {
    if (value.isNullOrWhitespace) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }

  /// Validate required field
  static String? required(String? value, {String? fieldName}) {
    if (value.isNullOrWhitespace) {
      return '${fieldName ?? 'This field'} is required';
    }
    return null;
  }

  /// Validate exercise name
  static String? exerciseName(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Exercise name is required';
    }
    final trimmed = value!.trim();
    if (trimmed.length < ValidationConstants.minExerciseNameLength) {
      return 'Exercise name must be at least ${ValidationConstants.minExerciseNameLength} characters';
    }
    if (trimmed.length > ValidationConstants.maxExerciseNameLength) {
      return 'Exercise name must be less than ${ValidationConstants.maxExerciseNameLength} characters';
    }
    return null;
  }

  /// Validate workout name
  static String? workoutName(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Workout name is required';
    }
    final trimmed = value!.trim();
    if (trimmed.length < ValidationConstants.minWorkoutNameLength) {
      return 'Workout name must be at least ${ValidationConstants.minWorkoutNameLength} characters';
    }
    if (trimmed.length > ValidationConstants.maxWorkoutNameLength) {
      return 'Workout name must be less than ${ValidationConstants.maxWorkoutNameLength} characters';
    }
    return null;
  }

  /// Validate notes field
  static String? notes(String? value) {
    if (value != null && value.length > ValidationConstants.maxNotesLength) {
      return 'Notes must be less than ${ValidationConstants.maxNotesLength} characters';
    }
    return null;
  }

  /// Validate positive number
  static String? positiveNumber(String? value, {String? fieldName}) {
    if (value.isNullOrWhitespace) {
      return '${fieldName ?? 'This field'} is required';
    }
    final number = double.tryParse(value!);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number <= 0) {
      return '${fieldName ?? 'This field'} must be greater than 0';
    }
    return null;
  }

  /// Validate non-negative number
  static String? nonNegativeNumber(String? value, {String? fieldName}) {
    if (value.isNullOrWhitespace) {
      return '${fieldName ?? 'This field'} is required';
    }
    final number = double.tryParse(value!);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < 0) {
      return '${fieldName ?? 'This field'} cannot be negative';
    }
    return null;
  }

  /// Validate weight value
  static String? weight(String? value) {
    if (value.isNullOrWhitespace) {
      return null; // Weight is optional
    }
    final weight = int.tryParse(value!);
    if (weight == null) {
      return 'Please enter a valid weight';
    }
    if (weight < 0) {
      return 'Weight cannot be negative';
    }
    if (weight > AppConstants.maxWeight) {
      return 'Weight cannot exceed ${AppConstants.maxWeight}';
    }
    return null;
  }

  /// Validate reps value
  static String? reps(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Reps is required';
    }
    final reps = int.tryParse(value!);
    if (reps == null) {
      return 'Please enter a valid number';
    }
    if (reps <= 0) {
      return 'Reps must be greater than 0';
    }
    if (reps > AppConstants.maxReps) {
      return 'Reps cannot exceed ${AppConstants.maxReps}';
    }
    return null;
  }

  /// Validate rest time
  static String? restTime(String? value) {
    if (value.isNullOrWhitespace) {
      return 'Rest time is required';
    }
    final time = int.tryParse(value!);
    if (time == null) {
      return 'Please enter a valid number';
    }
    if (time < AppConstants.minRestTime) {
      return 'Rest time cannot be less than ${AppConstants.minRestTime}';
    }
    if (time > AppConstants.maxRestTime) {
      return 'Rest time cannot exceed ${AppConstants.maxRestTime} seconds';
    }
    return null;
  }

  /// Validate number in range
  static String? numberInRange(
    String? value,
    int min,
    int max, {
    String? fieldName,
  }) {
    if (value.isNullOrWhitespace) {
      return '${fieldName ?? 'This field'} is required';
    }
    final number = int.tryParse(value!);
    if (number == null) {
      return 'Please enter a valid number';
    }
    if (number < min || number > max) {
      return '${fieldName ?? 'Value'} must be between $min and $max';
    }
    return null;
  }

  /// Validate phone number
  static String? phoneNumber(String? value) {
    if (value.isNullOrWhitespace) {
      return null; // Phone is optional
    }
    if (!value!.trim().isValidPhoneNumber) {
      return 'Please enter a valid phone number';
    }
    return null;
  }

  /// Validate URL
  static String? url(String? value) {
    if (value.isNullOrWhitespace) {
      return null; // URL is optional
    }
    final urlPattern = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    if (!urlPattern.hasMatch(value!)) {
      return 'Please enter a valid URL';
    }
    return null;
  }

  /// Combine multiple validators
  static String? combine(List<String? Function(String?)> validators, String? value) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }
}
