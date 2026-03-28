import 'package:equatable/equatable.dart';

import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';

enum CustomCategoryStatus { initial, loading, success, failure }

class CustomCategoryState extends Equatable {
  const CustomCategoryState({
    this.categories = const <CustomCategory>[],
    this.cardCounts = const <String, int>{},
    this.status = CustomCategoryStatus.initial,
    this.errorMessage,
    this.pendingDeletion,
    this.opSeq = 0,
  });

  final List<CustomCategory> categories;

  /// Cards per custom category id (from [CardRepository.getAll] counts).
  final Map<String, int> cardCounts;

  final CustomCategoryStatus status;
  final String? errorMessage;

  /// Set while the user can still undo a delete (before [CategoryDeleteCommitted]).
  final CustomCategory? pendingDeletion;

  /// Incremented after each successful create/update (for UI listeners).
  final int opSeq;

  CustomCategoryState copyWith({
    List<CustomCategory>? categories,
    Map<String, int>? cardCounts,
    CustomCategoryStatus? status,
    String? errorMessage,
    CustomCategory? pendingDeletion,
    int? opSeq,
    bool clearErrorMessage = false,
    bool clearPendingDeletion = false,
  }) {
    return CustomCategoryState(
      categories: categories ?? this.categories,
      cardCounts: cardCounts ?? this.cardCounts,
      status: status ?? this.status,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      pendingDeletion: clearPendingDeletion
          ? null
          : (pendingDeletion ?? this.pendingDeletion),
      opSeq: opSeq ?? this.opSeq,
    );
  }

  @override
  List<Object?> get props =>
      <Object?>[categories, cardCounts, status, errorMessage, pendingDeletion, opSeq];
}
