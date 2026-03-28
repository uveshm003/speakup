import 'package:equatable/equatable.dart';

sealed class TimerEvent extends Equatable {
  const TimerEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class TimerDurationSelected extends TimerEvent {
  const TimerDurationSelected(this.seconds);

  final int seconds;

  @override
  List<Object?> get props => <Object?>[seconds];
}

final class TimerStarted extends TimerEvent {
  const TimerStarted();
}

final class TimerTicked extends TimerEvent {
  const TimerTicked(this.remaining);

  final int remaining;

  @override
  List<Object?> get props => <Object?>[remaining];
}

final class TimerPaused extends TimerEvent {
  const TimerPaused();
}

final class TimerResumed extends TimerEvent {
  const TimerResumed();
}

final class TimerStopped extends TimerEvent {
  const TimerStopped();
}

final class TimerCompleted extends TimerEvent {
  const TimerCompleted();
}
