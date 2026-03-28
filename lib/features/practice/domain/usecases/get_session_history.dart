import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';

class GetSessionHistory {
  const GetSessionHistory(this._repository);

  final SessionRepository _repository;

  Future<Either<Failure, List<PracticeSession>>> call() {
    return _repository.getAllSessions();
  }
}
