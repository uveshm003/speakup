import 'package:equatable/equatable.dart';

sealed class SessionEndEvent extends Equatable {
  const SessionEndEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class SessionEndLoadRequested extends SessionEndEvent {
  const SessionEndLoadRequested();
}
