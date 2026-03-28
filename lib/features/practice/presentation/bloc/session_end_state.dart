import 'package:equatable/equatable.dart';

import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

enum SessionEndStatus { initial, loading, success, failure }

class SessionEndState extends Equatable {
  const SessionEndState({
    this.status = SessionEndStatus.initial,
    this.card,
    this.elapsedSeconds = 0,
    this.wasCompleted = false,
    this.streak = 0,
    this.streakIncreased = false,
    this.weekSessionsCount = 0,
    this.errorMessage,
  });

  final SessionEndStatus status;
  final TopicCard? card;
  final int elapsedSeconds;
  final bool wasCompleted;
  final int streak;
  final bool streakIncreased;
  final int weekSessionsCount;
  final String? errorMessage;

  SessionEndState copyWith({
    SessionEndStatus? status,
    TopicCard? card,
    int? elapsedSeconds,
    bool? wasCompleted,
    int? streak,
    bool? streakIncreased,
    int? weekSessionsCount,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return SessionEndState(
      status: status ?? this.status,
      card: card ?? this.card,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      wasCompleted: wasCompleted ?? this.wasCompleted,
      streak: streak ?? this.streak,
      streakIncreased: streakIncreased ?? this.streakIncreased,
      weekSessionsCount: weekSessionsCount ?? this.weekSessionsCount,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        card,
        elapsedSeconds,
        wasCompleted,
        streak,
        streakIncreased,
        weekSessionsCount,
        errorMessage,
      ];
}
