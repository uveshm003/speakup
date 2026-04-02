import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart';

import 'package:speakup/core/constants/app_assets.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/data/models/topic_card_entity.dart';
import 'package:speakup/features/settings/domain/entities/user_settings.dart';
import 'package:speakup/features/settings/domain/repositories/settings_repository.dart';
import 'package:speakup/objectbox.g.dart';

/// Loads built-in deck from [AppAssets.cardsJson] and seeds ObjectBox.
///
/// Uses [UserSettings.cardsSeedVersion] to detect when new cards have been
/// bundled and need to be written to the local store. Any card whose [cardId]
/// already exists is skipped so no duplicates are created.
///
/// Bump [_targetSeedVersion] every time [cards.json] is updated.
class CardAssetDataSource {
  CardAssetDataSource(this._store, this._settingsRepository);

  final Store _store;
  final SettingsRepository _settingsRepository;

  /// Increment this constant whenever cards.json gains new entries.
  static const int _targetSeedVersion = 2;

  Box<TopicCardEntity> get _box => _store.box<TopicCardEntity>();

  Future<Either<Failure, void>> seedBuiltInDeckIfNeeded() async {
    final Either<Failure, UserSettings> settingsResult = await _settingsRepository.getSettings();

    return settingsResult.fold<Future<Either<Failure, void>>>((Failure l) async => Left<Failure, void>(l), (UserSettings settings) async {
      // Already up-to-date — nothing to do.
      if (settings.cardsSeedVersion >= _targetSeedVersion) {
        return const Right<Failure, void>(null);
      }

      try {
        final String raw = await rootBundle.loadString(AppAssets.cardsJson);
        final List<dynamic> list = jsonDecode(raw) as List<dynamic>;

        // Build a set of card IDs already in the local store so we can
        // skip duplicates cheaply without loading every record.
        final Query<TopicCardEntity> allQuery = _box.query().build();
        final List<TopicCardEntity> existing = allQuery.find();
        allQuery.close();
        final Set<String> existingIds = existing.map((TopicCardEntity e) => e.cardId).toSet();

        // Upsert only the cards that are missing locally.
        for (final dynamic item in list) {
          final Map<String, dynamic> m = item as Map<String, dynamic>;
          final String id = m['id'] as String;
          if (!existingIds.contains(id)) {
            _box.put(_entityFromJson(m));
          }
        }

        await _settingsRepository.saveSettings(settings.copyWith(cardsSeeded: true, cardsSeedVersion: _targetSeedVersion));
        return const Right<Failure, void>(null);
      } catch (e, _) {
        return Left<Failure, void>(FormatFailure(e.toString()));
      }
    });
  }

  TopicCardEntity _entityFromJson(Map<String, dynamic> m) {
    final List<dynamic> guide = m['guide'] as List<dynamic>;
    final List<dynamic> vocab = m['vocabBoost'] as List<dynamic>;
    return TopicCardEntity(
      cardId: m['id'] as String,
      title: m['title'] as String,
      category: m['category'] as String,
      difficultyRaw: m['difficulty'] as String,
      guideJson: jsonEncode(guide),
      vocabJson: jsonEncode(vocab),
      isCustom: m['isCustom'] as bool? ?? false,
      isFavorite: false,
      createdAt: DateTime.now().toUtc(),
    );
  }
}
