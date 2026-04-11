import 'package:equatable/equatable.dart';

import 'package:speakup/features/settings/domain/entities/user_settings.dart';

enum SettingsStatus { initial, loading, success, failure }

enum DbActionStatus { idle, loading, success, failure }

/// Which specific DB operation is currently in-flight.
enum DbAction { export, restore, delete }

class SettingsState extends Equatable {
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.settings = const UserSettings(),
    this.errorMessage,
    this.dbActionStatus = DbActionStatus.idle,
    this.dbActionMessage,
    this.activeDbAction,
  });

  final SettingsStatus status;
  final UserSettings settings;
  final String? errorMessage;

  /// Status of the current export / restore / delete operation.
  final DbActionStatus dbActionStatus;
  final String? dbActionMessage;

  /// Which action triggered the current loading state. Null when idle.
  final DbAction? activeDbAction;

  SettingsState copyWith({
    SettingsStatus? status,
    UserSettings? settings,
    String? errorMessage,
    bool clearErrorMessage = false,
    DbActionStatus? dbActionStatus,
    String? dbActionMessage,
    bool clearDbActionMessage = false,
    DbAction? activeDbAction,
    bool clearActiveDbAction = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      settings: settings ?? this.settings,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      dbActionStatus: dbActionStatus ?? this.dbActionStatus,
      dbActionMessage: clearDbActionMessage ? null : (dbActionMessage ?? this.dbActionMessage),
      activeDbAction: clearActiveDbAction ? null : (activeDbAction ?? this.activeDbAction),
    );
  }

  @override
  List<Object?> get props => <Object?>[status, settings, errorMessage, dbActionStatus, dbActionMessage, activeDbAction];
}
