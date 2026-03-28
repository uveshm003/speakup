import 'package:flutter_bloc/flutter_bloc.dart';

import 'practice_event.dart';
import 'practice_state.dart';

class PracticeBloc extends Bloc<PracticeEvent, PracticeState> {
  PracticeBloc() : super(const PracticeInitial());
}
