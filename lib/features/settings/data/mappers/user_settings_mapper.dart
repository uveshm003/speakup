import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';

extension UserSettingsHiveMapper on UserSettingsHive {
  UserSettings toDomain() {
    return UserSettings(
      defaultTimerSeconds: defaultTimerSeconds,
      textSizeScale: textSizeScale,
      hasSeenOnboarding: hasSeenOnboarding,
      themeModeRaw: themeModeRaw,
      lastSessionDate: lastSessionDate,
      currentStreak: currentStreak,
      cardsSeeded: cardsSeeded,
    );
  }
}

UserSettingsHive userSettingsHiveFromDomain(UserSettings s) {
  return UserSettingsHive(
    defaultTimerSeconds: s.defaultTimerSeconds,
    textSizeScale: s.textSizeScale,
    hasSeenOnboarding: s.hasSeenOnboarding,
    themeModeRaw: s.themeModeRaw,
    lastSessionDate: s.lastSessionDate,
    currentStreak: s.currentStreak,
    cardsSeeded: s.cardsSeeded,
  );
}
