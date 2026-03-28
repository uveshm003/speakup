import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_event.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_state.dart';
import 'package:speakup/features/card_draw/presentation/models/card_detail_route_args.dart';
import 'package:speakup/features/card_draw/presentation/widgets/flip_draw_card.dart';

/// Card draw flow; expects [CardDrawBloc] above (provided by [GoRouter]).
class CardDrawScreen extends StatelessWidget {
  const CardDrawScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CardDrawBloc, CardDrawState>(
      builder: (BuildContext context, CardDrawState state) {
        final ThemeData theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Draw a card'),
            actions: <Widget>[
              if (state.currentCard != null)
                IconButton(
                  tooltip: 'Card details',
                  icon: const Icon(Icons.info_outline_rounded),
                  onPressed: () {
                    final CardDrawBloc bloc = context.read<CardDrawBloc>();
                    context.push(
                      AppRoutes.cardDetail,
                      extra: CardDetailRouteArgs(
                        card: state.currentCard!,
                        drawBloc: bloc,
                      ),
                    );
                  },
                ),
            ],
          ),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  if (state.drawCount > 0)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        'Draw #${state.drawCount}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Expanded(
                    child: _Body(state: state),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final CardDrawState state;

  @override
  Widget build(BuildContext context) {
    if (state.status == CardDrawStatus.loading && state.currentCard == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (state.status == CardDrawStatus.failure) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(state.errorMessage ?? 'Something went wrong'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.read<CardDrawBloc>().add(
                    CardDrawRequested(
                      category: state.filterCategory,
                      difficulty: state.filterDifficulty,
                    ),
                  ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    if (state.status == CardDrawStatus.empty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(Icons.search_off_rounded, size: 48),
            const SizedBox(height: 12),
            Text(
              state.errorMessage ?? 'No cards match',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.pop(),
              child: const Text('Go back'),
            ),
          ],
        ),
      );
    }
    final TopicCard? card = state.currentCard;
    if (card == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: SingleChildScrollView(
        child: FlipDrawCard(
          key: ValueKey<String>(card.cardId),
          card: card,
          isFavorite: state.isFavorite,
          onFlipPhaseChanged: (bool animating) {
            context.read<CardDrawBloc>().add(
                  CardDrawFlipPhaseChanged(animating),
                );
          },
          onToggleFavorite: () {
            context.read<CardDrawBloc>().add(
                  CardFavoriteToggled(card.cardId),
                );
          },
          onRedraw: () {
            context.read<CardDrawBloc>().add(const CardRedrawRequested());
          },
          onPractice: () {
            context.push(
              AppRoutes.timerSetup,
              extra: card,
            );
          },
        ),
      ),
    );
  }
}
