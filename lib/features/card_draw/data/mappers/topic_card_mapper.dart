import 'dart:convert';

import 'package:speakup/features/card_draw/data/models/topic_card_entity.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';

TopicCard topicCardFromEntity(TopicCardEntity e) {
  final String? customCategoryId = e.customCategory.target?.categoryId;
  return TopicCard(
    cardId: e.cardId,
    title: e.title,
    category: e.category,
    difficulty: difficultyFromRaw(e.difficultyRaw),
    guide: List<String>.from(jsonDecode(e.guideJson) as List<dynamic>),
    vocabBoost: _parseVocab(e.vocabJson),
    isCustom: e.isCustom,
    isFavorite: e.isFavorite,
    createdAt: e.createdAt,
    customCategoryId: customCategoryId,
  );
}

List<VocabWord> _parseVocab(String vocabJson) {
  final List<dynamic> list = jsonDecode(vocabJson) as List<dynamic>;
  return list.map((dynamic e) {
    final Map<String, dynamic> m = e as Map<String, dynamic>;
    return VocabWord(word: m['word']! as String, meaning: m['meaning']! as String);
  }).toList();
}

TopicCardEntity topicCardToEntity(TopicCard card, {int id = 0}) {
  final TopicCardEntity e = TopicCardEntity(
    id: id,
    cardId: card.cardId,
    title: card.title,
    category: card.category,
    difficultyRaw: card.difficulty.raw,
    guideJson: jsonEncode(card.guide),
    vocabJson: jsonEncode(card.vocabBoost.map((VocabWord v) => <String, String>{'word': v.word, 'meaning': v.meaning}).toList()),
    isCustom: card.isCustom,
    isFavorite: card.isFavorite,
    createdAt: card.createdAt,
  );
  return e;
}
