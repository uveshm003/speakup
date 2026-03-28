import 'package:equatable/equatable.dart';

enum HomeLoadStatus { initial, loading, success, failure }

class HomeRecentSession extends Equatable {
  const HomeRecentSession({
    required this.sessionId,
    required this.cardId,
    required this.cardTitle,
    required this.completedAt,
    required this.durationSeconds,
  });

  final String sessionId;
  final String cardId;
  final String cardTitle;
  final DateTime completedAt;
  final int durationSeconds;

  @override
  List<Object?> get props => <Object?>[
        sessionId,
        cardId,
        cardTitle,
        completedAt,
        durationSeconds,
      ];
}

class HomeState extends Equatable {
  const HomeState({
    this.status = HomeLoadStatus.initial,
    this.streak = 0,
    this.lastSessionDate,
    this.recentCategories = const <String>[],
    this.todaySessionCount = 0,
    this.categoryCardCounts = const <String, int>{},
    this.customCardsCount = 0,
    this.recentSessions = const <HomeRecentSession>[],
    this.errorMessage,
    this.pendingQuickDrawNavigation = false,
  });

  final HomeLoadStatus status;
  final int streak;
  final DateTime? lastSessionDate;
  final List<String> recentCategories;
  final int todaySessionCount;
  final Map<String, int> categoryCardCounts;
  final int customCardsCount;
  final List<HomeRecentSession> recentSessions;
  final String? errorMessage;
  final bool pendingQuickDrawNavigation;

  HomeState copyWith({
    HomeLoadStatus? status,
    int? streak,
    DateTime? lastSessionDate,
    List<String>? recentCategories,
    int? todaySessionCount,
    Map<String, int>? categoryCardCounts,
    int? customCardsCount,
    List<HomeRecentSession>? recentSessions,
    String? errorMessage,
    bool clearErrorMessage = false,
    bool? pendingQuickDrawNavigation,
  }) {
    return HomeState(
      status: status ?? this.status,
      streak: streak ?? this.streak,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      recentCategories: recentCategories ?? this.recentCategories,
      todaySessionCount: todaySessionCount ?? this.todaySessionCount,
      categoryCardCounts: categoryCardCounts ?? this.categoryCardCounts,
      customCardsCount: customCardsCount ?? this.customCardsCount,
      recentSessions: recentSessions ?? this.recentSessions,
      errorMessage:
          clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      pendingQuickDrawNavigation:
          pendingQuickDrawNavigation ?? this.pendingQuickDrawNavigation,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        status,
        streak,
        lastSessionDate,
        recentCategories,
        todaySessionCount,
        categoryCardCounts,
        customCardsCount,
        recentSessions,
        errorMessage,
        pendingQuickDrawNavigation,
      ];
}
