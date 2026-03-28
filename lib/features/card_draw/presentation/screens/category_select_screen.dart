import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/presentation/bloc/category_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/category_event.dart';
import 'package:speakup/features/card_draw/presentation/bloc/category_state.dart';

class CategorySelectScreen extends StatefulWidget {
  const CategorySelectScreen({
    super.key,
    this.quickDraw = false,
  });

  final bool quickDraw;

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _quickPulse;

  @override
  void initState() {
    super.initState();
    _quickPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.quickDraw) {
      _quickPulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _quickPulse.dispose();
    super.dispose();
  }

  Color _chipBg(DifficultyFilter f, ThemeData theme) {
    return switch (f) {
      DifficultyFilter.all => theme.colorScheme.surfaceContainerHighest,
      DifficultyFilter.beginner =>
        AppColors.success.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.18),
      DifficultyFilter.intermediate =>
        AppColors.warning.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.18),
      DifficultyFilter.advanced =>
        AppColors.error.withValues(alpha: theme.brightness == Brightness.dark ? 0.22 : 0.18),
    };
  }

  Color _chipFg(DifficultyFilter f, ThemeData theme) {
    return switch (f) {
      DifficultyFilter.all => theme.colorScheme.onSurface,
      DifficultyFilter.beginner => AppColors.success,
      DifficultyFilter.intermediate => AppColors.warning,
      DifficultyFilter.advanced => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets pad = AppLayout.pagePadding(context);

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (BuildContext context, CategoryState state) {
        Widget body;
        if (state.status == CategoryLoadStatus.initial ||
            state.status == CategoryLoadStatus.loading) {
          body = const Center(child: CircularProgressIndicator.adaptive());
        } else if (state.status == CategoryLoadStatus.failure) {
          body = Center(
            child: Padding(
              padding: pad,
              child: Text(state.errorMessage ?? 'Could not load categories'),
            ),
          );
        } else {
          body = Column(
                children: <Widget>[
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      pad.left,
                      AppSpacing.md,
                      pad.right,
                      AppSpacing.sm,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: <Widget>[
                            for (final DifficultyFilter f in DifficultyFilter.values)
                              Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.sm),
                                child: ChoiceChip(
                                  label: Text(f.label),
                                  selected: state.difficultyFilter == f,
                                  onSelected: (_) {
                                    context.read<CategoryBloc>().add(
                                          DifficultyFilterChanged(f),
                                        );
                                  },
                                  selectedColor: _chipBg(f, theme),
                                  labelStyle: TextStyle(
                                    color: state.difficultyFilter == f
                                        ? _chipFg(f, theme)
                                        : theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  side: BorderSide(
                                    color: theme.colorScheme.outline.withValues(
                                      alpha: 0.25,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      padding: pad.copyWith(top: 0, bottom: AppSpacing.huge),
                      children: <Widget>[
                        _AllCategoriesTile(
                          count: state.allFilteredCount,
                          selected: state.selectedCategoryKey == null,
                          onTap: () => context.read<CategoryBloc>().add(
                                const CategoryFilterChanged(null),
                              ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        for (final CategoryListItem item in state.items)
                          _CategoryTile(
                            item: item,
                            selected: state.selectedCategoryKey == item.key,
                            onTap: () => context.read<CategoryBloc>().add(
                                  CategoryFilterChanged(item.key),
                                ),
                          ),
                      ],
                    ),
                  ),
                  _BottomBar(
                    state: state,
                    quickPulse: widget.quickDraw ? _quickPulse : null,
                    onDraw: state.canDraw
                        ? () {
                            final Uri uri = Uri(
                              path: AppRoutes.cardDraw,
                              queryParameters: <String, String>{
                                if (state.selectedCategoryKey != null)
                                  'category': state.selectedCategoryKey!,
                                if (state.difficultyFilter != DifficultyFilter.all)
                                  'difficulty':
                                      state.difficultyFilter.asDifficulty!.raw,
                              },
                            );
                            context.push(uri.toString());
                          }
                        : null,
                  ),
                ],
              );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Choose a Topic'),
            leading: IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => context.pop(),
            ),
          ),
          body: body,
        );
      },
    );
  }
}

class _AllCategoriesTile extends StatelessWidget {
  const _AllCategoriesTile({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg + 2,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                ),
                child: Icon(
                  Icons.grid_view_rounded,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'All Categories',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count cards available',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final CategoryListItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int totalMix = item.beginnerCount + item.intermediateCount + item.advancedCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.28)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        item.accentColor.withValues(alpha: 0.35),
                        item.accentColor.withValues(alpha: 0.12),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    item.emoji,
                    style: const TextStyle(fontSize: 26),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              item.displayName,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ),
                          if (item.isCustom)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                borderRadius:
                                    BorderRadius.circular(AppRadius.xs),
                                border: Border.all(
                                  color: theme.colorScheme.outline
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'Custom',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${item.filteredCount} cards',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _DifficultyBar(
                        beginner: item.beginnerCount,
                        intermediate: item.intermediateCount,
                        advanced: item.advancedCount,
                        total: totalMix,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({
    required this.beginner,
    required this.intermediate,
    required this.advanced,
    required this.total,
  });

  final int beginner;
  final int intermediate;
  final int advanced;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (total == 0) {
      return Container(
        height: 6,
        decoration: BoxDecoration(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 6,
            width: w,
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: w * beginner / total,
                  child: Container(color: AppColors.success),
                ),
                SizedBox(
                  width: w * intermediate / total,
                  child: Container(color: AppColors.warning),
                ),
                SizedBox(
                  width: w * advanced / total,
                  child: Container(color: AppColors.error),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.state,
    required this.onDraw,
    this.quickPulse,
  });

  final CategoryState state;
  final VoidCallback? onDraw;
  final AnimationController? quickPulse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    String catLabel = 'All categories';
    if (state.selectedCategoryKey != null) {
      for (final CategoryListItem i in state.items) {
        if (i.key == state.selectedCategoryKey) {
          catLabel = i.displayName;
          break;
        }
      }
    }
    final String diffLabel = state.difficultyFilter.label;

    Widget buttonChild = SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: onDraw,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
          ),
        ),
        child: const Text('Draw Card'),
      ),
    );

    if (quickPulse != null) {
      buttonChild = AnimatedBuilder(
        animation: quickPulse!,
        builder: (BuildContext context, Widget? child) {
          return Transform.scale(
            scale: 1 + 0.02 * quickPulse!.value,
            child: child,
          );
        },
        child: buttonChild,
      );
    }

    return Material(
      color: theme.colorScheme.surface,
      elevation: 0,
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: <Widget>[
                      Chip(
                        label: Text(catLabel),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      Chip(
                        label: Text(diffLabel),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  buttonChild,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
