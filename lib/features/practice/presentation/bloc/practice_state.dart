import 'package:equatable/equatable.dart';

sealed class PracticeState extends Equatable {
  const PracticeState();

  @override
  List<Object?> get props => const <Object?>[];
}

final class PracticeInitial extends PracticeState {
  const PracticeInitial();
}
