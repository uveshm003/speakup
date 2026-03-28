import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

class GetUserSettings {
  const GetUserSettings(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, UserSettings>> call() {
    return _repository.getSettings();
  }
}
