import 'dart:convert';

import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/data/mappers/topic_card_mapper.dart';
import 'package:speakup/features/card_draw/data/models/topic_card_entity.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/objectbox.g.dart';

class CardRepositoryImpl implements CardRepository {
  CardRepositoryImpl(this._store);

  final Store _store;

  Box<TopicCardEntity> get _box => _store.box<TopicCardEntity>();

  @override
  Future<Either<Failure, List<TopicCard>>> getAll() async {
    try {
      final List<TopicCardEntity> list = _box.getAll();
      return Right<Failure, List<TopicCard>>(
        list.map(topicCardFromEntity).toList(),
      );
    } catch (e, _) {
      return Left<Failure, List<TopicCard>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopicCard>> getByCardId(String cardId) async {
    try {
      final Query<TopicCardEntity> q =
          _box.query(TopicCardEntity_.cardId.equals(cardId)).build();
      try {
        final TopicCardEntity? e = q.findFirst();
        if (e == null) {
          return Left<Failure, TopicCard>(
            CacheFailure('Card not found: $cardId'),
          );
        }
        return Right<Failure, TopicCard>(topicCardFromEntity(e));
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, TopicCard>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TopicCard>>> getByCategory(String category) async {
    try {
      final Query<TopicCardEntity> q = _box
          .query(TopicCardEntity_.category.equals(category))
          .build();
      try {
        final List<TopicCardEntity> list = q.find();
        return Right<Failure, List<TopicCard>>(
          list.map(topicCardFromEntity).toList(),
        );
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, List<TopicCard>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TopicCard>>> getByDifficulty(
    Difficulty difficulty,
  ) async {
    try {
      final Query<TopicCardEntity> q = _box
          .query(TopicCardEntity_.difficultyRaw.equals(difficulty.raw))
          .build();
      try {
        final List<TopicCardEntity> list = q.find();
        return Right<Failure, List<TopicCard>>(
          list.map(topicCardFromEntity).toList(),
        );
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, List<TopicCard>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TopicCard>>> getFavorites() async {
    try {
      final Query<TopicCardEntity> q =
          _box.query(TopicCardEntity_.isFavorite.equals(true)).build();
      try {
        final List<TopicCardEntity> list = q.find();
        return Right<Failure, List<TopicCard>>(
          list.map(topicCardFromEntity).toList(),
        );
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, List<TopicCard>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopicCard>> toggleFavorite(String cardId) async {
    try {
      final Query<TopicCardEntity> q =
          _box.query(TopicCardEntity_.cardId.equals(cardId)).build();
      try {
        final TopicCardEntity? e = q.findFirst();
        if (e == null) {
          return Left<Failure, TopicCard>(
            CacheFailure('Card not found: $cardId'),
          );
        }
        e.isFavorite = !e.isFavorite;
        _box.put(e);
        return Right<Failure, TopicCard>(topicCardFromEntity(e));
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, TopicCard>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<TopicCard>>> getByCustomCategoryId(
    String categoryId,
  ) async {
    try {
      final Query<CustomCategoryEntity> cq = _store
          .box<CustomCategoryEntity>()
          .query(CustomCategoryEntity_.categoryId.equals(categoryId))
          .build();
      try {
        final CustomCategoryEntity? cat = cq.findFirst();
        if (cat == null) {
          return const Right<Failure, List<TopicCard>>(<TopicCard>[]);
        }
        final List<TopicCardEntity> list = cat.cards.toList();
        list.sort(
          (TopicCardEntity a, TopicCardEntity b) =>
              b.createdAt.compareTo(a.createdAt),
        );
        return Right<Failure, List<TopicCard>>(
          list.map(topicCardFromEntity).toList(),
        );
      } finally {
        cq.close();
      }
    } catch (e, _) {
      return Left<Failure, List<TopicCard>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopicCard>> updateCustomCard(TopicCard card) async {
    try {
      final Query<TopicCardEntity> q =
          _box.query(TopicCardEntity_.cardId.equals(card.cardId)).build();
      try {
        final TopicCardEntity? e = q.findFirst();
        if (e == null) {
          return Left<Failure, TopicCard>(
            CacheFailure('Card not found: ${card.cardId}'),
          );
        }
        if (!e.isCustom) {
          return const Left<Failure, TopicCard>(
            CacheFailure('Cannot edit built-in card'),
          );
        }
        e.title = card.title;
        e.category = card.category;
        e.difficultyRaw = card.difficulty.raw;
        e.guideJson = jsonEncode(card.guide);
        e.vocabJson = jsonEncode(
          card.vocabBoost
              .map(
                (VocabWord v) =>
                    <String, String>{'word': v.word, 'meaning': v.meaning},
              )
              .toList(),
        );
        e.isFavorite = card.isFavorite;
        if (card.customCategoryId != null) {
          final Query<CustomCategoryEntity> cq = _store
              .box<CustomCategoryEntity>()
              .query(
                CustomCategoryEntity_.categoryId.equals(card.customCategoryId!),
              )
              .build();
          try {
            final CustomCategoryEntity? cat = cq.findFirst();
            if (cat != null) {
              e.customCategory.target = cat;
            } else {
              e.customCategory.target = null;
            }
          } finally {
            cq.close();
          }
        } else {
          e.customCategory.target = null;
        }
        _box.put(e);
        return Right<Failure, TopicCard>(topicCardFromEntity(e));
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, TopicCard>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, TopicCard>> addCustomCard(TopicCard card) async {
    try {
      final TopicCardEntity entity = topicCardToEntity(card);
      if (card.customCategoryId != null) {
        final Query<CustomCategoryEntity> cq = _store
            .box<CustomCategoryEntity>()
            .query(CustomCategoryEntity_.categoryId.equals(card.customCategoryId!))
            .build();
        try {
          final CustomCategoryEntity? cat = cq.findFirst();
          if (cat != null) {
            entity.customCategory.target = cat;
          }
        } finally {
          cq.close();
        }
      }
      _box.put(entity);
      return Right<Failure, TopicCard>(topicCardFromEntity(entity));
    } catch (e, _) {
      return Left<Failure, TopicCard>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteCustomCard(String cardId) async {
    try {
      final Query<TopicCardEntity> q =
          _box.query(TopicCardEntity_.cardId.equals(cardId)).build();
      try {
        final TopicCardEntity? e = q.findFirst();
        if (e == null) {
          return Left<Failure, void>(CacheFailure('Card not found: $cardId'));
        }
        if (!e.isCustom) {
          return Left<Failure, void>(
            CacheFailure('Cannot delete built-in card'),
          );
        }
        _box.remove(e.id);
        return const Right<Failure, void>(null);
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }
}
