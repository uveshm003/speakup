import 'package:flutter_bloc/flutter_bloc.dart';

import 'navigation_event.dart';
import 'navigation_state.dart';

/// Drives main-tab highlight state; keep in sync with [StatefulNavigationShell].
class NavigationBloc extends Bloc<NavigationEvent, NavigationState> {
  NavigationBloc() : super(const NavigationState()) {
    on<NavigationTabSelected>(_onTabSelected);
    on<NavigationRouteSynced>(_onRouteSynced);
  }

  void _onTabSelected(NavigationTabSelected event, Emitter<NavigationState> emit) {
    if (event.index < 0 || event.index > 3) {
      return;
    }
    emit(NavigationState(selectedIndex: event.index));
  }

  void _onRouteSynced(NavigationRouteSynced event, Emitter<NavigationState> emit) {
    if (event.index < 0 || event.index > 3) {
      return;
    }
    if (event.index == state.selectedIndex) {
      return;
    }
    emit(NavigationState(selectedIndex: event.index));
  }
}
