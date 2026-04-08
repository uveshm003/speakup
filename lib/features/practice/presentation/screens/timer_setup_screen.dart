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
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Setup Practice'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: BlocBuilder<TimerBloc, TimerState>(
          builder: (BuildContext context, TimerState state) {
            return Column(
              children: <Widget>[
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xxl,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const SizedBox(height: AppSpacing.md),
                        // Premium Hero Card Representation
                        _HeroCardPreview(card: widget.card, accent: accent),
                        const SizedBox(height: 32),

                        // Timer Visual
                        Center(
                          child: TweenAnimationBuilder<double>(
                            key: ValueKey<int>(state.duration),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 600),
                            curve: Curves.easeOutBack,
                            builder:
                                (
                                  BuildContext context,
                                  double t,
                                  Widget? child,
                                ) {
                                  return _TimerPreviewRing(
                                    progress: t,
                                    seconds: state.duration,
                                    color: accent,
                                    trackColor: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.3),
                                  );
                                },
                          ),
                        ),
                        const SizedBox(height: 48),

                        Text(
                          'Practice Duration',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Premium Horizontal Selector
                        SizedBox(
                          height: 52,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount:
                                _presets.length + 1, // +1 for "Custom" button
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: AppSpacing.sm),
                            itemBuilder: (BuildContext context, int index) {
                              if (index < _presets.length) {
                                final int sec = _presets[index];
                                final bool selected =
                                    !_customMode && state.duration == sec;
                                return _DurationPill(
                                  label: _presetLabels[index],
                                  selected: selected,
                                  accent: accent,
                                  onTap: () {
                                    setState(() {
                                      _customMode = false;
                                      _customController.text = sec.toString();
                                    });
                                    context.read<TimerBloc>().add(
                                      TimerDurationSelected(sec),
                                    );
                                  },
                                );
                              }
                              // Custom Mode toggle
                              return _DurationPill(
                                label: 'Custom',
                                selected: _customMode,
                                accent: accent,
                                onTap: () => setState(() => _customMode = true),
                              );
                            },
                          ),
                        ),

                        // Custom Input Row (Animated reveal)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          height: _customMode ? 80 : 0,
                          padding: const EdgeInsets.only(top: AppSpacing.lg),
                          child: SingleChildScrollView(
                            physics: const NeverScrollableScrollPhysics(),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: _customController,
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 18,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '0',
                                      filled: true,
                                      fillColor: isDark
                                          ? theme
                                                .colorScheme
                                                .surfaceContainerHighest
                                          : theme.colorScheme.surfaceContainer,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          AppRadius.lg,
                                        ),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 14,
                                          ),
                                    ),
                                    onChanged: (_) {
                                      _applyCustomFromField();
                                    },
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  flex: 3,
                                  child: SegmentedButton<bool>(
                                    segments: const <ButtonSegment<bool>>[
                                      ButtonSegment<bool>(
                                        value: false,
                                        label: Text('Seconds'),
                                      ),
                                      ButtonSegment<bool>(
                                        value: true,
                                        label: Text('Minutes'),
                                      ),
                                    ],
                                    selected: <bool>{_customMinutes},
                                    onSelectionChanged: (Set<bool> next) {
                                      setState(() {
                                        _customMinutes = next.first;
                                      });
                                      _applyCustomFromField();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                      ],
                    ),
                  ),
                ),

                // Bottom Fixed CTA
                Container(
                  padding: const EdgeInsets.all(AppSpacing.xxl),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    height: 60,
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: accent.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.xl),
                        ),
                      ),
                      onPressed: () {
                        context.pushReplacement(
                          AppRoutes.activePractice,
                          extra: ActivePracticeArgs(
                            card: widget.card,
                            durationSeconds: state.duration,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(Icons.play_circle_fill_rounded, size: 28),
                          const SizedBox(width: AppSpacing.md),
                          Text(
                            'Begin Practice',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DurationPill extends StatelessWidget {
  const _DurationPill({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Material(
      color: selected
          ? accent
          : (isDark
                ? theme.colorScheme.surfaceContainerHighest
                : theme.colorScheme.surfaceContainer),
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : theme.colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCardPreview extends StatelessWidget {
  const _HeroCardPreview({required this.card, required this.accent});

  final TopicCard card;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            accent.withValues(alpha: 0.15),
            accent.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              card.category.toUpperCase(),
              style: GoogleFonts.inter(
                fontSize: 10,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
                color: accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            card.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
              fontSize: 22,
              height: 1.25,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
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
      width: 180,
      height: 180,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size(180, 180),
            painter: _PreviewRingPainter(
              progress: progress,
              color: color,
              trackColor: trackColor,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.timer_outlined, size: 28, color: Colors.grey),
              const SizedBox(height: 4),
              Text(
                formatPracticeMmSs(seconds),
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
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
    final double r = size.shortestSide / 2 - 12;
    final Paint track = Paint()
      ..color = trackColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;
    canvas.drawCircle(c, r, track);
    final Paint fill = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
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
