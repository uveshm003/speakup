import 'package:equatable/equatable.dart';

import 'package:speakup/features/settings/domain/entities/user_settings.dart';

enum SettingsStatus { initial, loading, success, failure }

class SettingsState extends Equatable {
  const SettingsState({this.status = SettingsStatus.initial, this.settings = const UserSettings(), this.errorMessage});

  final SettingsStatus status;
  final UserSettings settings;
  final String? errorMessage;

  SettingsState copyWith({SettingsStatus? status, UserSettings? settings, String? errorMessage, bool clearErrorMessage = false}) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, settings, errorMessage];
}
