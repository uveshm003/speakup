import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/card_draw/presentation/utils/category_accent.dart';
import 'package:speakup/features/history/presentation/bloc/history_bloc.dart';
import 'package:speakup/features/history/presentation/bloc/history_event.dart';
import 'package:speakup/features/history/presentation/bloc/history_state.dart';
import 'package:speakup/features/practice/domain/entities/practice_session.dart';
import 'package:speakup/features/practice/presentation/utils/practice_format.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (HistoryState p, HistoryState c) =>
          c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext context, HistoryState state) {
        final PracticeSession? s = state.pendingDeletion;
        if (s == null) {
          return;
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session removed'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Undo',
              onPressed: () {
                context.read<HistoryBloc>().add(const SessionDeleteUndoRequested());
              },
            ),
          ),
        );
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('History'),
          actions: <Widget>[
            BlocBuilder<HistoryBloc, HistoryState>(
              builder: (BuildContext context, HistoryState state) {
                return IconButton(
                  icon: Icon(
                    state.filterRange != null
                        ? Icons.filter_alt_rounded
                        : Icons.filter_alt_outlined,
                  ),
                  tooltip: 'Filter by date',
                  onPressed: () async {
                    final DateTimeRange? r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
                      lastDate: DateTime.now(),
                    );
                    if (!context.mounted) {
                      return;
                    }
                    if (r == null) {
                      return;
                    }
                    context.read<HistoryBloc>().add(HistoryFilterChanged(range: r));
                  },
                );
              },
            ),
            BlocBuilder<HistoryBloc, HistoryState>(
              builder: (BuildContext context, HistoryState state) {
                if (state.filterRange == null) {
                  return const SizedBox.shrink();
                }
                return IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear filter',
                  onPressed: () {
                    context.read<HistoryBloc>().add(const HistoryFilterChanged(range: null));
                  },
                );
              },
            ),
          ],
        ),
        body: BlocBuilder<HistoryBloc, HistoryState>(
          builder: (BuildContext context, HistoryState state) {
            if (state.status == HistoryStatus.loading && state.allSessions.isEmpty) {
              return const ShimmerListPlaceholder(itemCount: 7, itemHeight: 72);
            }
            if (state.status == HistoryStatus.failure && state.allSessions.isEmpty) {
              return Center(child: Text(state.errorMessage ?? 'Could not load'));
            }
            return CustomScrollView(
              slivers: <Widget>[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.md,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: _StatsRow(state: state),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: _HeatmapSection(counts: state.sessionsPerDayKey),
                  ),
                ),
                if (state.logSessions.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _EmptyHistory(),
                  )
                else
                  ..._buildGroupedSlivers(context, state),
              ],
            );
          },
        ),
      ),
    );
  }
}

List<Widget> _buildGroupedSlivers(BuildContext context, HistoryState state) {
  final Map<DateTime, List<PracticeSession>> byDay = <DateTime, List<PracticeSession>>{};
  for (final PracticeSession s in state.logSessions) {
    final DateTime d = DateTime(
      s.completedAt.year,
      s.completedAt.month,
      s.completedAt.day,
    );
    byDay.putIfAbsent(d, () => <PracticeSession>[]).add(s);
  }
  final List<DateTime> days = byDay.keys.toList()
    ..sort((DateTime a, DateTime b) => b.compareTo(a));

  final List<Widget> out = <Widget>[];
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);

  for (final DateTime day in days) {
    out.add(
      SliverPersistentHeader(
        pinned: true,
        delegate: _DateHeaderDelegate(
          label: _dayHeaderLabel(day, today),
        ),
      ),
    );
    final List<PracticeSession> list = byDay[day]!;
    out.add(
      SliverList(
        delegate: SliverChildBuilderDelegate(
          (BuildContext context, int i) {
            final PracticeSession s = list[i];
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: _SessionRow(
                session: s,
                onDelete: () {
                  context.read<HistoryBloc>().add(SessionDeleted(s.sessionId));
                },
              ),
            );
          },
          childCount: list.length,
        ),
      ),
    );
  }
  return out;
}

String _dayHeaderLabel(DateTime day, DateTime today) {
  final DateTime y = today.subtract(const Duration(days: 1));
  if (day == today) {
    return 'Today';
  }
  if (day == y) {
    return 'Yesterday';
  }
  return DateFormat('EEEE, MMM d').format(day);
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color bg = dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color fg = dark ? AppColorsDark.primary : AppColors.primary;

    Widget metric(String emoji, String label, String value) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.md,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: <Widget>[
              Text(emoji, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: fg,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: <Widget>[
        metric('🔥', 'Streak', '${state.currentStreak}'),
        const SizedBox(width: AppSpacing.sm),
        metric('📅', 'Sessions', '${state.totalSessions}'),
        const SizedBox(width: AppSpacing.sm),
        metric('⏱', 'Minutes', '${state.totalPracticeMinutes}m'),
      ],
    );
  }
}

class _HeatmapSection extends StatelessWidget {
  const _HeatmapSection({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Activity',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Swipe for previous months',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 200,
          child: PageView.builder(
            itemCount: 3,
            controller: PageController(viewportFraction: 0.92),
            itemBuilder: (BuildContext context, int pageIndex) {
              final DateTime month = DateTime(now.year, now.month - pageIndex, 1);
              return Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: _MonthHeatmap(month: month, counts: counts),
              );
            },
          ),
        ),
        const SizedBox(height: AppSpacing.xxl),
      ],
    );
  }
}

class _MonthHeatmap extends StatelessWidget {
  const _MonthHeatmap({
    required this.month,
    required this.counts,
  });

  final DateTime month;
  final Map<String, int> counts;

  static String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color brandLight =
        theme.brightness == Brightness.dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    const Color emptyLight = Color(0xFFF3F4F6);
    final Color empty = theme.brightness == Brightness.dark
        ? AppColorsDark.border
        : emptyLight;

    final DateTime first = DateTime(month.year, month.month, 1);
    final int fromMonday = first.weekday - 1;
    final DateTime gridStart = first.subtract(Duration(days: fromMonday));
    final DateTime today = DateTime.now();
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);

    final List<String> dow = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          DateFormat('MMMM yyyy').format(month),
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: dow
              .map(
                (String d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              )
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
              fill = primary.withValues(alpha: 0.6);
            } else {
              fill = primary;
            }
            final DateTime cn = DateTime(cell.year, cell.month, cell.day);
            final bool isToday = cn == todayNorm;

            return GestureDetector(
              onTap: inMonth
                  ? () {
                      showDialog<void>(
                        context: context,
                        builder: (BuildContext context) => AlertDialog(
                          title: Text(DateFormat.yMMMd().format(cell)),
                          content: Text(
                            n == 0
                                ? 'No sessions'
                                : '$n session${n == 1 ? '' : 's'}',
                          ),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  : null,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: inMonth ? fill : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: isToday && inMonth
                      ? Border.all(color: primary, width: 2)
                      : null,
                ),
                child: inMonth && n > 0
                    ? Center(
                        child: Text(
                          '${cell.day}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      )
                    : inMonth
                        ? Center(
                            child: Text(
                              '${cell.day}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : null,
              ),
            );
          },
        ),
      ],
    );
  }
}

class _DateHeaderDelegate extends SliverPersistentHeaderDelegate {
  _DateHeaderDelegate({required this.label});

  final String label;

  @override
  double get minExtent => 40;

  @override
  double get maxExtent => 40;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _DateHeaderDelegate oldDelegate) {
    return oldDelegate.label != label;
  }
}

class _SessionRow extends StatelessWidget {
  const _SessionRow({
    required this.session,
    required this.onDelete,
  });

  final PracticeSession session;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(session.category);
    final String emoji = emojiForCategory(session.category);
    final String time = DateFormat.jm().format(session.completedAt);

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
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          leading: CircleAvatar(
            backgroundColor: accent.withValues(alpha: 0.2),
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
          title: Text(
            session.cardTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '$time · ${session.category}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Text(
                  formatPracticeMmSs(session.durationSeconds),
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: session.wasCompleted
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
            Icon(
              Icons.history_rounded,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.45),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No sessions yet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete a practice session to see it here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
