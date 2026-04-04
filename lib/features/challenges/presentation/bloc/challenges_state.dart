import 'package:equatable/equatable.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_progress.dart';

enum ChallengesStatus { initial, loading, success, failure }

class ChallengesState extends Equatable {
  const ChallengesState({this.status = ChallengesStatus.initial, this.progress = const <String, ChallengeProgress>{}, this.errorMessage});

  final ChallengesStatus status;

  /// key: challengeId → progress for enrolled challenges only.
  final Map<String, ChallengeProgress> progress;

  final String? errorMessage;

  ChallengesState copyWith({ChallengesStatus? status, Map<String, ChallengeProgress>? progress, String? errorMessage, bool clearError = false}) {
    return ChallengesState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, progress, errorMessage];
}
