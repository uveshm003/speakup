import 'package:hive/hive.dart';

part 'user_settings_hive.g.dart';

@HiveType(typeId: 0)
class UserSettingsHive extends HiveObject {
  UserSettingsHive({
    this.defaultTimerSeconds = 120,
    this.textSizeScale = 1.0,
    this.hasSeenOnboarding = false,
    this.themeModeRaw = 'system',
    this.lastSessionDate,
    this.currentStreak = 0,
    this.cardsSeeded = false,
    this.cardsSeedVersion = 0,
  });

  @HiveField(0)
  int defaultTimerSeconds;

  @HiveField(1)
  double textSizeScale;

  @HiveField(2)
  bool hasSeenOnboarding;

  @HiveField(3)
  String themeModeRaw;

  @HiveField(4)
  DateTime? lastSessionDate;

  @HiveField(5)
  int currentStreak;

  @HiveField(6)
  bool cardsSeeded;

  @HiveField(7)
  int cardsSeedVersion;
}
