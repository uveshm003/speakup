import 'package:objectbox/objectbox.dart';

@Entity()
class PracticeSessionEntity {
  PracticeSessionEntity({
    this.id = 0,
    required this.sessionId,
    required this.cardId,
    required this.cardTitle,
    required this.category,
    required this.durationSeconds,
    required this.wasCompleted,
    required this.completedAt,
  });

  @Id()
  int id;

  @Unique()
  late String sessionId;
  late String cardId;
  late String cardTitle;
  @Index()
  late String category;
  int durationSeconds;
  bool wasCompleted;
  @Index()
  @Property(type: PropertyType.dateUtc)
  DateTime completedAt;
}
