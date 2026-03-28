import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';

enum CategoryLoadStatus { initial, loading, success, failure }

enum DifficultyFilter { all, beginner, intermediate, advanced }

extension DifficultyFilterX on DifficultyFilter {
  String get label => switch (this) {
        DifficultyFilter.all => 'All',
        DifficultyFilter.beginner => 'Beginner',
        DifficultyFilter.intermediate => 'Intermediate',
        DifficultyFilter.advanced => 'Advanced',
      };

  Difficulty? get asDifficulty => switch (this) {
        DifficultyFilter.all => null,
        DifficultyFilter.beginner => Difficulty.beginner,
        DifficultyFilter.intermediate => Difficulty.intermediate,
        DifficultyFilter.advanced => Difficulty.advanced,
      };
}

class CategoryListItem extends Equatable {
  const CategoryListItem({
    required this.key,
    required this.displayName,
    required this.emoji,
    required this.accentColor,
    required this.isCustom,
    required this.filteredCount,
    required this.beginnerCount,
    required this.intermediateCount,
    required this.advancedCount,
  });

  final String key;
  final String displayName;
  final String emoji;
  final Color accentColor;
  final bool isCustom;
  final int filteredCount;
  final int beginnerCount;
  final int intermediateCount;
  final int advancedCount;

  @override
  List<Object?> get props => <Object?>[
        key,
        displayName,
        emoji,
        accentColor,
        isCustom,
        filteredCount,
        beginnerCount,
        intermediateCount,
        advancedCount,
      ];
}

class CategoryState extends Equatable {
  const CategoryState({
    this.status = CategoryLoadStatus.initial,
    this.items = const <CategoryListItem>[],
    this.allFilteredCount = 0,
    this.selectedCategoryKey,
    this.difficultyFilter = DifficultyFilter.all,
    this.errorMessage,
  });

  final CategoryLoadStatus status;
  final List<CategoryListItem> items;
  final int allFilteredCount;
  final String? selectedCategoryKey;
  final DifficultyFilter difficultyFilter;
  final String? errorMessage;

  int get selectedFilteredCount {
    if (selectedCategoryKey == null) {
      return allFilteredCount;
    }
    for (final CategoryListItem i in items) {
      if (i.key == selectedCategoryKey) {
        return i.filteredCount;
      }
    }
    return 0;
  }

  bool get canDraw =>
      status == CategoryLoadStatus.success && selectedFilteredCount > 0;

  CategoryState copyWith({
    CategoryLoadStatus? status,
    List<CategoryListItem>? items,
    int? allFilteredCount,
    String? selectedCategoryKey,
    DifficultyFilter? difficultyFilter,
    String? errorMessage,
    bool clearErrorMessage = false,
  }) {
    return CategoryState(
      status: status ?? this.status,
      items: items ?? this.items,
      allFilteredCount: allFilteredCount ?? this.allFilteredCount,
      selectedCategoryKey: selectedCategoryKey ?? this.selectedCategoryKey,
      difficultyFilter: difficultyFilter ?? this.difficultyFilter,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        items,
        allFilteredCount,
        selectedCategoryKey,
        difficultyFilter,
        errorMessage,
      ];
}
