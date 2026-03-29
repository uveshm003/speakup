import 'dart:math' show pi;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';

/// 3D flip card: front (brand back) → back (topic preview). [onFlipPhaseChanged] for BLoC sync.
class FlipDrawCard extends StatefulWidget {
  const FlipDrawCard({
    super.key,
    required this.card,
    required this.onRedraw,
    required this.onPractice,
    required this.onToggleFavorite,
    required this.isFavorite,
    this.onFlipPhaseChanged,
  });

  final TopicCard card;
  final VoidCallback onRedraw;
  final VoidCallback onPractice;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final ValueChanged<bool>? onFlipPhaseChanged;

  @override
  State<FlipDrawCard> createState() => _FlipDrawCardState();
}

class _FlipDrawCardState extends State<FlipDrawCard> with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final Animation<double> _entranceScale;
  late final AnimationController _flipController;
  late final Animation<double> _flipTurns;

  double _titleOpacity = 0;
  double _badgesOpacity = 0;
  double _actionsOpacity = 0;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _entranceScale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic));
    _flipController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _flipTurns = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 0, end: 1).chain(CurveTween(curve: Curves.easeInOutCubic)), weight: 1),
    ]).animate(_flipController);
    _flipController.addStatusListener(_onFlipStatus);
    _runEntranceThenFlip();
  }

  @override
  void didUpdateWidget(covariant FlipDrawCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.cardId != widget.card.cardId) {
      _titleOpacity = 0;
      _badgesOpacity = 0;
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
      if (!mounted) {
        return;
      }
      Future<void>.delayed(const Duration(milliseconds: 120), () {
        if (mounted) {
          widget.onFlipPhaseChanged?.call(true);
          _flipController.forward(from: 0);
        }
      });
    });
  }

  Future<void> _runStagger() async {
    if (!mounted) {
      return;
    }
    setState(() => _titleOpacity = 1);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
    setState(() => _badgesOpacity = 1);
    await Future<void>.delayed(const Duration(milliseconds: 90));
    if (!mounted) {
      return;
    }
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(widget.card.category);
    final double w = MediaQuery.sizeOf(context).width;
    final double cardW = (w * 0.85).clamp(0.0, 480.0);
    final double cardH = cardW / 1.5;

    return Hero(
      tag: 'card-hero-${widget.card.cardId}',
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[_entranceController, _flipController]),
          builder: (BuildContext context, Widget? child) {
            final double scale = _entranceScale.value;
            final double t = _flipTurns.value;
            final double angle = t * pi;
            final bool showFront = angle < pi / 2;

            return Transform.scale(
              scale: scale,
              child: SizedBox(
                width: cardW,
                height: cardH,
                child: GestureDetector(
                  onHorizontalDragEnd: (DragEndDetails d) {
                    final double vx = d.velocity.pixelsPerSecond.dx;
                    if (vx.abs() > 280) {
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
                            child: _CardBackPreview(
                              card: widget.card,
                              accent: accent,
                              theme: theme,
                              difficultyLabel: _difficultyLabel(widget.card.difficulty),
                              titleOpacity: _titleOpacity,
                              badgesOpacity: _badgesOpacity,
                              actionsOpacity: _actionsOpacity,
                              isFavorite: widget.isFavorite,
                              onToggleFavorite: widget.onToggleFavorite,
                              onRedraw: widget.onRedraw,
                              onPractice: widget.onPractice,
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

class _CardFront extends StatelessWidget {
  const _CardFront({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color start = dark ? AppColorsDark.primaryDark : AppColors.primary;
    final Color end = dark ? AppColorsDark.primary : AppColors.primaryLight;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[BoxShadow(color: theme.shadowColor.withValues(alpha: 0.18), blurRadius: 28, offset: const Offset(0, 14))],
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[start, end]),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              CustomPaint(
                painter: _DotPatternPainter(color: Colors.white.withValues(alpha: dark ? 0.06 : 0.12)),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.record_voice_over_rounded, size: 56, color: theme.colorScheme.onPrimary.withValues(alpha: 0.95)),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'SpeakUp',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onPrimary.withValues(alpha: 0.98),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), bottomLeft: Radius.circular(24)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DotPatternPainter extends CustomPainter {
  _DotPatternPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const double step = 14;
    final Paint p = Paint()..color = color;
    for (double x = 0; x < size.width; x += step) {
      for (double y = 0; y < size.height; y += step) {
        canvas.drawCircle(Offset(x, y), 1.2, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CardBackPreview extends StatelessWidget {
  const _CardBackPreview({
    required this.card,
    required this.accent,
    required this.theme,
    required this.difficultyLabel,
    required this.titleOpacity,
    required this.badgesOpacity,
    required this.actionsOpacity,
    required this.isFavorite,
    required this.onToggleFavorite,
    required this.onRedraw,
    required this.onPractice,
  });

  final TopicCard card;
  final Color accent;
  final ThemeData theme;
  final String difficultyLabel;
  final double titleOpacity;
  final double badgesOpacity;
  final double actionsOpacity;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRedraw;
  final VoidCallback onPractice;

  @override
  Widget build(BuildContext context) {
    final Color bg = theme.brightness == Brightness.dark ? AppColorsDark.surface : Colors.white;

    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
          boxShadow: <BoxShadow>[BoxShadow(color: theme.shadowColor.withValues(alpha: 0.16), blurRadius: 28, offset: const Offset(0, 14))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 4, color: accent)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 18, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AnimatedOpacity(
                      opacity: badgesOpacity,
                      duration: const Duration(milliseconds: 280),
                      child: Row(
                        children: <Widget>[
                          _pill(context, card.category, theme.colorScheme.primaryContainer, theme.colorScheme.onPrimaryContainer),
                          const Spacer(),
                          _pill(context, difficultyLabel, theme.colorScheme.secondaryContainer, theme.colorScheme.onSecondaryContainer),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(
                      child: AnimatedOpacity(
                        opacity: titleOpacity,
                        duration: const Duration(milliseconds: 320),
                        child: Text(
                          card.title,
                          textAlign: TextAlign.center,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Divider(color: theme.colorScheme.outline.withValues(alpha: 0.25)),
                    AnimatedOpacity(
                      opacity: badgesOpacity,
                      duration: const Duration(milliseconds: 280),
                      child: _teaserRow(context, icon: Icons.explore_rounded, label: 'Mini Guide'),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AnimatedOpacity(
                      opacity: badgesOpacity,
                      duration: const Duration(milliseconds: 280),
                      child: _teaserRow(context, icon: Icons.menu_book_rounded, label: 'Vocabulary Boost'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AnimatedOpacity(
                      opacity: actionsOpacity,
                      duration: const Duration(milliseconds: 300),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onRedraw,
                              icon: const Icon(Icons.shuffle_rounded, size: 20),
                              label: const Text('Re-draw'),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onPractice,
                              icon: const Icon(Icons.play_arrow_rounded, size: 22),
                              label: const Text('Practice'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filledTonal(
                  onPressed: onToggleFavorite,
                  icon: Icon(isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, color: isFavorite ? Colors.redAccent : null),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(BuildContext context, String text, Color bg, Color fg) {
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

  Widget _teaserRow(BuildContext context, {required IconData icon, required String label}) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(label, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant),
      ],
    );
  }
}
