import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';

abstract class CategoryRepository {
  Future<Either<Failure, List<CustomCategory>>> getAll();

  Future<Either<Failure, CustomCategory>> create(CustomCategory category);

  Future<Either<Failure, CustomCategory>> update(CustomCategory category);

  Future<Either<Failure, void>> delete(String categoryId);
}
