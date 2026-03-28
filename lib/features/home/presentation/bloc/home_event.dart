import 'package:equatable/equatable.dart';

sealed class HomeEvent extends Equatable {
  const HomeEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class HomeLoadRequested extends HomeEvent {
  const HomeLoadRequested();
}

final class HomeQuickDrawRequested extends HomeEvent {
  const HomeQuickDrawRequested();
}

final class HomeQuickDrawNavigationConsumed extends HomeEvent {
  const HomeQuickDrawNavigationConsumed();
}
