import 'package:equatable/equatable.dart';

/// Persisted progress for one enrolled challenge.
class ChallengeProgress extends Equatable {
  const ChallengeProgress({
    required this.challengeId,
    required this.enrolledAt,
    this.completedDays = const <int>[],
    this.isCompleted = false,
  });

  final String challengeId;

  /// Wall-clock datetime when the user enrolled.
  final DateTime enrolledAt;

  /// Zero-indexed day numbers that have been marked complete (0 = day 1).
  final List<int> completedDays;

  /// True once the full challenge duration has been marked done.
  final bool isCompleted;

  // ── Computed helpers ─────────────────────────────────────────────────────

  /// Number of calendar days elapsed since enrolment (0-based).
  int get currentDay => DateTime.now().difference(enrolledAt).inDays;

  /// Whether today's day has already been marked complete.
  bool get todayCompleted => completedDays.contains(currentDay);

  ChallengeProgress copyWith({
    List<int>? completedDays,
    bool? isCompleted,
  }) {
    return ChallengeProgress(
      challengeId: challengeId,
      enrolledAt: enrolledAt,
      completedDays: completedDays ?? this.completedDays,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  // ── JSON serialisation (no build_runner) ─────────────────────────────────

  Map<String, dynamic> toJson() => <String, dynamic>{
        'challengeId': challengeId,
        'enrolledAt': enrolledAt.toIso8601String(),
        'completedDays': completedDays,
        'isCompleted': isCompleted,
      };

  factory ChallengeProgress.fromJson(Map<String, dynamic> map) {
    return ChallengeProgress(
      challengeId: map['challengeId'] as String,
      enrolledAt: DateTime.parse(map['enrolledAt'] as String),
      completedDays: List<int>.from(map['completedDays'] as List<dynamic>),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[challengeId, enrolledAt, completedDays, isCompleted];
}
