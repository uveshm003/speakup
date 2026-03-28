import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

class ToggleFavorite {
  const ToggleFavorite(this._repository);

  final CardRepository _repository;

  Future<Either<Failure, TopicCard>> call(String cardId) {
    return _repository.toggleFavorite(cardId);
  }
}
