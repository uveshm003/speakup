import 'dart:convert';

import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_progress.dart';
import 'package:speakup/features/challenges/domain/repositories/challenge_repository.dart';

/// Persists challenge progress as JSON strings in a [Box<String>].
/// Each key is the challenge ID; the value is the JSON-encoded [ChallengeProgress].
/// No Hive adapter / code generation required.
class ChallengeRepositoryImpl implements ChallengeRepository {
  ChallengeRepositoryImpl(this._box);

  final Box<String> _box;

  @override
  Future<Either<Failure, Map<String, ChallengeProgress>>> getAllProgress() async {
    try {
      final Map<String, ChallengeProgress> result = <String, ChallengeProgress>{};
      for (final String key in _box.keys.cast<String>()) {
        final String? raw = _box.get(key);
        if (raw == null) continue;
        try {
          final Map<String, dynamic> map = json.decode(raw) as Map<String, dynamic>;
          result[key] = ChallengeProgress.fromJson(map);
        } catch (_) {
          // Skip corrupted entries silently.
        }
      }
      return Right<Failure, Map<String, ChallengeProgress>>(result);
    } catch (e) {
      return Left<Failure, Map<String, ChallengeProgress>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> enrol(String challengeId, {Map<String, String>? dailyPromptIds}) async {
    try {
      if (_box.containsKey(challengeId)) {
        return const Right<Failure, void>(null); // already enrolled
      }
      final ChallengeProgress progress = ChallengeProgress(
        challengeId: challengeId,
        enrolledAt: DateTime.now(),
        dailyPromptIds: dailyPromptIds ?? const <String, String>{},
      );
      await _box.put(challengeId, json.encode(progress.toJson()));
      return const Right<Failure, void>(null);
    } catch (e) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markDayComplete(String challengeId, int day, int totalDays) async {
    try {
      final String? raw = _box.get(challengeId);
      if (raw == null) {
        return Left<Failure, void>(CacheFailure('Challenge not enrolled'));
      }
      final ChallengeProgress existing = ChallengeProgress.fromJson(json.decode(raw) as Map<String, dynamic>);
      final List<int> updated = List<int>.from(existing.completedDays);
      if (!updated.contains(day)) updated.add(day);
      final bool done = updated.length >= totalDays;
      final ChallengeProgress saved = existing.copyWith(completedDays: updated, isCompleted: done);
      await _box.put(challengeId, json.encode(saved.toJson()));
      return const Right<Failure, void>(null);
    } catch (e) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> abandon(String challengeId) async {
    try {
      await _box.delete(challengeId);
      return const Right<Failure, void>(null);
    } catch (e) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }
}
