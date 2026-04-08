import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/recording_player_sheet.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/challenges/domain/built_in_challenges.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_def.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_progress.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_bloc.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_event.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_state.dart';
import 'package:speakup/features/challenges/presentation/screens/challenge_detail_screen.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root screen
// ─────────────────────────────────────────────────────────────────────────────

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<ChallengesBloc, ChallengesState>(
      listenWhen: (ChallengesState p, ChallengesState c) => c.errorMessage != null && c.errorMessage != p.errorMessage,
      listener: (BuildContext ctx, ChallengesState state) {
        if (state.errorMessage != null) {
          ScaffoldMessenger.of(ctx)
            ..clearSnackBars()
            ..showSnackBar(SnackBar(content: Text(state.errorMessage!), behavior: SnackBarBehavior.floating));
        }
      },
      builder: (BuildContext ctx, ChallengesState state) {
        // Split challenges into active / available / completed.
        final Map<String, ChallengeProgress> progress = state.progress;
        final List<ChallengeDef> active = kBuiltInChallenges
            .where((ChallengeDef d) => progress.containsKey(d.id) && !progress[d.id]!.isCompleted)
            .toList();
        final List<ChallengeDef> available = kBuiltInChallenges.where((ChallengeDef d) => !progress.containsKey(d.id)).toList();
        final List<ChallengeDef> completed = kBuiltInChallenges
            .where((ChallengeDef d) => progress.containsKey(d.id) && progress[d.id]!.isCompleted)
            .toList();

        return Scaffold(
          backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
          body: CustomScrollView(
            slivers: <Widget>[
              // ── Gradient header ────────────────────────────────────────
              _ChallengesAppBar(isDark: isDark, theme: theme),

              // ── Body ──────────────────────────────────────────────────
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.huge),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // ── Recent Recordings ──────────────────────────────────
                    _RecentRecordingsSection(),
                    const SizedBox(height: AppSpacing.xl),

                    // Active challenges
                    if (active.isNotEmpty) ...<Widget>[
                      _SectionLabel(label: 'In Progress'),
                      const SizedBox(height: AppSpacing.md),
                      ...active.map(
                        (ChallengeDef def) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _ActiveChallengeCard(
                            def: def,
                            progress: progress[def.id]!,
                            onTap: () => _goDetail(ctx, def, progress[def.id]),
                            onMarkComplete: () {
                              HapticFeedback.mediumImpact();
                              ctx.read<ChallengesBloc>().add(ChallengeDayCompleted(def.id, progress[def.id]!.currentDay, def.durationDays));
                            },
                            onAbandon: () => _confirmAbandon(ctx, def),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Available challenges
                    if (available.isNotEmpty) ...<Widget>[
                      _SectionLabel(label: 'Browse Challenges'),
                      const SizedBox(height: AppSpacing.md),
                      ...available.map(
                        (ChallengeDef def) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _AvailableChallengeCard(
                            def: def,
                            onTap: () => _goDetail(ctx, def, null),
                            onEnrol: () {
                              HapticFeedback.mediumImpact();
                              ctx.read<ChallengesBloc>().add(ChallengeEnrolRequested(def.id));
                              ScaffoldMessenger.of(ctx)
                                ..clearSnackBars()
                                ..showSnackBar(SnackBar(content: Text('Enrolled in ${def.title}! 🎉'), behavior: SnackBarBehavior.floating));
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],

                    // Completed challenges
                    if (completed.isNotEmpty) ...<Widget>[
                      _SectionLabel(label: 'Completed 🏅'),
                      const SizedBox(height: AppSpacing.md),
                      ...completed.map(
                        (ChallengeDef def) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: _CompletedChallengeCard(def: def),
                        ),
                      ),
                    ],

                    // Empty state
                    if (active.isEmpty && available.isEmpty && completed.isEmpty) const _EmptyState(),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _goDetail(BuildContext context, ChallengeDef def, ChallengeProgress? progress) {
    context.push(
      AppRoutes.challengeDetail,
      extra: ChallengeDetailArgs(def: def, progress: progress),
    );
  }

  Future<void> _confirmAbandon(BuildContext context, ChallengeDef def) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext dlgCtx) => AlertDialog(
        title: const Text('Abandon challenge?'),
        content: Text("Your progress on '${def.title}' will be lost. This can't be undone."),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(dlgCtx, false), child: const Text('Keep going')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Theme.of(dlgCtx).colorScheme.error, foregroundColor: Theme.of(dlgCtx).colorScheme.onError),
            onPressed: () => Navigator.pop(dlgCtx, true),
            child: const Text('Abandon'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      context.read<ChallengesBloc>().add(ChallengeAbandoned(def.id));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// App bar
// ─────────────────────────────────────────────────────────────────────────────

class _ChallengesAppBar extends StatelessWidget {
  const _ChallengesAppBar({required this.isDark, required this.theme});
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
      foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.parallax,
        titlePadding: const EdgeInsetsDirectional.fromSTEB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Challenges',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: isDark ? theme.colorScheme.onSurface : Colors.white,
              ),
            ),
            Text('Track your speaking journey', style: TextStyle(fontSize: 11, color: isDark ? theme.colorScheme.onSurfaceVariant : Colors.white70)),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? <Color>[theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), theme.colorScheme.surface]
                  : <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.82)],
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Opacity(
              opacity: isDark ? 0.07 : 0.1,
              child: Icon(Icons.emoji_events_rounded, size: 130, color: isDark ? theme.colorScheme.primary : Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Section label
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active challenge card (enrolled, in progress)
// ─────────────────────────────────────────────────────────────────────────────

class _ActiveChallengeCard extends StatelessWidget {
  const _ActiveChallengeCard({required this.def, required this.progress, required this.onTap, required this.onMarkComplete, required this.onAbandon});

  final ChallengeDef def;
  final ChallengeProgress progress;
  final VoidCallback onTap;
  final VoidCallback onMarkComplete;
  final VoidCallback onAbandon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final int currentDay = progress.currentDay.clamp(0, def.durationDays - 1);
    final bool todayDone = progress.todayCompleted;
    final double frac = (progress.completedDays.length / def.durationDays).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: def.accentColor.withValues(alpha: 0.4), width: 1.5),
          boxShadow: isDark
              ? null
              : <BoxShadow>[BoxShadow(color: def.accentColor.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Coloured header band
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: <Color>[def.accentColor.withValues(alpha: 0.15), def.accentColor.withValues(alpha: 0.05)]),
              ),
              child: Row(
                children: <Widget>[
                  Text(def.emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(def.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                        Text(
                          'Day ${currentDay + 1} of ${def.durationDays}',
                          style: TextStyle(fontSize: 12, color: def.accentColor, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  // Progress ring
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Stack(
                      alignment: Alignment.center,
                      children: <Widget>[
                        CircularProgressIndicator(
                          value: frac,
                          strokeWidth: 4,
                          backgroundColor: def.accentColor.withValues(alpha: 0.15),
                          color: def.accentColor,
                        ),
                        Text(
                          '${(frac * 100).round()}%',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: def.accentColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Action row
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: todayDone
                        ? _DonePill(accentColor: def.accentColor)
                        : FilledButton.icon(
                            onPressed: onMarkComplete,
                            style: FilledButton.styleFrom(
                              backgroundColor: def.accentColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
                              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                            ),
                            icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                            label: const Text('Mark Today Complete', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Abandon challenge',
                    icon: const Icon(Icons.close_rounded, size: 18),
                    color: theme.colorScheme.onSurfaceVariant,
                    onPressed: onAbandon,
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

class _DonePill extends StatelessWidget {
  const _DonePill({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: accentColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.check_rounded, size: 16, color: accentColor),
          const SizedBox(width: AppSpacing.xs),
          Text(
            "Today's done! 🎉",
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Available challenge card (browse / enrol)
// ─────────────────────────────────────────────────────────────────────────────

class _AvailableChallengeCard extends StatelessWidget {
  const _AvailableChallengeCard({required this.def, required this.onTap, required this.onEnrol});

  final ChallengeDef def;
  final VoidCallback onTap;
  final VoidCallback onEnrol;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
          boxShadow: isDark
              ? null
              : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: <Widget>[
            // Emoji badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(color: def.accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.lg)),
              child: Center(child: Text(def.emoji, style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: AppSpacing.md),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(def.title, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(
                    def.subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Badges
                  Row(
                    children: <Widget>[
                      _Chip(label: '${def.durationDays} days', color: def.accentColor),
                      const SizedBox(width: AppSpacing.xs),
                      _Chip(label: '${def.tasksPerDay}×/day', color: def.accentColor),
                      if (def.category != null) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        _Chip(label: def.category!.split(' ').first, color: def.accentColor),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Enrol button
            FilledButton(
              onPressed: onEnrol,
              style: FilledButton.styleFrom(
                backgroundColor: def.accentColor,
                minimumSize: const Size(72, 36),
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
              ),
              child: const Text('Join', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.full)),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Completed challenge card
// ─────────────────────────────────────────────────────────────────────────────

class _CompletedChallengeCard extends StatelessWidget {
  const _CompletedChallengeCard({required this.def});
  final ChallengeDef def;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2) : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: const Color(0xFF22C55E).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: <Widget>[
          Text(def.emoji, style: const TextStyle(fontSize: 26)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  def.title,
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 14, color: theme.colorScheme.onSurfaceVariant),
                ),
                Text(
                  'Completed · ${def.durationDays} days',
                  style: theme.textTheme.bodySmall?.copyWith(color: const Color(0xFF22C55E), fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const Icon(Icons.verified_rounded, color: Color(0xFF22C55E), size: 28),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.huge),
      child: Column(
        children: <Widget>[
          const Text('🏆', style: TextStyle(fontSize: 56)),
          const SizedBox(height: AppSpacing.lg),
          Text('No challenges yet', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 18)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Pick a challenge below and start your journey.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Recordings section
// ─────────────────────────────────────────────────────────────────────────────

class _RecentRecordingsSection extends StatefulWidget {
  @override
  State<_RecentRecordingsSection> createState() => _RecentRecordingsSectionState();
}

class _RecentRecordingsSectionState extends State<_RecentRecordingsSection> {
  late Future<List<PracticeSession>> _future;

  @override
  void initState() {
    super.initState();
    final SessionRepository repo = context.read<SessionRepository>();
    _future = repo.getAllSessions().then((result) {
      return result.fold(
        (failure) => <PracticeSession>[],
        (sessions) => sessions.where((s) => s.recordingPath != null && s.recordingPath!.isNotEmpty).take(5).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PracticeSession>>(
      future: _future,
      builder: (BuildContext context, AsyncSnapshot<List<PracticeSession>> snap) {
        if (!snap.hasData || snap.data!.isEmpty) return const SizedBox.shrink();
        final List<PracticeSession> recordings = snap.data!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SectionLabel(label: '🎙 Recent Recordings'),
            const SizedBox(height: AppSpacing.md),
            ...recordings.map((PracticeSession s) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _RecordingListTile(session: s),
            )),
          ],
        );
      },
    );
  }
}

class _RecordingListTile extends StatelessWidget {
  const _RecordingListTile({required this.session});
  final PracticeSession session;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(session.category);
    final String date = DateFormat('MMM d').format(session.completedAt);

    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: () {
          showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => RecordingPlayerSheet(session: session),
          );
        },
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                child: Icon(Icons.mic_rounded, color: accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      session.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${session.category} · $date',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
