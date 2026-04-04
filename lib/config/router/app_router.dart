import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/core/widgets/app_shell.dart';

import 'package:speakup/features/card_draw/domain/entities/difficulty.dart';
import 'package:speakup/features/card_draw/domain/entities/topic_card.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/card_draw_event.dart';
import 'package:speakup/features/card_draw/presentation/bloc/category_bloc.dart';
import 'package:speakup/features/card_draw/presentation/bloc/category_event.dart';
import 'package:speakup/features/card_draw/presentation/models/card_detail_route_args.dart';
import 'package:speakup/features/card_draw/presentation/screens/card_detail_screen.dart';
import 'package:speakup/features/card_draw/presentation/screens/card_draw_screen.dart';
import 'package:speakup/features/card_draw/presentation/screens/category_select_screen.dart';
import 'package:speakup/features/custom_categories/domain/entities/custom_category.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_card_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_bloc.dart';
import 'package:speakup/features/custom_categories/presentation/bloc/custom_category_event.dart';
import 'package:speakup/features/custom_categories/presentation/models/create_card_route_args.dart';
import 'package:speakup/features/custom_categories/presentation/screens/category_detail_screen.dart';
import 'package:speakup/features/custom_categories/presentation/screens/create_card_screen.dart';
import 'package:speakup/features/custom_categories/presentation/screens/my_categories_screen.dart';
import 'package:speakup/features/favorites/presentation/screens/favorites_screen.dart';
import 'package:speakup/features/history/presentation/screens/history_screen.dart';
import 'package:speakup/features/home/presentation/screens/home_screen.dart';
import 'package:speakup/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:speakup/features/practice/presentation/bloc/session_end_bloc.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/practice/presentation/models/practice_route_args.dart';
import 'package:speakup/features/practice/presentation/screens/active_practice_screen.dart';
import 'package:speakup/features/practice/presentation/screens/session_end_screen.dart';
import 'package:speakup/features/practice/presentation/screens/timer_setup_screen.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/presentation/screens/settings_screen.dart';
import 'package:speakup/features/splash/presentation/screens/splash_screen.dart';
import 'package:speakup/features/challenges/presentation/screens/challenges_screen.dart';
import 'package:speakup/features/challenges/presentation/screens/challenge_detail_screen.dart';

import 'app_routes.dart';
import 'router_refresh.dart';

export 'app_routes.dart';
export 'router_refresh.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

CustomTransitionPage<void> _fadeTabPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}

CustomTransitionPage<void> _slideForwardPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    transitionsBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.06, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}

bool _hasSeenOnboardingSync() {
  try {
    final Box<UserSettingsHive> box = Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName);
    final UserSettingsHive? hive = box.get(AppConstants.hiveUserSettingsKey);
    return hive?.hasSeenOnboarding ?? false;
  } catch (_) {
    return false;
  }
}

String? _redirect(BuildContext context, GoRouterState state) {
  final String path = state.uri.path;
  final bool onboarded = _hasSeenOnboardingSync();

  if (!onboarded) {
    if (path == AppRoutes.splash || path == '/') {
      return null;
    }
    if (path == AppRoutes.onboarding) {
      return null;
    }
    return AppRoutes.onboarding;
  }

  if (onboarded && path == AppRoutes.onboarding) {
    return AppRoutes.home;
  }

  return null;
}

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.splash,
  refreshListenable: appRouterRefreshNotifier,
  redirect: _redirect,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.splash,
      name: 'splash',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return NoTransitionPage<void>(key: state.pageKey, child: const SplashScreen());
      },
    ),
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _slideForwardPage(state, const OnboardingScreen());
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (BuildContext context, GoRouterState state, StatefulNavigationShell navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: <StatefulShellBranch>[
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.home,
              name: 'home',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return _fadeTabPage(state, const HomeScreen());
              },
              routes: <RouteBase>[
                GoRoute(
                  path: 'category-select',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final Map<String, String> q = state.uri.queryParameters;
                    return _slideForwardPage(
                      state,
                      BlocProvider<CategoryBloc>(
                        create: (BuildContext context) => CategoryBloc(
                          cardRepository: context.read<CardRepository>(),
                          categoryRepository: context.read<CategoryRepository>(),
                          initialCategoryKey: q['category'],
                        )..add(const CategoryLoadRequested()),
                        child: CategorySelectScreen(quickDraw: q['quickDraw'] == 'true'),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'card-draw',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final Map<String, String> q = state.uri.queryParameters;
                    return _slideForwardPage(
                      state,
                      BlocProvider<CardDrawBloc>(
                        create: (BuildContext context) => CardDrawBloc(cardRepository: context.read<CardRepository>())
                          ..add(
                            CardDrawRequested(
                              category: q['category'],
                              difficulty: q['difficulty'] != null ? difficultyFromRaw(q['difficulty']!) : null,
                            ),
                          ),
                        child: const CardDrawScreen(),
                      ),
                    );
                  },
                ),
                GoRoute(
                  path: 'card-detail',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final TopicCard? card = CardDetailRouteArgs.cardFromExtra(state.extra);
                    final CardDrawBloc? drawBloc = CardDetailRouteArgs.drawBlocFromExtra(state.extra);
                    if (card == null) {
                      return _slideForwardPage(state, const Scaffold(body: Center(child: Text('No card to display'))));
                    }
                    return _slideForwardPage(state, CardDetailScreen(card: card, drawBloc: drawBloc));
                  },
                ),
                GoRoute(
                  path: 'timer-setup',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final TopicCard? card = state.extra as TopicCard?;
                    return _slideForwardPage(state, TimerSetupScreen(card: card));
                  },
                ),
                GoRoute(
                  path: 'active-practice',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final ActivePracticeArgs? args = state.extra as ActivePracticeArgs?;
                    if (args == null) {
                      return _slideForwardPage(state, const Scaffold(body: Center(child: Text('Missing practice session'))));
                    }
                    return _slideForwardPage(state, ActivePracticeScreen(args: args));
                  },
                ),
                GoRoute(
                  path: 'session-end',
                  parentNavigatorKey: rootNavigatorKey,
                  pageBuilder: (BuildContext context, GoRouterState state) {
                    final SessionEndRouteArgs? args = state.extra as SessionEndRouteArgs?;
                    if (args == null) {
                      return _slideForwardPage(state, const Scaffold(body: Center(child: Text('Missing session summary'))));
                    }
                    return _slideForwardPage(
                      state,
                      BlocProvider<SessionEndBloc>(
                        create: (BuildContext context) => SessionEndBloc(
                          sessionRepository: context.read<SessionRepository>(),
                          settingsRepository: context.read<SettingsRepository>(),
                          args: args,
                        ),
                        child: const SessionEndScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.favorites,
              name: 'favorites',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return _fadeTabPage(state, const FavoritesScreen());
              },
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.history,
              name: 'history',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return _fadeTabPage(state, const HistoryScreen());
              },
            ),
          ],
        ),
        // ── 4th tab: Challenges ────────────────────────────────────────────
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.challenges,
              name: 'challenges',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return _fadeTabPage(state, const ChallengesScreen());
              },
            ),
          ],
        ),
        // ── 5th tab: Settings ──────────────────────────────────────────────
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              pageBuilder: (BuildContext context, GoRouterState state) {
                return _fadeTabPage(state, const SettingsScreen());
              },
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/custom-categories',
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        return _slideForwardPage(
          state,
          BlocProvider<CustomCategoryBloc>(
            create: (BuildContext context) =>
                CustomCategoryBloc(categoryRepository: context.read<CategoryRepository>(), cardRepository: context.read<CardRepository>())
                  ..add(const CategoriesLoadRequested()),
            child: const MyCategoriesScreen(),
          ),
        );
      },
      routes: <RouteBase>[
        GoRoute(
          path: 'detail',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Object? extra = state.extra;
            if (extra is! CustomCategory) {
              return _slideForwardPage(state, const Scaffold(body: Center(child: Text('Category not found'))));
            }
            return _slideForwardPage(
              state,
              BlocProvider<CustomCardBloc>(
                create: (BuildContext context) => CustomCardBloc(cardRepository: context.read<CardRepository>()),
                child: CategoryDetailScreen(category: extra),
              ),
            );
          },
        ),
        GoRoute(
          path: 'create-card',
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (BuildContext context, GoRouterState state) {
            final Object? extra = state.extra;
            if (extra is! CreateCardRouteArgs) {
              return _slideForwardPage(state, const Scaffold(body: Center(child: Text('Missing card arguments'))));
            }
            return _slideForwardPage(state, CreateCardScreen(args: extra));
          },
        ),
      ],
    ),
    // ── Challenge detail (push over bottom nav) ──────────────────────────
    GoRoute(
      path: AppRoutes.challengeDetail,
      parentNavigatorKey: rootNavigatorKey,
      pageBuilder: (BuildContext context, GoRouterState state) {
        final Object? extra = state.extra;
        if (extra is! ChallengeDetailArgs) {
          return _slideForwardPage(state, const Scaffold(body: Center(child: Text('Challenge not found'))));
        }
        return _slideForwardPage(state, ChallengeDetailScreen(args: extra));
      },
    ),
  ],
);
