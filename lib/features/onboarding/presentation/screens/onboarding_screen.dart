import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/router/app_routes.dart';
import 'package:speakup/config/router/router_refresh.dart';
import 'package:speakup/config/theme/app_radius.dart';
import 'package:speakup/config/theme/app_spacing.dart';
import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/features/settings/data/mappers/user_settings_mapper.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  Future<void> _completeOnboarding() async {
    final Box<UserSettingsHive> box = Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName);
    final UserSettings current = (box.get(AppConstants.hiveUserSettingsKey)?.toDomain()) ?? const UserSettings();
    await box.put(AppConstants.hiveUserSettingsKey, userSettingsHiveFromDomain(current.copyWith(hasSeenOnboarding: true)));
    notifyAppRouterRefresh();
    if (!mounted) {
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color primary = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        actions: <Widget>[if (_page < 2) TextButton(onPressed: _completeOnboarding, child: const Text('Skip'))],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (int i) => setState(() => _page = i),
              children: <Widget>[
                _OnboardingPage(
                  icon: Icons.mic_rounded,
                  title: 'Pick a card',
                  body: 'Browse 70+ topics across 7 categories — from opinions to storytelling.',
                  color: primary,
                ),
                _OnboardingPage(
                  icon: Icons.menu_book_rounded,
                  title: 'Learn before you speak',
                  body: 'Every card has a Mini Guide and Vocabulary Boost to help you prepare in under 60 seconds.',
                  color: primary,
                ),
                _OnboardingPage(
                  icon: Icons.timer_outlined,
                  title: 'Practice daily, build streaks',
                  body: 'Track your sessions, earn streaks, and grow one conversation at a time.',
                  color: primary,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(3, (int i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _page == i ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _page == i ? primary : theme.dividerColor,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: AppSpacing.lg),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      if (_page < 2) {
                        _pageController.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
                      } else {
                        _completeOnboarding();
                      }
                    },
                    child: Text(_page < 2 ? 'Next' : 'Get Started'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.icon, required this.title, required this.body, required this.color});

  final IconData icon;
  final String title;
  final String body;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: <Color>[color.withValues(alpha: 0.35), color.withValues(alpha: 0.08)]),
            ),
            child: Icon(icon, size: 72, color: color),
          ),
          const SizedBox(height: AppSpacing.xxl),
          Text(title, style: theme.textTheme.headlineLarge, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant, height: 1.45),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
