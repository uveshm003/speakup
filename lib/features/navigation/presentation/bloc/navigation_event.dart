import 'package:equatable/equatable.dart';

sealed class NavigationEvent extends Equatable {
  const NavigationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// User selected a main tab (0–3).
final class NavigationTabSelected extends NavigationEvent {
  const NavigationTabSelected(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}

/// Sync tab highlight from GoRouter / [StatefulNavigationShell] (e.g. deep link).
final class NavigationRouteSynced extends NavigationEvent {
  const NavigationRouteSynced(this.index);

  final int index;

  @override
  List<Object?> get props => <Object?>[index];
}
