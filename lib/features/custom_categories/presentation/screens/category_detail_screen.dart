import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_card_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_card_event.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_card_state.dart';
import 'package:speakup/features/custom_categories/presentation/models/create_card_route_args.dart';

class CategoryDetailScreen extends StatefulWidget {
  const CategoryDetailScreen({super.key, required this.category});

  final CustomCategory category;

  @override
  State<CategoryDetailScreen> createState() => _CategoryDetailScreenState();
}

class _CategoryDetailScreenState extends State<CategoryDetailScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CustomCardBloc>().add(
          CardsLoadRequested(widget.category.categoryId),
        );
  }

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  Color _difficultyColor(Difficulty d, ThemeData theme) {
    switch (d) {
      case Difficulty.beginner:
        return theme.brightness == Brightness.dark
            ? const Color(0xFF34D399)
            : const Color(0xFF22C55E);
      case Difficulty.intermediate:
        return const Color(0xFFF59E0B);
      case Difficulty.advanced:
        return theme.colorScheme.error;
    }
  }

  void _deleteCard(TopicCard card) {
    context.read<CustomCardBloc>().add(CardDeleteRequested(card.cardId));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String drawParam = 'custom:${widget.category.categoryId}';

    return BlocListener<CustomCardBloc, CustomCardState>(
      listenWhen: (CustomCardState p, CustomCardState c) =>
          c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext context, CustomCardState state) {
        final TopicCard? card = state.pendingDeletion;
        if (card == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed "${card.title}"'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<CustomCardBloc>().add(const CardDeleteUndoRequested());
              },
            ),
          ),
        );
      },
      child: BlocBuilder<CustomCardBloc, CustomCardState>(
        builder: (BuildContext context, CustomCardState state) {
          return Scaffold(
            appBar: AppBar(
              title: Row(
                children: <Widget>[
                  Text(widget.category.iconEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      widget.category.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton.icon(
                  onPressed: () async {
                    final Object? result = await context.push(
                      AppRoutes.createCard,
                      extra: CreateCardRouteArgs(category: widget.category),
                    );
                    if (result == true && context.mounted) {
                      context.read<CustomCardBloc>().add(
                            CardsLoadRequested(widget.category.categoryId),
                          );
                    }
                  },
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('Add Card'),
                ),
              ],
            ),
            body: state.status == CustomCardStatus.loading && state.cards.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : state.cards.isEmpty
                    ? _EmptyCards(onAdd: () async {
                        final Object? result = await context.push(
                          AppRoutes.createCard,
                          extra: CreateCardRouteArgs(category: widget.category),
                        );
                        if (result == true && context.mounted) {
                          context.read<CustomCardBloc>().add(
                                CardsLoadRequested(widget.category.categoryId),
                              );
                        }
                      })
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.lg,
                          88,
                        ),
                        itemCount: state.cards.length,
                        itemBuilder: (BuildContext context, int i) {
                          final TopicCard card = state.cards[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Dismissible(
                              key: ValueKey<String>('d_${card.cardId}'),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: AppSpacing.xxl),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.error,
                                  borderRadius: BorderRadius.circular(AppRadius.lg),
                                ),
                                child: const Icon(Icons.delete_outline, color: Colors.white),
                              ),
                              onDismissed: (_) => _deleteCard(card),
                              child: Material(
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(AppRadius.lg),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.lg,
                                    vertical: AppSpacing.xs,
                                  ),
                                  title: Text(
                                    card.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _difficultyColor(card.difficulty, theme)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(AppRadius.sm),
                                      ),
                                      child: Text(
                                        _difficultyLabel(card.difficulty),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: _difficultyColor(card.difficulty, theme),
                                        ),
                                      ),
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      IconButton(
                                        icon: const Icon(Icons.edit_outlined, size: 20),
                                        onPressed: () async {
                                          final Object? result = await context.push(
                                            AppRoutes.createCard,
                                            extra: CreateCardRouteArgs(
                                              category: widget.category,
                                              existingCard: card,
                                            ),
                                          );
                                          if (result == true && context.mounted) {
                                            context.read<CustomCardBloc>().add(
                                                  CardsLoadRequested(
                                                    widget.category.categoryId,
                                                  ),
                                                );
                                          }
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 20),
                                        onPressed: () => _deleteCard(card),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
            bottomNavigationBar: state.cards.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg,
                      ),
                      child: FilledButton(
                        onPressed: () {
                          context.push(
                            '${AppRoutes.cardDraw}?category=${Uri.encodeComponent(drawParam)}',
                          );
                        },
                        child: const Text('Draw from this category'),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _EmptyCards extends StatelessWidget {
  const _EmptyCards({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.style_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.55),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No cards yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Add your first topic card to start practicing.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: onAdd,
              child: const Text('Add Card'),
            ),
          ],
        ),
      ),
    );
  }
}
