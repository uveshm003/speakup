import 'dart:math' show Random;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
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

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  // ── Filter state ────────────────────────────────────────────────────────────
  String? _selectedCategory;
  Difficulty? _selectedDifficulty;

  // ── Stagger entrance ────────────────────────────────────────────────────────
  bool _staggerScheduled = false;
  bool _staggerStarted = false;

  // ── FAB entrance ────────────────────────────────────────────────────────────
  late final AnimationController _fabCtrl;
  late final Animation<double> _fabScale;

  // ── Content fade ────────────────────────────────────────────────────────────
  late final AnimationController _contentFadeCtrl;
  late final Animation<double> _contentFade;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fabScale = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut));

    _contentFadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _contentFade = CurvedAnimation(parent: _contentFadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    _contentFadeCtrl.dispose();
    super.dispose();
  }

  void _runStagger(bool hasFavorites) {
    if (_staggerStarted) return;
    _staggerStarted = true;
    Future<void>.delayed(const Duration(milliseconds: 120), () {
      if (mounted) _contentFadeCtrl.forward();
    });
    if (hasFavorites) {
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) _fabCtrl.forward();
      });
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

  void _drawRandom(BuildContext context, List<TopicCard> cards) {
    if (cards.isEmpty) return;
    final TopicCard pick = cards[Random().nextInt(cards.length)];
    context.read<FavoritesBloc>().add(FavoriteDrawRequested(pick));
    context.push(AppRoutes.timerSetup, extra: pick);
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePad = AppLayout.pagePadding(context);

    return BlocBuilder<FavoritesBloc, FavoritesState>(
      builder: (BuildContext ctx, FavoritesState state) {
        // Trigger stagger once data is ready.
        if ((state.status == FavoritesStatus.success || (state.status == FavoritesStatus.failure && state.cards.isNotEmpty)) &&
            !_staggerStarted &&
            !_staggerScheduled) {
          _staggerScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _runStagger(state.cards.isNotEmpty);
          });
        }

        final List<TopicCard> filtered = _filter(state.cards);

        return Scaffold(
          body: SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: <Widget>[
                // ── Immersive header banner ─────────────────────────────────
                SliverToBoxAdapter(
                  child: _FavoritesHeader(count: state.cards.length, pad: pagePad),
                ),

                // ── Loading ────────────────────────────────────────────────
                if (state.status == FavoritesStatus.loading && state.cards.isEmpty)
                  SliverPadding(
                    padding: pagePad.copyWith(top: AppSpacing.xl),
                    sliver: SliverToBoxAdapter(child: ShimmerListPlaceholder(itemCount: 5, itemHeight: 100)),
                  )
                // ── Failure ───────────────────────────────────────────────
                else if (state.status == FavoritesStatus.failure && state.cards.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text(
                        state.errorMessage ?? 'Something went wrong',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                // ── Empty ─────────────────────────────────────────────────
                else if (state.cards.isEmpty)
                  SliverFillRemaining(child: _EmptyFavorites(onBrowse: () => ctx.go(AppRoutes.home)))
                // ── Has cards → show filters + list ───────────────────────
                else ...<Widget>[
                  // Category tab bar
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pagePad.left, AppSpacing.lg, pagePad.right, AppSpacing.xs),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: _CategoryTabBar(
                          cards: state.cards,
                          selected: _selectedCategory,
                          onChanged: (String? v) => setState(() => _selectedCategory = v),
                        ),
                      ),
                    ),
                  ),

                  // Difficulty segmented control
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pagePad.left, AppSpacing.sm, pagePad.right, AppSpacing.md),
                    sliver: SliverToBoxAdapter(
                      child: FadeTransition(
                        opacity: _contentFade,
                        child: _DifficultySegment(
                          selected: _selectedDifficulty,
                          onChanged: (Difficulty? d) => setState(() => _selectedDifficulty = d),
                          hasActiveFilter: _selectedCategory != null || _selectedDifficulty != null,
                          onClearAll: () => setState(() {
                            _selectedCategory = null;
                            _selectedDifficulty = null;
                          }),
                        ),
                      ),
                    ),
                  ),

                  // No results after filter
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      child: _NoResults(
                        onClear: () => setState(() {
                          _selectedCategory = null;
                          _selectedDifficulty = null;
                        }),
                      ),
                    )
                  // Card list
                  else
                    SliverFadeTransition(
                      opacity: _contentFade,
                      sliver: SliverPadding(
                        padding: EdgeInsets.fromLTRB(pagePad.left, 0, pagePad.right, AppSpacing.huge + 24),
                        sliver: SliverList.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (BuildContext context, int i) {
                            return _FavoriteListCard(card: filtered[i]);
                          },
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),

          // ── Shuffle FAB ─────────────────────────────────────────────────
          floatingActionButton: state.cards.isNotEmpty
              ? AnimatedBuilder(
                  animation: _fabScale,
                  builder: (BuildContext context, Widget? child) => Transform.scale(scale: _fabScale.value, child: child),
                  child: FloatingActionButton(
                    onPressed: () => _drawRandom(context, filtered.isEmpty ? state.cards : filtered),
                    // label: const Text('Shuffle'),
                    elevation: 2,
                    child: const Icon(Icons.shuffle_rounded, size: 18),
                  ),
                )
              : null,
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Immersive header banner
// ─────────────────────────────────────────────────────────────────────────────

class _FavoritesHeader extends StatelessWidget {
  const _FavoritesHeader({required this.count, required this.pad});
  final int count;
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;

    // Warm rose tint gradient — stays subtle and brand-neutral
    final Color rosetint = dark ? theme.colorScheme.error.withValues(alpha: 0.18) : theme.colorScheme.error.withValues(alpha: 0.07);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[rosetint, theme.colorScheme.surface]),
      ),
      padding: EdgeInsets.fromLTRB(pad.left, pad.top + AppSpacing.md, pad.right, AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Favorites', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    children: <InlineSpan>[
                      if (count == 0)
                        const TextSpan(text: 'Your saved cards appear here')
                      else ...<InlineSpan>[
                        TextSpan(
                          text: '$count',
                          style: TextStyle(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                        ),
                        TextSpan(text: ' ${count == 1 ? 'card' : 'cards'} saved'),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Heart badge icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: theme.colorScheme.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2), width: 1),
            ),
            child: Icon(Icons.favorite_rounded, size: 20, color: theme.colorScheme.error),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category tab bar — horizontal scrolling "pill" tabs
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryTabBar extends StatelessWidget {
  const _CategoryTabBar({required this.cards, required this.selected, required this.onChanged});
  final List<TopicCard> cards;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> cats = cards.map((TopicCard c) => c.category).toSet().toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(Icons.category_outlined, size: 13, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Category',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          clipBehavior: Clip.none,
          child: Row(
            children: <Widget>[
              // "All" tab
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.xs),
                child: _CategoryTab(
                  label: 'All',
                  emoji: '✨',
                  accentColor: theme.colorScheme.primary,
                  isSelected: selected == null,
                  onTap: () => onChanged(null),
                ),
              ),
              ...cats.map((String cat) {
                final Color accent = accentColorForCategory(cat);
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: _CategoryTab(
                    label: cat,
                    emoji: emojiForCategory(cat),
                    accentColor: accent,
                    isSelected: selected == cat,
                    onTap: () => onChanged(selected == cat ? null : cat),
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.emoji, required this.accentColor, required this.isSelected, required this.onTap});

  final String label;
  final String emoji;
  final Color accentColor;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs + 1),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withValues(alpha: 0.14) : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected ? accentColor.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: isSelected ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: isSelected ? accentColor : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Difficulty segmented control + clear-all button
// ─────────────────────────────────────────────────────────────────────────────

class _DifficultySegment extends StatelessWidget {
  const _DifficultySegment({required this.selected, required this.onChanged, required this.hasActiveFilter, required this.onClearAll});

  final Difficulty? selected;
  final ValueChanged<Difficulty?> onChanged;
  final bool hasActiveFilter;
  final VoidCallback onClearAll;

  Color _diffColor(BuildContext context, Difficulty d) {
    return switch (d) {
      Difficulty.beginner => Colors.green.shade500,
      Difficulty.intermediate => Colors.orange.shade600,
      Difficulty.advanced => Theme.of(context).colorScheme.error,
    };
  }

  String _diffLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          Icon(Icons.signal_cellular_alt_rounded, size: 13, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Difficulty',
            style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Segmented pill
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(AppRadius.full),
              border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
            ),
            padding: const EdgeInsets.all(2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: Difficulty.values.map((Difficulty d) {
                final bool sel = selected == d;
                final Color dc = _diffColor(context, d);
                return GestureDetector(
                  onTap: () => onChanged(sel ? null : d),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                    decoration: BoxDecoration(
                      color: sel ? dc.withValues(alpha: 0.15) : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      border: sel ? Border.all(color: dc.withValues(alpha: 0.5), width: 1.2) : null,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: sel ? dc : dc.withValues(alpha: 0.45)),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _diffLabel(d),
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 10.5,
                            color: sel ? dc : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // const Spacer(),
          // SizedBox(width: 16),

          // Clear-all badge
          // if (hasActiveFilter)
          //   GestureDetector(
          //     onTap: onClearAll,
          //     child: AnimatedContainer(
          //       duration: const Duration(milliseconds: 160),
          //       padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
          //       decoration: BoxDecoration(
          //         color: theme.colorScheme.primary.withValues(alpha: 0.1),
          //         borderRadius: BorderRadius.circular(AppRadius.full),
          //         border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
          //       ),
          //       child: Row(
          //         mainAxisSize: MainAxisSize.min,
          //         children: <Widget>[
          //           Icon(Icons.close_rounded, size: 11, color: theme.colorScheme.primary),
          //           const SizedBox(width: 3),
          //           Text(
          //             'Clear',
          //             style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 10.5, color: theme.colorScheme.primary),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Favorite list card — full-width, rich design
// ─────────────────────────────────────────────────────────────────────────────

class _FavoriteListCard extends StatelessWidget {
  const _FavoriteListCard({required this.card});
  final TopicCard card;

  Color _diffColor(BuildContext context, Difficulty d) => switch (d) {
    Difficulty.beginner => Colors.green.shade500,
    Difficulty.intermediate => Colors.orange.shade600,
    Difficulty.advanced => Theme.of(context).colorScheme.error,
  };

  String _diffLabel(Difficulty d) {
    final String n = d.name;
    return '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(card.category);
    final String emoji = emojiForCategory(card.category);
    final Color diffColor = _diffColor(context, card.difficulty);
    final String? guidePreview = card.guide.isNotEmpty ? card.guide.first : null;

    return _PressScaleTile(
      onTap: () => context.push(AppRoutes.cardDetail, extra: card),
      child: Dismissible(
        key: ValueKey<String>(card.cardId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: AppSpacing.xl),
          decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.xl)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.heart_broken_rounded, color: theme.colorScheme.error, size: 22),
              const SizedBox(height: 4),
              Text(
                'Remove',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
        onDismissed: (_) {
          context.read<FavoritesBloc>().add(FavoriteRemoved(card.cardId));
        },
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: accent.withValues(alpha: 0.18), width: 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.push(AppRoutes.cardDetail, extra: card),
            onLongPress: () => _showActions(context, card, accent),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // Left accent bar
                  Container(
                    width: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[accent, accent.withValues(alpha: 0.35)],
                      ),
                    ),
                  ),

                  // Main content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          // Emoji avatar
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                            alignment: Alignment.center,
                            child: Text(emoji, style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: AppSpacing.md),

                          // Text block
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // Category + difficulty row
                                Row(
                                  children: <Widget>[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: accent.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: Text(
                                        card.category,
                                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.2),
                                      ),
                                    ),
                                    const SizedBox(width: AppSpacing.xs),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: diffColor.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(AppRadius.xs),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          Container(
                                            width: 5,
                                            height: 5,
                                            decoration: BoxDecoration(shape: BoxShape.circle, color: diffColor),
                                          ),
                                          const SizedBox(width: 3),
                                          Text(
                                            _diffLabel(card.difficulty),
                                            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: diffColor),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.xs + 2),

                                // Title
                                Text(
                                  card.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    height: 1.3,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),

                                // Guide preview
                                if (guidePreview != null) ...<Widget>[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    guidePreview,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),

                          const SizedBox(width: AppSpacing.xs),

                          // Right action column
                          Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              // Remove heart
                              _SmallIconBtn(
                                icon: Icons.favorite_rounded,
                                color: theme.colorScheme.error,
                                onTap: () => context.read<FavoritesBloc>().add(FavoriteRemoved(card.cardId)),
                              ),
                              // Practice play
                              _SmallIconBtn(
                                icon: Icons.play_circle_fill_rounded,
                                color: accent,
                                onTap: () => context.push(AppRoutes.timerSetup, extra: card),
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
        ),
      ),
    );
  }

  void _showActions(BuildContext context, TopicCard card, Color accent) {
    final ThemeData theme = Theme.of(context);
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl + 4))),
      builder: (BuildContext sheetCtx) {
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Mini card header
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(color: accent.withValues(alpha: 0.14), borderRadius: BorderRadius.circular(AppRadius.md)),
                      child: Text(emojiForCategory(card.category), style: const TextStyle(fontSize: 18)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
              const SizedBox(height: AppSpacing.xs),
              ListTile(
                leading: _SheetActionIcon(
                  icon: Icons.play_arrow_rounded,
                  color: theme.colorScheme.primary,
                  bg: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                ),
                title: const Text('Practice Now'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push(AppRoutes.timerSetup, extra: card);
                },
              ),
              ListTile(
                leading: _SheetActionIcon(icon: Icons.visibility_rounded, color: accent, bg: accent.withValues(alpha: 0.12)),
                title: const Text('View Card'),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.push(AppRoutes.cardDetail, extra: card);
                },
              ),
              ListTile(
                leading: _SheetActionIcon(
                  icon: Icons.heart_broken_rounded,
                  color: theme.colorScheme.error,
                  bg: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
                ),
                title: Text('Remove from Favorites', style: TextStyle(color: theme.colorScheme.error)),
                onTap: () {
                  Navigator.pop(sheetCtx);
                  context.read<FavoritesBloc>().add(FavoriteRemoved(card.cardId));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SmallIconBtn extends StatelessWidget {
  const _SmallIconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      radius: 20,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xs),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}

class _SheetActionIcon extends StatelessWidget {
  const _SheetActionIcon({required this.icon, required this.color, required this.bg});
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm - 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state — animated pulse heart
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyFavorites extends StatefulWidget {
  const _EmptyFavorites({required this.onBrowse});
  final VoidCallback onBrowse;

  @override
  State<_EmptyFavorites> createState() => _EmptyFavoritesState();
}

class _EmptyFavoritesState extends State<_EmptyFavorites> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.88, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
            // Layered pulse decoration
            ScaleTransition(
              scale: _pulse,
              child: Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  Container(
                    width: 104,
                    height: 104,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.error.withValues(alpha: 0.08)),
                  ),
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.error.withValues(alpha: 0.15)),
                    child: Icon(Icons.favorite_border_rounded, size: 36, color: theme.colorScheme.error.withValues(alpha: 0.75)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No favorites yet',
              style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the ♡ on any card to save it here\nfor quick access and practice.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.55),
            ),
            const SizedBox(height: AppSpacing.xxl + AppSpacing.md),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: widget.onBrowse,
                style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl))),
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
// No results state
// ─────────────────────────────────────────────────────────────────────────────

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.filter_list_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: AppSpacing.md),
            Text('No cards match', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: AppSpacing.sm),
            Text('Try adjusting your filters.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.tonal(
              onPressed: onClear,
              style: FilledButton.styleFrom(
                shape: StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
              ),
              child: const Text('Clear filters'),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Press-scale wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _PressScaleTile extends StatefulWidget {
  const _PressScaleTile({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScaleTile> createState() => _PressScaleTileState();
}

class _PressScaleTileState extends State<_PressScaleTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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
        builder: (BuildContext ctx, Widget? child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}
