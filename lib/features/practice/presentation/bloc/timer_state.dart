import 'package:equatable/equatable.dart';

enum TimerStatus {
  initial,
  running,
  paused,
  stopped,
  completed,
}

class TimerState extends Equatable {
  const TimerState({
    this.duration = 120,
    this.remaining = 120,
    this.status = TimerStatus.initial,
  });

  /// Planned session length (seconds).
  final int duration;

  /// Seconds left while running / paused; 0 when completed.
  final int remaining;

  final TimerStatus status;

  TimerState copyWith({
    int? duration,
    int? remaining,
    TimerStatus? status,
  }) {
    return TimerState(
      duration: duration ?? this.duration,
      remaining: remaining ?? this.remaining,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => <Object?>[duration, remaining, status];
}
