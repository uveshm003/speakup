import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';

/// Debug-only logging for BLoC transitions and errors.
class AppBlocObserver extends BlocObserver {
  @override
  void onCreate(BlocBase<dynamic> bloc) {
    super.onCreate(bloc);
    if (kDebugMode) {
      debugPrint('Bloc created: ${bloc.runtimeType}');
    }
  }

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    if (kDebugMode) {
      debugPrint('${bloc.runtimeType} $transition');
    }
  }

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    if (kDebugMode) {
      debugPrint('Bloc error: ${bloc.runtimeType} $error');
    }
    super.onError(bloc, error, stackTrace);
  }
}
