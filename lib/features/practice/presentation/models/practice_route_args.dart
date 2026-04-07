import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

/// [GoRouter] extra for `/home/active-practice`.
class ActivePracticeArgs {
  const ActivePracticeArgs({required this.card, required this.durationSeconds});

  final TopicCard card;
  final int durationSeconds;
}

/// [GoRouter] extra for `/home/session-end`.
class SessionEndRouteArgs {
  const SessionEndRouteArgs({
    required this.card,
    required this.elapsedSeconds,
    required this.wasCompleted,
    this.recordingPath,
  });

  final TopicCard card;
  final int elapsedSeconds;
  final bool wasCompleted;

  /// Absolute path to the .m4a recording saved during this session, or null.
  final String? recordingPath;
}
