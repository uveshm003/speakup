import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';

abstract class SettingsRepository {
  Future<Either<Failure, UserSettings>> getSettings();

  Future<Either<Failure, void>> saveSettings(UserSettings settings);

  /// Recomputes streak from saved sessions and persists to settings.
  Future<Either<Failure, void>> updateStreak();
}
