import 'package:equatable/equatable.dart';

class PracticeSession extends Equatable {
  const PracticeSession({
    required this.sessionId,
    required this.cardId,
    required this.cardTitle,
    required this.category,
    required this.durationSeconds,
    required this.wasCompleted,
    required this.completedAt,
  });

  final String sessionId;
  final String cardId;
  final String cardTitle;
  final String category;
  final int durationSeconds;
  final bool wasCompleted;
  final DateTime completedAt;

  @override
  List<Object?> get props => <Object?>[sessionId, cardId, cardTitle, category, durationSeconds, wasCompleted, completedAt];
}
