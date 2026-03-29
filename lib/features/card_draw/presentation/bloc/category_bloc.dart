import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';
import 'package:speakup/features/home/domain/built_in_categories.dart';

import 'category_event.dart';
import 'category_state.dart';

class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  CategoryBloc({required CardRepository cardRepository, required CategoryRepository categoryRepository, String? initialCategoryKey})
    : _cardRepository = cardRepository,
      _categoryRepository = categoryRepository,
      _initialCategoryKey = initialCategoryKey,
      super(const CategoryState()) {
    on<CategoryLoadRequested>(_onLoad);
    on<CategoryFilterChanged>(_onCategoryFilter);
    on<DifficultyFilterChanged>(_onDifficultyFilter);
  }

  final CardRepository _cardRepository;
  final CategoryRepository _categoryRepository;
  final String? _initialCategoryKey;

  List<TopicCard> _cards = <TopicCard>[];
  List<CustomCategory> _customCats = <CustomCategory>[];

  Color _accentForCustom(String categoryId) {
    final int h = categoryId.hashCode.abs() % 360;
    return HSLColor.fromAHSL(1, h.toDouble(), 0.42, 0.52).toColor();
  }

  bool _isValidSelection(String key) {
    if (key.startsWith('custom:')) {
      final String id = key.substring('custom:'.length);
      return _customCats.any((CustomCategory c) => c.categoryId == id);
    }
    return kBuiltInBrowseCategories.any((BuiltInCategoryDef d) => d.name == key);
  }

  List<TopicCard> _applyDifficulty(List<TopicCard> list, DifficultyFilter filter) {
    final Difficulty? d = filter.asDifficulty;
    if (d == null) {
      return list;
    }
    return list.where((TopicCard c) => c.difficulty == d).toList();
  }

  ({int b, int i, int a}) _difficultyBreakdown(List<TopicCard> raw) {
    int b = 0;
    int i = 0;
    int a = 0;
    for (final TopicCard c in raw) {
      switch (c.difficulty) {
        case Difficulty.beginner:
          b++;
          break;
        case Difficulty.intermediate:
          i++;
          break;
        case Difficulty.advanced:
          a++;
          break;
      }
    }
    return (b: b, i: i, a: a);
  }

  CategoryState _computeState({required String? selectedKey, required DifficultyFilter difficultyFilter}) {
    final List<TopicCard> cards = _cards;
    final List<TopicCard> allFiltered = _applyDifficulty(cards, difficultyFilter);

    final List<CategoryListItem> items = <CategoryListItem>[];

    for (final BuiltInCategoryDef def in kBuiltInBrowseCategories) {
      final List<TopicCard> raw = cards.where((TopicCard c) => !c.isCustom && c.category == def.name).toList();
      final List<TopicCard> filtered = _applyDifficulty(raw, difficultyFilter);
      final ({int b, int i, int a}) br = _difficultyBreakdown(raw);
      items.add(
        CategoryListItem(
          key: def.name,
          displayName: def.name,
          emoji: def.emoji,
          accentColor: def.accentColor,
          isCustom: false,
          filteredCount: filtered.length,
          beginnerCount: br.b,
          intermediateCount: br.i,
          advancedCount: br.a,
        ),
      );
    }

    for (final CustomCategory cc in _customCats) {
      final List<TopicCard> raw = cards.where((TopicCard c) => c.customCategoryId == cc.categoryId).toList();
      final List<TopicCard> filtered = _applyDifficulty(raw, difficultyFilter);
      final ({int b, int i, int a}) br = _difficultyBreakdown(raw);
      final String key = 'custom:${cc.categoryId}';
      items.add(
        CategoryListItem(
          key: key,
          displayName: cc.name,
          emoji: cc.iconEmoji,
          accentColor: _accentForCustom(cc.categoryId),
          isCustom: true,
          filteredCount: filtered.length,
          beginnerCount: br.b,
          intermediateCount: br.i,
          advancedCount: br.a,
        ),
      );
    }

    return CategoryState(
      status: CategoryLoadStatus.success,
      items: items,
      allFilteredCount: allFiltered.length,
      selectedCategoryKey: selectedKey,
      difficultyFilter: difficultyFilter,
      errorMessage: null,
    );
  }

  Future<void> _onLoad(CategoryLoadRequested event, Emitter<CategoryState> emit) async {
    emit(state.copyWith(status: CategoryLoadStatus.loading, clearErrorMessage: true));

    final cardsEither = await _cardRepository.getAll();
    final catsEither = await _categoryRepository.getAll();

    String? failureMessage;
    cardsEither.fold((l) => failureMessage ??= l.message, (_) {});
    catsEither.fold((l) => failureMessage ??= l.message, (_) {});

    if (failureMessage != null) {
      emit(CategoryState(status: CategoryLoadStatus.failure, errorMessage: failureMessage, difficultyFilter: state.difficultyFilter));
      return;
    }

    _cards = cardsEither.fold((l) => throw StateError(''), (r) => r);
    _customCats = catsEither.fold((l) => throw StateError(''), (r) => r);

    String? selected = _initialCategoryKey;
    if (selected != null && !_isValidSelection(selected)) {
      selected = null;
    }

    emit(_computeState(selectedKey: selected, difficultyFilter: DifficultyFilter.all));
  }

  void _onCategoryFilter(CategoryFilterChanged event, Emitter<CategoryState> emit) {
    if (state.status != CategoryLoadStatus.success) {
      return;
    }
    emit(_computeState(selectedKey: event.categoryKey, difficultyFilter: state.difficultyFilter));
  }

  void _onDifficultyFilter(DifficultyFilterChanged event, Emitter<CategoryState> emit) {
    if (state.status != CategoryLoadStatus.success) {
      return;
    }
    emit(_computeState(selectedKey: state.selectedCategoryKey, difficultyFilter: event.filter));
  }
}
