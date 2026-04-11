import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/services/recording_service.dart';
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
  late final RecordingService _recordingService;
  late final AnimationController _recPulseController;

  bool _isRecording = false;
  String? _recordingPath;
  late final String _sessionId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _recordingService = RecordingService();
    _recPulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);
    _sessionId = 's_${DateTime.now().microsecondsSinceEpoch}_${widget.args.card.cardId}';
    // Auto-start recording once the frame is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoStartRecording());
  }

  Future<void> _autoStartRecording() async {
    final bool started = await _recordingService.startRecording(_sessionId);
    if (mounted && started) {
      setState(() => _isRecording = true);
    }
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
    _recPulseController.dispose();
    _recordingService.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final String? path = await _recordingService.stopRecording();
      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingPath = path;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Recording saved ✓'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating));
      }
    } else {
      final bool started = await _recordingService.startRecording(_sessionId);
      if (mounted) {
        if (started) {
          setState(() => _isRecording = true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Microphone permission denied. Please enable it in Settings.'),
              duration: Duration(seconds: 4),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<String?> _stopRecordingIfActive() async {
    if (_isRecording) {
      final String? path = await _recordingService.stopRecording();
      if (mounted) setState(() => _isRecording = false);
      return path ?? _recordingPath;
    }
    return _recordingPath;
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
    if (ok != true || !context.mounted) return;
    final String? path = await _stopRecordingIfActive();
    if (!context.mounted) return;
    final TimerBloc bloc = context.read<TimerBloc>();
    bloc.add(const TimerStopped());
    final TimerState s = bloc.state;
    final int elapsed = s.duration - s.remaining;
    if (!context.mounted) return;
    context.pushReplacement(
      AppRoutes.sessionEnd,
      extra: SessionEndRouteArgs(card: widget.args.card, elapsedSeconds: elapsed, wasCompleted: false, recordingPath: path),
    );
  }

  Future<void> _maybePop(BuildContext context, TimerState state) async {
    if (state.status == TimerStatus.completed || state.status == TimerStatus.stopped) {
      if (context.mounted) context.pop();
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
      await _recordingService.cancelRecording();
      if (!context.mounted) return;
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
        if (didPop) return;
        final TimerState s = context.read<TimerBloc>().state;
        await _maybePop(context, s);
      },
      child: BlocListener<TimerBloc, TimerState>(
        listenWhen: (TimerState p, TimerState c) => c.status == TimerStatus.completed,
        listener: (BuildContext context, TimerState state) async {
          final String? path = await _stopRecordingIfActive();
          if (!context.mounted) return;
          context.pushReplacement(
            AppRoutes.sessionEnd,
            extra: SessionEndRouteArgs(card: widget.args.card, elapsedSeconds: state.duration, wasCompleted: true, recordingPath: path),
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
              body: Stack(
                children: <Widget>[
                  // ── Timer area (top, fixed, scrolled below by sheet) ──────
                  SafeArea(
                    bottom: false,
                    child: _TimerArea(
                      card: card,
                      theme: theme,
                      isDark: isDark,
                      onBg: onBg,
                      progress: progress,
                      remaining: remaining,
                      paused: paused,
                      pulse: pulse,
                      isRecording: _isRecording,
                      recPulseController: _recPulseController,
                      onClosePressed: () => _maybePop(context, state),
                      onPlayPausePressed: () {
                        final TimerBloc b = context.read<TimerBloc>();
                        if (paused) {
                          b.add(const TimerResumed());
                        } else {
                          b.add(const TimerPaused());
                        }
                      },
                      onStopPressed: () => _confirmStop(context),
                      onMicPressed: _toggleRecording,
                    ),
                  ),

                  // ── Bottom draggable sheet ─────────────────────────────────
                  DraggableScrollableSheet(
                    initialChildSize: 0.42,
                    minChildSize: 0.12,
                    maxChildSize: 0.72,
                    snap: true,
                    snapSizes: const <double>[0.12, 0.42, 0.72],
                    builder: (BuildContext ctx, ScrollController scrollController) {
                      return _BottomDrawer(
                        scrollController: scrollController,
                        tabController: _tabController,
                        card: card,
                        theme: theme,
                        isDark: isDark,
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

// ─────────────────────────────────────────────────────────────────────────────
// Timer area (top section of the Stack)
// ─────────────────────────────────────────────────────────────────────────────

class _TimerArea extends StatelessWidget {
  const _TimerArea({
    required this.card,
    required this.theme,
    required this.isDark,
    required this.onBg,
    required this.progress,
    required this.remaining,
    required this.paused,
    required this.pulse,
    required this.isRecording,
    required this.recPulseController,
    required this.onClosePressed,
    required this.onPlayPausePressed,
    required this.onStopPressed,
    required this.onMicPressed,
  });

  final TopicCard card;
  final ThemeData theme;
  final bool isDark;
  final Color onBg;
  final double progress;
  final int remaining;
  final bool paused;
  final bool pulse;
  final bool isRecording;
  final AnimationController recPulseController;
  final VoidCallback onClosePressed;
  final VoidCallback onPlayPausePressed;
  final VoidCallback onStopPressed;
  final VoidCallback onMicPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // ── App bar row ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              IconButton(icon: const Icon(Icons.close_rounded), color: onBg, onPressed: onClosePressed),
              // REC / PRACTICING badge
              _RecBadge(isRecording: isRecording, recPulseController: recPulseController, theme: theme),
              const SizedBox(width: 48),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // ── Card title ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
          child: Text(
            card.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 20, fontWeight: FontWeight.w700, height: 1.25, color: onBg),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── Timer ring ───────────────────────────────────────────────────
        Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              height: 200,
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
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 46, fontWeight: FontWeight.w800, color: onBg),
            ),
            if (paused)
              ClipOval(
                child: Container(
                  width: 200,
                  height: 200,
                  color: Colors.black.withValues(alpha: 0.6),
                  alignment: Alignment.center,
                  child: Text(
                    'PAUSED',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 20,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),

        const SizedBox(height: AppSpacing.xl),

        // ── Glassmorphic control bar ──────────────────────────────────────
        _ControlBar(
          isDark: isDark,
          onBg: onBg,
          theme: theme,
          paused: paused,
          isRecording: isRecording,
          recPulseController: recPulseController,
          onPlayPause: onPlayPausePressed,
          onMic: onMicPressed,
          onStop: onStopPressed,
        ),

        // Reserve space so the sheet handle peek doesn't overlap controls
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REC badge
// ─────────────────────────────────────────────────────────────────────────────

class _RecBadge extends StatelessWidget {
  const _RecBadge({required this.isRecording, required this.recPulseController, required this.theme});

  final bool isRecording;
  final AnimationController recPulseController;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (isRecording) ...<Widget>[
          AnimatedBuilder(
            animation: recPulseController,
            builder: (BuildContext ctx, Widget? child) {
              return Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.4 + 0.6 * recPulseController.value),
                ),
              );
            },
          ),
          const SizedBox(width: 5),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isRecording ? AppColors.error.withValues(alpha: 0.12) : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: isRecording ? Border.all(color: AppColors.error.withValues(alpha: 0.35)) : null,
          ),
          child: Text(
            isRecording ? 'REC · PRACTICING' : 'PRACTICING',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: isRecording ? AppColors.error : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control bar (Play/Pause · Mic · Stop) — uses LayoutBuilder to stay in bounds
// ─────────────────────────────────────────────────────────────────────────────

class _ControlBar extends StatelessWidget {
  const _ControlBar({
    required this.isDark,
    required this.onBg,
    required this.theme,
    required this.paused,
    required this.isRecording,
    required this.recPulseController,
    required this.onPlayPause,
    required this.onMic,
    required this.onStop,
  });

  final bool isDark;
  final Color onBg;
  final ThemeData theme;
  final bool paused;
  final bool isRecording;
  final AnimationController recPulseController;
  final VoidCallback onPlayPause;
  final VoidCallback onMic;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                // ── Play / Pause ─────────────────────────────
                Flexible(
                  child: _ControlPill(
                    filled: paused,
                    fillColor: theme.colorScheme.primary,
                    onTap: onPlayPause,
                    icon: paused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                    label: paused ? 'Resume' : 'Pause',
                    iconColor: paused ? theme.colorScheme.onPrimary : onBg,
                    labelColor: paused ? theme.colorScheme.onPrimary : onBg,
                  ),
                ),

                const SizedBox(width: AppSpacing.xs),

                // ── Mic ──────────────────────────────────────
                Flexible(
                  child: _MicPill(isRecording: isRecording, isDark: isDark, onBg: onBg, pulseController: recPulseController, onTap: onMic),
                ),

                const SizedBox(width: AppSpacing.xs),

                // ── Stop ─────────────────────────────────────
                Flexible(
                  child: _ControlPill(
                    filled: false,
                    fillColor: Colors.transparent,
                    onTap: onStop,
                    icon: Icons.stop_rounded,
                    label: 'Stop',
                    iconColor: theme.colorScheme.error,
                    labelColor: theme.colorScheme.error,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mic pill
// ─────────────────────────────────────────────────────────────────────────────

class _MicPill extends StatelessWidget {
  const _MicPill({required this.isRecording, required this.isDark, required this.onBg, required this.pulseController, required this.onTap});

  final bool isRecording;
  final bool isDark;
  final Color onBg;
  final AnimationController pulseController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: AnimatedBuilder(
          animation: pulseController,
          builder: (BuildContext ctx, Widget? child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: isRecording ? AppColors.error.withValues(alpha: 0.15 + 0.1 * pulseController.value) : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: isRecording ? Border.all(color: AppColors.error.withValues(alpha: 0.5 + 0.3 * pulseController.value), width: 1.5) : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Icon(
                    isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                    color: isRecording ? AppColors.error : onBg.withValues(alpha: 0.75),
                    size: 20,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      isRecording ? 'Stop Rec' : 'Record',
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isRecording ? AppColors.error : onBg.withValues(alpha: 0.75),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Generic control pill (Play/Pause, Stop)
// ─────────────────────────────────────────────────────────────────────────────

class _ControlPill extends StatelessWidget {
  const _ControlPill({
    required this.filled,
    required this.fillColor,
    required this.onTap,
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.labelColor,
  });

  final bool filled;
  final Color fillColor;
  final VoidCallback onTap;
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color labelColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? fillColor : Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.full),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: labelColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom drawer (DraggableScrollableSheet content)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomDrawer extends StatelessWidget {
  const _BottomDrawer({required this.scrollController, required this.tabController, required this.card, required this.theme, required this.isDark});

  final ScrollController scrollController;
  final TabController tabController;
  final TopicCard card;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 24, offset: const Offset(0, -6))],
      ),
      child: Column(
        children: <Widget>[
          // ── Drag handle + tab bar (not scrollable, always visible) ──────
          SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: Container(
                    width: 40,
                    height: 5,
                    decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TabBar(
                  controller: tabController,
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
              ],
            ),
          ),

          // ── Tab content fills remaining space ───────────────────────────
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: <Widget>[
                ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
                  children: _guideChildren(card, theme),
                ),
                ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
                  children: _vocabChildren(card, theme),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Guide / Vocab helpers
// ─────────────────────────────────────────────────────────────────────────────

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
            style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.primary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(w.meaning, style: GoogleFonts.inter(fontSize: 14, color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }).toList();
}

// ─────────────────────────────────────────────────────────────────────────────
// Pulsing timer label
// ─────────────────────────────────────────────────────────────────────────────

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
    if (widget.pulse) _controller.repeat(reverse: true);
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

// ─────────────────────────────────────────────────────────────────────────────
// Countdown ring painter
// ─────────────────────────────────────────────────────────────────────────────

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
    final double r = size.shortestSide / 2 - 12;

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
      startAngle: -1.5707963267948966,
      endAngle: 4.71238898038469,
      colors: <Color>[baseColor.withValues(alpha: 0.4), baseColor],
      stops: const <double>[0.0, 1.0],
    );

    final Rect rect = Rect.fromCircle(center: c, radius: r);
    final Paint fill = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round;

    final double sweep = progress * 6.283185307179586;
    canvas.drawArc(rect, -1.5707963267948966, sweep, false, fill);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.remaining != remaining || oldDelegate.isDark != isDark;
  }
}
