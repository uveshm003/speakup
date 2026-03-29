import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/theme/app_colors.dart';
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
      if (!mounted) {
        return;
      }
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
    if (_staggerStarted) {
      return;
    }
    _staggerStarted = true;
    setState(() => _showGreeting = true);
    Future<void>.delayed(const Duration(milliseconds: 90), () {
      if (mounted) {
        setState(() => _showStreak = true);
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 180), () {
      if (mounted) {
        setState(() => _showCta = true);
        _ctaController.forward();
      }
    });
    Future<void>.delayed(const Duration(milliseconds: 260), () {
      if (mounted) {
        setState(() => _showGrid = true);
      }
    });
  }

  String _greetingLine() {
    final int h = DateTime.now().hour;
    if (h < 12) {
      return 'Good morning, let\'s practice 👋';
    }
    if (h < 17) {
      return 'Good afternoon';
    }
    return 'Good evening';
  }

  int _gridCrossAxisCount(BuildContext context) {
    return switch (Responsive.of(context)) {
      ScreenSize.mobile => 2,
      ScreenSize.tablet => 3,
      ScreenSize.desktop => 4,
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets pagePad = AppLayout.pagePadding(context);

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
        if (state.status == HomeLoadStatus.success && !_staggerStarted && !_staggerScheduled) {
          _staggerScheduled = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _runStaggerEntrance();
            }
          });
        }
        if (state.status == HomeLoadStatus.failure) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: pagePad,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(state.errorMessage ?? 'Something went wrong', textAlign: TextAlign.center),
                    const SizedBox(height: AppSpacing.md),
                    FilledButton(onPressed: () => context.read<HomeBloc>().add(const HomeLoadRequested()), child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          );
        }

        if (state.status == HomeLoadStatus.initial || state.status == HomeLoadStatus.loading) {
          return const Scaffold(body: ShimmerListPlaceholder(itemCount: 6, itemHeight: 100));
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: <Widget>[
              SliverPadding(
                padding: pagePad.copyWith(top: pagePad.top + AppSpacing.md, bottom: AppSpacing.xxl),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    AnimatedOpacity(
                      opacity: _showGreeting ? 1 : 0,
                      duration: const Duration(milliseconds: 380),
                      curve: Curves.easeOut,
                      child: _GreetingHeader(
                        greeting: _greetingLine(),
                        streak: state.streak,
                        subtitleRecent: state.recentCategories.isNotEmpty,
                        recentCategories: state.recentCategories,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedSlide(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeOutCubic,
                      offset: _showStreak ? Offset.zero : const Offset(0, 0.06),
                      child: AnimatedOpacity(
                        opacity: _showStreak ? 1 : 0,
                        duration: const Duration(milliseconds: 320),
                        child: _StreakCard(streak: state.streak, todayCount: state.todaySessionCount, theme: theme),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AnimatedOpacity(
                      opacity: _showCta ? 1 : 0,
                      duration: const Duration(milliseconds: 320),
                      child: ScaleTransition(
                        scale: _ctaScale,
                        child: _IdlePulseCta(onPressed: () => context.read<HomeBloc>().add(const HomeQuickDrawRequested())),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AnimatedOpacity(
                      opacity: _showGrid ? 1 : 0,
                      duration: const Duration(milliseconds: 400),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Browse by category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
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
                    if (state.recentSessions.isNotEmpty) ...<Widget>[
                      const SizedBox(height: AppSpacing.xxl),
                      AnimatedOpacity(
                        opacity: _showGrid ? 1 : 0,
                        duration: const Duration(milliseconds: 400),
                        child: _RecentSessionsRow(sessions: state.recentSessions),
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

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.greeting, required this.streak, required this.subtitleRecent, required this.recentCategories});

  final String greeting;
  final int streak;
  final bool subtitleRecent;
  final List<String> recentCategories;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final String subtitle = streak > 0 ? 'Day $streak streak 🔥' : 'Start your streak today';
    final String? recentLine = subtitleRecent && recentCategories.isNotEmpty ? 'Recent: ${recentCategories.take(2).join(', ')}' : null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(greeting, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3)),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
              ),
              if (recentLine != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(recentLine, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.85))),
              ],
            ],
          ),
        ),
        CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            'S',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
      ],
    );
  }
}

class _StreakCard extends StatelessWidget {
  const _StreakCard({required this.streak, required this.todayCount, required this.theme});

  final int streak;
  final int todayCount;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final bool isDark = theme.brightness == Brightness.dark;
    final Color start = isDark ? AppColorsDark.primaryLight : AppColors.primaryLight;
    final Color end = theme.colorScheme.surface;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: <Color>[start, end]),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.local_fire_department_rounded, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '$streak',
                style: GoogleFonts.plusJakartaSans(fontSize: 40, fontWeight: FontWeight.w800, height: 1, color: theme.colorScheme.onSurface),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Day streak',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Today: $todayCount sessions', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          if (streak == 0) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text('Practice today to start your streak', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

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
        _CategoryPillCard(
          emoji: def.emoji,
          title: def.name,
          count: categoryCardCounts[def.name] ?? 0,
          onTap: () {
            final String uri = Uri(path: AppRoutes.categorySelect, queryParameters: <String, String>{'category': def.name}).toString();
            context.push(uri);
          },
        ),
      _CategoryPillCard(emoji: '✏️', title: 'My Categories', count: customCardsCount, onTap: () => context.push(AppRoutes.customCategories)),
    ];

    return GridView.count(
      crossAxisCount: crossAxisCount,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.05,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: tiles,
    );
  }
}

class _CategoryPillCard extends StatelessWidget {
  const _CategoryPillCard({required this.emoji, required this.title, required this.count, required this.onTap});

  final String emoji;
  final String title;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return _PressScaleTile(
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(emoji, style: const TextStyle(fontSize: 28)),
                const Spacer(),
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(
                    '$count cards',
                    style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.onPrimaryContainer),
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

/// Wraps any widget to scale it down on press (0.97) and spring back (1.0).
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
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
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

/// Draw a Card CTA that pulses gently every 3 seconds when idle.
class _IdlePulseCta extends StatefulWidget {
  const _IdlePulseCta({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_IdlePulseCta> createState() => _IdlePulseCtaState();
}

class _IdlePulseCtaState extends State<_IdlePulseCta> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.04), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.04, end: 1.0), weight: 60),
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
    return AnimatedBuilder(
      animation: _scale,
      builder: (BuildContext context, Widget? child) => Transform.scale(scale: _scale.value, child: child),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: FilledButton.icon(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl))),
          icon: const Icon(Icons.shuffle_rounded),
          label: const Text('Draw a Card'),
        ),
      ),
    );
  }
}

class _RecentSessionsRow extends StatelessWidget {
  const _RecentSessionsRow({required this.sessions});

  final List<HomeRecentSession> sessions;

  String _formatAgo(DateTime t) {
    final Duration d = DateTime.now().difference(t);
    if (d.inMinutes < 1) {
      return 'Just now';
    }
    if (d.inMinutes < 60) {
      return '${d.inMinutes}m ago';
    }
    if (d.inHours < 24) {
      return '${d.inHours}h ago';
    }
    if (d.inDays < 7) {
      return '${d.inDays}d ago';
    }
    return '${t.month}/${t.day}';
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text('Continue practicing', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: sessions.length,
            separatorBuilder: (BuildContext context, int index) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (BuildContext context, int i) {
              final HomeRecentSession s = sessions[i];
              return Material(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () async {
                    final CardRepository repo = context.read<CardRepository>();
                    final result = await repo.getByCardId(s.cardId);
                    if (!context.mounted) {
                      return;
                    }
                    result.fold((_) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open card')));
                    }, (card) => context.push(AppRoutes.cardDetail, extra: CardDetailRouteArgs(card: card)));
                  },
                  child: SizedBox(
                    width: 220,
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            s.cardTitle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Row(
                            children: <Widget>[
                              Text(_formatAgo(s.completedAt), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  _formatDuration(s.durationSeconds),
                                  style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
