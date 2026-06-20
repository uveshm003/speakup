import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_event.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_state.dart';

class MockCardRepository extends Mock implements CardRepository {}

TopicCard _card(
  String id, {
  String category = 'General',
  Difficulty difficulty = Difficulty.beginner,
  bool isCustom = false,
  String? customCategoryId,
  bool isFavorite = false,
}) {
  return TopicCard(
    cardId: id,
    title: 'Card $id',
    category: category,
    difficulty: difficulty,
    guide: const <String>['point'],
    vocabBoost: const <VocabWord>[],
    isCustom: isCustom,
    isFavorite: isFavorite,
    createdAt: DateTime(2026, 1, 1),
    customCategoryId: customCategoryId,
  );
}

void main() {
  late MockCardRepository repository;

  setUp(() {
    repository = MockCardRepository();
  });

  CardDrawBloc buildBloc() => CardDrawBloc(cardRepository: repository);

  group('CardDrawBloc - draw', () {
    blocTest<CardDrawBloc, CardDrawState>(
      'emits [loading, success] and increments drawCount on a successful draw',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => Right<Failure, List<TopicCard>>(<TopicCard>[_card('a')]));
        return buildBloc();
      },
      act: (CardDrawBloc bloc) => bloc.add(const CardDrawRequested()),
      expect: () => <Matcher>[
        isA<CardDrawState>().having((CardDrawState s) => s.status, 'status', CardDrawStatus.loading),
        isA<CardDrawState>()
            .having((CardDrawState s) => s.status, 'status', CardDrawStatus.success)
            .having((CardDrawState s) => s.currentCard?.cardId, 'currentCard', 'a')
            .having((CardDrawState s) => s.drawCount, 'drawCount', 1),
      ],
    );

    blocTest<CardDrawBloc, CardDrawState>(
      'emits [loading, empty] when no card matches the filters',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => Right<Failure, List<TopicCard>>(<TopicCard>[_card('a', category: 'General')]));
        return buildBloc();
      },
      act: (CardDrawBloc bloc) => bloc.add(const CardDrawRequested(category: 'Nonexistent')),
      expect: () => <Matcher>[
        isA<CardDrawState>().having((CardDrawState s) => s.status, 'status', CardDrawStatus.loading),
        isA<CardDrawState>()
            .having((CardDrawState s) => s.status, 'status', CardDrawStatus.empty)
            .having((CardDrawState s) => s.currentCard, 'currentCard', isNull),
      ],
    );

    blocTest<CardDrawBloc, CardDrawState>(
      'emits [loading, failure] with a message when the repository fails',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => const Left<Failure, List<TopicCard>>(CacheFailure('disk error')));
        return buildBloc();
      },
      act: (CardDrawBloc bloc) => bloc.add(const CardDrawRequested()),
      expect: () => <Matcher>[
        isA<CardDrawState>().having((CardDrawState s) => s.status, 'status', CardDrawStatus.loading),
        isA<CardDrawState>()
            .having((CardDrawState s) => s.status, 'status', CardDrawStatus.failure)
            .having((CardDrawState s) => s.errorMessage, 'errorMessage', 'disk error'),
      ],
    );

    blocTest<CardDrawBloc, CardDrawState>(
      'honours a custom:<id> category filter',
      build: () {
        when(() => repository.getAll()).thenAnswer(
          (_) async => Right<Failure, List<TopicCard>>(<TopicCard>[
            _card('builtin'),
            _card('mine', isCustom: true, customCategoryId: 'cat1'),
          ]),
        );
        return buildBloc();
      },
      act: (CardDrawBloc bloc) => bloc.add(const CardDrawRequested(category: 'custom:cat1')),
      expect: () => <Matcher>[
        isA<CardDrawState>().having((CardDrawState s) => s.status, 'status', CardDrawStatus.loading),
        isA<CardDrawState>()
            .having((CardDrawState s) => s.status, 'status', CardDrawStatus.success)
            .having((CardDrawState s) => s.currentCard?.cardId, 'currentCard', 'mine'),
      ],
    );
  });

  group('CardDrawBloc - favorite toggle', () {
    blocTest<CardDrawBloc, CardDrawState>(
      'updates the current card when its favorite is toggled',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => Right<Failure, List<TopicCard>>(<TopicCard>[_card('a')]));
        when(() => repository.toggleFavorite('a')).thenAnswer((_) async => Right<Failure, TopicCard>(_card('a', isFavorite: true)));
        return buildBloc();
      },
      act: (CardDrawBloc bloc) async {
        bloc.add(const CardDrawRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CardFavoriteToggled('a'));
      },
      skip: 2,
      expect: () => <Matcher>[
        isA<CardDrawState>().having((CardDrawState s) => s.isFavorite, 'isFavorite', true),
      ],
    );

    blocTest<CardDrawBloc, CardDrawState>(
      'ignores a toggle for a card that is not the current one',
      build: () {
        when(() => repository.getAll()).thenAnswer((_) async => Right<Failure, List<TopicCard>>(<TopicCard>[_card('a')]));
        return buildBloc();
      },
      act: (CardDrawBloc bloc) async {
        bloc.add(const CardDrawRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const CardFavoriteToggled('other'));
      },
      skip: 2,
      expect: () => <Matcher>[],
      verify: (_) => verifyNever(() => repository.toggleFavorite(any())),
    );
  });
}
