import 'package:equatable/equatable.dart';

sealed class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SettingsLoadRequested extends SettingsEvent {
  const SettingsLoadRequested();
}

final class DefaultTimerChanged extends SettingsEvent {
  const DefaultTimerChanged(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => <Object?>[seconds];
}

final class SessionHistoryClearRequested extends SettingsEvent {
  const SessionHistoryClearRequested();
}

/// Triggers JSON export + share sheet.
final class DatabaseExportRequested extends SettingsEvent {
  const DatabaseExportRequested();
}

/// Triggers restore from a user-picked JSON [filePath].
final class DatabaseRestoreRequested extends SettingsEvent {
  const DatabaseRestoreRequested(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => <Object?>[filePath];
}

/// Wipes all ObjectBox data and resets Hive settings.
final class DatabaseDeleteRequested extends SettingsEvent {
  const DatabaseDeleteRequested();
}
