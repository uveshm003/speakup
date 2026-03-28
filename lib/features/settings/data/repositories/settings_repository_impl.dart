import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/core/utils/streak_calculator.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/data/mappers/user_settings_mapper.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  SettingsRepositoryImpl(
    this._box,
    this._sessionRepository,
  );

  final Box<UserSettingsHive> _box;
  final SessionRepository _sessionRepository;

  UserSettingsHive _readOrCreateHive() {
    final UserSettingsHive? existing =
        _box.get(AppConstants.hiveUserSettingsKey);
    if (existing != null) {
      return existing;
    }
    final UserSettingsHive created = UserSettingsHive();
    _box.put(AppConstants.hiveUserSettingsKey, created);
    return created;
  }

  @override
  Future<Either<Failure, UserSettings>> getSettings() async {
    try {
      return Right<Failure, UserSettings>(_readOrCreateHive().toDomain());
    } catch (e, _) {
      return Left<Failure, UserSettings>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveSettings(UserSettings settings) async {
    try {
      _box.put(
        AppConstants.hiveUserSettingsKey,
        userSettingsHiveFromDomain(settings),
      );
      return const Right<Failure, void>(null);
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateStreak() async {
    try {
      final Either<Failure, List<PracticeSession>> sessions =
          await _sessionRepository.getAllSessions();
      return await sessions.fold(
        (Failure f) async => Left<Failure, void>(f),
        (List<PracticeSession> list) async {
          final List<DateTime> times =
              list.map((PracticeSession e) => e.completedAt).toList();
          final int streak = StreakCalculator.fromSessionTimes(times);
          final DateTime? last = StreakCalculator.mostRecentSessionTime(times);
          final UserSettings current = _readOrCreateHive().toDomain();
          final UserSettings updated = current.copyWith(
            currentStreak: streak,
            lastSessionDate: last,
          );
          return saveSettings(updated);
        },
      );
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }
}
