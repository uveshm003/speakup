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
