import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_def.dart';
import 'package:speakup/features/challenges/domain/entities/challenge_progress.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_bloc.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_event.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Route args
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeDetailArgs {
  const ChallengeDetailArgs({required this.def, this.progress});
  final ChallengeDef def;
  final ChallengeProgress? progress;
}

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class ChallengeDetailScreen extends StatelessWidget {
  const ChallengeDetailScreen({required this.args, super.key});

  final ChallengeDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final ChallengeDef def = args.def;
    final ChallengeProgress? progress = args.progress;
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool isEnrolled = progress != null;

    return Scaffold(
      backgroundColor: isDark
          ? theme.colorScheme.surface
          : theme.colorScheme.surfaceContainerLowest,
      body: CustomScrollView(
        slivers: <Widget>[
          // ── Hero header ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor:
                isDark ? theme.colorScheme.surface : theme.colorScheme.primary,
            foregroundColor:
                isDark ? theme.colorScheme.onSurface : Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      def.accentColor,
                      def.accentColor.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Stack(
                  children: <Widget>[
                    // Ghost icon
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Opacity(
                        opacity: 0.12,
                        child: Text(
                          def.emoji,
                          style: const TextStyle(fontSize: 160),
                        ),
                      ),
                    ),
                    // Title content
                    Positioned(
                      left: AppSpacing.xl,
                      bottom: AppSpacing.xl,
                      right: 80,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              '${def.durationDays}-Day Challenge',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            def.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Body ──────────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl,
              AppSpacing.lg, AppSpacing.huge,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                // Description
                Text(
                  def.subtitle,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),

                // Stats row
                _StatsRow(def: def),
                const SizedBox(height: AppSpacing.xl),

                // Progress section (if enrolled)
                if (isEnrolled) ...<Widget>[
                  _ProgressSection(def: def, progress: progress!),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Day timeline
                _DayTimeline(def: def, progress: progress),
                const SizedBox(height: AppSpacing.xxl),

                // CTA
                _CtaSection(
                  def: def,
                  progress: progress,
                  isEnrolled: isEnrolled,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.def});
  final ChallengeDef def;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    Widget stat(String value, String label, IconData icon) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md, horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: isDark
                ? theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.35)
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: def.accentColor.withValues(alpha: 0.25),
            ),
          ),
          child: Column(
            children: <Widget>[
              Icon(icon, color: def.accentColor, size: 20),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: def.accentColor,
                ),
              ),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        stat('${def.durationDays}', 'days', Icons.calendar_month_rounded),
        const SizedBox(width: AppSpacing.sm),
        stat('${def.tasksPerDay}×', 'per day', Icons.repeat_rounded),
        const SizedBox(width: AppSpacing.sm),
        stat(
          def.category?.split(' ').first ?? 'Mixed',
          'topic',
          Icons.category_outlined,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Progress section (enrolled only)
// ─────────────────────────────────────────────────────────────────────────────

class _ProgressSection extends StatelessWidget {
  const _ProgressSection({required this.def, required this.progress});
  final ChallengeDef def;
  final ChallengeProgress progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final int done = progress.completedDays.length;
    final double frac = (done / def.durationDays).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            def.accentColor.withValues(alpha: 0.12),
            def.accentColor.withValues(alpha: 0.04),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: def.accentColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'Your Progress',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              Text(
                '$done / ${def.durationDays} days',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: def.accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 10,
              backgroundColor:
                  isDark ? theme.colorScheme.surfaceContainerHighest : Colors.white,
              color: def.accentColor,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            frac >= 1.0
                ? '🎉 Challenge completed!'
                : '${((1 - frac) * def.durationDays).ceil()} days remaining',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Day timeline
// ─────────────────────────────────────────────────────────────────────────────

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.def, this.progress});
  final ChallengeDef def;
  final ChallengeProgress? progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Set<int> done = progress?.completedDays.toSet() ?? <int>{};
    final int currentDay = progress?.currentDay ?? -1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Day-by-Day Plan',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...List<Widget>.generate(def.durationDays, (int i) {
          final bool isDone = done.contains(i);
          final bool isToday = i == currentDay;
          return _DayRow(
            day: i + 1,
            isDone: isDone,
            isToday: isToday,
            isLast: i == def.durationDays - 1,
            tasksPerDay: def.tasksPerDay,
            accentColor: def.accentColor,
            category: def.category,
            theme: theme,
          );
        }),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.day,
    required this.isDone,
    required this.isToday,
    required this.isLast,
    required this.tasksPerDay,
    required this.accentColor,
    required this.category,
    required this.theme,
  });

  final int day;
  final bool isDone;
  final bool isToday;
  final bool isLast;
  final int tasksPerDay;
  final Color accentColor;
  final String? category;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color lineColor =
        isDone ? accentColor : theme.colorScheme.outlineVariant;
    final Color dotColor = isDone
        ? accentColor
        : isToday
            ? accentColor.withValues(alpha: 0.5)
            : theme.colorScheme.outlineVariant;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Timeline spine
          SizedBox(
            width: 28,
            child: Column(
              children: <Widget>[
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: isToday && !isDone
                        ? Border.all(color: accentColor, width: 2)
                        : null,
                  ),
                  child: isDone
                      ? const Icon(Icons.check_rounded,
                          size: 12, color: Colors.white)
                      : null,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: lineColor.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Text
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Text(
                        'Day $day',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: isDone
                              ? accentColor
                              : isToday
                                  ? theme.colorScheme.onSurface
                                  : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isToday)
                        Container(
                          margin: const EdgeInsets.only(left: AppSpacing.xs),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: accentColor,
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                          child: const Text(
                            'TODAY',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$tasksPerDay ${tasksPerDay > 1 ? 'sessions' : 'session'}'
                    '${category != null ? ' · $category' : ' · any category'}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CTA section
// ─────────────────────────────────────────────────────────────────────────────

class _CtaSection extends StatelessWidget {
  const _CtaSection({
    required this.def,
    required this.progress,
    required this.isEnrolled,
  });

  final ChallengeDef def;
  final ChallengeProgress? progress;
  final bool isEnrolled;

  void _startPractice(BuildContext context) {
    HapticFeedback.mediumImpact();
    final Map<String, String> params = <String, String>{};
    if (def.category != null) params['category'] = def.category!;
    final String uri = Uri(
      path: AppRoutes.categorySelect,
      queryParameters: params.isEmpty ? null : params,
    ).toString();
    context.push(uri);
  }

  void _enrol(BuildContext context) {
    HapticFeedback.mediumImpact();
    context.read<ChallengesBloc>().add(ChallengeEnrolRequested(def.id));
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('Enrolled in ${def.title}! 🎉'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool todayDone = progress?.todayCompleted ?? false;

    if (isEnrolled && todayDone) {
      return Container(
        height: 56,
        width: double.infinity,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: def.accentColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: def.accentColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.check_circle_rounded, color: def.accentColor, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              "Today's session done! Come back tomorrow",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: def.accentColor,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: () =>
          isEnrolled ? _startPractice(context) : _enrol(context),
      child: Container(
        height: 56,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              def.accentColor,
              def.accentColor.withValues(alpha: 0.85),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: def.accentColor.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              isEnrolled
                  ? Icons.play_circle_outline_rounded
                  : Icons.flag_rounded,
              color: Colors.white,
              size: 22,
            ),
            const SizedBox(width: AppSpacing.md),
            Text(
              isEnrolled ? "Start Today's Practice" : 'Join Challenge',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
