import 'package:fpdart/fpdart.dart';
import 'package:speakup/core/errors/failures.dart';

import '../entities/challenge_progress.dart';

abstract interface class ChallengeRepository {
  /// Load all persisted progress entries. Returns an empty map if none enrolled.
  Future<Either<Failure, Map<String, ChallengeProgress>>> getAllProgress();

  /// Persist enrolment for [challengeId].
  Future<Either<Failure, void>> enrol(String challengeId);

  /// Mark the current day as complete for [challengeId].
  Future<Either<Failure, void>> markDayComplete(
    String challengeId,
    int day,
    int totalDays,
  );

  /// Remove the challenge enrolment entirely.
  Future<Either<Failure, void>> abandon(String challengeId);
}
