import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';

import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';

/// Bottom sheet that plays back a recorded practice session.
///
/// Usage:
/// ```dart
/// showModalBottomSheet(
///   context: context,
///   isScrollControlled: true,
///   backgroundColor: Colors.transparent,
///   builder: (_) => RecordingPlayerSheet(session: session),
/// );
/// ```
class RecordingPlayerSheet extends StatefulWidget {
  const RecordingPlayerSheet({super.key, required this.session});

  final PracticeSession session;

  @override
  State<RecordingPlayerSheet> createState() => _RecordingPlayerSheetState();
}

class _RecordingPlayerSheetState extends State<RecordingPlayerSheet> with TickerProviderStateMixin {
  late final AudioPlayer _player;
  late final AnimationController _waveController;
  Duration _position = Duration.zero;
  Duration _total = Duration.zero;
  bool _playing = false;
  bool _loading = true;
  bool _fileError = false;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    final String? path = widget.session.recordingPath;
    if (path == null) {
      if (mounted)
        setState(() {
          _loading = false;
          _fileError = true;
        });
      return;
    }
    final File file = File(path);
    if (!await file.exists()) {
      if (mounted)
        setState(() {
          _loading = false;
          _fileError = true;
        });
      return;
    }
    try {
      final Duration? dur = await _player.setAudioSource(AudioSource.uri(Uri.file(file.absolute.path)));
      if (mounted) {
        setState(() {
          _total = dur ?? Duration.zero;
          _loading = false;
        });
      }
      _player.positionStream.listen((Duration p) {
        if (mounted) setState(() => _position = p);
      });
      _player.playingStream.listen((bool playing) {
        if (mounted) setState(() => _playing = playing);
      });
      // Auto-play once loaded
      await _player.play();
    } catch (e) {
      if (mounted)
        setState(() {
          _loading = false;
          _fileError = true;
        });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    _waveController.dispose();
    super.dispose();
  }

  String _fmt(Duration d) {
    final String mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final String ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mm:$ss';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final Color accent = accentColorForCategory(widget.session.category);
    final double fraction = _total.inMilliseconds > 0 ? (_position.inMilliseconds / _total.inMilliseconds).clamp(0.0, 1.0) : 0.0;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
        boxShadow: <BoxShadow>[BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 30, offset: const Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(AppRadius.full)),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Header
            Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                  alignment: Alignment.center,
                  child: Icon(Icons.mic_rounded, color: accent, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        widget.session.cardTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.session.category,
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: accent),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),

            if (_loading) ...<Widget>[const CircularProgressIndicator(), const SizedBox(height: AppSpacing.lg)] else if (_fileError) ...<Widget>[
              Icon(Icons.error_outline_rounded, color: theme.colorScheme.error, size: 40),
              const SizedBox(height: AppSpacing.md),
              Text('Recording file not found.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error)),
            ] else ...<Widget>[
              // Waveform
              RecordingWaveformVisualiser(controller: _waveController, isPlaying: _playing, accent: accent),
              const SizedBox(height: AppSpacing.lg),

              // Scrubber
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  activeTrackColor: accent,
                  thumbColor: accent,
                  inactiveTrackColor: accent.withValues(alpha: 0.2),
                  overlayColor: accent.withValues(alpha: 0.15),
                ),
                child: Slider(
                  value: fraction,
                  onChanged: (double v) async {
                    final Duration seek = Duration(milliseconds: (_total.inMilliseconds * v).round());
                    await _player.seek(seek);
                  },
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(_fmt(_position), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    Text(_fmt(_total), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Controls
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _CircleIconButton(
                    icon: Icons.replay_10_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                    onTap: () async {
                      final Duration seekTo = _position - const Duration(seconds: 10);
                      await _player.seek(seekTo < Duration.zero ? Duration.zero : seekTo);
                    },
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  GestureDetector(
                    onTap: () async {
                      if (_playing) {
                        await _player.pause();
                      } else {
                        if (_position >= _total && _total > Duration.zero) {
                          await _player.seek(Duration.zero);
                        }
                        await _player.play();
                      }
                    },
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent,
                        boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 4))],
                      ),
                      child: Icon(_playing ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xl),
                  _CircleIconButton(
                    icon: Icons.forward_10_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 28,
                    onTap: () async {
                      final Duration seekTo = _position + const Duration(seconds: 10);
                      await _player.seek(seekTo > _total ? _total : seekTo);
                    },
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared waveform visualiser
// ─────────────────────────────────────────────────────────────────────────────

class RecordingWaveformVisualiser extends StatelessWidget {
  const RecordingWaveformVisualiser({super.key, required this.controller, required this.isPlaying, required this.accent});

  final AnimationController controller;
  final bool isPlaying;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    const int barCount = 24;
    const List<double> heights = <double>[
      0.4,
      0.7,
      1.0,
      0.6,
      0.8,
      0.5,
      0.9,
      0.3,
      0.7,
      1.0,
      0.6,
      0.4,
      0.8,
      0.5,
      0.9,
      0.3,
      0.7,
      1.0,
      0.5,
      0.6,
      0.9,
      0.4,
      0.7,
      0.5,
    ];

    return SizedBox(
      height: 48,
      child: AnimatedBuilder(
        animation: controller,
        builder: (BuildContext context, Widget? child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List<Widget>.generate(barCount, (int i) {
              final double phase = (i / barCount + controller.value) % 1.0;
              final double animated = isPlaying
                  ? heights[i % heights.length] * (0.4 + 0.6 * (phase < 0.5 ? phase * 2 : (1 - phase) * 2))
                  : heights[i % heights.length] * 0.3;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1.5),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 4,
                  height: (48 * animated).clamp(4.0, 48.0),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: isPlaying ? 0.85 : 0.35),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Circle icon button
// ─────────────────────────────────────────────────────────────────────────────

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.color, required this.size, required this.onTap});

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.08)),
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}
