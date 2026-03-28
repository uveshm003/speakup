import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';

class CreateCustomCategory {
  const CreateCustomCategory(this._repository);

  final CategoryRepository _repository;

  Future<Either<Failure, CustomCategory>> call(CustomCategory category) {
    return _repository.create(category);
  }
}
