import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';

class UpdateUserSettings {
  const UpdateUserSettings(this._repository);

  final SettingsRepository _repository;

  Future<Either<Failure, UserSettings>> call(UserSettings settings) async {
    final Either<Failure, void> saved = await _repository.saveSettings(settings);
    return await saved.fold<Future<Either<Failure, UserSettings>>>(
      (Failure l) async => Left<Failure, UserSettings>(l),
      (_) async => _repository.getSettings(),
    );
  }
}
