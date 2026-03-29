// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_settings_hive.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserSettingsHiveAdapter extends TypeAdapter<UserSettingsHive> {
  @override
  final int typeId = 0;

  @override
  UserSettingsHive read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read()};
    return UserSettingsHive(
      defaultTimerSeconds: (fields[0] as num).toInt(),
      textSizeScale: (fields[1] as num).toDouble(),
      hasSeenOnboarding: fields[2] as bool,
      themeModeRaw: fields[3] as String,
      lastSessionDate: fields[4] as DateTime?,
      currentStreak: (fields[5] as num).toInt(),
      cardsSeeded: fields[6] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, UserSettingsHive obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.defaultTimerSeconds)
      ..writeByte(1)
      ..write(obj.textSizeScale)
      ..writeByte(2)
      ..write(obj.hasSeenOnboarding)
      ..writeByte(3)
      ..write(obj.themeModeRaw)
      ..writeByte(4)
      ..write(obj.lastSessionDate)
      ..writeByte(5)
      ..write(obj.currentStreak)
      ..writeByte(6)
      ..write(obj.cardsSeeded);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserSettingsHiveAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
