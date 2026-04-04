// ignore_for_file: dead_code — ObjectBoxStore is conditional; analyzer uses web stub where .store never returns.

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/config/router/app_router.dart';
import 'package:speakup/config/theme/app_theme.dart';
import 'package:speakup/config/theme/bloc/theme_bloc.dart';
import 'package:speakup/config/theme/bloc/theme_state.dart';
import 'package:speakup/config/theme/theme_brightness_observer.dart';
import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/core/constants/app_strings.dart';
import 'package:speakup/core/data/stub_repositories.dart';
import 'package:speakup/core/utils/objectbox_store.dart';
import 'package:speakup/features/card_draw/data/repositories/card_repository_impl.dart';
import 'package:speakup/features/card_draw/domain/repositories/card_repository.dart';
import 'package:speakup/features/custom_categories/data/repositories/category_repository_impl.dart';
import 'package:speakup/features/custom_categories/domain/repositories/category_repository.dart';
import 'package:speakup/features/favorites/presentation/bloc/favorites_bloc.dart';
import 'package:speakup/features/history/presentation/bloc/history_bloc.dart';
import 'package:speakup/features/home/presentation/bloc/home_bloc.dart';
import 'package:speakup/features/navigation/presentation/bloc/navigation_bloc.dart';
import 'package:speakup/features/practice/data/repositories/session_repository_impl.dart';
import 'package:speakup/features/practice/domain/repositories/session_repository.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:speakup/features/settings/presentation/bloc/settings_state.dart';
import 'package:speakup/features/challenges/data/repositories/challenge_repository_impl.dart';
import 'package:speakup/features/challenges/domain/repositories/challenge_repository.dart';
import 'package:speakup/features/challenges/presentation/bloc/challenges_bloc.dart';

/// Root widget: routing + global BLoC providers (add feature blocs here).
class SpeakUpApp extends StatelessWidget {
  const SpeakUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return _RepositoryProviders(
      child: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<ThemeBloc>(create: (BuildContext context) => ThemeBloc(settingsRepository: context.read<SettingsRepository>())),
          BlocProvider<HistoryBloc>(
            create: (BuildContext context) =>
                HistoryBloc(sessionRepository: context.read<SessionRepository>(), settingsRepository: context.read<SettingsRepository>()),
          ),
          BlocProvider<FavoritesBloc>(create: (BuildContext context) => FavoritesBloc(cardRepository: context.read<CardRepository>())),
          BlocProvider<SettingsBloc>(
            create: (BuildContext context) => SettingsBloc(
              settingsRepository: context.read<SettingsRepository>(),
              sessionRepository: context.read<SessionRepository>(),
              historyBloc: context.read<HistoryBloc>(),
            ),
          ),
          BlocProvider<HomeBloc>(
            create: (BuildContext context) => HomeBloc(
              cardRepository: context.read<CardRepository>(),
              sessionRepository: context.read<SessionRepository>(),
              settingsRepository: context.read<SettingsRepository>(),
            ),
          ),
          BlocProvider<NavigationBloc>(create: (_) => NavigationBloc()),
          BlocProvider<ChallengesBloc>(
            create: (BuildContext context) =>
                ChallengesBloc(challengeRepository: context.read<ChallengeRepository>(), cardRepository: context.read<CardRepository>()),
          ),
        ],
        child: BlocBuilder<ThemeBloc, ThemeBlocState>(
          buildWhen: (ThemeBlocState p, ThemeBlocState c) => p.mode != c.mode || p.brightnessEpoch != c.brightnessEpoch,
          builder: (BuildContext context, ThemeBlocState themeState) {
            return BlocBuilder<SettingsBloc, SettingsState>(
              buildWhen: (SettingsState p, SettingsState c) => p.settings.textSizeScale != c.settings.textSizeScale,
              builder: (BuildContext context, SettingsState settingsState) {
                return ThemeBrightnessObserver(
                  child: MaterialApp.router(
                    title: AppStrings.appTitle,
                    theme: AppTheme.light,
                    darkTheme: AppTheme.dark,
                    themeMode: themeState.mode,
                    routerConfig: appRouter,
                    debugShowCheckedModeBanner: false,
                    builder: (BuildContext context, Widget? child) {
                      final MediaQueryData mq = MediaQuery.of(context);
                      return MediaQuery(
                        data: mq.copyWith(textScaler: TextScaler.linear(settingsState.settings.textSizeScale)),
                        child: child ?? const SizedBox.shrink(),
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _RepositoryProviders extends StatelessWidget {
  const _RepositoryProviders({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _stubRepositories(child);
    }
    try {
      final store = ObjectBoxStore.store;
      final SessionRepository sessionRepo = SessionRepositoryImpl(store);
      return MultiRepositoryProvider(
        providers: <RepositoryProvider<dynamic>>[
          RepositoryProvider<SessionRepository>.value(value: sessionRepo),
          RepositoryProvider<SettingsRepository>(
            create: (_) => SettingsRepositoryImpl(Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName), sessionRepo),
          ),
          RepositoryProvider<CardRepository>(create: (_) => CardRepositoryImpl(store)),
          RepositoryProvider<CategoryRepository>(create: (_) => CategoryRepositoryImpl(store)),
          RepositoryProvider<ChallengeRepository>(create: (_) => ChallengeRepositoryImpl(Hive.box<String>(AppConstants.hiveChallengesBoxName))),
        ],
        child: child,
      );
    } catch (_) {
      return _stubRepositories(child);
    }
  }

  static Widget _stubRepositories(Widget child) {
    const SessionRepository sessionRepo = StubSessionRepository();
    return MultiRepositoryProvider(
      providers: <RepositoryProvider<dynamic>>[
        RepositoryProvider<SessionRepository>.value(value: sessionRepo),
        RepositoryProvider<SettingsRepository>(
          create: (_) => SettingsRepositoryImpl(Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName), sessionRepo),
        ),
        RepositoryProvider<CardRepository>(create: (_) => const StubCardRepository()),
        RepositoryProvider<CategoryRepository>(create: (_) => const StubCategoryRepository()),
        RepositoryProvider<ChallengeRepository>(create: (_) => ChallengeRepositoryImpl(Hive.box<String>(AppConstants.hiveChallengesBoxName))),
      ],
      child: child,
    );
  }
}
