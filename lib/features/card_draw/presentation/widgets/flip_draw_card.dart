import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';
import 'package:speakup/features/card_draw/presentation/models/card_detail_route_args.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';

/// 3-D flip card: front (brand back) → back (topic preview).
/// [onFlipPhaseChanged] syncs flip animation state to BLoC.
class FlipDrawCard extends StatefulWidget {
  const FlipDrawCard({
    super.key,
    required this.card,
    required this.onRedraw,
    required this.onPractice,
    required this.onToggleFavorite,
    required this.isFavorite,
    this.onFlipPhaseChanged,
    this.drawBloc,
  });

  final TopicCard card;
  final VoidCallback onRedraw;
  final VoidCallback onPractice;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final ValueChanged<bool>? onFlipPhaseChanged;
  final CardDrawBloc? drawBloc;

  @override
  State<FlipDrawCard> createState() => _FlipDrawCardState();
}

class _FlipDrawCardState extends State<FlipDrawCard>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final AnimationController _flipController;
  late final Animation<double> _flipTurns;

  double _contentOpacity = 0;
  double _actionsOpacity = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 420));
    _entranceScale = Tween<double>(begin: 0.82, end: 1).animate(
        CurvedAnimation(
            parent: _entranceController, curve: Curves.easeOutCubic));
    _flipController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _flipTurns = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(
          tween: Tween<double>(begin: 0, end: 1)
              .chain(CurveTween(curve: Curves.easeInOutCubic)),
          weight: 1),
    ]).animate(_flipController);
    _flipController.addStatusListener(_onFlipStatus);
    _runEntranceThenFlip();
  }

  @override
  void didUpdateWidget(covariant FlipDrawCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.cardId != widget.card.cardId) {
      _contentOpacity = 0;
      _actionsOpacity = 0;
      _entranceController.reset();
      _flipController.reset();
      _runEntranceThenFlip();
    }
  }

  void _onFlipStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      HapticFeedback.mediumImpact();
      widget.onFlipPhaseChanged?.call(false);
      _runStagger();
    } else if (status == AnimationStatus.dismissed) {
      widget.onFlipPhaseChanged?.call(false);
    }
  }

  void _runEntranceThenFlip() {
    _entranceController.forward(from: 0).then((_) {
      if (!mounted) return;
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          widget.onFlipPhaseChanged?.call(true);
          _flipController.forward(from: 0);
        }
      });
    });
  }

  Future<void> _runStagger() async {
    if (!mounted) return;
    setState(() => _contentOpacity = 1);
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    setState(() => _actionsOpacity = 1);
  }

  @override
  void dispose() {
    _flipController.removeStatusListener(_onFlipStatus);
    _entranceController.dispose();
    _flipController.dispose();
    super.dispose();
  }

  String _difficultyLabel(Difficulty d) {
    final String n = d.name;
    return n.isEmpty ? n : '${n[0].toUpperCase()}${n.substring(1)}';
  }

  IconData _difficultyIcon(Difficulty d) {
    switch (d) {
      case Difficulty.beginner:
        return Icons.eco_rounded;
      case Difficulty.intermediate:
        return Icons.local_fire_department_rounded;
      case Difficulty.advanced:
        return Icons.bolt_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(widget.card.category);
    final double w = MediaQuery.sizeOf(context).width;
    final double cardW = (w * 0.90).clamp(0.0, 440.0);
    final double cardH = (cardW * 1.52).clamp(500.0, 640.0);

    return Hero(
      tag: 'card-hero-${widget.card.cardId}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge(
              <Listenable>[_entranceController, _flipController]),
          builder: (BuildContext context, Widget? child) {
            final double scale = _entranceScale.value;
            final double angle = _flipTurns.value * pi;
            final bool showFront = angle < pi / 2;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails d) {
                    if (d.velocity.pixelsPerSecond.dx.abs() > 280) {
                      widget.onRedraw();
                    }
                  },
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()
                      ..setEntry(3, 2, 0.001)
                      ..rotateY(angle),
                    child: showFront
                        ? _CardFront(accent: accent)
                        : Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(pi),
                            child: _CardBack(
                              card: widget.card,
                              accent: accent,
                              theme: theme,
                              difficultyLabel:
                                  _difficultyLabel(widget.card.difficulty),
                              difficultyIcon:
                                  _difficultyIcon(widget.card.difficulty),
                              contentOpacity: _contentOpacity,
                              actionsOpacity: _actionsOpacity,
                              isFavorite: widget.isFavorite,
                              onToggleFavorite: widget.onToggleFavorite,
                              onRedraw: widget.onRedraw,
                              onPractice: widget.onPractice,
                              drawBloc: widget.drawBloc,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Front (brand face)
// ─────────────────────────────────────────────────────────────────────────────

class _CardFront extends StatelessWidget {
  const _CardFront({required this.accent});
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color start = dark ? AppColorsDark.primaryDark : AppColors.primary;
    final Color end = dark ? AppColorsDark.primary : AppColors.primaryLight;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: start.withValues(alpha: 0.35),
              blurRadius: 36,
              offset: const Offset(0, 18)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.10),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: const <double>[0.0, 0.55, 1.0],
          colors: <Color>[start, Color.lerp(start, end, 0.5)!, end],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            CustomPaint(
              painter: _StripePainter(
                  color: Colors.white.withValues(alpha: dark ? 0.04 : 0.07)),
            ),
            // Decorative circles
            Positioned(
              top: -50,
              right: -50,
              child: _GlassCircle(size: 200),
            ),
            Positioned(
              bottom: -70,
              left: -40,
              child: _GlassCircle(size: 240),
            ),
            // Category accent stripe
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 6,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.85),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    bottomLeft: Radius.circular(28),
                  ),
                ),
              ),
            ),
            // Center content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.13),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2), width: 1),
                    ),
                    child: Icon(
                      Icons.record_voice_over_rounded,
                      size: 52,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.97),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'SpeakUp',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'TAP TO REVEAL',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.5),
                      letterSpacing: 3,
                    ),
                  ),
                ],
              ),
            ),
            // Swipe hint at bottom
            Positioned(
              bottom: AppSpacing.lg,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(Icons.swipe_rounded,
                      size: 13,
                      color:
                          theme.colorScheme.onPrimary.withValues(alpha: 0.35)),
                  const SizedBox(width: 4),
                  Text(
                    'Swipe to re-draw',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: theme.colorScheme.onPrimary.withValues(alpha: 0.35),
                      fontWeight: FontWeight.w500,
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

class _GlassCircle extends StatelessWidget {
  const _GlassCircle({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Card Back (topic preview)
// ─────────────────────────────────────────────────────────────────────────────

class _CardBack extends StatelessWidget {
  const _CardBack({
    required this.card,
    required this.accent,
    required this.theme,
    required this.difficultyLabel,
    required this.difficultyIcon,
    required this.contentOpacity,
    required this.actionsOpacity,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRedraw,
    required this.onPractice,
    this.drawBloc,
  });

  final TopicCard card;
  final Color accent;
  final ThemeData theme;
  final String difficultyLabel;
  final IconData difficultyIcon;
  final double contentOpacity;
  final double actionsOpacity;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRedraw;
  final VoidCallback onPractice;
  final CardDrawBloc? drawBloc;

  @override
  Widget build(BuildContext context) {
    final bool dark = theme.brightness == Brightness.dark;
    final Color cardBg = dark ? AppColorsDark.surface : Colors.white;
    final Color accentSurface = accent.withValues(alpha: dark ? 0.16 : 0.09);
    final String emoji = emojiForCategory(card.category);

    void openDetail(String initialTab) {
      context.push(
        AppRoutes.cardDetail,
        extra: CardDetailRouteArgs(card: card, drawBloc: drawBloc),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: <BoxShadow>[
          BoxShadow(
              color: accent.withValues(alpha: 0.20),
              blurRadius: 32,
              offset: const Offset(0, 16)),
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: <Widget>[
            // Top accent gradient band
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[accent, accent.withValues(alpha: 0.35)],
                  ),
                ),
              ),
            ),

            // Main body
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.xl, AppSpacing.xxl, AppSpacing.xl, AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  // ── Tags: vertical list ──────────────────────────────────
                  AnimatedOpacity(
                    opacity: contentOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      children: <Widget>[
                        _Tag(
                          label: card.category,
                          leadingEmoji: emoji,
                          bg: accentSurface,
                          fg: accent,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _Tag(
                          label: difficultyLabel,
                          leadingIcon: difficultyIcon,
                          bg: theme.colorScheme.secondaryContainer
                              .withValues(alpha: 0.75),
                          fg: theme.colorScheme.onSecondaryContainer,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // ── Title (auto-sized, never clips) ──────────────────────
                  Expanded(
                    child: AnimatedOpacity(
                      opacity: contentOpacity,
                      duration: const Duration(milliseconds: 320),
                      child: Center(
                        child: _TitleText(
                          title: card.title,
                          theme: theme,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Clickable Guide & Vocab rows ─────────────────────────
                  AnimatedOpacity(
                    opacity: contentOpacity,
                    duration: const Duration(milliseconds: 280),
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: <Widget>[
                          _TeaserTile(
                            icon: Icons.explore_rounded,
                            iconColor: accent,
                            label: 'Mini Guide',
                            subtitle: '4 structured prompts',
                            onTap: () => openDetail('guide'),
                          ),
                          Divider(
                            height: 1,
                            indent: AppSpacing.lg,
                            endIndent: AppSpacing.lg,
                            color:
                                theme.colorScheme.outline.withValues(alpha: 0.2),
                          ),
                          _TeaserTile(
                            icon: Icons.menu_book_rounded,
                            iconColor: accent,
                            label: 'Vocab Boost',
                            subtitle: '5 power words',
                            onTap: () => openDetail('vocab'),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.lg),

                  // ── Actions ──────────────────────────────────────────────
                  AnimatedOpacity(
                    opacity: actionsOpacity,
                    duration: const Duration(milliseconds: 300),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onRedraw,
                            icon: const Icon(Icons.shuffle_rounded, size: 19),
                            label: const Text('Re-draw'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          flex: 2,
                          child: FilledButton.icon(
                            onPressed: onPractice,
                            icon:
                                const Icon(Icons.play_arrow_rounded, size: 22),
                            label: const Text('Start Practice'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.md),
                              backgroundColor: accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Favorite button (top-right)
            Positioned(
              top: AppSpacing.md + 6,
              right: AppSpacing.md,
              child: AnimatedOpacity(
                opacity: contentOpacity,
                duration: const Duration(milliseconds: 300),
                child: _FavoriteButton(
                  isFavorite: isFavorite,
                  onTap: onToggleFavorite,
                  theme: theme,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Title — dynamic font size + FittedBox so it always fits
// ─────────────────────────────────────────────────────────────────────────────

class _TitleText extends StatelessWidget {
  const _TitleText({required this.title, required this.theme});
  final String title;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext ctx, BoxConstraints constraints) {
        double fontSize = 26;
        if (title.length > 65) {
          fontSize = 19;
        } else if (title.length > 45) {
          fontSize = 22;
        }

        return FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: constraints.maxWidth,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.bg,
    required this.fg,
    this.leadingEmoji,
    this.leadingIcon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final String? leadingEmoji;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingEmoji != null) ...<Widget>[
            Text(leadingEmoji!, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
          ] else if (leadingIcon != null) ...<Widget>[
            Icon(leadingIcon, size: 13, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A tappable row inside the feature teaser panel.
class _TeaserTile extends StatelessWidget {
  const _TeaserTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 20, color: theme.colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({
    required this.isFavorite,
    required this.onTap,
    required this.theme,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: isFavorite
              ? Colors.redAccent.withValues(alpha: 0.12)
              : theme.colorScheme.surfaceContainerHighest
                  .withValues(alpha: 0.7),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 22,
          color: isFavorite
              ? Colors.redAccent
              : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painters
// ─────────────────────────────────────────────────────────────────────────────

class _StripePainter extends CustomPainter {
  _StripePainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;
    const double gap = 28;
    for (double i = -size.height; i < size.width + size.height; i += gap) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
