import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';

abstract class CardRepository {
  Future<Either<Failure, List<TopicCard>>> getAll();

  Future<Either<Failure, TopicCard>> getByCardId(String cardId);

  Future<Either<Failure, List<TopicCard>>> getByCategory(String category);

  Future<Either<Failure, List<TopicCard>>> getByDifficulty(Difficulty difficulty);

  Future<Either<Failure, List<TopicCard>>> getFavorites();

  Future<Either<Failure, TopicCard>> toggleFavorite(String cardId);

  Future<Either<Failure, TopicCard>> addCustomCard(TopicCard card);

  /// Updates an existing custom card (same [TopicCard.cardId]).
  Future<Either<Failure, TopicCard>> updateCustomCard(TopicCard card);

  Future<Either<Failure, void>> deleteCustomCard(String cardId);

  /// All custom cards linked to the given custom category id.
  Future<Either<Failure, List<TopicCard>>> getByCustomCategoryId(String categoryId);
}
