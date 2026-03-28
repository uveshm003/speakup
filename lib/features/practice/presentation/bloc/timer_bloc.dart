import 'dart:async';

import 'package:bloc/bloc.dart';

import 'timer_event.dart';
import 'timer_state.dart';

class TimerBloc extends Bloc<TimerEvent, TimerState> {
  TimerBloc() : super(const TimerState()) {
    on<TimerDurationSelected>(_onDurationSelected);
    on<TimerStarted>(_onStarted);
    on<TimerTicked>(_onTicked);
    on<TimerPaused>(_onPaused);
    on<TimerResumed>(_onResumed);
    on<TimerStopped>(_onStopped);
    on<TimerCompleted>(_onCompleted);
  }

  StreamSubscription<void>? _tickSub;
  int _tickingRemaining = 0;

  void _onDurationSelected(
    TimerDurationSelected event,
    Emitter<TimerState> emit,
  ) {
    if (state.status == TimerStatus.initial || state.status == TimerStatus.stopped) {
      emit(
        state.copyWith(
          duration: event.seconds,
          remaining: event.seconds,
        ),
      );
    }
  }

  Future<void> _onStarted(TimerStarted event, Emitter<TimerState> emit) async {
    await _tickSub?.cancel();
    final int total = state.duration;
    if (total <= 0) {
      return;
    }
    _tickingRemaining = total;
    emit(
      state.copyWith(
        status: TimerStatus.running,
        remaining: total,
      ),
    );
    _tickSub = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      _tickingRemaining--;
      if (_tickingRemaining <= 0) {
        add(const TimerCompleted());
      } else {
        add(TimerTicked(_tickingRemaining));
      }
    });
  }

  void _onTicked(TimerTicked event, Emitter<TimerState> emit) {
    emit(
      state.copyWith(
        remaining: event.remaining,
        status: TimerStatus.running,
      ),
    );
  }

  Future<void> _onPaused(TimerPaused event, Emitter<TimerState> emit) async {
    await _tickSub?.cancel();
    _tickSub = null;
    emit(state.copyWith(status: TimerStatus.paused));
  }

  Future<void> _onResumed(TimerResumed event, Emitter<TimerState> emit) async {
    await _tickSub?.cancel();
    _tickingRemaining = state.remaining;
    if (_tickingRemaining <= 0) {
      add(const TimerCompleted());
      return;
    }
    emit(state.copyWith(status: TimerStatus.running));
    _tickSub = Stream.periodic(const Duration(seconds: 1)).listen((_) {
      _tickingRemaining--;
      if (_tickingRemaining <= 0) {
        add(const TimerCompleted());
      } else {
        add(TimerTicked(_tickingRemaining));
      }
    });
  }

  Future<void> _onStopped(TimerStopped event, Emitter<TimerState> emit) async {
    await _tickSub?.cancel();
    _tickSub = null;
    emit(state.copyWith(status: TimerStatus.stopped));
  }

  Future<void> _onCompleted(TimerCompleted event, Emitter<TimerState> emit) async {
    await _tickSub?.cancel();
    _tickSub = null;
    emit(
      state.copyWith(
        status: TimerStatus.completed,
        remaining: 0,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _tickSub?.cancel();
    return super.close();
  }
}
