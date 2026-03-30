import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/router/router_refresh.dart';
import 'package:speakup/config/theme/app_colors.dart';
import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/core/core.dart';
import 'package:speakup/features/settings/data/mappers/user_settings_mapper.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';

// =============================================================================
// Onboarding data
// =============================================================================

class _OnboardingData {
  const _OnboardingData({required this.title, required this.body, required this.illustrationBuilder});

  final String title;
  final String body;
  final Widget Function(BuildContext) illustrationBuilder;
}

final List<_OnboardingData> _pages = [
  _OnboardingData(
    title: 'Speak with Confidence',
    body: 'Master spoken English through guided, real-world topics and vocabulary boosts.',
    illustrationBuilder: (_) => Image.asset(AppAssets.ob1),
  ),
  _OnboardingData(
    title: 'Learn Before You Speak',
    body: 'Every card has a Mini Guide and Vocabulary Boost to help you prepare in under 60 seconds.',
    illustrationBuilder: (_) => Image.asset(AppAssets.ob2),
  ),
  _OnboardingData(
    title: 'Practice Daily, Build Streaks',
    body: 'Track your sessions, earn streaks, and grow one conversation at a time.',
    illustrationBuilder: (_) => Image.asset(AppAssets.ob3),
  ),
];

// =============================================================================
// OnboardingScreen
// =============================================================================

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with SingleTickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _page = 0;

  // Card entrance animation
  late final AnimationController _cardCtrl;
  late final Animation<double> _cardOpacity;
  late final Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _cardOpacity = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Interval(0.0, 1.0, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardCtrl.forward();
  }

  Future<void> _completeOnboarding() async {
    final box = Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName);
    final current = (box.get(AppConstants.hiveUserSettingsKey)?.toDomain()) ?? const UserSettings();
    await box.put(AppConstants.hiveUserSettingsKey, userSettingsHiveFromDomain(current.copyWith(hasSeenOnboarding: true)));
    notifyAppRouterRefresh();
    if (!mounted) return;
    context.go(AppRoutes.home);
  }

  void _nextPage() {
    if (_page < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _completeOnboarding();
    }
  }

  void _onPageChanged(int i) {
    setState(() => _page = i);
    _cardCtrl.forward(from: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _cardCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorsNew.surface,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Ambient background gradient ─────────────────────────────────
          // from-surface via-surface-container-low to-tertiary/10
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColorsNew.surface, AppColorsNew.surfaceContainerLow, AppColorsNew.tertiary.withValues(alpha: 0.10)],
              ),
            ),
          ),

          // ── Main content ────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // Illustration area (flex-1)
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        return _IllustrationArea(page: _pages[index]);
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Bottom card
                  FadeTransition(
                    opacity: _cardOpacity,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _BottomCard(page: _pages[_page], pageIndex: _page, total: _pages.length, onNext: _nextPage, onSkip: _completeOnboarding),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Fixed header: branding + streak ────────────────────────────
          const _TopHeader(),

          // ── Invisible separator line below header ───────────────────────
          Positioned(
            top: kToolbarHeight + MediaQuery.of(context).padding.top,
            left: 0,
            right: 0,
            child: Container(height: 1, color: AppColorsNew.surfaceContainerLow.withValues(alpha: 0.50)),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Top header
// =============================================================================

class _TopHeader extends StatelessWidget {
  const _TopHeader();

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: EdgeInsets.fromLTRB(32, top + 20, 32, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand wordmark
            Text(
              'SpeakUp',
              style: GoogleFonts.newsreader(fontSize: 24, fontStyle: FontStyle.italic, color: AppColorsNew.primary, fontWeight: FontWeight.w400),
            ),

            // Streak badge
            // Row(
            //   children: [
            //     Icon(Icons.local_fire_department, color: AppColorsNew.primary, size: 22),
            //     const SizedBox(width: 4),
            //     Text(
            //       '0',
            //       style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w700, color: AppColorsNew.primary, letterSpacing: -0.5),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Illustration area — top scrollable section
// =============================================================================

class _IllustrationArea extends StatelessWidget {
  const _IllustrationArea({required this.page});

  final _OnboardingData page;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(18), child: page.illustrationBuilder(context)),
    );
  }
}

// =============================================================================
// Bottom card
// =============================================================================

class _BottomCard extends StatelessWidget {
  const _BottomCard({required this.page, required this.pageIndex, required this.total, required this.onNext, required this.onSkip});

  final _OnboardingData page;
  final int pageIndex;
  final int total;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final isLast = pageIndex == total - 1;

    return Container(
      decoration: BoxDecoration(
        color: AppColorsNew.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), // rgba(27,28,26,0.08) ≈ 8% of shadow
            blurRadius: 48,
            spreadRadius: -12,
            offset: Offset(0, 24),
          ),
        ],
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Typography group
          _TypographyGroup(page: page),

          const SizedBox(height: 20),

          // Interaction group
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress dots
              _ProgressDots(current: pageIndex, total: total),

              const SizedBox(height: 16),

              // Footer actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip (hidden on last page)
                  if (!isLast)
                    GestureDetector(
                      onTap: onSkip,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppColorsNew.onSurfaceVariant),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Next / Get Started button
                  _NextButton(label: isLast ? 'Get Started' : 'Next', onTap: onNext),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Typography group inside card
// =============================================================================

class _TypographyGroup extends StatelessWidget {
  const _TypographyGroup({required this.page});

  final _OnboardingData page;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Headline — Newsreader bold, 36px, primary, tight tracking
        Text(
          page.title,
          style: GoogleFonts.newsreader(fontSize: 28, fontWeight: FontWeight.w700, color: AppColorsNew.primary, letterSpacing: -0.5, height: 1.15),
        ),

        const SizedBox(height: 10),

        // Body — Inter regular, 18px, onSurfaceVariant, relaxed leading
        Text(
          page.body,
          style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w400, color: AppColorsNew.onSurfaceVariant, height: 1.6),
        ),
      ],
    );
  }
}

// =============================================================================
// Progress dots — active dot is wider (pill), inactive are small circles
// =============================================================================

class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 8),
          height: 6,
          width: isActive ? 32 : 6,
          decoration: BoxDecoration(color: isActive ? AppColorsNew.primary : AppColorsNew.outlineVariant, borderRadius: BorderRadius.circular(999)),
        );
      }),
    );
  }
}

// =============================================================================
// Next / Get Started button — primary with gradient + arrow icon
// =============================================================================

class _NextButton extends StatelessWidget {
  const _NextButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColorsNew.primaryButtonGradient,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: AppColorsNew.primary.withValues(alpha: 0.25), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: AppColorsNew.onPrimary),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_rounded, color: AppColorsNew.onPrimary, size: 20),
          ],
        ),
      ),
    );
  }
}
