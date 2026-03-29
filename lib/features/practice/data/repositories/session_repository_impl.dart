import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/practice/data/mappers/practice_session_mapper.dart';
import 'package:speakup/features/practice/data/models/practice_session_entity.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/objectbox.g.dart';

class SessionRepositoryImpl implements SessionRepository {
  SessionRepositoryImpl(this._store);

  final Store _store;

  Box<PracticeSessionEntity> get _box => _store.box<PracticeSessionEntity>();

  @override
  Future<Either<Failure, void>> saveSession(PracticeSession session) async {
    try {
      final PracticeSessionEntity e = practiceSessionToEntity(session);
      _box.put(e);
      return const Right<Failure, void>(null);
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PracticeSession>>> getAllSessions() async {
    try {
      final List<PracticeSessionEntity> list = _box.getAll();
      list.sort((PracticeSessionEntity a, PracticeSessionEntity b) => b.completedAt.compareTo(a.completedAt));
      return Right<Failure, List<PracticeSession>>(list.map(practiceSessionFromEntity).toList());
    } catch (e, _) {
      return Left<Failure, List<PracticeSession>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<PracticeSession>>> getSessionsByDateRange({required DateTime start, required DateTime end}) async {
    try {
      final List<PracticeSessionEntity> all = _box.getAll();
      final List<PracticeSessionEntity> filtered = all.where((PracticeSessionEntity e) {
        final DateTime t = e.completedAt;
        return !t.isBefore(start) && !t.isAfter(end);
      }).toList()..sort((PracticeSessionEntity a, PracticeSessionEntity b) => b.completedAt.compareTo(a.completedAt));
      return Right<Failure, List<PracticeSession>>(filtered.map(practiceSessionFromEntity).toList());
    } catch (e, _) {
      return Left<Failure, List<PracticeSession>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllSessions() async {
    try {
      _box.removeAll();
      return const Right<Failure, void>(null);
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async {
    try {
      final Query<PracticeSessionEntity> q = _box.query(PracticeSessionEntity_.sessionId.equals(sessionId)).build();
      try {
        final PracticeSessionEntity? e = q.findFirst();
        if (e == null) {
          return Left<Failure, void>(CacheFailure('Session not found: $sessionId'));
        }
        _box.remove(e.id);
        return const Right<Failure, void>(null);
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }
}
