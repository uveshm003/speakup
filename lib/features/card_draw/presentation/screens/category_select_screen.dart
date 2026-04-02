import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
  const CategorySelectScreen({super.key, this.quickDraw = false});

  final bool quickDraw;

  @override
  State<CategorySelectScreen> createState() => _CategorySelectScreenState();
}

class _CategorySelectScreenState extends State<CategorySelectScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _quickPulse;

  @override
  void initState() {
    super.initState();
    _quickPulse = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    if (widget.quickDraw) {
      _quickPulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _quickPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets pad = AppLayout.pagePadding(context);

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (BuildContext context, CategoryState state) {
        Widget body;
        if (state.status == CategoryLoadStatus.initial || state.status == CategoryLoadStatus.loading) {
          body = const Center(child: CircularProgressIndicator.adaptive());
        } else if (state.status == CategoryLoadStatus.failure) {
          body = Center(
            child: Padding(padding: pad, child: Text(state.errorMessage ?? 'Could not load categories')),
          );
        } else {
          body = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // ── Difficulty filter ─────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.sm, pad.right, AppSpacing.sm),
                child: _DifficultyFilterRow(
                  currentFilter: state.difficultyFilter,
                  onFilterChanged: (DifficultyFilter f) => context.read<CategoryBloc>().add(DifficultyFilterChanged(f)),
                ),
              ),

              // ── Category list ─────────────────────────────────────────────
              Expanded(
                child: ListView(
                  padding: pad.copyWith(top: AppSpacing.xs, bottom: AppSpacing.huge),
                  children: <Widget>[
                    _AllCategoriesTile(
                      count: state.allFilteredCount,
                      selected: state.selectedCategoryKey == null,
                      onTap: () => context.read<CategoryBloc>().add(const CategoryFilterChanged(null)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final CategoryListItem item in state.items)
                      _CategoryTile(
                        item: item,
                        selected: state.selectedCategoryKey == item.key,
                        onTap: () => context.read<CategoryBloc>().add(CategoryFilterChanged(item.key)),
                      ),
                  ],
                ),
              ),

              // ── Bottom bar ────────────────────────────────────────────────
              _BottomBar(
                state: state,
                quickPulse: widget.quickDraw ? _quickPulse : null,
                onDraw: state.canDraw
                    ? () {
                        final Uri uri = Uri(
                          path: AppRoutes.cardDraw,
                          queryParameters: <String, String>{
                            if (state.selectedCategoryKey != null) 'category': state.selectedCategoryKey!,
                            if (state.difficultyFilter != DifficultyFilter.all) 'difficulty': state.difficultyFilter.asDifficulty!.raw,
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
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Inline header (no AppBar) ─────────────────────────────
                Padding(
                  padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.md, pad.right, 0),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Choose a Topic', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3)),
                            const SizedBox(height: 2),
                            Text(
                              widget.quickDraw ? 'Pick a category to draw from' : 'Select a category and difficulty',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      // Close button
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7), shape: BoxShape.circle),
                          child: Icon(Icons.close_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Body ──────────────────────────────────────────────────
                Expanded(child: body),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty filter row
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyFilterRow extends StatelessWidget {
  const _DifficultyFilterRow({required this.currentFilter, required this.onFilterChanged});

  final DifficultyFilter currentFilter;
  final ValueChanged<DifficultyFilter> onFilterChanged;

  Color _activeColor(BuildContext context, DifficultyFilter f) {
    final ThemeData theme = Theme.of(context);
    return switch (f) {
      DifficultyFilter.all => theme.colorScheme.primary,
      DifficultyFilter.beginner => AppColors.success,
      DifficultyFilter.intermediate => AppColors.warning,
      DifficultyFilter.advanced => AppColors.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: <Widget>[
          for (final DifficultyFilter f in DifficultyFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => onFilterChanged(f),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
                  decoration: BoxDecoration(
                    color: currentFilter == f
                        ? _activeColor(context, f).withValues(alpha: 0.14)
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(
                      width: currentFilter == f ? 1.4 : 1.0,
                      color: currentFilter == f
                          ? _activeColor(context, f).withValues(alpha: 0.55)
                          : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      if (f != DifficultyFilter.all) ...<Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: currentFilter == f ? _activeColor(context, f) : _activeColor(context, f).withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Text(
                        f.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: currentFilter == f ? _activeColor(context, f) : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// All-categories tile
// ─────────────────────────────────────────────────────────────────────────────

class _AllCategoriesTile extends StatelessWidget {
  const _AllCategoriesTile({required this.count, required this.selected, required this.onTap});

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Material(
        color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35) : theme.colorScheme.surfaceContainerLow,
        child: InkWell(
          onTap: onTap,
          child: Row(
            children: <Widget>[
              // Accent left strip (visible when selected)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 72,
                color: selected ? theme.colorScheme.primary : Colors.transparent,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.lg + 2),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primary.withValues(alpha: 0.13)),
                      child: Icon(Icons.grid_view_rounded, color: theme.colorScheme.primary, size: 22),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('All Categories', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        Text('$count cards available', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.md),
                child: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tile
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.item, required this.selected, required this.onTap});

  final CategoryListItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int totalMix = item.beginnerCount + item.intermediateCount + item.advancedCount;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: selected ? item.accentColor.withValues(alpha: 0.09) : theme.colorScheme.surfaceContainerLow,
          child: InkWell(
            onTap: onTap,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // ── Accent left strip ──────────────────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 4,
                  height: 94,
                  color: selected ? item.accentColor : Colors.transparent,
                ),

                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Emoji avatar
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[item.accentColor.withValues(alpha: 0.30), item.accentColor.withValues(alpha: 0.10)],
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(item.emoji, style: const TextStyle(fontSize: 24)),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Text + bar
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      item.displayName,
                                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2),
                                    ),
                                  ),
                                  if (item.isCustom) ...<Widget>[
                                    const SizedBox(width: AppSpacing.sm),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(AppRadius.xs),
                                        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.4)),
                                      ),
                                      child: Text('Custom', style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${item.filteredCount} cards',
                                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _DifficultyBar(
                                beginner: item.beginnerCount,
                                intermediate: item.intermediateCount,
                                advanced: item.advancedCount,
                                total: totalMix,
                              ),
                            ],
                          ),
                        ),

                        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant, size: 18),
                      ],
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty bar
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultyBar extends StatelessWidget {
  const _DifficultyBar({required this.beginner, required this.intermediate, required this.advanced, required this.total});

  final int beginner;
  final int intermediate;
  final int advanced;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    if (total == 0) {
      return Container(
        height: 5,
        decoration: BoxDecoration(color: theme.colorScheme.outline.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(AppRadius.full)),
      );
    }
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints c) {
        final double w = c.maxWidth;
        return ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.full),
          child: SizedBox(
            height: 5,
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

// ─────────────────────────────────────────────────────────────────────────────
// Bottom draw bar
// ─────────────────────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state, required this.onDraw, this.quickPulse});

  final CategoryState state;
  final VoidCallback? onDraw;
  final AnimationController? quickPulse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Resolve category label.
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
    final bool isAll = state.difficultyFilter == DifficultyFilter.all;

    Widget button = SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: onDraw,
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl))),
        icon: const Icon(Icons.shuffle_rounded, size: 18),
        label: const Text('Draw Card'),
      ),
    );

    if (quickPulse != null) {
      button = AnimatedBuilder(
        animation: quickPulse!,
        builder: (BuildContext context, Widget? child) => Transform.scale(scale: 1 + 0.018 * quickPulse!.value, child: child),
        child: button,
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
            Divider(height: 1, color: theme.colorScheme.outline.withValues(alpha: 0.18)),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // ── Active selection summary ──────────────────────────────
                  Row(
                    children: <Widget>[
                      _SummaryChip(label: catLabel, icon: Icons.category_rounded, color: theme.colorScheme.primary),
                      const SizedBox(width: AppSpacing.sm),
                      if (!isAll) _SummaryChip(label: diffLabel, icon: Icons.tune_rounded, color: theme.colorScheme.secondary),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ── Draw button ───────────────────────────────────────────
                  button,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small read-only pill showing the current selection in the bottom bar.
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
          ),
        ],
      ),
    );
  }
}
