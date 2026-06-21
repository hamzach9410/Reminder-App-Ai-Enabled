import 'dart:math';

/// CronEngine handles the logic for recurring reminders using a simplified CRON-like format.
/// Format: "minute hour day month dayOfWeek" (e.g., "0 9 * * 1" for 9:00 AM every Monday)
class CronEngine {
  /// Calculates the next execution timestamp based on a rule and current (or specific) time.
  /// @param rule CRON rule string
  /// @param fromDate Starting date for calculation (defaults to now)
  /// @returns Next DateTime or a date 24 hours in the future if invalid.
  static DateTime getNextRunAt(String rule, [DateTime? fromDate]) {
    final now = fromDate ?? DateTime.now();
    final parts = rule.split(' ');
    
    if (parts.length != 5) {
      return now.add(const Duration(hours: 24)); // Fallback
    }

    final min = parts[0];
    final hour = parts[1];
    final day = parts[2];
    final month = parts[3];
    final dayOfWeek = parts[4];

    DateTime next = now.copyWith(second: 0, millisecond: 0, microsecond: 0);

    // Keep advancing time by 1 minute until all criteria match
    // Simple but robust approach for client-side usage (max 1 year search)
    final limit = next.add(const Duration(days: 366));

    while (next.isBefore(limit)) {
      next = next.add(const Duration(minutes: 1));

      if (!_match(next.minute, min)) continue;
      if (!_match(next.hour, hour)) continue;
      if (!_match(next.day, day)) continue;
      if (!_match(next.month, month)) continue;
      // DateTime.weekday is 1 (Mon) to 7 (Sun). 
      // NoteWise/CRON usually uses 0-6 (Sun-Sat).
      // We adjust to match CRON: 0=Sunday, 1=Monday, ..., 6=Saturday
      final cronWeekday = next.weekday % 7;
      if (!_match(cronWeekday, dayOfWeek)) continue;

      return next;
    }

    return now.add(const Duration(hours: 24)); // Fallback
  }

  static bool _match(int value, String pattern) {
    if (pattern == '*') return true;

    // Support lists: "1,3,5"
    if (pattern.contains(',')) {
      return pattern.split(',').map(int.parse).contains(value);
    }

    // Support ranges: "1-5"
    if (pattern.contains('-')) {
      final parts = pattern.split('-').map(int.parse).toList();
      return value >= parts[0] && value <= parts[1];
    }

    // Support intervals: "*/5"
    if (pattern.startsWith('*/')) {
      final interval = int.parse(pattern.replaceAll('*/', ''));
      return value % interval == 0;
    }

    // Exact match
    return int.tryParse(pattern) == value;
  }

  /// Helper to generate a rule from user-friendly parameters.
  static String generateRule({
    required String type, // 'daily', 'weekly', 'monthly'
    required DateTime time,
    List<int>? days, // 0-6 for weekly
    int? dayOfMonth, // 1-31 for monthly
  }) {
    final m = time.minute;
    final h = time.hour;

    switch (type) {
      case 'daily':
        return '$m $h * * *';
      case 'weekly':
        final d = (days ?? [time.weekday % 7]).join(',');
        return '$m $h * * $d';
      case 'monthly':
        final dom = dayOfMonth ?? time.day;
        return '$m $h $dom * *';
      default:
        return '$m $h * * *';
    }
  }
}

extension on DateTime {
  DateTime copyWith({
    int? year,
    int? month,
    int? day,
    int? hour,
    int? minute,
    int? second,
    int? millisecond,
    int? microsecond,
  }) {
    return DateTime(
      year ?? this.year,
      month ?? this.month,
      day ?? this.day,
      hour ?? this.hour,
      minute ?? this.minute,
      second ?? this.second,
      millisecond ?? this.millisecond,
      microsecond ?? this.microsecond,
    );
  }
}
