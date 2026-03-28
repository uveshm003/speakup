/// Pure streak logic from session completion timestamps.
abstract final class StreakCalculator {
  StreakCalculator._();

  /// Counts consecutive calendar days with at least one session, walking back
  /// from the most recent session day.
  static int fromSessionTimes(List<DateTime> completedAts) {
    if (completedAts.isEmpty) {
      return 0;
    }
    final Set<DateTime> days = completedAts.map(_dateOnly).toSet();
    final List<DateTime> sorted = days.toList()..sort((DateTime a, DateTime b) => b.compareTo(a));
    final DateTime mostRecent = sorted.first;
    int streak = 0;
    DateTime cursor = mostRecent;
    while (days.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  static DateTime? mostRecentSessionTime(List<DateTime> completedAts) {
    if (completedAts.isEmpty) {
      return null;
    }
    return completedAts.reduce(
      (DateTime a, DateTime b) => a.isAfter(b) ? a : b,
    );
  }

  static DateTime _dateOnly(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }
}
