import 'package:equatable/equatable.dart';

sealed class ChallengesEvent extends Equatable {
  const ChallengesEvent();
  @override
  List<Object?> get props => const <Object?>[];
}

final class ChallengesLoadRequested extends ChallengesEvent {
  const ChallengesLoadRequested();
}

final class ChallengeEnrolRequested extends ChallengesEvent {
  const ChallengeEnrolRequested(this.challengeId);
  final String challengeId;
  @override
  List<Object?> get props => <Object?>[challengeId];
}

final class ChallengeDayCompleted extends ChallengesEvent {
  const ChallengeDayCompleted(this.challengeId, this.day, this.totalDays);
  final String challengeId;
  final int day;
  final int totalDays;
  @override
  List<Object?> get props => <Object?>[challengeId, day, totalDays];
}

final class ChallengeAbandoned extends ChallengesEvent {
  const ChallengeAbandoned(this.challengeId);
  final String challengeId;
  @override
  List<Object?> get props => <Object?>[challengeId];
}
