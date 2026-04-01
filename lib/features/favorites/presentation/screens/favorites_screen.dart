import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  // ── Filter state ────────────────────────────────────────────────────────────
  String? _selectedCategory;
  Difficulty? _selectedDifficulty;

  // ── Stagger entrance ────────────────────────────────────────────────────────
  bool _staggerScheduled = false;
  bool _staggerStarted = false;
  bool _showHeader = false;
  bool _showFilters = false;
  bool _showGrid = false;

  // ── FAB pulse ───────────────────────────────────────────────────────────────
  late final AnimationController _fabPulseCtrl;
  late final Animation<double> _fabScale;

  // ── Grid fade (SliverFadeTransition needs an Animation<double>) ─────────────
  late final AnimationController _gridFadeCtrl;
  late final Animation<double> _gridFade;

  @override
  void initState() {
    super.initState();
    _fabPulseCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 480));
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _fabPulseCtrl, curve: Curves.elasticOut));

    _gridFadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 380));
    _gridFade = CurvedAnimation(parent: _gridFadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabPulseCtrl.dispose();
    _gridFadeCtrl.dispose();
    super.dispose();
  }

  void _runStagger(bool hasFavorites) {
    if (_staggerStarted) return;
    _staggerStarted = true;
    setState(() => _showHeader = true);
    Future<void>.delayed(const Duration(milliseconds: 80),
        () { if (mounted) setState(() => _showFilters = hasFavorites); });
    Future<void>.delayed(const Duration(milliseconds: 160), () {
      if (mounted) {
        setState(() => _showGrid = true);
        _gridFadeCtrl.forward();
      }
    });
    if (hasFavorites) {
      Future<void>.delayed(const Duration(milliseconds: 240),
          () { if (mounted) _fabPulseCtrl.forward(); });
    }
  }

  List<TopicCard> _filter(List<TopicCard> cards) {
    return cards.where((TopicCard c) {
      if (_selectedCategory != null && c.category != _selectedCategory) {
        return false;
      }
      if (_selectedDifficulty != null && c.difficulty != _selectedDifficulty) {
        return false;
      }
      return true;
    }).toList();
  }

  void _drawRandomFrom(BuildContext context, List<TopicCard> cards) {
    if (cards.isEmpty) return;
    final TopicCard pick = cards[Random().nextInt(cards.length)];
    context.read<FavoritesBloc>().add(FavoriteDrawRequested(pick));
    context.push(AppRoutes.timerSetup, extra: pick);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePad = AppLayout.pagePadding(context);
    final ThemeData theme = Theme.of(context);

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (BuildContext ctx, FavoritesState state) {
        // Trigger stagger once data is ready.
        if ((state.status == FavoritesStatus.success ||
                (state.status == FavoritesStatus.failure &&
                    state.cards.isNotEmpty)) &&
            !_staggerStarted &&
            !_staggerScheduled) {
          _staggerScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _runStagger(state.cards.isNotEmpty);
          });
        }

        final List<TopicCard> filtered = _filter(state.cards);
        final int cross = MediaQuery.sizeOf(ctx).width >= 600 ? 3 : 2;

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              slivers: <Widget>[
                // ── Header ─────────────────────────────────────────────────
                SliverPadding(
                  padding: pagePad.copyWith(
                      top: pagePad.top + AppSpacing.md, bottom: 0),
                  sliver: SliverToBoxAdapter(
                    child: AnimatedOpacity(
                      opacity: _showHeader ? 1 : 0,
                      duration: const Duration(milliseconds: 360),
                      child: _FavoritesHeader(count: state.cards.length),
                    ),
                  ),
                ),

                // ── Filter chips ───────────────────────────────────────────
                if (state.cards.isNotEmpty)
                  SliverPadding(
                    padding: EdgeInsets.only(
                        top: AppSpacing.lg,
                        bottom: AppSpacing.sm,
                        left: pagePad.left,
                        right: pagePad.right),
                    sliver: SliverToBoxAdapter(
                      child: AnimatedOpacity(
                        opacity: _showFilters ? 1 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: AnimatedSlide(
                          duration: const Duration(milliseconds: 340),
                          curve: Curves.easeOutCubic,
                          offset: _showFilters
                              ? Offset.zero
                              : const Offset(0, 0.08),
                          child: _FilterRow(
                            cards: state.cards,
                            selectedCategory: _selectedCategory,
                            selectedDifficulty: _selectedDifficulty,
                            onCategoryChanged: (String? v) =>
                                setState(() => _selectedCategory = v),
                            onDifficultyChanged: (Difficulty? v) =>
                                setState(() => _selectedDifficulty = v),
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Loading shimmer ────────────────────────────────────────
                if (state.status == FavoritesStatus.loading &&
                    state.cards.isEmpty)
                  SliverPadding(
                    padding: pagePad.copyWith(top: AppSpacing.lg),
                    sliver: SliverToBoxAdapter(
                      child: ShimmerGridPlaceholder(
                          crossAxisCount: cross, itemCount: cross * 3),
                    ),
                  )

                // ── Error ──────────────────────────────────────────────────
                else if (state.status == FavoritesStatus.failure &&
                    state.cards.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.errorMessage ?? 'Something went wrong',
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )

                // ── Empty state ────────────────────────────────────────────
                else if (state.cards.isEmpty)
                  SliverFillRemaining(
                    child: AnimatedOpacity(
                      opacity: _showGrid ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: _EmptyFavorites(
                          onBrowse: () => ctx.go(AppRoutes.home)),
                    ),
                  )

                // ── No results after filter ────────────────────────────────
                else if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(Icons.filter_list_off_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.45)),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            'No cards match these filters',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  )

                // ── Favorites grid ─────────────────────────────────────────
                else
                  SliverPadding(
                    padding: pagePad.copyWith(
                        top: AppSpacing.md, bottom: AppSpacing.huge + 16),
                    // SliverFadeTransition is the proper Sliver equivalent of
                    // AnimatedOpacity — AnimatedOpacity is a Box widget and
                    // cannot be used as a SliverPadding.sliver child.
                    sliver: SliverFadeTransition(
                      opacity: _gridFade,
                      sliver: SliverGrid.builder(
                        gridDelegate:
                            SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cross,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 0.72,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (BuildContext context, int i) {
                          final TopicCard card = filtered[i];
                          return _FavoriteTile(card: card);
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── FAB ────────────────────────────────────────────────────────
          // Use AnimatedBuilder+Transform.scale instead of ScaleTransition
          // so the FAB's internal clipping/layout is not affected by the
          // wrapper and the icon stays within its background bounds.
          floatingActionButton: state.cards.isNotEmpty
              ? AnimatedBuilder(
                  animation: _fabScale,
                  builder: (BuildContext context, Widget? child) =>
                      Transform.scale(scale: _fabScale.value, child: child),
                  child: FloatingActionButton.extended(
                    tooltip: 'Draw a random favorite',
                    onPressed: () => _drawRandomFrom(
                        context, filtered.isEmpty ? state.cards : filtered),
                    icon: const Icon(Icons.shuffle_rounded, size: 20),
                    label: const Text('Shuffle'),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header
// ─────────────────────────────────────────────────────────────────────────────

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Favorites',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700, letterSpacing: -0.3),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                count == 0
                    ? 'Your saved cards will appear here'
                    : '$count ${count == 1 ? 'card' : 'cards'} saved',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        // Heart icon badge
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Icon(
            Icons.favorite_rounded,
            size: 22,
            color: theme.colorScheme.error,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter row
// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({
    required this.cards,
    required this.selectedCategory,
    required this.selectedDifficulty,
    required this.onCategoryChanged,
    required this.onDifficultyChanged,
  });

  final List<TopicCard> cards;
  final String? selectedCategory;
  final Difficulty? selectedDifficulty;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<Difficulty?> onDifficultyChanged;

  bool get _hasActiveFilter =>
      selectedCategory != null || selectedDifficulty != null;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    // Unique categories present in the saved cards.
    final List<String> categories = cards
        .map((TopicCard c) => c.category)
        .toSet()
        .toList()
      ..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Section heading + active-filter count ─────────────────────────
        Row(
          children: <Widget>[
            Text(
              'Filter',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
            if (_hasActiveFilter) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: () {
                  onCategoryChanged(null);
                  onDifficultyChanged(null);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.close_rounded,
                          size: 11,
                          color: theme.colorScheme.primary),
                      const SizedBox(width: 3),
                      Text(
                        'Clear',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.sm),

        // ── Chips row ──────────────────────────────────────────────────────
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: <Widget>[
              // Category chips
              ...categories.map((String cat) {
                final Color accent = accentColorForCategory(cat);
                final bool selected = selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    onTap: () => onCategoryChanged(selected ? null : cat),
                    selected: selected,
                    activeColor: accent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(emojiForCategory(cat),
                            style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          cat,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? accent
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),

              // Divider between category and difficulty groups
              if (categories.length > 1)
                Container(
                  width: 1,
                  height: 18,
                  margin: const EdgeInsets.only(right: AppSpacing.md),
                  color: theme.colorScheme.outlineVariant
                      .withValues(alpha: 0.45),
                ),

              // Difficulty chips
              ...Difficulty.values.map((Difficulty d) {
                final bool sel = selectedDifficulty == d;
                final Color diffColor = _diffColor(context, d);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.sm),
                  child: _FilterChip(
                    onTap: () => onDifficultyChanged(sel ? null : d),
                    selected: sel,
                    activeColor: diffColor,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: sel
                                ? diffColor
                                : diffColor.withValues(alpha: 0.5),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _diffLabel(d),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: sel
                                ? diffColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  String _diffLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  Color _diffColor(BuildContext context, Difficulty d) {
    final ThemeData theme = Theme.of(context);
    return switch (d) {
      Difficulty.beginner => Colors.green.shade500,
      Difficulty.intermediate => Colors.orange.shade600,
      Difficulty.advanced => theme.colorScheme.error,
    };
  }
}

/// Reusable animated filter pill — used for both category and difficulty chips.
class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.onTap,
    required this.selected,
    required this.activeColor,
    required this.child,
  });

  final VoidCallback onTap;
  final bool selected;
  final Color activeColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: selected
              ? activeColor.withValues(alpha: 0.14)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            width: selected ? 1.4 : 1.0,
            color: selected
                ? activeColor.withValues(alpha: 0.55)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatefulWidget {
  const _EmptyFavorites({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  State<_EmptyFavorites> createState() => _EmptyFavoritesState();
}

class _EmptyFavoritesState extends State<_EmptyFavorites>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.85, end: 1.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.huge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ScaleTransition(
              scale: _pulse,
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.35),
                ),
                child: Icon(
                  Icons.favorite_border_rounded,
                  size: 52,
                  color: theme.colorScheme.error.withValues(alpha: 0.7),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No favorites yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the ♡ on any card\nto save it here for quick access',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxl + AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: widget.onBrowse,
                style: FilledButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl)),
                ),
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Browse Cards'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favourite tile
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.card});
  final TopicCard card;

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  Color _difficultyColor(BuildContext context, Difficulty d) {
    final ThemeData theme = Theme.of(context);
    return switch (d) {
      Difficulty.beginner => Colors.green.shade500,
      Difficulty.intermediate => Colors.orange.shade600,
      Difficulty.advanced => theme.colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(card.category);
    final String emoji = emojiForCategory(card.category);

    return _PressScaleTile(
      onTap: () => context.push(AppRoutes.cardDetail, extra: card),
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(AppRoutes.cardDetail, extra: card),
          onLongPress: () => _showActions(context, card, accent),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // ── Accent top stripe ──────────────────────────────────────
              Container(
                height: 4,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[accent, accent.withValues(alpha: 0.45)],
                  ),
                ),
              ),

              // ── Body ──────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Category pill + emoji
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.13),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Text(emoji,
                                style: const TextStyle(fontSize: 11)),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                card.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: accent,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Title — grows to fill available space
                      Expanded(
                        child: Text(
                          card.title,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Difficulty badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(
                          color: _difficultyColor(context, card.difficulty)
                              .withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Text(
                          _difficultyLabel(card.difficulty),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _difficultyColor(context, card.difficulty),
                          ),
                        ),
                      ),

                      const Divider(height: AppSpacing.lg, thickness: 0),

                      // ── Action row ─────────────────────────────────────
                      Row(
                        children: <Widget>[
                          // Remove favourite
                          _ActionIcon(
                            icon: Icons.favorite_rounded,
                            color: theme.colorScheme.error,
                            tooltip: 'Remove',
                            onTap: () {
                              context
                                  .read<FavoritesBloc>()
                                  .add(FavoriteRemoved(card.cardId));
                            },
                          ),
                          const Spacer(),
                          // Practice
                          _ActionIcon(
                            icon: Icons.play_circle_fill_rounded,
                            color: accent,
                            tooltip: 'Practice',
                            onTap: () {
                              context.push(AppRoutes.timerSetup, extra: card);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showActions(BuildContext context, TopicCard card, Color accent) {
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl + 4)),
      ),
      builder: (BuildContext sheetCtx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                // Card mini-header inside sheet
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Text(
                          emojiForCategory(card.category),
                          style: const TextStyle(fontSize: 18),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          card.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                    height: 1,
                    indent: AppSpacing.lg,
                    endIndent: AppSpacing.lg),
                const SizedBox(height: AppSpacing.xs),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm - 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer
                          .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.play_arrow_rounded,
                        color: theme.colorScheme.primary, size: 20),
                  ),
                  title: const Text('Practice Now'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push(AppRoutes.timerSetup, extra: card);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm - 2),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.visibility_rounded,
                        color: accent, size: 20),
                  ),
                  title: const Text('View Card'),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context.push(AppRoutes.cardDetail, extra: card);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSpacing.sm - 2),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer
                          .withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Icon(Icons.heart_broken_rounded,
                        color: theme.colorScheme.error, size: 20),
                  ),
                  title: Text(
                    'Remove from Favorites',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                  onTap: () {
                    Navigator.pop(sheetCtx);
                    context
                        .read<FavoritesBloc>()
                        .add(FavoriteRemoved(card.cardId));
                  },
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
// Tiny icon action button inside the tile
// ─────────────────────────────────────────────────────────────────────────────

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 20,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xs),
          child: Icon(icon, size: 20, color: color),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Press-scale wrapper (matches home screen)
// ─────────────────────────────────────────────────────────────────────────────

class _PressScaleTile extends StatefulWidget {
  const _PressScaleTile({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScaleTile> createState() => _PressScaleTileState();
}

class _PressScaleTileState extends State<_PressScaleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (BuildContext ctx, Widget? child) =>
            Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
