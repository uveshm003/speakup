import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/history/presentation/bloc/history_bloc.dart';
import 'package:speakup/features/history/presentation/bloc/history_event.dart';
import 'package:speakup/features/history/presentation/bloc/history_state.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/presentation/utils/practice_format.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen root
// ─────────────────────────────────────────────────────────────────────────────

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  bool _calendarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = AppLayout.pagePadding(context);

    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (HistoryState p, HistoryState c) =>
          c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext context, HistoryState state) {
        final PracticeSession? s = state.pendingDeletion;
        if (s == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session removed'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () =>
                  context.read<HistoryBloc>().add(const SessionDeleteUndoRequested()),
            ),
          ),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (BuildContext context, HistoryState state) {
              // ── Loading ────────────────────────────────────────────────────
              if (state.status == HistoryStatus.loading &&
                  state.allSessions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _InlineHeader(pad: pad),
                    const Expanded(
                        child: ShimmerListPlaceholder(
                            itemCount: 7, itemHeight: 72)),
                  ],
                );
              }

              // ── Error ──────────────────────────────────────────────────────
              if (state.status == HistoryStatus.failure &&
                  state.allSessions.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _InlineHeader(pad: pad),
                    Expanded(
                      child: Center(
                          child: Text(
                              state.errorMessage ?? 'Could not load history')),
                    ),
                  ],
                );
              }

              return CustomScrollView(
                slivers: <Widget>[
                  // ── Header ─────────────────────────────────────────────────
                  SliverToBoxAdapter(
                    child: _InlineHeader(pad: pad),
                  ),

                  // ── Stats row ──────────────────────────────────────────────
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        pad.left, AppSpacing.md, pad.right, 0),
                    sliver: SliverToBoxAdapter(
                      child: _StatsRow(state: state),
                    ),
                  ),

                  // ── Activity section (compact strip + optional calendar) ───
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(
                        pad.left, AppSpacing.xl, pad.right, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ActivitySection(
                        counts: state.sessionsPerDayKey,
                        expanded: _calendarExpanded,
                        onToggle: () => setState(
                            () => _calendarExpanded = !_calendarExpanded),
                      ),
                    ),
                  ),

                  // ── Sessions or empty ──────────────────────────────────────
                  if (state.logSessions.isEmpty)
                    const SliverFillRemaining(
                        hasScrollBody: false, child: _EmptyHistory())
                  else
                    ..._buildGroupedSlivers(context, state, pad),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline header (no AppBar — consistent with Favorites / Home)
// ─────────────────────────────────────────────────────────────────────────────

class _InlineHeader extends StatelessWidget {
  const _InlineHeader({required this.pad});
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: pad.copyWith(top: pad.top + AppSpacing.md, bottom: 0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'History',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your practice sessions',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          // Icon badge
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color:
                  theme.colorScheme.primaryContainer.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(Icons.history_rounded,
                size: 22, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats row — three metric cards
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});
  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      children: <Widget>[
        _StatCard(
          emoji: '🔥',
          label: 'Streak',
          value: '${state.currentStreak}d',
          accentColor: const Color(0xFFEA580C),
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(
          emoji: '📋',
          label: 'Sessions',
          value: '${state.totalSessions}',
          accentColor: theme.colorScheme.primary,
          theme: theme,
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatCard(
          emoji: '⏱',
          label: 'Minutes',
          value: '${state.totalPracticeMinutes}m',
          accentColor: const Color(0xFF16A34A),
          theme: theme,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.accentColor,
    required this.theme,
  });

  final String emoji;
  final String label;
  final String value;
  final Color accentColor;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md + 2, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
              color: accentColor.withValues(alpha: 0.18), width: 1),
        ),
        child: Column(
          children: <Widget>[
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: accentColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                  color: accentColor.withValues(alpha: 0.75),
                  fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity section — compact week strip + expandable monthly calendar
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({
    required this.counts,
    required this.expanded,
    required this.onToggle,
  });

  final Map<String, int> counts;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // ── Section heading row ────────────────────────────────────────────
        Row(
          children: <Widget>[
            Text(
              'Activity',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onToggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  border: Border.all(
                      color: theme.colorScheme.outlineVariant
                          .withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      expanded ? 'Hide calendar' : 'Full calendar',
                      style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    AnimatedRotation(
                      turns: expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),

        // ── 7-day compact strip (always visible) ──────────────────────────
        _WeekStrip(counts: counts),

        // ── Full monthly calendar (collapsible) ───────────────────────────
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xl),
                  child: _MonthPageView(counts: counts),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day compact strip (Mon–Sun of current week)
// ─────────────────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.counts});
  final Map<String, int> counts;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final bool dark = theme.brightness == Brightness.dark;
    final Color brandLight =
        dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color emptyBg = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: dark ? 0.5 : 0.7);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    // Start of the current ISO week (Monday)
    final DateTime weekStart =
        today.subtract(Duration(days: today.weekday - 1));

    final List<String> dow = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      children: List<Widget>.generate(7, (int i) {
        final DateTime day = weekStart.add(Duration(days: i));
        final bool isToday = day == today;
        final bool isFuture = day.isAfter(today);
        final String k = _key(day);
        final int n = counts[k] ?? 0;

        Color fill;
        if (isFuture || n <= 0) {
          fill = emptyBg;
        } else if (n == 1) {
          fill = brandLight;
        } else if (n == 2) {
          fill = primary.withValues(alpha: 0.55);
        } else {
          fill = primary;
        }

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < 6 ? AppSpacing.xs : 0),
            child: Column(
              children: <Widget>[
                // Day letter
                Text(
                  dow[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isToday
                        ? primary
                        : theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Activity cell
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 38,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    border: isToday
                        ? Border.all(color: primary, width: 2)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: n > 0 && !isFuture
                          ? (n >= 2 ? Colors.white : primary)
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: isFuture ? 0.3 : 0.55),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full monthly page view (visible when expanded)
// ─────────────────────────────────────────────────────────────────────────────

class _MonthPageView extends StatelessWidget {
  const _MonthPageView({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    // Use LayoutBuilder to compute the exact height the grid needs so it never
    // overflows its parent. Each cell is square with side = width/7 minus gaps.
    // Grid: 5 rows × cellSize + 4 × 4px gaps.
    // Above it: monthTitle(≈20) + gap(8) + DOW row(≈18) + gap(4) = 50px fixed.
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double cellGap = 4;
        final double cellSize = (constraints.maxWidth - 6 * cellGap) / 7;
        final double gridHeight = 5 * cellSize + 4 * cellGap;
        // 20 title + 8 gap + 18 DOW row + 4 gap
        final double totalHeight = 50 + gridHeight;

        return SizedBox(
          height: totalHeight,
          child: PageView.builder(
            itemCount: 3,
            controller: PageController(viewportFraction: 1),
            itemBuilder: (BuildContext context, int pageIndex) {
              final DateTime month =
                  DateTime(now.year, now.month - pageIndex, 1);
              return _MonthGrid(month: month, counts: counts);
            },
          ),
        );
      },
    );
  }
}

class _MonthGrid extends StatelessWidget {
  const _MonthGrid({required this.month, required this.counts});
  final DateTime month;
  final Map<String, int> counts;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final bool dark = theme.brightness == Brightness.dark;
    final Color brandLight =
        dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color empty = theme.colorScheme.surfaceContainerHighest
        .withValues(alpha: dark ? 0.4 : 0.6);

    final DateTime first = DateTime(month.year, month.month, 1);
    final int fromMonday = first.weekday - 1;
    final DateTime gridStart = first.subtract(Duration(days: fromMonday));
    final DateTime today = DateTime.now();
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);
    final List<String> dow = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(DateFormat('MMMM yyyy').format(month),
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: dow
              .map((String d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1,
          ),
          itemCount: 35,
          itemBuilder: (BuildContext context, int i) {
            final DateTime cell = gridStart.add(Duration(days: i));
            final bool inMonth = cell.month == month.month;
            final String k = _key(cell);
            final int n = counts[k] ?? 0;
            Color fill;
            if (n <= 0) {
              fill = empty;
            } else if (n == 1) {
              fill = brandLight;
            } else if (n == 2) {
              fill = primary.withValues(alpha: 0.55);
            } else {
              fill = primary;
            }
            final DateTime cn =
                DateTime(cell.year, cell.month, cell.day);
            final bool isToday = cn == todayNorm;

            return DecoratedBox(
              decoration: BoxDecoration(
                color: inMonth ? fill : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: isToday && inMonth
                    ? Border.all(color: primary, width: 1.8)
                    : null,
              ),
              child: inMonth
                  ? Center(
                      child: Text(
                        '${cell.day}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: n > 0
                              ? (n >= 2 ? Colors.white : primary)
                              : theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.55),
                        ),
                      ),
                    )
                  : null,
            );
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grouped slivers builder
// ─────────────────────────────────────────────────────────────────────────────

List<Widget> _buildGroupedSlivers(
    BuildContext context, HistoryState state, EdgeInsets pad) {
  final Map<DateTime, List<PracticeSession>> byDay =
      <DateTime, List<PracticeSession>>{};
  for (final PracticeSession s in state.logSessions) {
    final DateTime d = DateTime(
        s.completedAt.year, s.completedAt.month, s.completedAt.day);
    byDay.putIfAbsent(d, () => <PracticeSession>[]).add(s);
  }
  final List<DateTime> days = byDay.keys.toList()
    ..sort((DateTime a, DateTime b) => b.compareTo(a));

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<Widget> out = <Widget>[];

  for (final DateTime day in days) {
    // ── Day header sliver ──────────────────────────────────────────────────
    out.add(SliverPersistentHeader(
      pinned: true,
      delegate: _DateHeaderDelegate(
          label: _dayHeaderLabel(day, today)),
    ));
    // ── Sessions sliver ────────────────────────────────────────────────────
    final List<PracticeSession> list = byDay[day]!;
    out.add(
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, AppSpacing.xs),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int i) {
              final PracticeSession s = list[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _SessionTile(
                  session: s,
                  onDelete: () => context
                      .read<HistoryBloc>()
                      .add(SessionDeleted(s.sessionId)),
                ),
              );
            },
            childCount: list.length,
          ),
        ),
      ),
    );
  }

  // Bottom padding so last tile clears nav bar
  out.add(const SliverPadding(
      padding: EdgeInsets.only(bottom: AppSpacing.huge)));
  return out;
}

String _dayHeaderLabel(DateTime day, DateTime today) {
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';
  return DateFormat('EEEE, MMM d').format(day);
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky date header
// ─────────────────────────────────────────────────────────────────────────────

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateHeaderDelegate({required this.label});
  final String label;

  @override
  double get minExtent => 36;
  @override
  double get maxExtent => 36;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ThemeData theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate old) =>
      old.label != label;
}

// ─────────────────────────────────────────────────────────────────────────────
// Session tile — dismissible with accent left border
// ─────────────────────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({required this.session, required this.onDelete});
  final PracticeSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(session.category);
    final String emoji = emojiForCategory(session.category);
    final String time = DateFormat.jm().format(session.completedAt);
    final bool completed = session.wasCompleted;

    return Dismissible(
      key: ValueKey<String>(session.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xxl),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Material(
          color: theme.colorScheme.surfaceContainerLow,
          child: InkWell(
            onTap: () {},
            child: Row(
              children: <Widget>[
                // Accent left strip
                Container(
                  width: 4,
                  height: 68,
                  color: accent,
                ),

                // Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.md),
                    child: Row(
                      children: <Widget>[
                        // Emoji avatar
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: accent.withValues(alpha: 0.15),
                          ),
                          alignment: Alignment.center,
                          child:
                              Text(emoji, style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: AppSpacing.md),

                        // Title + subtitle
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                session.cardTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: <Widget>[
                                  Text(
                                    time,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme
                                            .colorScheme.onSurfaceVariant),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Container(
                                    width: 3,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: theme.colorScheme.onSurfaceVariant
                                          .withValues(alpha: 0.5),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Flexible(
                                    child: Text(
                                      session.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: AppSpacing.sm),

                        // Duration + completion dot
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer
                                    .withValues(alpha: 0.5),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                formatPracticeMmSs(session.durationSeconds),
                                style: theme.textTheme.labelSmall?.copyWith(
                                    fontWeight: FontWeight.w700),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: completed
                                        ? AppColors.success
                                        : AppColors.warning,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  completed ? 'Done' : 'Partial',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: completed
                                        ? AppColors.success
                                        : AppColors.warning,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
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
// Empty state
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primaryContainer
                    .withValues(alpha: 0.35),
              ),
              child: Icon(
                Icons.history_rounded,
                size: 48,
                color: theme.colorScheme.primary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No sessions yet',
              style: GoogleFonts.plusJakartaSans(
                  fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete a practice session\nto see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
