import 'package:flutter_test/flutter_test.dart';
import 'package:speakup/core/utils/streak_calculator.dart';

void main() {
  group('StreakCalculator.fromSessionTimes', () {
    final DateTime now = DateTime(2026, 6, 20, 15);

    test('returns 0 for no sessions', () {
      expect(StreakCalculator.fromSessionTimes(<DateTime>[], now: now), 0);
    });

    test('counts a single day as a streak of 1', () {
      expect(StreakCalculator.fromSessionTimes(<DateTime>[DateTime(2026, 6, 20, 9)], now: now), 1);
    });

    test('collapses multiple sessions on the same day into one', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 20, 8),
        DateTime(2026, 6, 20, 14),
        DateTime(2026, 6, 20, 21),
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 1);
    });

    test('counts consecutive calendar days ending today', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 18, 10),
        DateTime(2026, 6, 19, 10),
        DateTime(2026, 6, 20, 10),
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 3);
    });

    test('a gap breaks the streak; only the most recent run counts', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 10, 10),
        DateTime(2026, 6, 11, 10),
        // gap
        DateTime(2026, 6, 19, 10),
        DateTime(2026, 6, 20, 10),
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 2);
    });

    test('ignores time-of-day and ordering of input', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 20, 23, 59),
        DateTime(2026, 6, 18, 0, 1),
        DateTime(2026, 6, 19, 12),
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 3);
    });

    test('a streak whose last session was yesterday still counts (grace day)', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 18, 10),
        DateTime(2026, 6, 19, 10), // yesterday relative to `now`
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 2);
    });

    test('a lapsed streak (last session older than yesterday) resets to 0', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 15, 10),
        DateTime(2026, 6, 16, 10),
        DateTime(2026, 6, 17, 10), // 3 days before `now` — lapsed
      ];
      expect(StreakCalculator.fromSessionTimes(times, now: now), 0);
    });
  });

  group('StreakCalculator.mostRecentSessionTime', () {
    test('returns null for no sessions', () {
      expect(StreakCalculator.mostRecentSessionTime(<DateTime>[]), isNull);
    });

    test('returns the latest timestamp', () {
      final List<DateTime> times = <DateTime>[
        DateTime(2026, 6, 18, 10),
        DateTime(2026, 6, 20, 8),
        DateTime(2026, 6, 19, 23),
      ];
      expect(StreakCalculator.mostRecentSessionTime(times), DateTime(2026, 6, 20, 8));
    });
  });
}
