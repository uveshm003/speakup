import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';

abstract class SessionRepository {
  Future<Either<Failure, void>> saveSession(PracticeSession session);

  Future<Either<Failure, List<PracticeSession>>> getAllSessions();

  Future<Either<Failure, List<PracticeSession>>> getSessionsByDateRange({required DateTime start, required DateTime end});

  Future<Either<Failure, void>> deleteSession(String sessionId);

  /// Removes all practice sessions (used from settings).
  Future<Either<Failure, void>> clearAllSessions();
}
