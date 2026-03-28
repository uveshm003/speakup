import 'package:objectbox/objectbox.dart';

@Entity()
class TopicCardEntity {
  TopicCardEntity({
    this.id = 0,
    required this.cardId,
    required this.title,
    required this.category,
    required this.difficultyRaw,
    required this.guideJson,
    required this.vocabJson,
    this.isCustom = false,
    this.isFavorite = false,
    required this.createdAt,
  });

  @Id()
  int id;

  @Unique()
  late String cardId;
  late String title;
  @Index()
  late String category;
  late String difficultyRaw;
  late String guideJson;
  late String vocabJson;
  bool isCustom;
  bool isFavorite;
  @Property(type: PropertyType.dateUtc)
  DateTime createdAt;

  final customCategory = ToOne<CustomCategoryEntity>();
}

@Entity()
class CustomCategoryEntity {
  CustomCategoryEntity({
    this.id = 0,
    required this.categoryId,
    required this.name,
    required this.iconEmoji,
    required this.createdAt,
  });

  @Id()
  int id;

  @Unique()
  late String categoryId;
  late String name;
  late String iconEmoji;
  @Property(type: PropertyType.dateUtc)
  DateTime createdAt;

  @Backlink('customCategory')
  final cards = ToMany<TopicCardEntity>();
}
