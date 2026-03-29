import 'package:speakup/features/practice/data/models/practice_session_entity.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';

PracticeSession practiceSessionFromEntity(PracticeSessionEntity e) {
  return PracticeSession(
    sessionId: e.sessionId,
    cardId: e.cardId,
    cardTitle: e.cardTitle,
    category: e.category,
    durationSeconds: e.durationSeconds,
    wasCompleted: e.wasCompleted,
    completedAt: e.completedAt,
  );
}

PracticeSessionEntity practiceSessionToEntity(PracticeSession s, {int id = 0}) {
  return PracticeSessionEntity(
    id: id,
    sessionId: s.sessionId,
    cardId: s.cardId,
    cardTitle: s.cardTitle,
    category: s.category,
    durationSeconds: s.durationSeconds,
    wasCompleted: s.wasCompleted,
    completedAt: s.completedAt,
  );
}
