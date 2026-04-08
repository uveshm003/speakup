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
    context.read<CustomCardBloc>().add(CardsLoadRequested(widget.category.categoryId));
  }

  Future<void> _openCreateCard({TopicCard? existing}) async {
    final Object? result = await context.push(
      AppRoutes.createCard,
      extra: CreateCardRouteArgs(category: widget.category, existingCard: existing),
    );
    if (result == true && mounted) {
      context.read<CustomCardBloc>().add(CardsLoadRequested(widget.category.categoryId));
    }
  }

  void _deleteCard(TopicCard card) {
    context.read<CustomCardBloc>().add(CardDeleteRequested(card.cardId));
  }

  Color _difficultyColor(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return Theme.of(context).brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF22C55E);
      case Difficulty.intermediate:
        return const Color(0xFFF59E0B);
      case Difficulty.advanced:
        return Theme.of(context).colorScheme.error;
    }
  }

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final String drawParam = 'custom:${Uri.encodeComponent(widget.category.categoryId)}';

    return BlocListener<CustomCardBloc, CustomCardState>(
      listenWhen: (CustomCardState p, CustomCardState c) => c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext ctx, CustomCardState state) {
        final TopicCard? card = state.pendingDeletion;
        if (card == null) return;
        ScaffoldMessenger.of(ctx).clearSnackBars();
        ScaffoldMessenger.of(ctx).showSnackBar(
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
        builder: (BuildContext ctx, CustomCardState state) {
          return Scaffold(
            body: CustomScrollView(
              slivers: <Widget>[
                // ── App bar ───────────────────────────────────────────────
                SliverAppBar(
                  expandedHeight: 140,
                  pinned: true,
                  backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
                  foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    titlePadding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                    title: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(widget.category.iconEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: AppSpacing.sm),
                        Flexible(
                          child: Text(
                            widget.category.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: isDark ? theme.colorScheme.onSurface : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    background: _DetailAppBarBg(isDark: isDark, theme: theme),
                  ),
                  actions: <Widget>[
                    TextButton.icon(
                      style: TextButton.styleFrom(foregroundColor: isDark ? theme.colorScheme.primary : Colors.white),
                      onPressed: () => _openCreateCard(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: const Text('Add Card'),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ),

                // ── Card count badge ──────────────────────────────────────
                if (state.cards.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.style_outlined, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            '${state.cards.length} ${state.cards.length == 1 ? 'card' : 'cards'}',
                            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                          ),
                          Text(' · swipe left to delete', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),

                // ── Body ─────────────────────────────────────────────────
                if (state.status == CustomCardStatus.loading && state.cards.isEmpty)
                  const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
                else if (state.cards.isEmpty)
                  SliverFillRemaining(child: _EmptyCards(onAdd: () => _openCreateCard()))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 100),
                    sliver: SliverList.separated(
                      itemCount: state.cards.length,
                      separatorBuilder: (_, int __) => const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (BuildContext listCtx, int i) {
                        final TopicCard card = state.cards[i];
                        return _CardTile(
                          key: ValueKey<String>('card_${card.cardId}'),
                          card: card,
                          difficultyColor: _difficultyColor(card.difficulty),
                          difficultyLabel: _difficultyLabel(card.difficulty),
                          onEdit: () => _openCreateCard(existing: card),
                          onDelete: () => _deleteCard(card),
                        );
                      },
                    ),
                  ),
              ],
            ),

            // ── Draw CTA ─────────────────────────────────────────────────
            bottomNavigationBar: state.cards.isEmpty
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
                      child: FilledButton.icon(
                        onPressed: () {
                          context.push('${AppRoutes.cardDraw}?category=$drawParam');
                        },
                        icon: const Icon(Icons.shuffle_rounded),
                        label: const Text('Draw from this Category'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar background
// ─────────────────────────────────────────────────────────────────────────────
class _DetailAppBarBg extends StatelessWidget {
  const _DetailAppBarBg({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? <Color>[theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), theme.colorScheme.surface]
              : <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card tile (dismissible)
// ─────────────────────────────────────────────────────────────────────────────
class _CardTile extends StatefulWidget {
  const _CardTile({
    super.key,
    required this.card,
    required this.difficultyColor,
    required this.difficultyLabel,
    required this.onEdit,
    required this.onDelete,
  });

  final TopicCard card;
  final Color difficultyColor;
  final String difficultyLabel;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Dismissible(
      key: ValueKey<String>('dismiss_${widget.card.cardId}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Icon(Icons.delete_outline_rounded, color: theme.colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => widget.onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isDark
              ? null
              : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Title row ─────────────────────────────────────────────
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.sm, AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            widget.card.title,
                            maxLines: _expanded ? null : 2,
                            overflow: _expanded ? TextOverflow.visible : TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, height: 1.4),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          // Difficulty badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.difficultyColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              widget.difficultyLabel,
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: widget.difficultyColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Actions
                    IconButton(
                      icon: Icon(Icons.edit_outlined, size: 18, color: theme.colorScheme.onSurfaceVariant),
                      onPressed: widget.onEdit,
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.expand_more_rounded, color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ),
              ),
            ),

            // ── Expanded guide preview ─────────────────────────────────
            if (_expanded && widget.card.guide.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Guide',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    ...widget.card.guide.map(
                      (String bullet) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '• ',
                              style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w700),
                            ),
                            Expanded(
                              child: Text(bullet, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.4)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
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
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35), shape: BoxShape.circle),
              child: Icon(Icons.style_outlined, size: 44, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No cards yet', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Add your first topic card to start practicing in this category.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add First Card'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(200, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
