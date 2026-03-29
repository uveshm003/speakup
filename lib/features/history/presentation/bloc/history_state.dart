import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:speakup/features/practice/domain/entities/practice_session.dart';

enum HistoryStatus { initial, loading, success, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.allSessions = const <PracticeSession>[],
    this.filterRange,
    this.currentStreak = 0,
    this.totalSessions = 0,
    this.totalPracticeMinutes = 0,
    this.pendingDeletion,
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<PracticeSession> allSessions;

  /// Log filter (null = show all in log).
  final DateTimeRange? filterRange;

  final int currentStreak;
  final int totalSessions;
  final int totalPracticeMinutes;

  final PracticeSession? pendingDeletion;
  final String? errorMessage;

  /// Sessions for log (filtered + sorted desc).
  List<PracticeSession> get logSessions {
    List<PracticeSession> list = List<PracticeSession>.from(allSessions);
    final DateTimeRange? r = filterRange;
    if (r != null) {
      final DateTime start = DateTime(r.start.year, r.start.month, r.start.day);
      final DateTime end = DateTime(r.end.year, r.end.month, r.end.day);
      list = list.where((PracticeSession s) {
        final DateTime d = DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
        return !d.isBefore(start) && !d.isAfter(end);
      }).toList();
    }
    list.sort((PracticeSession a, PracticeSession b) => b.completedAt.compareTo(a.completedAt));
    return list;
  }

  /// yyyy-MM-dd -> count (for heatmap, all sessions).
  Map<String, int> get sessionsPerDayKey {
    final Map<String, int> m = <String, int>{};
    for (final PracticeSession s in allSessions) {
      final String k = '${s.completedAt.year}-${s.completedAt.month.toString().padLeft(2, '0')}-${s.completedAt.day.toString().padLeft(2, '0')}';
      m[k] = (m[k] ?? 0) + 1;
    }
    return m;
  }

  HistoryState copyWith({
    HistoryStatus? status,
    List<PracticeSession>? allSessions,
    DateTimeRange? filterRange,
    bool clearFilterRange = false,
    int? currentStreak,
    int? totalSessions,
    int? totalPracticeMinutes,
    PracticeSession? pendingDeletion,
    bool clearPendingDeletion = false,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      allSessions: allSessions ?? this.allSessions,
      filterRange: clearFilterRange ? null : (filterRange ?? this.filterRange),
      currentStreak: currentStreak ?? this.currentStreak,
      totalSessions: totalSessions ?? this.totalSessions,
      totalPracticeMinutes: totalPracticeMinutes ?? this.totalPracticeMinutes,
      pendingDeletion: clearPendingDeletion ? null : (pendingDeletion ?? this.pendingDeletion),
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
    status,
    allSessions,
    filterRange,
    currentStreak,
    totalSessions,
    totalPracticeMinutes,
    pendingDeletion,
    errorMessage,
  ];
}
