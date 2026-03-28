import 'package:equatable/equatable.dart';

/// Domain settings (persisted via Hive in the data layer).
class UserSettings extends Equatable {
  const UserSettings({
    this.defaultTimerSeconds = 120,
    this.textSizeScale = 1.0,
    this.hasSeenOnboarding = false,
    this.themeModeRaw = 'system',
    this.lastSessionDate,
    this.currentStreak = 0,
    this.cardsSeeded = false,
  });

  final int defaultTimerSeconds;
  final double textSizeScale;
  final bool hasSeenOnboarding;

  /// `system` | `light` | `dark`
  final String themeModeRaw;
  final DateTime? lastSessionDate;
  final int currentStreak;
  final bool cardsSeeded;

  UserSettings copyWith({
    int? defaultTimerSeconds,
    double? textSizeScale,
    bool? hasSeenOnboarding,
    String? themeModeRaw,
    DateTime? lastSessionDate,
    int? currentStreak,
    bool? cardsSeeded,
  }) {
    return UserSettings(
      defaultTimerSeconds: defaultTimerSeconds ?? this.defaultTimerSeconds,
      textSizeScale: textSizeScale ?? this.textSizeScale,
      hasSeenOnboarding: hasSeenOnboarding ?? this.hasSeenOnboarding,
      themeModeRaw: themeModeRaw ?? this.themeModeRaw,
      lastSessionDate: lastSessionDate ?? this.lastSessionDate,
      currentStreak: currentStreak ?? this.currentStreak,
      cardsSeeded: cardsSeeded ?? this.cardsSeeded,
    );
  }

  @override
  List<Object?> get props => <Object?>[
        defaultTimerSeconds,
        textSizeScale,
        hasSeenOnboarding,
        themeModeRaw,
        lastSessionDate,
        currentStreak,
        cardsSeeded,
      ];
}
