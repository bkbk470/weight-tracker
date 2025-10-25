import 'package:intl/intl.dart';

extension DateTimeExtension on DateTime {
  /// Format date as 'Jan 1, 2025'
  String toFormattedDate() {
    return DateFormat('MMM d, y').format(this);
  }

  /// Format time as '2:30 PM'
  String toFormattedTime() {
    return DateFormat('h:mm a').format(this);
  }

  /// Format as 'Jan 1, 2025 2:30 PM'
  String toFormattedDateTime() {
    return DateFormat('MMM d, y h:mm a').format(this);
  }

  /// Format as '2025-01-01'
  String toISODate() {
    return DateFormat('yyyy-MM-dd').format(this);
  }

  /// Check if date is today
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Check if date is yesterday
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Check if date is tomorrow
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Get relative time string (e.g., 'Today', 'Yesterday', '2 days ago')
  String toRelativeTime() {
    if (isToday) return 'Today';
    if (isYesterday) return 'Yesterday';
    if (isTomorrow) return 'Tomorrow';

    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return weeks == 1 ? '1 week ago' : '$weeks weeks ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return months == 1 ? '1 month ago' : '$months months ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return years == 1 ? '1 year ago' : '$years years ago';
    }
  }

  /// Get beginning of day (00:00:00)
  DateTime get startOfDay {
    return DateTime(year, month, day);
  }

  /// Get end of day (23:59:59)
  DateTime get endOfDay {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }

  /// Get beginning of week (Monday)
  DateTime get startOfWeek {
    final daysToSubtract = (weekday - 1) % 7;
    return subtract(Duration(days: daysToSubtract)).startOfDay;
  }

  /// Get end of week (Sunday)
  DateTime get endOfWeek {
    final daysToAdd = (7 - weekday) % 7;
    return add(Duration(days: daysToAdd)).endOfDay;
  }

  /// Get beginning of month
  DateTime get startOfMonth {
    return DateTime(year, month, 1);
  }

  /// Get end of month
  DateTime get endOfMonth {
    return DateTime(year, month + 1, 0, 23, 59, 59, 999);
  }

  /// Check if date is in the same week
  bool isSameWeek(DateTime other) {
    final thisWeekStart = startOfWeek;
    final thisWeekEnd = endOfWeek;
    return other.isAfter(thisWeekStart) && other.isBefore(thisWeekEnd);
  }

  /// Check if date is in the same month
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Check if date is in the same year
  bool isSameYear(DateTime other) {
    return year == other.year;
  }
}
