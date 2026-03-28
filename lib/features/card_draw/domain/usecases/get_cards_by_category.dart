import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

class GetCardsByCategory {
  const GetCardsByCategory(this._repository);

  final CardRepository _repository;

  Future<Either<Failure, List<TopicCard>>> call(String category) {
    return _repository.getByCategory(category);
  }
}
