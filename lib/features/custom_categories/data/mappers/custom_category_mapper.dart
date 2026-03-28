import 'package:speakup/features/custom_categories/data/models/custom_category_entity.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';

CustomCategory customCategoryFromEntity(CustomCategoryEntity e) {
  return CustomCategory(
    categoryId: e.categoryId,
    name: e.name,
    iconEmoji: e.iconEmoji,
    createdAt: e.createdAt,
  );
}

CustomCategoryEntity customCategoryToEntity(
  CustomCategory c, {
  int id = 0,
}) {
  return CustomCategoryEntity(
    id: id,
    categoryId: c.categoryId,
    name: c.name,
    iconEmoji: c.iconEmoji,
    createdAt: c.createdAt,
  );
}
