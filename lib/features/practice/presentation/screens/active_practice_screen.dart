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

class _ActivePracticeBodyState extends State<_ActivePracticeBody>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final TabController _tabController;
  late final DraggableScrollableController _sheetController;

  double _sheetExtent = 0.1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _sheetController = DraggableScrollableController();
    _sheetController.addListener(_onSheetChanged);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    final timerBloc = context.read<TimerBloc>();
    final timerState = timerBloc.state;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (timerState.status == TimerStatus.running) {
        timerBloc.add(const TimerPaused());
      }
    } else if (state == AppLifecycleState.resumed) {
      if (timerState.status == TimerStatus.paused) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Timer paused while you were away. Tap Resume when ready.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) {
      return;
    }
    setState(() {});
  }

  void _onSheetChanged() {
    if (_sheetController.isAttached) {
      setState(() => _sheetExtent = _sheetController.size);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _sheetController.removeListener(_onSheetChanged);
    _sheetController.dispose();
    super.dispose();
  }

  Color _ringColor(int remaining, Brightness brightness) {
    final Color primary =
        brightness == Brightness.dark ? AppColorsDark.primary : AppColors.primary;
    const Color amber = AppColors.warning;
    const Color red = AppColors.error;
    if (remaining <= 10) {
      final double t = remaining / 10.0;
      return ColorTween(begin: amber, end: red).transform(1 - t)!;
    }
    if (remaining <= 30) {
      final double t = (remaining - 10) / 20.0;
      return ColorTween(begin: primary, end: amber).transform(1 - t)!;
    }
    return primary;
  }

  Future<void> _confirmStop(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('End practice?'),
          content: const Text(
            'Your session will be saved as incomplete.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton.tonal(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
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
      extra: SessionEndRouteArgs(
        card: widget.args.card,
        elapsedSeconds: elapsed,
        wasCompleted: false,
      ),
    );
  }

  Future<void> _maybePop(BuildContext context, TimerState state) async {
    if (state.status == TimerStatus.completed ||
        state.status == TimerStatus.stopped) {
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
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Stay'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Leave'),
            ),
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
    final Color bg = isDark ? AppColorsDark.surface : AppColors.primaryLight;
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
        listenWhen: (TimerState p, TimerState c) =>
            c.status == TimerStatus.completed,
        listener: (BuildContext context, TimerState state) {
          context.pushReplacement(
            AppRoutes.sessionEnd,
            extra: SessionEndRouteArgs(
              card: widget.args.card,
              elapsedSeconds: state.duration,
              wasCompleted: true,
            ),
          );
        },
        child: BlocBuilder<TimerBloc, TimerState>(
          builder: (BuildContext context, TimerState state) {
            final int total = state.duration;
            final int remaining = state.remaining;
            final bool running = state.status == TimerStatus.running;
            final bool paused = state.status == TimerStatus.paused;
            final bool pulse = running && remaining < 10;

            final double progress =
                total <= 0 ? 0 : remaining / total.clamp(1, 999999);
            final Color ringColor = _ringColor(remaining, theme.brightness);

            final double scrimT = ((_sheetExtent - 0.1) / 0.5).clamp(0.0, 1.0);

            return Scaffold(
              backgroundColor: bg,
              body: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  SafeArea(
                    child: Column(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                          ),
                          child: Row(
                            children: <Widget>[
                              IconButton(
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: onBg,
                                onPressed: () async {
                                  await _maybePop(context, state);
                                },
                              ),
                              const Spacer(),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xxl,
                          ),
                          child: Text(
                            card.title,
                            textAlign: TextAlign.center,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                              color: onBg,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            SizedBox(
                              width: 200,
                              height: 200,
                              child: CustomPaint(
                                painter: _CountdownRingPainter(
                                  progress: progress,
                                  color: ringColor,
                                  trackColor: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.45),
                                ),
                              ),
                            ),
                            _PulsingTimerLabel(
                              pulse: pulse,
                              text: formatPracticeMmSs(remaining),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 42,
                                fontWeight: FontWeight.w700,
                                color: onBg,
                              ),
                            ),
                            if (paused)
                              ClipOval(
                                child: Container(
                                  width: 200,
                                  height: 200,
                                  color: Colors.black.withValues(alpha: 0.42),
                                  alignment: Alignment.center,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Text(
                                        'Paused',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      FilledButton(
                                        onPressed: () {
                                          context
                                              .read<TimerBloc>()
                                              .add(const TimerResumed());
                                        },
                                        child: const Text('Resume'),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const Spacer(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xxl,
                            0,
                            AppSpacing.xxl,
                            AppSpacing.lg,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              IconButton(
                                iconSize: 32,
                                style: IconButton.styleFrom(
                                  backgroundColor:
                                      theme.colorScheme.primaryContainer,
                                  foregroundColor:
                                      theme.colorScheme.onPrimaryContainer,
                                ),
                                onPressed: () {
                                  final TimerBloc b = context.read<TimerBloc>();
                                  if (paused) {
                                    b.add(const TimerResumed());
                                  } else {
                                    b.add(const TimerPaused());
                                  }
                                },
                                icon: Icon(
                                  paused
                                      ? Icons.play_arrow_rounded
                                      : Icons.pause_rounded,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xxl),
                              OutlinedButton(
                                onPressed: () => _confirmStop(context),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: theme.colorScheme.error,
                                  side: BorderSide(
                                    color: theme.colorScheme.error
                                        .withValues(alpha: 0.65),
                                  ),
                                ),
                                child: const Text('Stop'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 72),
                      ],
                    ),
                  ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.38 * scrimT),
                      ),
                    ),
                  ),
                  DraggableScrollableSheet(
                    controller: _sheetController,
                    initialChildSize: 0.1,
                    minChildSize: 0.1,
                    maxChildSize: 0.6,
                    builder: (
                      BuildContext context,
                      ScrollController scrollController,
                    ) {
                      return Material(
                        color: theme.colorScheme.surface.withValues(
                          alpha: 0.94,
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.lg),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Column(
                          children: <Widget>[
                            const SizedBox(height: AppSpacing.sm),
                            Icon(
                              Icons.horizontal_rule_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            Text(
                              'Tap to peek',
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Icon(Icons.keyboard_arrow_up_rounded),
                            TabBar(
                              controller: _tabController,
                              tabs: const <Widget>[
                                Tab(text: 'Mini Guide'),
                                Tab(text: 'Vocabulary'),
                              ],
                            ),
                            Expanded(
                              child: ListView(
                                controller: scrollController,
                                padding: const EdgeInsets.fromLTRB(
                                  AppSpacing.xxl,
                                  AppSpacing.sm,
                                  AppSpacing.xxl,
                                  AppSpacing.xxl,
                                ),
                                children: _tabController.index == 0
                                    ? _guideChildren(card, theme)
                                    : _vocabChildren(card, theme),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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

List<Widget> _guideChildren(TopicCard card, ThemeData theme) {
  if (card.guide.isEmpty) {
    return <Widget>[
      Text(
        'No guide for this topic.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }
  return card.guide
      .map(
        (String line) => Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                '• ',
                style: theme.textTheme.bodyLarge,
              ),
              Expanded(
                child: Text(
                  line,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      )
      .toList();
}

List<Widget> _vocabChildren(TopicCard card, ThemeData theme) {
  if (card.vocabBoost.isEmpty) {
    return <Widget>[
      Text(
        'No vocabulary listed.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    ];
  }
  return card.vocabBoost.map((VocabWord w) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            w.word,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            w.meaning,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }).toList();
}

class _PulsingTimerLabel extends StatefulWidget {
  const _PulsingTimerLabel({
    required this.pulse,
    required this.text,
    required this.style,
  });

  final bool pulse;
  final String text;
  final TextStyle style;

  @override
  State<_PulsingTimerLabel> createState() => _PulsingTimerLabelState();
}

class _PulsingTimerLabelState extends State<_PulsingTimerLabel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
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
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset c = Offset(size.width / 2, size.height / 2);
    final double r = size.shortestSide / 2 - 8;
    final Paint track = Paint()
      ..color = trackColor
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
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.trackColor != trackColor;
  }
}
