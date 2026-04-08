
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/widgets/recording_player_sheet.dart';
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

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _calendarExpanded = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late final AnimationController _headerAnimController;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _headerAnimController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
          ..forward();
    _headerFade = CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOut);
    // Listen to router so we pick up new sessions when returning from practice
    WidgetsBinding.instance.addPostFrameCallback((_) {
      GoRouter.of(context).routerDelegate.addListener(_onRouteChanged);
    });
  }

  void _onRouteChanged() {
    // Re-fetch whenever we land back on the history path
    if (!mounted) return;
    final String location = GoRouter.of(context).routerDelegate.currentConfiguration.uri.toString();
    if (location == AppRoutes.history || location == AppRoutes.home) {
      context.read<HistoryBloc>().add(const HistoryLoadRequested());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reload when app comes back to foreground (e.g. returning from permissions)
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<HistoryBloc>().add(const HistoryLoadRequested());
    }
  }


  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Safe removal — GoRouter may already be disposed
    try {
      GoRouter.of(context).routerDelegate.removeListener(_onRouteChanged);
    } catch (_) {}
    _searchController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pad = AppLayout.pagePadding(context);

    return BlocListener<HistoryBloc, HistoryState>(
      listenWhen: (HistoryState p, HistoryState c) => c.pendingDeletion != null && c.pendingDeletion != p.pendingDeletion,
      listener: (BuildContext context, HistoryState state) {
        final PracticeSession? s = state.pendingDeletion;
        if (s == null) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Session removed'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'Undo', onPressed: () => context.read<HistoryBloc>().add(const SessionDeleteUndoRequested())),
          ),
        );
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<HistoryBloc, HistoryState>(
            builder: (BuildContext context, HistoryState state) {
              if (state.status == HistoryStatus.loading && state.allSessions.isEmpty) {
                return _LoadingSkeleton(pad: pad);
              }

              if (state.status == HistoryStatus.failure && state.allSessions.isEmpty) {
                return _ErrorState(message: state.errorMessage ?? 'Could not load history', pad: pad);
              }

              final List<PracticeSession> filtered = _applySearch(state.logSessions, _searchQuery);

              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: <Widget>[
                  SliverToBoxAdapter(
                    child: FadeTransition(
                      opacity: _headerFade,
                      child: _StatsHeader(state: state, pad: pad),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.xl, pad.right, 0),
                    sliver: SliverToBoxAdapter(
                      child: _ActivitySection(
                        counts: state.sessionsPerDayKey,
                        expanded: _calendarExpanded,
                        onToggle: () => setState(() => _calendarExpanded = !_calendarExpanded),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(pad.left, AppSpacing.lg, pad.right, AppSpacing.sm),
                    sliver: SliverToBoxAdapter(
                      child: _SearchBar(controller: _searchController, onChanged: (String q) => setState(() => _searchQuery = q)),
                    ),
                  ),
                  if (filtered.isEmpty && state.logSessions.isEmpty)
                    const SliverFillRemaining(hasScrollBody: false, child: _EmptyHistory())
                  else if (filtered.isEmpty)
                    SliverFillRemaining(hasScrollBody: false, child: _NoSearchResults(query: _searchQuery))
                  else
                    ..._buildTimelineSlivers(context, filtered, pad),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  List<PracticeSession> _applySearch(List<PracticeSession> sessions, String q) {
    if (q.trim().isEmpty) return sessions;
    final String lower = q.toLowerCase();
    return sessions.where((PracticeSession s) => s.cardTitle.toLowerCase().contains(lower) || s.category.toLowerCase().contains(lower)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading skeleton
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingSkeleton extends StatelessWidget {
  const _LoadingSkeleton({required this.pad});
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ShimmerWidget(width: double.infinity, height: 160, borderRadius: BorderRadius.zero),
        Expanded(child: ShimmerListPlaceholder(itemCount: 6, itemHeight: 80)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error state
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.pad});
  final String message;
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: pad,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.error_outline_rounded, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Immersive stats header
// ─────────────────────────────────────────────────────────────────────────────

class _StatsHeader extends StatelessWidget {
  const _StatsHeader({required this.state, required this.pad});
  final HistoryState state;
  final EdgeInsets pad;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final Color primaryContainer = theme.colorScheme.primaryContainer;
    final bool dark = theme.brightness == Brightness.dark;

    final LinearGradient grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: dark
          ? <Color>[primary.withValues(alpha: 0.22), theme.colorScheme.surface]
          : <Color>[primaryContainer.withValues(alpha: 0.55), theme.colorScheme.surface],
    );

    return Container(
      decoration: BoxDecoration(gradient: grad),
      padding: EdgeInsets.fromLTRB(pad.left, pad.top + AppSpacing.md, pad.right, AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('History', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.5)),
                    const SizedBox(height: 2),
                    Text('Your practice journey', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: primary.withValues(alpha: 0.2), width: 1),
                ),
                child: Icon(Icons.auto_graph_rounded, size: 20, color: primary),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFEA580C),
                label: 'Streak',
                value: '${state.currentStreak}d',
                accentColor: const Color(0xFFEA580C),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                icon: Icons.playlist_play_rounded,
                iconColor: primary,
                label: 'Sessions',
                value: '${state.totalSessions}',
                accentColor: primary,
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatChip(
                icon: Icons.timer_outlined,
                iconColor: const Color(0xFF16A34A),
                label: 'Minutes',
                value: '${state.totalPracticeMinutes}m',
                accentColor: const Color(0xFF16A34A),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.iconColor, required this.label, required this.value, required this.accentColor});

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.sm),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: accentColor.withValues(alpha: 0.15), width: 1),
          boxShadow: <BoxShadow>[BoxShadow(color: accentColor.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: <Widget>[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sm)),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(height: AppSpacing.xs + 2),
            Text(value, style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 18, fontWeight: FontWeight.w800, color: accentColor, height: 1.1)),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.2)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Search bar
// ─────────────────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.controller, required this.onChanged});
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: theme.textTheme.bodyMedium,
      decoration: InputDecoration(
        hintText: 'Search sessions…',
        prefixIcon: Icon(Icons.search_rounded, size: 20, color: theme.colorScheme.onSurfaceVariant),
        suffixIcon: controller.text.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  controller.clear();
                  onChanged('');
                },
                child: Icon(Icons.close_rounded, size: 18, color: theme.colorScheme.onSurfaceVariant),
              )
            : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
        isDense: true,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Activity section
// ─────────────────────────────────────────────────────────────────────────────

class _ActivitySection extends StatelessWidget {
  const _ActivitySection({required this.counts, required this.expanded, required this.onToggle});

  final Map<String, int> counts;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35), width: 1),
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.bar_chart_rounded, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Activity', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
              const Spacer(),
              _ToggleChip(expanded: expanded, onTap: onToggle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _WeekStrip(counts: counts),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOut,
            child: expanded
                ? Padding(padding: const EdgeInsets.only(top: AppSpacing.xl), child: _MonthPageView(counts: counts))
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.expanded, required this.onTap});
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm + 2, vertical: AppSpacing.xs),
        decoration: BoxDecoration(
          color: expanded
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: expanded ? theme.colorScheme.primary.withValues(alpha: 0.3) : theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              expanded ? 'Hide' : 'Calendar',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: expanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 250),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 14,
                color: expanded ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 7-day compact strip
// ─────────────────────────────────────────────────────────────────────────────

class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.counts});
  final Map<String, int> counts;

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final bool dark = theme.brightness == Brightness.dark;
    final Color brandLight = dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color emptyBg = theme.colorScheme.surfaceContainerHighest.withValues(alpha: dark ? 0.5 : 0.6);

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime weekStart = today.subtract(Duration(days: today.weekday - 1));
    const List<String> dow = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
                Text(
                  dow[i],
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                    color: isToday ? primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 36,
                  decoration: BoxDecoration(
                    color: fill,
                    borderRadius: BorderRadius.circular(AppRadius.sm + 2),
                    border: isToday ? Border.all(color: primary, width: 2) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${day.day}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                      color: n > 0 && !isFuture
                          ? (n >= 2 ? Colors.white : primary)
                          : theme.colorScheme.onSurfaceVariant.withValues(alpha: isFuture ? 0.28 : 0.5),
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
// Full monthly page view
// ─────────────────────────────────────────────────────────────────────────────

class _MonthPageView extends StatelessWidget {
  const _MonthPageView({required this.counts});
  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double cellGap = 4;
        final double cellSize = (constraints.maxWidth - 6 * cellGap) / 7;
        final double gridHeight = 5 * cellSize + 4 * cellGap;
        final double totalHeight = 50 + gridHeight;

        return SizedBox(
          height: totalHeight,
          child: PageView.builder(
            itemCount: 3,
            controller: PageController(viewportFraction: 1),
            itemBuilder: (BuildContext context, int pageIndex) {
              final DateTime month = DateTime(now.year, now.month - pageIndex, 1);
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

  static String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;
    final bool dark = theme.brightness == Brightness.dark;
    final Color brandLight = dark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color empty = theme.colorScheme.surfaceContainerHighest.withValues(alpha: dark ? 0.4 : 0.6);

    final DateTime first = DateTime(month.year, month.month, 1);
    final int fromMonday = first.weekday - 1;
    final DateTime gridStart = first.subtract(Duration(days: fromMonday));
    final DateTime today = DateTime.now();
    final DateTime todayNorm = DateTime(today.year, today.month, today.day);
    const List<String> dow = <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(DateFormat('MMMM yyyy').format(month), style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: dow
              .map((String d) => Expanded(child: Center(child: Text(d, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)))))
              .toList(),
        ),
        const SizedBox(height: AppSpacing.xs),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4, childAspectRatio: 1),
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
            final bool isToday = DateTime(cell.year, cell.month, cell.day) == todayNorm;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: inMonth ? fill : Colors.transparent,
                borderRadius: BorderRadius.circular(5),
                border: isToday && inMonth ? Border.all(color: primary, width: 1.8) : null,
              ),
              child: inMonth
                  ? Center(
                      child: Text(
                        '${cell.day}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: n > 0 ? (n >= 2 ? Colors.white : primary) : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
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
// Timeline slivers builder
// ─────────────────────────────────────────────────────────────────────────────

List<Widget> _buildTimelineSlivers(BuildContext context, List<PracticeSession> sessions, EdgeInsets pad) {
  final Map<DateTime, List<PracticeSession>> byDay = <DateTime, List<PracticeSession>>{};
  for (final PracticeSession s in sessions) {
    final DateTime d = DateTime(s.completedAt.year, s.completedAt.month, s.completedAt.day);
    byDay.putIfAbsent(d, () => <PracticeSession>[]).add(s);
  }
  final List<DateTime> days = byDay.keys.toList()..sort((DateTime a, DateTime b) => b.compareTo(a));

  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final List<Widget> out = <Widget>[];

  for (int dayIdx = 0; dayIdx < days.length; dayIdx++) {
    final DateTime day = days[dayIdx];
    final List<PracticeSession> list = byDay[day]!;
    final bool isLast = dayIdx == days.length - 1;

    out.add(
      SliverPadding(
        padding: EdgeInsets.fromLTRB(pad.left, 0, pad.right, 0),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (BuildContext context, int i) {
              final bool isFirstInDay = i == 0;
              final bool isLastInDay = i == list.length - 1;
              return _TimelineSessionCard(
                session: list[i],
                dayLabel: isFirstInDay ? _dayHeaderLabel(day, today) : null,
                isLastCard: isLast && isLastInDay,
                onDelete: () => context.read<HistoryBloc>().add(SessionDeleted(list[i].sessionId)),
              );
            },
            childCount: list.length,
          ),
        ),
      ),
    );
  }

  out.add(const SliverPadding(padding: EdgeInsets.only(bottom: AppSpacing.huge)));
  return out;
}

String _dayHeaderLabel(DateTime day, DateTime today) {
  final DateTime yesterday = today.subtract(const Duration(days: 1));
  if (day == today) return 'Today';
  if (day == yesterday) return 'Yesterday';
  return DateFormat('EEE, MMM d').format(day);
}

// ─────────────────────────────────────────────────────────────────────────────
// Timeline session card
// ─────────────────────────────────────────────────────────────────────────────

class _TimelineSessionCard extends StatelessWidget {
  const _TimelineSessionCard({required this.session, required this.onDelete, required this.isLastCard, this.dayLabel});

  final PracticeSession session;
  final VoidCallback onDelete;
  final bool isLastCard;
  final String? dayLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent = accentColorForCategory(session.category);
    final String emoji = emojiForCategory(session.category);
    final String time = DateFormat.jm().format(session.completedAt);
    final bool completed = session.wasCompleted;
    final Color spineColor = theme.colorScheme.outlineVariant.withValues(alpha: 0.4);

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 52,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                if (dayLabel != null) ...<Widget>[_DateBadge(label: dayLabel!, theme: theme), const SizedBox(height: AppSpacing.xs)] else const SizedBox(height: AppSpacing.xs + 4),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: <BoxShadow>[BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 6, spreadRadius: 1)],
                  ),
                ),
                if (!isLastCard) Container(width: 1.5, height: 56, color: spineColor, margin: const EdgeInsets.only(top: 4)),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 0),
              child: _SessionCard(
                session: session,
                emoji: emoji,
                accent: accent,
                time: time,
                completed: completed,
                onDelete: onDelete,
                hasTopLabel: dayLabel != null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.label, required this.theme});
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 52),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45), borderRadius: BorderRadius.circular(AppRadius.xs)),
      child: Text(
        label.length > 5 ? label.substring(0, 3) : label,
        textAlign: TextAlign.center,
        style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, fontSize: 9, color: theme.colorScheme.primary, letterSpacing: 0.3),
      ),
    );
  }
}

class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.emoji,
    required this.accent,
    required this.time,
    required this.completed,
    required this.onDelete,
    required this.hasTopLabel,
  });

  final PracticeSession session;
  final String emoji;
  final Color accent;
  final String time;
  final bool completed;
  final VoidCallback onDelete;
  final bool hasTopLabel;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasRecording = session.recordingPath != null && session.recordingPath!.isNotEmpty;

    return Dismissible(
      key: ValueKey<String>(session.sessionId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        decoration: BoxDecoration(color: theme.colorScheme.error.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.lg)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.delete_outline_rounded, color: theme.colorScheme.error, size: 20),
            const SizedBox(width: AppSpacing.xs),
            Text('Delete', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.error, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: EdgeInsets.only(top: hasTopLabel ? 0 : 0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: accent.withValues(alpha: 0.18), width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: InkWell(
              onTap: hasRecording ? () => _openPlayer(context) : null,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    height: 3,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: <Color>[accent, accent.withValues(alpha: 0.3)])),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.sm),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)),
                          alignment: Alignment.center,
                          child: Text(emoji, style: const TextStyle(fontSize: 20)),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                session.cardTitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700, height: 1.3),
                              ),
                              const SizedBox(height: 3),
                              Row(
                                children: <Widget>[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                                    decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.xs)),
                                    child: Text(
                                      session.category,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: accent, letterSpacing: 0.2),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Text('· $time', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                formatPracticeMmSs(session.durationSeconds),
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: theme.colorScheme.primary),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(shape: BoxShape.circle, color: completed ? AppColors.success : AppColors.warning),
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  completed ? 'Done' : 'Partial',
                                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: completed ? AppColors.success : AppColors.warning),
                                ),
                              ],
                            ),
                            // Play recording button
                            if (hasRecording) ...<Widget>[
                              const SizedBox(height: AppSpacing.xs),
                              GestureDetector(
                                onTap: () => _openPlayer(context),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs + 2, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(AppRadius.xs),
                                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.25)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(Icons.play_arrow_rounded, size: 12, color: theme.colorScheme.primary),
                                      const SizedBox(width: 2),
                                      Text('Play', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.primary)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openPlayer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => RecordingPlayerSheet(session: session),
    );
  }
}
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
            Stack(
              alignment: Alignment.center,
              children: <Widget>[
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2)),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35)),
                  child: Icon(Icons.history_edu_rounded, size: 36, color: theme.colorScheme.primary.withValues(alpha: 0.75)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('No sessions yet', style: GoogleFonts.newsreader(fontSize: 22, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete your first practice session\nand your journey will appear here.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xl),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go(AppRoutes.home),
                borderRadius: BorderRadius.circular(AppRadius.full),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.arrow_back_rounded, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.75)),
                      const SizedBox(width: AppSpacing.xs),
                      Text('Go practise!', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: theme.colorScheme.primary)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No search results
// ─────────────────────────────────────────────────────────────────────────────

class _NoSearchResults extends StatelessWidget {
  const _NoSearchResults({required this.query});
  final String query;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(Icons.search_off_rounded, size: 48, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: AppSpacing.md),
            Text('No results for "$query"', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.sm),
            Text('Try a different card title or category.', style: theme.textTheme.bodySmall, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
