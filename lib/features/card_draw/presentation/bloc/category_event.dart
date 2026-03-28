import 'package:equatable/equatable.dart';

import 'category_state.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

final class CategoryLoadRequested extends CategoryEvent {
  const CategoryLoadRequested();
}

/// `null` = All categories.
final class CategoryFilterChanged extends CategoryEvent {
  const CategoryFilterChanged(this.categoryKey);

  final String? categoryKey;

  @override
  List<Object?> get props => <Object?>[categoryKey];
}

final class DifficultyFilterChanged extends CategoryEvent {
  const DifficultyFilterChanged(this.filter);

  final DifficultyFilter filter;

  @override
  List<Object?> get props => <Object?>[filter];
}
