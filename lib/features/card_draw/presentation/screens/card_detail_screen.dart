import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speakup/config/config.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/utils/responsive.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_event.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_state.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';

/// Full topic card: guide + vocabulary. Optional [drawBloc] when opened from draw flow.
class CardDetailScreen extends StatefulWidget {
  const CardDetailScreen({super.key, required this.card, this.drawBloc});

  final TopicCard card;
  final CardDrawBloc? drawBloc;

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late TopicCard _card;
  late bool _guideExpanded;
  late bool _vocabExpanded;
  bool _favAnimating = false;

  @override
  void initState() {
    super.initState();
    _card = widget.card;
    _guideExpanded = true;
    _vocabExpanded = false;
  }

  Future<void> _toggleFavorite() async {
    // Capture repo before any await to satisfy use_build_context_synchronously.
    final repo = widget.drawBloc == null ? context.read<CardRepository>() : null;
    setState(() => _favAnimating = true);
    await Future<void>.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _favAnimating = false);
    if (widget.drawBloc != null) {
      widget.drawBloc!.add(CardFavoriteToggled(_card.cardId));
      return;
    }
    final result = await repo!.toggleFavorite(_card.cardId);
    result.fold((_) {}, (TopicCard c) {
      if (mounted) {
        setState(() => _card = c);
      }
    });
  }

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(_card.category);
    final bool isDesktop = Responsive.isDesktop(context);
    final bool twoCol = Responsive.of(context) != ScreenSize.mobile;
    final bool mobileSticky = Responsive.isMobile(context);

    if (widget.drawBloc != null) {
      return BlocListener<CardDrawBloc, CardDrawState>(
        bloc: widget.drawBloc,
        listenWhen: (CardDrawState p, CardDrawState c) => c.currentCard?.cardId == _card.cardId && p.currentCard != c.currentCard,
        listener: (BuildContext context, CardDrawState state) {
          final TopicCard? c = state.currentCard;
          if (c != null && c.cardId == _card.cardId) {
            setState(() => _card = c);
          }
        },
        child: _scaffold(context, theme, accent, isDesktop, twoCol, mobileSticky),
      );
    }

    return _scaffold(context, theme, accent, isDesktop, twoCol, mobileSticky);
  }

  Widget _scaffold(BuildContext context, ThemeData theme, Color accent, bool isDesktop, bool twoCol, bool mobileSticky) {
    final EdgeInsets pad = AppLayout.pagePadding(context);

    final Widget heroCard = Hero(
      tag: 'card-hero-${_card.cardId}',
      child: Material(
        color: Colors.transparent,
        child: _DetailCardPreview(card: _card, accent: accent, difficultyLabel: _difficultyLabel(_card.difficulty)),
      ),
    );

    final Widget guideSection = _CollapsibleGuideSection(
      guideLines: _card.guide,
      expanded: _guideExpanded,
      onToggle: () => setState(() => _guideExpanded = !_guideExpanded),
    );

    final Widget vocabSection = _CollapsibleVocabSection(
      words: _card.vocabBoost,
      accent: accent,
      expanded: _vocabExpanded,
      onToggle: () => setState(() => _vocabExpanded = !_vocabExpanded),
    );

    final Widget practiceButton = SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: () {
          context.push(AppRoutes.timerSetup, extra: _card);
        },
        icon: const Icon(Icons.timer_outlined),
        label: const Text('Set Timer & Practice'),
        style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl))),
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_card.category, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: <Widget>[
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 1.0, end: _favAnimating ? 1.4 : 1.0),
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            builder: (BuildContext context, double scale, Widget? child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: IconButton(
              tooltip: 'Favorite',
              onPressed: _toggleFavorite,
              icon: Icon(
                _card.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: _card.isFavorite ? Colors.redAccent : null,
              ),
            ),
          ),
          IconButton(tooltip: 'Share (soon)', onPressed: () {}, icon: const Icon(Icons.ios_share_rounded)),
          if (isDesktop)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                onPressed: () => context.push(AppRoutes.timerSetup, extra: _card),
                icon: const Icon(Icons.timer_outlined, size: 20),
                label: const Text('Practice'),
              ),
            ),
        ],
      ),
      body: twoCol
          ? Padding(
              padding: pad,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 5,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          heroCard,
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            _card.category,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  Expanded(
                    flex: 7,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          guideSection,
                          const SizedBox(height: AppSpacing.lg),
                          vocabSection,
                          if (!isDesktop) ...<Widget>[const SizedBox(height: AppSpacing.xxl), practiceButton],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: pad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        heroCard,
                        const SizedBox(height: AppSpacing.xl),
                        guideSection,
                        const SizedBox(height: AppSpacing.lg),
                        vocabSection,
                        SizedBox(height: isDesktop ? AppSpacing.xxl : 100),
                      ],
                    ),
                  ),
                ),
                if (mobileSticky)
                  Material(
                    elevation: 0,
                    color: theme.colorScheme.surface,
                    child: SafeArea(
                      top: false,
                      child: Padding(padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.md, pad.right, AppSpacing.md), child: practiceButton),
                    ),
                  ),
              ],
            ),
    );
  }
}

class _DetailCardPreview extends StatelessWidget {
  const _DetailCardPreview({required this.card, required this.accent, required this.difficultyLabel});

  final TopicCard card;
  final Color accent;
  final String difficultyLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color bg = theme.brightness == Brightness.dark ? theme.colorScheme.surfaceContainerHigh : Colors.white;

    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: <BoxShadow>[BoxShadow(color: theme.shadowColor.withValues(alpha: 0.12), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      _badge(theme, card.category, theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
                      const Spacer(),
                      _badge(theme, difficultyLabel, theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    card.title,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(ThemeData theme, String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.labelMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _CollapsibleGuideSection extends StatelessWidget {
  const _CollapsibleGuideSection({required this.guideLines, required this.expanded, required this.onToggle});

  final List<String> guideLines;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> lines = guideLines.length > 4 ? guideLines.sublist(0, 4) : List<String>.from(guideLines);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Icon(Icons.explore_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Mini Guide', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        expanded
            ? Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Divider(color: AppColorsNew.primaryContainer, thickness: 1),
              )
            : Offstage(),

        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          child: expanded
              ? Column(
                  children: <Widget>[
                    for (int i = 0; i < lines.length; i++)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
                              child: Text(
                                '${i + 1}',
                                style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: Text(lines[i], style: theme.textTheme.bodyLarge)),
                          ],
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _CollapsibleVocabSection extends StatelessWidget {
  const _CollapsibleVocabSection({required this.words, required this.accent, required this.expanded, required this.onToggle});

  final List<VocabWord> words;
  final Color accent;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<VocabWord> list = words.length > 5 ? words.sublist(0, 5) : List<VocabWord>.from(words);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Row(
              children: <Widget>[
                Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Text('Vocabulary Boost', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                const Spacer(),
                Icon(expanded ? Icons.expand_less : Icons.expand_more, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
        expanded
            ? Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Divider(color: AppColorsNew.primaryContainer, thickness: 1),
              )
            : Offstage(),
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeInOutCubic,
          child: expanded
              ? Column(
                  children: <Widget>[
                    for (final VocabWord w in list)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border(left: BorderSide(color: accent, width: 3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(w.word, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                              const SizedBox(height: 4),
                              Text(w.meaning, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
