import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';

/// Used when ObjectBox is unavailable (e.g. web or tests without a store).
class StubCardRepository implements CardRepository {
  const StubCardRepository();

  @override
  Future<Either<Failure, List<TopicCard>>> getAll() async => const Right<Failure, List<TopicCard>>(<TopicCard>[]);

  @override
  Future<Either<Failure, List<TopicCard>>> getByCategory(String category) async => const Right<Failure, List<TopicCard>>(<TopicCard>[]);

  @override
  Future<Either<Failure, List<TopicCard>>> getByDifficulty(Difficulty difficulty) async => const Right<Failure, List<TopicCard>>(<TopicCard>[]);

  @override
  Future<Either<Failure, List<TopicCard>>> getFavorites() async => const Right<Failure, List<TopicCard>>(<TopicCard>[]);

  @override
  Future<Either<Failure, TopicCard>> getByCardId(String cardId) async => Left<Failure, TopicCard>(CacheFailure('Card not found: $cardId'));

  @override
  Future<Either<Failure, TopicCard>> toggleFavorite(String cardId) async => const Left<Failure, TopicCard>(CacheFailure('Cards unavailable'));

  @override
  Future<Either<Failure, TopicCard>> addCustomCard(TopicCard card) async => const Left<Failure, TopicCard>(CacheFailure('Cards unavailable'));

  @override
  Future<Either<Failure, TopicCard>> updateCustomCard(TopicCard card) async => const Left<Failure, TopicCard>(CacheFailure('Cards unavailable'));

  @override
  Future<Either<Failure, List<TopicCard>>> getByCustomCategoryId(String categoryId) async => const Right<Failure, List<TopicCard>>(<TopicCard>[]);

  @override
  Future<Either<Failure, void>> deleteCustomCard(String cardId) async => const Left<Failure, void>(CacheFailure('Cards unavailable'));
}

/// Used when ObjectBox is unavailable (e.g. web or tests without a store).
class StubSessionRepository implements SessionRepository {
  const StubSessionRepository();

  @override
  Future<Either<Failure, void>> saveSession(PracticeSession session) async => const Right<Failure, void>(null);

  @override
  Future<Either<Failure, List<PracticeSession>>> getAllSessions() async => const Right<Failure, List<PracticeSession>>(<PracticeSession>[]);

  @override
  Future<Either<Failure, List<PracticeSession>>> getSessionsByDateRange({required DateTime start, required DateTime end}) async =>
      const Right<Failure, List<PracticeSession>>(<PracticeSession>[]);

  @override
  Future<Either<Failure, void>> deleteSession(String sessionId) async => const Right<Failure, void>(null);

  @override
  Future<Either<Failure, void>> clearAllSessions() async => const Right<Failure, void>(null);
}

/// Used when ObjectBox is unavailable (e.g. web or tests without a store).
class StubCategoryRepository implements CategoryRepository {
  const StubCategoryRepository();

  @override
  Future<Either<Failure, List<CustomCategory>>> getAll() async => const Right<Failure, List<CustomCategory>>(<CustomCategory>[]);

  @override
  Future<Either<Failure, CustomCategory>> create(CustomCategory category) async =>
      const Left<Failure, CustomCategory>(CacheFailure('Categories unavailable'));

  @override
  Future<Either<Failure, CustomCategory>> update(CustomCategory category) async =>
      const Left<Failure, CustomCategory>(CacheFailure('Categories unavailable'));

  @override
  Future<Either<Failure, void>> delete(String categoryId) async => const Left<Failure, void>(CacheFailure('Categories unavailable'));
}
