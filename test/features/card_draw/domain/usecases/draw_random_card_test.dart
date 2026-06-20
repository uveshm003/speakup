import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/card_draw/domain/usecases/draw_random_card.dart';
import 'package:speakup/features/card_draw/domain/usecases/get_cards_by_category.dart';

class MockCardRepository extends Mock implements CardRepository {}

TopicCard _card(String id, {String category = 'General'}) {
  return TopicCard(
    cardId: id,
    title: 'Card $id',
    category: category,
    difficulty: Difficulty.beginner,
    guide: const <String>['point'],
    vocabBoost: const <VocabWord>[],
    isCustom: false,
    isFavorite: false,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockCardRepository repository;

  setUp(() {
    repository = MockCardRepository();
  });

  group('DrawRandomCard', () {
    test('returns a FormatFailure when the deck is empty', () async {
      when(() => repository.getAll()).thenAnswer((_) async => const Right<Failure, List<TopicCard>>(<TopicCard>[]));

      final result = await DrawRandomCard(repository)();

      expect(result.isLeft(), isTrue);
      result.match((Failure f) => expect(f, isA<FormatFailure>()), (_) => fail('expected Left'));
    });

    test('propagates a repository failure', () async {
      when(() => repository.getAll()).thenAnswer((_) async => const Left<Failure, List<TopicCard>>(CacheFailure('boom')));

      final result = await DrawRandomCard(repository)();

      expect(result.isLeft(), isTrue);
      result.match((Failure f) => expect(f, isA<CacheFailure>()), (_) => fail('expected Left'));
    });

    test('returns a card drawn from the available deck', () async {
      final List<TopicCard> deck = <TopicCard>[_card('a'), _card('b'), _card('c')];
      when(() => repository.getAll()).thenAnswer((_) async => Right<Failure, List<TopicCard>>(deck));

      // Draw several times; every draw must come from the deck.
      for (int i = 0; i < 20; i++) {
        final result = await DrawRandomCard(repository)();
        expect(result.isRight(), isTrue);
        result.match((_) => fail('expected Right'), (TopicCard c) => expect(deck, contains(c)));
      }
    });
  });

  group('GetCardsByCategory', () {
    test('forwards the category to the repository and returns its result', () async {
      final List<TopicCard> cards = <TopicCard>[_card('a', category: 'Travel')];
      when(() => repository.getByCategory('Travel')).thenAnswer((_) async => Right<Failure, List<TopicCard>>(cards));

      final result = await GetCardsByCategory(repository)('Travel');

      expect(result, Right<Failure, List<TopicCard>>(cards));
      verify(() => repository.getByCategory('Travel')).called(1);
    });

    test('propagates a repository failure', () async {
      when(() => repository.getByCategory(any())).thenAnswer((_) async => const Left<Failure, List<TopicCard>>(CacheFailure()));

      final result = await GetCardsByCategory(repository)('Travel');

      expect(result.isLeft(), isTrue);
    });
  });
}
