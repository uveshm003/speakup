import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/entities/vocab_word.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_bloc.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_event.dart';
import 'package:speakup/features/practice/presentation/bloc/timer_state.dart';
import 'package:speakup/features/practice/presentation/models/practice_route_args.dart';
import 'package:speakup/features/practice/presentation/utils/practice_format.dart';

class ActivePracticeScreen extends StatelessWidget {
  const ActivePracticeScreen({super.key, required this.args});

  final ActivePracticeArgs args;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TimerBloc>(
      create: (BuildContext context) {
        final TimerBloc bloc = TimerBloc();
        bloc.add(TimerDurationSelected(args.durationSeconds));
        bloc.add(const TimerStarted());
        return bloc;
      },
      child: _ActivePracticeBody(args: args),
    );
  }
}

class _ActivePracticeBody extends StatefulWidget {
  const _ActivePracticeBody({required this.args});

  final ActivePracticeArgs args;

  @override
  State<_ActivePracticeBody> createState() => _ActivePracticeBodyState();
}

class _ActivePracticeBodyState extends State<_ActivePracticeBody> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final TimerBloc timerBloc = context.read<TimerBloc>();
    final TimerState timerState = timerBloc.state;
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      if (timerState.status == TimerStatus.running) {
        timerBloc.add(const TimerPaused());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (timerState.status == TimerStatus.paused) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Timer paused while you were away. Tap Resume when ready.'), duration: Duration(seconds: 4)));
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.dispose();
    super.dispose();
  }



  Future<void> _confirmStop(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End practice?'),
          content: const Text('Your session will be saved as incomplete.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
              child: const Text('Stop'),
            ),
          ],
        );
      },
    );
    if (ok != true || !context.mounted) {
      return;
    }
    final TimerBloc bloc = context.read<TimerBloc>();
    bloc.add(const TimerStopped());
    final TimerState s = bloc.state;
    final int elapsed = s.duration - s.remaining;
    if (!context.mounted) {
      return;
    }
    context.pushReplacement(
      AppRoutes.sessionEnd,
      extra: SessionEndRouteArgs(card: widget.args.card, elapsedSeconds: elapsed, wasCompleted: false),
    );
  }

  Future<void> _maybePop(BuildContext context, TimerState state) async {
    if (state.status == TimerStatus.completed || state.status == TimerStatus.stopped) {
      if (context.mounted) {
        context.pop();
      }
      return;
    }
    final bool? leave = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Leave practice?'),
          content: const Text('Your progress will not be saved.'),
          actions: <Widget>[
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Stay')),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Leave')),
          ],
        );
      },
    );
    if (leave == true && context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color bg = isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest;
    final Color onBg = theme.colorScheme.onSurface;
    final TopicCard card = widget.args.card;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) {
          return;
        }
        final TimerState s = context.read<TimerBloc>().state;
        await _maybePop(context, s);
      },
      child: BlocListener<TimerBloc, TimerState>(
        listenWhen: (TimerState p, TimerState c) => c.status == TimerStatus.completed,
        listener: (BuildContext context, TimerState state) {
          context.pushReplacement(
            AppRoutes.sessionEnd,
            extra: SessionEndRouteArgs(card: widget.args.card, elapsedSeconds: state.duration, wasCompleted: true),
          );
        },
        child: BlocBuilder<TimerBloc, TimerState>(
          builder: (BuildContext context, TimerState state) {
            final int total = state.duration;
            final int remaining = state.remaining;
            final bool running = state.status == TimerStatus.running;
            final bool paused = state.status == TimerStatus.paused;
            final bool pulse = running && remaining <= 15;

            final double progress = total <= 0 ? 0 : remaining / total.clamp(1, 999999);

            return Scaffold(
              backgroundColor: bg,
              body: SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    // TOP HALF: IMMERSIVE TIMER AREA
                    Expanded(
                      flex: 4,
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                IconButton(icon: const Icon(Icons.close_rounded), color: onBg, onPressed: () async => _maybePop(context, state)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    'PRACTICING',
                                    style: GoogleFonts.inter(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.5,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 48), // Balance for back button
                              ],
                            ),
                          ),
                          const Spacer(),
                          // TOPIC TITLE
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                            child: Text(
                              card.title,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w700, height: 1.2, color: onBg),
                            ),
                          ),
                          const Spacer(),
                          // TIMER VISUAL
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              SizedBox(
                                width: 220,
                                height: 220,
                                child: CustomPaint(
                                  painter: _CountdownRingPainter(
                                    progress: progress,
                                    remaining: remaining,
                                    isDark: isDark,
                                    primaryColor: theme.colorScheme.primary,
                                    trackColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.25),
                                  ),
                                ),
                              ),
                              _PulsingTimerLabel(
                                pulse: pulse,
                                text: formatPracticeMmSs(remaining),
                                style: GoogleFonts.plusJakartaSans(fontSize: 48, fontWeight: FontWeight.w800, color: onBg),
                              ),
                              if (paused)
                                ClipOval(
                                  child: Container(
                                    width: 220,
                                    height: 220,
                                    color: Colors.black.withValues(alpha: 0.6),
                                    alignment: Alignment.center,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Text(
                                          'PAUSED',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 20,
                                            letterSpacing: 1.5,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Spacer(),
                          // CONTROLS
                          Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
                                  decoration: BoxDecoration(
                                    color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                    border: Border.all(color: onBg.withValues(alpha: 0.12)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      // Play / Pause
                                      Material(
                                        color: paused ? theme.colorScheme.primary : Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                        child: InkWell(
                                          onTap: () {
                                            final TimerBloc b = context.read<TimerBloc>();
                                            if (paused) {
                                              b.add(const TimerResumed());
                                            } else {
                                              b.add(const TimerPaused());
                                            }
                                          },
                                          borderRadius: BorderRadius.circular(AppRadius.full),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                                            child: Row(
                                              children: <Widget>[
                                                Icon(
                                                  paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                                                  color: paused ? theme.colorScheme.onPrimary : onBg,
                                                ),
                                                const SizedBox(width: 8),
                                                Text(
                                                  paused ? 'Resume' : 'Pause',
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: paused ? theme.colorScheme.onPrimary : onBg),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      // Stop
                                      Material(
                                        color: Colors.transparent,
                                        borderRadius: BorderRadius.circular(AppRadius.full),
                                        child: InkWell(
                                          onTap: () => _confirmStop(context),
                                          borderRadius: BorderRadius.circular(AppRadius.full),
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.sm),
                                            child: Row(
                                              children: <Widget>[
                                                Icon(Icons.stop_rounded, color: theme.colorScheme.error),
                                                const SizedBox(width: 8),
                                                Text(
                                                  'Stop',
                                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: theme.colorScheme.error),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BOTTOM HALF: HELPERS & INFORMATION
                    Expanded(
                      flex: 5,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerLowest,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
                          boxShadow: <BoxShadow>[
                            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20, offset: const Offset(0, -10)),
                          ],
                        ),
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            // Handle bar visual purely for aesthetic since it's no longer draggable
                            Container(
                              width: 40,
                              height: 5,
                              decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            TabBar(
                              controller: _tabController,
                              dividerColor: Colors.transparent,
                              indicatorSize: TabBarIndicatorSize.tab,
                              indicatorPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                              indicator: BoxDecoration(
                                color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(AppRadius.full),
                              ),
                              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w700),
                              unselectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.w500),
                              tabs: const <Widget>[
                                Tab(text: 'Mini Guide'),
                                Tab(text: 'Vocabulary'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                controller: _tabController,
                                children: <Widget>[
                                  ListView(padding: const EdgeInsets.all(AppSpacing.xxl), children: _guideChildren(card, theme)),
                                  ListView(padding: const EdgeInsets.all(AppSpacing.xxl), children: _vocabChildren(card, theme)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _guideChildren(TopicCard card, ThemeData theme) {
  if (card.guide.isEmpty) {
    return <Widget>[Text('No guide for this topic.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))];
  }
  return card.guide
      .map(
        (String line) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Icon(Icons.check_circle_outline_rounded, size: 20, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(line, style: GoogleFonts.inter(fontSize: 15, height: 1.5, color: theme.colorScheme.onSurface)),
              ),
            ],
          ),
        ),
      )
      .toList();
}

List<Widget> _vocabChildren(TopicCard card, ThemeData theme) {
  if (card.vocabBoost.isEmpty) {
    return <Widget>[Text('No vocabulary listed.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant))];
  }
  return card.vocabBoost.map((VocabWord w) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            w.word,
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(w.meaning, style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }).toList();
}

class _PulsingTimerLabel extends StatefulWidget {
  const _PulsingTimerLabel({required this.pulse, required this.text, required this.style});

  final bool pulse;
  final String text;
  final TextStyle style;

  @override
  State<_PulsingTimerLabel> createState() => _PulsingTimerLabelState();
}

class _PulsingTimerLabelState extends State<_PulsingTimerLabel> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 650));
    if (widget.pulse) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _PulsingTimerLabel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse != oldWidget.pulse) {
      if (widget.pulse) {
        _controller.repeat(reverse: true);
      } else {
        _controller
          ..stop()
          ..reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        final double scale = widget.pulse ? 1.0 + (_controller.value * 0.05) : 1.0;
        return Transform.scale(
          scale: scale,
          child: Text(widget.text, style: widget.style),
        );
      },
    );
  }
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.remaining,
    required this.isDark,
    required this.primaryColor,
    required this.trackColor,
  });

  final double progress;
  final int remaining;
  final bool isDark;
  final Color primaryColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 12; // slightly thicker

    final Paint track = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14;
    canvas.drawCircle(c, r, track);

    Color baseColor;
    if (remaining <= 15) {
      baseColor = AppColors.error;
    } else if (remaining <= 30) {
      baseColor = AppColors.warning;
    } else {
      baseColor = primaryColor;
    }

    final SweepGradient gradient = SweepGradient(
      startAngle: -1.5707963267948966, // -pi/2
      endAngle: 4.71238898038469, // 3 * pi / 2
      colors: <Color>[
        baseColor.withValues(alpha: 0.4),
        baseColor,
      ],
      stops: const <double>[0.0, 1.0],
    );

    final Rect rect = Rect.fromCircle(center: c, radius: r);
    final Paint fill = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final double sweep = progress * 6.283185307179586; // 2 * pi
    canvas.drawArc(rect, -1.5707963267948966, sweep, false, fill); // -pi/2 start
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.remaining != remaining || oldDelegate.isDark != isDark;
  }
}
