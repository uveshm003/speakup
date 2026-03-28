import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_bloc.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_event.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_state.dart';
import 'package:speakup/features/practice/presentation/models/practice_route_args.dart';
import 'package:speakup/features/practice/presentation/utils/practice_format.dart';

/// Timer selection before practice; [card] is passed from draw / card detail.
class TimerSetupScreen extends StatelessWidget {
  const TimerSetupScreen({super.key, this.card});

  final TopicCard? card;

  @override
  Widget build(BuildContext context) {
    if (card == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Practice')),
        body: const Center(child: Text('No card to practice')),
      );
    }
    return BlocProvider<TimerBloc>(
      create: (_) => TimerBloc(),
      child: _TimerSetupBody(card: card!),
    );
  }
}

class _TimerSetupBody extends StatefulWidget {
  const _TimerSetupBody({required this.card});

  final TopicCard card;

  @override
  State<_TimerSetupBody> createState() => _TimerSetupBodyState();
}

class _TimerSetupBodyState extends State<_TimerSetupBody> {
  static const List<int> _presets = <int>[30, 60, 120, 180, 300];
  static const List<String> _presetLabels = <String>[
    '30s',
    '1 min',
    '2 min',
    '3 min',
    '5 min',
  ];

  bool _customMode = false;
  final TextEditingController _customController = TextEditingController();
  bool _customMinutes = false;

  @override
  void initState() {
    super.initState();
    _customController.text = '120';
  }

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyCustomFromField() {
    final int? n = int.tryParse(_customController.text.trim());
    if (n == null || n <= 0) {
      return;
    }
    final int seconds = _customMinutes ? n * 60 : n;
    final int clamped = seconds.clamp(1, 3600);
    context.read<TimerBloc>().add(TimerDurationSelected(clamped));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(widget.card.category);

    return Scaffold(
      appBar: AppBar(title: const Text('Practice')),
      body: SafeArea(
        child: BlocBuilder<TimerBloc, TimerState>(
          builder: (BuildContext context, TimerState state) {
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.md,
                AppSpacing.xxl,
                AppSpacing.xxl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _MiniCardPreview(card: widget.card, accent: accent),
                  const SizedBox(height: AppSpacing.xxl),
                  Text(
                    'How long will you practice?',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: List<Widget>.generate(_presets.length, (int i) {
                      final int sec = _presets[i];
                      final bool selected =
                          !_customMode && state.duration == sec;
                      return FilterChip(
                        label: Text(_presetLabels[i]),
                        selected: selected,
                        onSelected: (bool v) {
                          if (!v) {
                            return;
                          }
                          setState(() {
                            _customMode = false;
                            _customController.text = sec.toString();
                          });
                          context.read<TimerBloc>().add(
                                TimerDurationSelected(sec),
                              );
                        },
                        selectedColor: theme.colorScheme.primary,
                        checkmarkColor: theme.colorScheme.onPrimary,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                        showCheckmark: false,
                      );
                    }),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Custom',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: TextField(
                          controller: _customController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Duration',
                          ),
                          onTap: () => setState(() => _customMode = true),
                          onChanged: (_) {
                            setState(() => _customMode = true);
                            _applyCustomFromField();
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      SegmentedButton<bool>(
                        segments: const <ButtonSegment<bool>>[
                          ButtonSegment<bool>(
                            value: false,
                            label: Text('sec'),
                          ),
                          ButtonSegment<bool>(
                            value: true,
                            label: Text('min'),
                          ),
                        ],
                        selected: <bool>{_customMinutes},
                        onSelectionChanged: (Set<bool> next) {
                          setState(() {
                            _customMode = true;
                            _customMinutes = next.first;
                          });
                          _applyCustomFromField();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  Center(
                    child: TweenAnimationBuilder<double>(
                      key: ValueKey<int>(state.duration),
                      tween: Tween<double>(begin: 0, end: 1),
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      builder: (
                        BuildContext context,
                        double t,
                        Widget? child,
                      ) {
                        return _TimerPreviewRing(
                          progress: t,
                          seconds: state.duration,
                          color: theme.colorScheme.primary,
                          trackColor: theme.colorScheme.outlineVariant,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.pushReplacement(
                          AppRoutes.activePractice,
                          extra: ActivePracticeArgs(
                            card: widget.card,
                            durationSeconds: state.duration,
                          ),
                        );
                      },
                      icon: const Icon(Icons.play_arrow_rounded, size: 28),
                      label: const Text('Start Practice'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MiniCardPreview extends StatelessWidget {
  const _MiniCardPreview({
    required this.card,
    required this.accent,
  });

  final TopicCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Text(
                card.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(color: accent.withValues(alpha: 0.45)),
              ),
              child: Text(
                card.category,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimerPreviewRing extends StatelessWidget {
  const _TimerPreviewRing({
    required this.progress,
    required this.seconds,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final int seconds;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(220, 220),
            painter: _PreviewRingPainter(
              progress: progress,
              color: color,
              trackColor: trackColor,
            ),
          ),
          Text(
            formatPracticeMmSs(seconds),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewRingPainter extends CustomPainter {
  _PreviewRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 10;
    final Paint track = Paint()
      ..color = trackColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(c, r, track);
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    final double sweep = progress * 6.283185307179586;
    canvas.drawArc(
      Rect.fromCircle(center: c, radius: r),
      -1.5707963267948966,
      sweep,
      false,
      fill,
    );
  }

  @override
  bool shouldRepaint(covariant _PreviewRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
