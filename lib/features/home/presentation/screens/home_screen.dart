import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_layout.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/utils/responsive.dart';
import 'package:speakup/core/widgets/shimmer_widget.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/card_draw/presentation/models/card_detail_route_args.dart';
import 'package:speakup/features/home/domain/built_in_categories.dart';
import 'package:speakup/features/home/presentation/bloc/home_bloc.dart';
import 'package:speakup/features/home/presentation/bloc/home_event.dart';
import 'package:speakup/features/home/presentation/bloc/home_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Home Screen
// ─────────────────────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _staggerScheduled = false;
  bool _staggerStarted = false;
  bool _showGreeting = false;
  bool _showStreak = false;
  bool _showCta = false;
  bool _showGrid = false;

  late final AnimationController _ctaController;
  late final Animation<double> _ctaScale;

  @override
  void initState() {
    super.initState();
    _ctaController = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _ctaScale = Tween<double>(begin: 0.94, end: 1).animate(CurvedAnimation(parent: _ctaController, curve: Curves.elasticOut));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final HomeBloc bloc = context.read<HomeBloc>();
      if (bloc.state.status == HomeLoadStatus.initial) {
        bloc.add(const HomeLoadRequested());
      }
    });
  }

  @override
  void dispose() {
    _ctaController.dispose();
    super.dispose();
  }

  void _runStaggerEntrance() {
    if (_staggerStarted) return;
    _staggerStarted = true;
    setState(() => _showGreeting = true);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) setState(() => _showStreak = true);
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() => _showCta = true);
        _ctaController.forward();
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) setState(() => _showGrid = true);
    });
  }

  String _greeting() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good morning 👋';
    if (h < 17) return 'Good afternoon 👋';
    return 'Good evening 👋';
  }

  int _gridCrossAxisCount(BuildContext context) => switch (Responsive.of(context)) {
    ScreenSize.mobile => 2,
    ScreenSize.tablet => 3,
    ScreenSize.desktop => 4,
  };

  @override
  Widget build(BuildContext context) {
    final EdgeInsets pagePad = AppLayout.pagePadding(context);
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return BlocConsumer<HomeBloc, HomeState>(
      listenWhen: (HomeState p, HomeState c) => c.pendingQuickDrawNavigation != p.pendingQuickDrawNavigation,
      listener: (BuildContext context, HomeState state) {
        if (state.pendingQuickDrawNavigation) {
          final String uri = Uri(path: AppRoutes.categorySelect, queryParameters: const <String, String>{'quickDraw': 'true'}).toString();
          context.push(uri);
          context.read<HomeBloc>().add(const HomeQuickDrawNavigationConsumed());
        }
      },
      builder: (BuildContext context, HomeState state) {
        // Schedule stagger once data is ready
        if (state.status == HomeLoadStatus.success && !_staggerStarted && !_staggerScheduled) {
          _staggerScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _runStaggerEntrance();
          });
        }

        // ── Error state ─────────────────────────────────────────────────────
        if (state.status == HomeLoadStatus.failure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: pagePad,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(color: theme.colorScheme.errorContainer.withValues(alpha: 0.5), shape: BoxShape.circle),
                      child: Icon(Icons.wifi_off_rounded, size: 40, color: theme.colorScheme.error),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(state.errorMessage ?? 'Something went wrong', textAlign: TextAlign.center, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: AppSpacing.lg),
                    FilledButton.icon(
                      onPressed: () => context.read<HomeBloc>().add(const HomeLoadRequested()),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg))),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // ── Loading state ────────────────────────────────────────────────────
        if (state.status == HomeLoadStatus.initial || state.status == HomeLoadStatus.loading) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 6, itemHeight: 100));
        }

        // ── Success state ────────────────────────────────────────────────────
        return Scaffold(
          backgroundColor: isDark ? theme.colorScheme.surface : theme.colorScheme.surfaceContainerLowest,
          body: CustomScrollView(
            slivers: <Widget>[
              // ── Hero app bar ───────────────────────────────────────────────
              _HeroAppBar(
                greeting: _greeting(),
                streak: state.streak,
                recentCategories: state.recentCategories,
                isDark: isDark,
                theme: theme,
                showGreeting: _showGreeting,
              ),

              // ── Body content ───────────────────────────────────────────────
              SliverPadding(
                padding: pagePad.copyWith(top: AppSpacing.lg, bottom: AppSpacing.huge),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // ── Streak / stats card ──────────────────────────────────
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      offset: _showStreak ? Offset.zero : const Offset(0, 0.06),
                      child: AnimatedOpacity(
                        opacity: _showStreak ? 1 : 0,
                        duration: const Duration(milliseconds: 320),
                        child: _StreakCard(streak: state.streak, todayCount: state.todaySessionCount),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Streak goal nudge (shown when no streak) ─────────────
                    if (state.streak == 0) ...<Widget>[const _StreakGoalNudge(), const SizedBox(height: AppSpacing.xl)],

                    // ── Quick Draw CTA ───────────────────────────────────────
                    AnimatedOpacity(
                      opacity: _showCta ? 1 : 0,
                      duration: const Duration(milliseconds: 320),
                      child: ScaleTransition(
                        scale: _ctaScale,
                        child: _QuickDrawCta(onPressed: () => context.read<HomeBloc>().add(const HomeQuickDrawRequested())),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // ── Discovery strip ───────────────────────────────────────
                    const _DiscoveryStrip(),

                    const SizedBox(height: AppSpacing.xxl),

                    // ── Category grid ────────────────────────────────────────
                    AnimatedOpacity(
                      opacity: _showGrid ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          _SectionLabel(label: 'Browse by Category'),
                          const SizedBox(height: AppSpacing.md),
                          _CategoryGrid(
                            crossAxisCount: _gridCrossAxisCount(context),
                            categoryCardCounts: state.categoryCardCounts,
                            customCardsCount: state.customCardsCount,
                            recentCategories: state.recentCategories,
                          ),
                        ],
                      ),
                    ),

                    // ── Recent sessions ──────────────────────────────────────
                    if (state.recentSessions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedOpacity(
                        opacity: _showGrid ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _SectionLabel(label: 'Continue Practicing'),
                            const SizedBox(height: AppSpacing.md),
                            _RecentSessionsRow(sessions: state.recentSessions),
                          ],
                        ),
                      ),
                    ],
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero collapsible app bar with greeting
// ─────────────────────────────────────────────────────────────────────────────

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({
    required this.greeting,
    required this.streak,
    required this.recentCategories,
    required this.isDark,
    required this.theme,
    required this.showGreeting,
  });

  final String greeting;
  final int streak;
  final List<String> recentCategories;
  final bool isDark;
  final ThemeData theme;
  final bool showGreeting;

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
        title: AnimatedOpacity(
          opacity: showGreeting ? 1 : 0,
          duration: const Duration(milliseconds: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                greeting,
                style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  color: isDark ? theme.colorScheme.onSurface : Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              _GreetingSubtitle(streak: streak, recentCategories: recentCategories, isDark: isDark, theme: theme),
            ],
          ),
        ),
        // background: _HeroBackground(isDark: isDark, theme: theme),
      ),
    );
  }
}

class _GreetingSubtitle extends StatelessWidget {
  const _GreetingSubtitle({required this.streak, required this.recentCategories, required this.isDark, required this.theme});

  final int streak;
  final List<String> recentCategories;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final Color subtitleColor = isDark ? theme.colorScheme.onSurfaceVariant : Colors.white70;

    if (streak > 0) {
      return Text(
        '🔥  $streak-day streak — keep going!',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: subtitleColor),
      );
    }
    if (recentCategories.isNotEmpty) {
      return Text(
        'Recent: ${recentCategories.take(2).join(' · ')}',
        style: TextStyle(fontSize: 11, color: subtitleColor),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      );
    }
    return Text('Start your speaking journey today', style: TextStyle(fontSize: 11, color: subtitleColor));
  }
}

class _HeroBackground extends StatelessWidget {
  const _HeroBackground({required this.isDark, required this.theme});

  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    if (isDark) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8), theme.colorScheme.surface],
          ),
        ),
        child: Align(
          alignment: Alignment.centerRight,
          child: Opacity(opacity: 0.06, child: Icon(Icons.record_voice_over_rounded, size: 150, color: theme.colorScheme.primary)),
        ),
      );
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.82)],
        ),
      ),
      child: const Align(
        alignment: Alignment.centerRight,
        child: Opacity(opacity: 0.1, child: Icon(Icons.record_voice_over_rounded, size: 150, color: Colors.white)),
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
    final ThemeData theme = Theme.of(context);
    return Text(
      label,
      style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak card
// ─────────────────────────────────────────────────────────────────────────────

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.todayCount});

  final int streak;
  final int todayCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final bool hasStreak = streak > 0;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: isDark
            ? null
            : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: <Widget>[
            // Streak icon badge
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: hasStreak ? const Color(0xFFFFF3C0) : theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(child: Text(hasStreak ? '🔥' : '💪', style: const TextStyle(fontSize: 26))),
            ),
            const SizedBox(width: AppSpacing.lg),

            // Streak info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        '$streak',
                        style: TextStyle(fontFamily: 'Plus Jakarta Sans', 
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: hasStreak ? const Color(0xFFF59E0B) : theme.colorScheme.onSurface,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.xs, bottom: AppSpacing.xs),
                        child: Text('day streak', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    streak == 0 ? 'Practice today to start a streak' : "Keep going — you're on a roll!",
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),

            // Vertical divider
            Container(
              width: 1,
              height: 48,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),

            // Today count
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Text(
                  '$todayCount',
                  style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 28, fontWeight: FontWeight.w800, height: 1, color: theme.colorScheme.primary),
                ),
                const SizedBox(height: 2),
                Text('today', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Draw CTA — pulsing idle button with gradient
// ─────────────────────────────────────────────────────────────────────────────

class _QuickDrawCta extends StatefulWidget {
  const _QuickDrawCta({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_QuickDrawCta> createState() => _QuickDrawCtaState();
}

class _QuickDrawCtaState extends State<_QuickDrawCta> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.0, end: 1.025), weight: 40),
      TweenSequenceItem<double>(tween: Tween<double>(begin: 1.025, end: 1.0), weight: 60),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _schedulePulse();
  }

  void _schedulePulse() {
    _idleTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        _ctrl.forward(from: 0);
        _schedulePulse();
      }
    });
  }

  @override
  void dispose() {
    _idleTimer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return AnimatedBuilder(
      animation: _scale,
      builder: (BuildContext ctx, Widget? child) => Transform.scale(scale: _scale.value, child: child),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onPressed();
        },
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(colors: <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.8)])
                : LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.85)],
                  ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: <BoxShadow>[BoxShadow(color: theme.colorScheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(Icons.shuffle_rounded, color: Colors.white, size: 22),
              const SizedBox(width: AppSpacing.md),
              Text(
                'Draw a Card',
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Category grid
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.crossAxisCount,
    required this.categoryCardCounts,
    required this.customCardsCount,
    required this.recentCategories,
  });

  final int crossAxisCount;
  final Map<String, int> categoryCardCounts;
  final int customCardsCount;
  final List<String> recentCategories;

  @override
  Widget build(BuildContext context) {
    final Set<String> recent = recentCategories.toSet();
    final List<BuiltInCategoryDef> ordered = <BuiltInCategoryDef>[
      ...kBuiltInBrowseCategories.where((BuiltInCategoryDef d) => recent.contains(d.name)),
      ...kBuiltInBrowseCategories.where((BuiltInCategoryDef d) => !recent.contains(d.name)),
    ];

    final List<Widget> tiles = <Widget>[
      for (final BuiltInCategoryDef def in ordered)
        _CategoryTile(
          emoji: def.emoji,
          title: def.name,
          count: categoryCardCounts[def.name] ?? 0,
          accentColor: def.accentColor,
          isRecent: recent.contains(def.name),
          onTap: () {
            final String uri = Uri(path: AppRoutes.categorySelect, queryParameters: <String, String>{'category': def.name}).toString();
            context.push(uri);
          },
        ),
      _CategoryTile(
        emoji: '✏️',
        title: 'My Cards',
        count: customCardsCount,
        accentColor: const Color(0xFF8B5CF6),
        isRecent: false,
        onTap: () => context.push(AppRoutes.customCategories),
      ),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.02,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.emoji,
    required this.title,
    required this.count,
    required this.accentColor,
    required this.isRecent,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final int count;
  final Color accentColor;
  final bool isRecent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return _PressScaleTile(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
          boxShadow: isDark
              ? null
              : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: <Widget>[
            // Subtle top-left accent tint
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: <Color>[
                      accentColor.withValues(alpha: isDark ? 0.18 : 0.12),
                      Colors.transparent,
                    ],
                    radius: 1,
                  ),
                ),
              ),
            ),
            // Accent top stripe
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.7),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const Spacer(),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, height: 1.3),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                        decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.sm)),
                        child: Text(
                          '$count cards',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accentColor),
                        ),
                      ),
                      if (isRecent) ...<Widget>[
                        const SizedBox(width: AppSpacing.xs),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent sessions row
// ─────────────────────────────────────────────────────────────────────────────

class _RecentSessionsRow extends StatelessWidget {
  const _RecentSessionsRow({required this.sessions});
  final List<HomeRecentSession> sessions;

  String _formatAgo(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 1) return 'Just now';
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 7) return '${d.inDays}d ago';
    return '${t.month}/${t.day}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sessions.length,
        separatorBuilder: (_, int _i) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (BuildContext ctx, int i) {
          final HomeRecentSession s = sessions[i];
          return GestureDetector(
            onTap: () async {
              HapticFeedback.selectionClick();
              final CardRepository repo = ctx.read<CardRepository>();
              final result = await repo.getByCardId(s.cardId);
              if (!ctx.mounted) return;
              result.fold(
                (_) => ScaffoldMessenger.of(ctx)
                  ..clearSnackBars()
                  ..showSnackBar(const SnackBar(content: Text('Could not open card'), behavior: SnackBarBehavior.floating)),
                (card) => ctx.push(AppRoutes.cardDetail, extra: CardDetailRouteArgs(card: card)),
              );
            },
            child: Container(
              width: 220,
              decoration: BoxDecoration(
                color: isDark ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35) : theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35)),
                boxShadow: isDark
                    ? null
                    : <BoxShadow>[BoxShadow(color: theme.colorScheme.shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.history_rounded, size: 14, color: theme.colorScheme.primary.withValues(alpha: 0.7)),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatAgo(s.completedAt),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      s.cardTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, height: 1.35),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer.withValues(alpha: 0.8),
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: Text(
                        _formatDuration(s.durationSeconds),
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Press-scale wrapper
// ─────────────────────────────────────────────────────────────────────────────

class _PressScaleTile extends StatefulWidget {
  const _PressScaleTile({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  State<_PressScaleTile> createState() => _PressScaleTileState();
}

class _PressScaleTileState extends State<_PressScaleTile> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        HapticFeedback.selectionClick();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (BuildContext ctx, Widget? child) => Transform.scale(scale: _scale.value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Discovery Strip — curated topic spotlights
// ─────────────────────────────────────────────────────────────────────────────

class _SpotlightItem {
  const _SpotlightItem({required this.label, required this.emoji, required this.subtitle, required this.accentColor, required this.category});
  final String label;
  final String emoji;
  final String subtitle;
  final Color accentColor;
  final String category;
}

const List<_SpotlightItem> _kSpotlights = <_SpotlightItem>[
  _SpotlightItem(label: 'AI & Ethics', emoji: '🤖', subtitle: 'Trending topic', accentColor: Color(0xFF6366F1), category: 'Technology'),
  _SpotlightItem(label: 'Influence Others', emoji: '💡', subtitle: "Today's pick", accentColor: Color(0xFF16A34A), category: 'Personal Growth'),
  _SpotlightItem(label: 'Debate Corner', emoji: '🗣️', subtitle: 'Hot debate', accentColor: Color(0xFFDB2777), category: 'Opinion & Debate'),
];

class _DiscoveryStrip extends StatelessWidget {
  const _DiscoveryStrip();

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Spotlight',
          style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 16, fontWeight: FontWeight.w800, color: theme.colorScheme.onSurface),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _kSpotlights.length,
            separatorBuilder: (_, int _i) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext ctx, int i) {
              final _SpotlightItem s = _kSpotlights[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  final String uri = Uri(path: AppRoutes.categorySelect, queryParameters: <String, String>{'category': s.category}).toString();
                  ctx.push(uri);
                },
                child: Container(
                  width: 160,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[s.accentColor.withValues(alpha: 0.18), s.accentColor.withValues(alpha: 0.06)],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: s.accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Text(s.emoji, style: const TextStyle(fontSize: 20)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: s.accentColor.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              s.subtitle,
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: s.accentColor),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(s.label, maxLines: 2, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13, height: 1.2)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Streak Goal Nudge — pill shown when streak == 0
// ─────────────────────────────────────────────────────────────────────────────

class _StreakGoalNudge extends StatelessWidget {
  const _StreakGoalNudge();

  void _showGoalSheet(BuildContext context) {
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl))),
      builder: (BuildContext sheetCtx) {
        final ThemeData theme = Theme.of(sheetCtx);
        return Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.xl, AppSpacing.xl, AppSpacing.xl, AppSpacing.huge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Set a daily goal', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w800, fontSize: 20)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'How many sessions do you want to do each day?',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.xl),
              ...List<Widget>.generate(3, (int i) {
                final int goal = i + 1;
                final List<String> labels = <String>['1 session — Easy start', '2 sessions — Steady pace', '3 sessions — Full power'];
                final List<String> emojis = <String>['🌱', '🔥', '⚡'];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ListTile(
                    leading: Text(emojis[i], style: const TextStyle(fontSize: 24)),
                    title: Text(labels[i], style: const TextStyle(fontWeight: FontWeight.w600)),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      side: BorderSide(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(sheetCtx);
                      ScaffoldMessenger.of(context)
                        ..clearSnackBars()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('Goal set: $goal ${goal == 1 ? 'session' : 'sessions'}/day 🎯'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                    },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    return GestureDetector(
      onTap: () => _showGoalSheet(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
              : theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: <Widget>[
            const Text('🎯', style: TextStyle(fontSize: 22)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Set a daily goal', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13)),
                  Text('Stay consistent with a target', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}
