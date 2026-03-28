// ignore_for_file: dead_code — ObjectBox seeding is skipped on web; the analyzer flags the io-only branch.

import 'package:hive_flutter/hive_flutter.dart';

import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/features/card_draw/data/datasources/card_asset_data_source.dart';
import 'package:speakup/features/practice/data/repositories/session_repository_impl.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:speakup/core/utils/objectbox_store.dart';

/// Registers Hive adapters, opens boxes, optionally initializes ObjectBox + seeds cards.
Future<void> bootstrapDataLayer({required bool enableObjectBox}) async {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(UserSettingsHiveAdapter());
  }
  await Hive.openBox<UserSettingsHive>(AppConstants.hiveSettingsBoxName);

  if (enableObjectBox) {
    await ObjectBoxStore.init();
    final sessionRepo = SessionRepositoryImpl(ObjectBoxStore.store);
    final settingsRepo = SettingsRepositoryImpl(
      Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName),
      sessionRepo,
    );
    final cardSource = CardAssetDataSource(ObjectBoxStore.store, settingsRepo);
    await cardSource.seedBuiltInDeckIfNeeded();
  }
}
