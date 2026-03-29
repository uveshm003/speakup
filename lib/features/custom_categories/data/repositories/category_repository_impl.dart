import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/data/models/topic_card_entity.dart';
import 'package:speakup/features/custom_categories/data/mappers/custom_category_mapper.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';
import 'package:speakup/objectbox.g.dart';

class CategoryRepositoryImpl implements CategoryRepository {
  CategoryRepositoryImpl(this._store);

  final Store _store;

  Box<CustomCategoryEntity> get _catBox => _store.box<CustomCategoryEntity>();
  Box<TopicCardEntity> get _cardBox => _store.box<TopicCardEntity>();

  @override
  Future<Either<Failure, List<CustomCategory>>> getAll() async {
    try {
      final List<CustomCategoryEntity> list = _catBox.getAll();
      list.sort((CustomCategoryEntity a, CustomCategoryEntity b) => b.createdAt.compareTo(a.createdAt));
      return Right<Failure, List<CustomCategory>>(list.map(customCategoryFromEntity).toList());
    } catch (e, _) {
      return Left<Failure, List<CustomCategory>>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomCategory>> create(CustomCategory category) async {
    try {
      final CustomCategoryEntity e = customCategoryToEntity(category);
      _catBox.put(e);
      return Right<Failure, CustomCategory>(customCategoryFromEntity(e));
    } catch (e, _) {
      return Left<Failure, CustomCategory>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, CustomCategory>> update(CustomCategory category) async {
    try {
      final Query<CustomCategoryEntity> q = _catBox.query(CustomCategoryEntity_.categoryId.equals(category.categoryId)).build();
      try {
        final CustomCategoryEntity? existing = q.findFirst();
        if (existing == null) {
          return Left<Failure, CustomCategory>(CacheFailure('Category not found: ${category.categoryId}'));
        }
        existing.name = category.name;
        existing.iconEmoji = category.iconEmoji;
        _catBox.put(existing);
        return Right<Failure, CustomCategory>(customCategoryFromEntity(existing));
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, CustomCategory>(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> delete(String categoryId) async {
    try {
      final Query<CustomCategoryEntity> q = _catBox.query(CustomCategoryEntity_.categoryId.equals(categoryId)).build();
      try {
        final CustomCategoryEntity? cat = q.findFirst();
        if (cat == null) {
          return Left<Failure, void>(CacheFailure('Category not found'));
        }
        for (final TopicCardEntity card in cat.cards.toList()) {
          _cardBox.remove(card.id);
        }
        _catBox.remove(cat.id);
        return const Right<Failure, void>(null);
      } finally {
        q.close();
      }
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure(e.toString()));
    }
  }
}
