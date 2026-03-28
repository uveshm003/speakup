import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';

/// Route [extra] for [CardDetailScreen]: supports legacy [TopicCard] only or [card] + optional [drawBloc].
class CardDetailRouteArgs {
  const CardDetailRouteArgs({
    required this.card,
    this.drawBloc,
  });

  final TopicCard card;
  final CardDrawBloc? drawBloc;

  static TopicCard? cardFromExtra(Object? extra) {
    if (extra == null) {
      return null;
    }
    if (extra is CardDetailRouteArgs) {
      return extra.card;
    }
    if (extra is TopicCard) {
      return extra;
    }
    return null;
  }

  static CardDrawBloc? drawBlocFromExtra(Object? extra) {
    if (extra is CardDetailRouteArgs) {
      return extra.drawBloc;
    }
    return null;
  }
}
