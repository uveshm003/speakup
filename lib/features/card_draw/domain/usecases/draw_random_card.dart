import 'dart:math';

import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';

class DrawRandomCard {
  DrawRandomCard(this._repository);

  final CardRepository _repository;
  final Random _random = Random();

  Future<Either<Failure, TopicCard>> call() async {
    final Either<Failure, List<TopicCard>> result = await _repository.getAll();
    return result.flatMap((List<TopicCard> cards) {
      if (cards.isEmpty) {
        return Left<Failure, TopicCard>(const FormatFailure('No cards available'));
      }
      return Right<Failure, TopicCard>(cards[_random.nextInt(cards.length)]);
    });
  }
}
