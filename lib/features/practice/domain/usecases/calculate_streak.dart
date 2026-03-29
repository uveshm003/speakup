import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/core/utils/streak_calculator.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';

class CalculateStreak {
  const CalculateStreak(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, int>> call() async {
    final Either<Failure, List<PracticeSession>> sessions = await _repository.getAllSessions();
    return sessions.map((List<PracticeSession> list) => StreakCalculator.fromSessionTimes(list.map((PracticeSession s) => s.completedAt).toList()));
  }
}
