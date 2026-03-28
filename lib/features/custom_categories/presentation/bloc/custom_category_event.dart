import 'package:equatable/equatable.dart';

import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';

sealed class CustomCategoryEvent extends Equatable {
  const CustomCategoryEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CategoriesLoadRequested extends CustomCategoryEvent {
  const CategoriesLoadRequested();
}

final class CategoryCreateRequested extends CustomCategoryEvent {
  const CategoryCreateRequested({required this.name, required this.emoji});

  final String name;
  final String emoji;

  @override
  List<Object?> get props => <Object?>[name, emoji];
}

final class CategoryUpdateRequested extends CustomCategoryEvent {
  const CategoryUpdateRequested(this.category);

  final CustomCategory category;

  @override
  List<Object?> get props => <Object?>[category];
}

final class CategoryDeleteRequested extends CustomCategoryEvent {
  const CategoryDeleteRequested(this.categoryId);

  final String categoryId;

  @override
  List<Object?> get props => <Object?>[categoryId];
}

final class CategoryDeleteUndoRequested extends CustomCategoryEvent {
  const CategoryDeleteUndoRequested();
}

final class CategoryDeleteCommitted extends CustomCategoryEvent {
  const CategoryDeleteCommitted();
}
