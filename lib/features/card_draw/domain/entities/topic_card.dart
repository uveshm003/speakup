import 'package:equatable/equatable.dart';

import 'difficulty.dart';
import 'vocab_word.dart';

class TopicCard extends Equatable {
  const TopicCard({
    required this.cardId,
    required this.title,
    required this.category,
    required this.difficulty,
    required this.guide,
    required this.vocabBoost,
    required this.isCustom,
    required this.isFavorite,
    required this.createdAt,
    this.customCategoryId,
  });

  final String cardId;
  final String title;
  final String category;
  final Difficulty difficulty;
  final List<String> guide;
  final List<VocabWord> vocabBoost;
  final bool isCustom;
  final bool isFavorite;
  final DateTime createdAt;

  /// When [isCustom], links to [CustomCategory.categoryId] if assigned.
  final String? customCategoryId;

  @override
  List<Object?> get props => <Object?>[
        cardId,
        title,
        category,
        difficulty,
        guide,
        vocabBoost,
        isCustom,
        isFavorite,
        createdAt,
        customCategoryId,
      ];
}
