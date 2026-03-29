import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_event.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_state.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      floatingActionButton: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (BuildContext context, FavoritesState state) {
          if (state.cards.isEmpty) {
            return const SizedBox.shrink();
          }
          return FloatingActionButton(
            tooltip: 'Draw a random favorite',
            onPressed: () {
              final List<TopicCard> all = state.cards;
              final TopicCard pick = all[DateTime.now().millisecondsSinceEpoch % all.length];
              context.read<FavoritesBloc>().add(FavoriteDrawRequested(pick));
              context.push(AppRoutes.timerSetup, extra: pick);
            },
            child: const Icon(Icons.shuffle_rounded),
          );
        },
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (BuildContext context, FavoritesState state) {
          if (state.status == FavoritesStatus.loading && state.cards.isEmpty) {
            final int cross = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;
            return ShimmerGridPlaceholder(crossAxisCount: cross, itemCount: cross * 3);
          }
          if (state.status == FavoritesStatus.failure && state.cards.isEmpty) {
            return Center(child: Text(state.errorMessage ?? 'Error'));
          }
          if (state.cards.isEmpty) {
            return _EmptyFavorites(onBrowse: () => context.go(AppRoutes.home));
          }
          final int cross = MediaQuery.sizeOf(context).width >= 600 ? 3 : 2;
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 88),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cross,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
            ),
            itemCount: state.cards.length,
            itemBuilder: (BuildContext context, int i) {
              final TopicCard card = state.cards[i];
              return _FavoriteTile(card: card);
            },
          );
        },
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites({required this.onBrowse});

  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.favorite_border_rounded, size: 80, color: theme.colorScheme.primary.withValues(alpha: 0.45)),
            const SizedBox(height: AppSpacing.lg),
            Text('No favorites yet', style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap the heart on any card to save it here',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(onPressed: onBrowse, child: const Text('Browse Cards')),
          ],
        ),
      ),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.card});

  final TopicCard card;

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(card.category);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(AppRoutes.cardDetail, extra: card),
        onLongPress: () => _showActions(context, card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Container(height: 4, color: accent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                              decoration: BoxDecoration(color: accent.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(AppRadius.full)),
                              child: Text(
                                card.category,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelSmall?.copyWith(color: accent, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(_difficultyLabel(card.difficulty), style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, height: 1.25),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        IconButton(
                          icon: const Icon(Icons.favorite_rounded),
                          color: theme.colorScheme.error,
                          onPressed: () {
                            context.read<FavoritesBloc>().add(FavoriteRemoved(card.cardId));
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.play_circle_fill_rounded),
                          color: theme.colorScheme.primary,
                          onPressed: () {
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
    );
  }

  void _showActions(BuildContext context, TopicCard card) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.play_arrow_rounded),
                title: const Text('Practice Now'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.timerSetup, extra: card);
                },
              ),
              ListTile(
                leading: const Icon(Icons.visibility_rounded),
                title: const Text('View Card'),
                onTap: () {
                  Navigator.pop(context);
                  context.push(AppRoutes.cardDetail, extra: card);
                },
              ),
              ListTile(
                leading: Icon(Icons.heart_broken_rounded, color: Theme.of(context).colorScheme.error),
                title: const Text('Remove from Favorites'),
                onTap: () {
                  Navigator.pop(context);
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
