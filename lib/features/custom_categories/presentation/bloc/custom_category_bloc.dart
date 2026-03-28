import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';

import 'custom_category_event.dart';
import 'custom_category_state.dart';

class CustomCategoryBloc extends Bloc<CustomCategoryEvent, CustomCategoryState> {
  CustomCategoryBloc({
    required CategoryRepository categoryRepository,
    required CardRepository cardRepository,
  })  : _categoryRepository = categoryRepository,
        _cardRepository = cardRepository,
        super(const CustomCategoryState()) {
    on<CategoriesLoadRequested>(_onLoad);
    on<CategoryCreateRequested>(_onCreate);
    on<CategoryUpdateRequested>(_onUpdate);
    on<CategoryDeleteRequested>(_onDelete);
    on<CategoryDeleteUndoRequested>(_onDeleteUndo);
    on<CategoryDeleteCommitted>(_onDeleteCommitted);
  }

  final CategoryRepository _categoryRepository;
  final CardRepository _cardRepository;
  Timer? _deleteTimer;

  Future<Map<String, int>> _cardCountsByCategory() async {
    final result = await _cardRepository.getAll();
    return result.fold(
      (_) => <String, int>{},
      (List<TopicCard> all) {
        final Map<String, int> m = <String, int>{};
        for (final TopicCard c in all) {
          final String? id = c.customCategoryId;
          if (id != null) {
            m[id] = (m[id] ?? 0) + 1;
          }
        }
        return m;
      },
    );
  }

  Future<void> _onLoad(
    CategoriesLoadRequested event,
    Emitter<CustomCategoryState> emit,
  ) async {
    emit(state.copyWith(status: CustomCategoryStatus.loading, clearErrorMessage: true));
    final result = await _categoryRepository.getAll();
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            status: CustomCategoryStatus.failure,
            errorMessage: failure.message ?? 'Could not load categories',
          ),
        );
      },
      (List<CustomCategory> list) async {
        final Map<String, int> counts = await _cardCountsByCategory();
        emit(
          state.copyWith(
            status: CustomCategoryStatus.success,
            categories: list,
            cardCounts: counts,
          ),
        );
      },
    );
  }

  Future<void> _onCreate(
    CategoryCreateRequested event,
    Emitter<CustomCategoryState> emit,
  ) async {
    final String trimmed = event.name.trim();
    if (trimmed.isEmpty) {
      return;
    }
    final CustomCategory cat = CustomCategory(
      categoryId: 'cc_${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.length > 30 ? trimmed.substring(0, 30) : trimmed,
      iconEmoji: event.emoji,
      createdAt: DateTime.now(),
    );
    final result = await _categoryRepository.create(cat);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not create category',
          ),
        );
      },
      (CustomCategory created) async {
        final List<CustomCategory> next = List<CustomCategory>.from(state.categories)
          ..insert(0, created);
        final Map<String, int> counts = await _cardCountsByCategory();
        emit(
          state.copyWith(
            categories: next,
            status: CustomCategoryStatus.success,
            clearErrorMessage: true,
            opSeq: state.opSeq + 1,
            cardCounts: counts,
          ),
        );
      },
    );
  }

  Future<void> _onUpdate(
    CategoryUpdateRequested event,
    Emitter<CustomCategoryState> emit,
  ) async {
    final result = await _categoryRepository.update(event.category);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not update category',
          ),
        );
      },
      (CustomCategory updated) async {
        final List<CustomCategory> next = state.categories
            .map(
              (CustomCategory c) =>
                  c.categoryId == updated.categoryId ? updated : c,
            )
            .toList();
        final Map<String, int> counts = await _cardCountsByCategory();
        emit(
          state.copyWith(
            categories: next,
            clearErrorMessage: true,
            opSeq: state.opSeq + 1,
            cardCounts: counts,
          ),
        );
      },
    );
  }

  Future<void> _onDelete(
    CategoryDeleteRequested event,
    Emitter<CustomCategoryState> emit,
  ) async {
    final int idx =
        state.categories.indexWhere((CustomCategory c) => c.categoryId == event.categoryId);
    if (idx < 0) {
      return;
    }
    final CustomCategory cat = state.categories[idx];
    _deleteTimer?.cancel();
    final List<CustomCategory> next = state.categories
        .where((CustomCategory c) => c.categoryId != event.categoryId)
        .toList();
    emit(
      state.copyWith(
        categories: next,
        pendingDeletion: cat,
        clearErrorMessage: true,
      ),
    );
    _deleteTimer = Timer(const Duration(seconds: 5), () {
      add(const CategoryDeleteCommitted());
    });
  }

  void _onDeleteUndo(
    CategoryDeleteUndoRequested event,
    Emitter<CustomCategoryState> emit,
  ) {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final CustomCategory? cat = state.pendingDeletion;
    if (cat == null) {
      return;
    }
    final List<CustomCategory> next = List<CustomCategory>.from(state.categories)
      ..add(cat);
    next.sort(
      (CustomCategory a, CustomCategory b) => b.createdAt.compareTo(a.createdAt),
    );
    emit(
      state.copyWith(
        categories: next,
        clearPendingDeletion: true,
      ),
    );
  }

  Future<void> _onDeleteCommitted(
    CategoryDeleteCommitted event,
    Emitter<CustomCategoryState> emit,
  ) async {
    _deleteTimer?.cancel();
    _deleteTimer = null;
    final CustomCategory? cat = state.pendingDeletion;
    if (cat == null) {
      return;
    }
    final result = await _categoryRepository.delete(cat.categoryId);
    await result.fold(
      (failure) async {
        emit(
          state.copyWith(
            errorMessage: failure.message ?? 'Could not delete category',
            clearPendingDeletion: true,
          ),
        );
        final Either<Failure, List<CustomCategory>> reload =
            await _categoryRepository.getAll();
        final Map<String, int> counts = await _cardCountsByCategory();
        reload.fold((_) {}, (List<CustomCategory> list) {
          emit(state.copyWith(categories: list, cardCounts: counts));
        });
      },
      (_) async {
        final Map<String, int> counts = await _cardCountsByCategory();
        emit(
          state.copyWith(
            clearPendingDeletion: true,
            cardCounts: counts,
          ),
        );
      },
    );
  }

  @override
  Future<void> close() {
    _deleteTimer?.cancel();
    return super.close();
  }
}
