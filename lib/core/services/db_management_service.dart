import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive_flutter/hive_flutter.dart' as hive;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'package:speakup/core/constants/app_constants.dart';
import 'package:speakup/core/errors/failures.dart';
import 'package:speakup/features/card_draw/data/models/topic_card_entity.dart';
import 'package:speakup/features/practice/data/models/practice_session_entity.dart';
import 'package:speakup/features/settings/data/models/user_settings_hive.dart';
import 'package:speakup/objectbox.g.dart';

/// High-level service for exporting, restoring, and deleting all app data.
///
/// Works with the ObjectBox [Store] (cards, categories, sessions) plus the
/// Hive settings box.
class DbManagementService {
  const DbManagementService({required this.store});

  final Store store;

  // ── Private helpers ───────────────────────────────────────────────────────

  Box<TopicCardEntity> get _cardBox => store.box<TopicCardEntity>();
  Box<CustomCategoryEntity> get _categoryBox => store.box<CustomCategoryEntity>();
  Box<PracticeSessionEntity> get _sessionBox => store.box<PracticeSessionEntity>();
  hive.Box<UserSettingsHive> get _settingsBox => hive.Hive.box<UserSettingsHive>(AppConstants.hiveSettingsBoxName);

  // ── Export ────────────────────────────────────────────────────────────────

  /// Serializes all data to JSON, writes a file, then triggers the share sheet.
  Future<Either<Failure, String>> exportAndShare() async {
    try {
      final Map<String, dynamic> payload = _buildExportPayload();
      final String json = const JsonEncoder.withIndent('  ').convert(payload);

      final Directory dir = await getApplicationDocumentsDirectory();
      final String timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').substring(0, 19);
      final File file = File('${dir.path}/speakup_backup_$timestamp.json');
      await file.writeAsString(json);

      if (!kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(
            files: [XFile(file.path, mimeType: 'application/json')],
            subject: 'SpeakUp Data Backup',
          ),
        );
      }
      return Right<Failure, String>(file.path);
    } catch (e, _) {
      return Left<Failure, String>(CacheFailure('Export failed: $e'));
    }
  }

  Map<String, dynamic> _buildExportPayload() {
    // Custom cards only — built-in cards are always re-seeded from assets
    final List<TopicCardEntity> customCards = _cardBox.getAll().where((TopicCardEntity c) => c.isCustom).toList();
    final List<CustomCategoryEntity> categories = _categoryBox.getAll();
    final List<PracticeSessionEntity> sessions = _sessionBox.getAll();
    final UserSettingsHive? settings = _settingsBox.get(AppConstants.hiveUserSettingsKey);

    return <String, dynamic>{
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'customCards': customCards.map(_cardToMap).toList(),
      'categories': categories.map(_categoryToMap).toList(),
      'sessions': sessions.map(_sessionToMap).toList(),
      'settings': settings != null
          ? <String, dynamic>{
              'defaultTimerSeconds': settings.defaultTimerSeconds,
              'hasSeenOnboarding': settings.hasSeenOnboarding,
              'themeModeRaw': settings.themeModeRaw,
              'textSizeScale': settings.textSizeScale,
            }
          : null,
    };
  }

  // ── Restore ───────────────────────────────────────────────────────────────

  /// Reads a JSON file at [filePath], validates its schema, then upserts all
  /// records into the local store without destroying existing built-in cards.
  Future<Either<Failure, void>> restoreFromFile(String filePath) async {
    try {
      final String raw = await File(filePath).readAsString();
      final dynamic decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const Left<Failure, void>(CacheFailure('Invalid backup file'));
      }
      final Map<String, dynamic> payload = decoded;
      final int version = (payload['version'] as int?) ?? 0;
      if (version < 1) {
        return const Left<Failure, void>(CacheFailure('Unsupported backup version'));
      }

      // 1. Restore categories first (cards reference them)
      final List<dynamic> cats = (payload['categories'] as List<dynamic>?) ?? [];
      for (final dynamic c in cats) {
        _upsertCategory(c as Map<String, dynamic>);
      }

      // 2. Restore custom cards
      final List<dynamic> cards = (payload['customCards'] as List<dynamic>?) ?? [];
      for (final dynamic c in cards) {
        _upsertCard(c as Map<String, dynamic>);
      }

      // 3. Restore sessions
      final List<dynamic> sessions = (payload['sessions'] as List<dynamic>?) ?? [];
      for (final dynamic s in sessions) {
        _upsertSession(s as Map<String, dynamic>);
      }

      // 4. Restore settings (optional — only safe fields)
      final dynamic settingsMap = payload['settings'];
      if (settingsMap is Map<String, dynamic>) {
        final UserSettingsHive existing = _settingsBox.get(AppConstants.hiveUserSettingsKey) ?? UserSettingsHive();
        existing.defaultTimerSeconds = (settingsMap['defaultTimerSeconds'] as int?) ?? existing.defaultTimerSeconds;
        await _settingsBox.put(AppConstants.hiveUserSettingsKey, existing);
      }

      return const Right<Failure, void>(null);
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure('Restore failed: $e'));
    }
  }

  void _upsertCategory(Map<String, dynamic> m) {
    final String id = m['categoryId'] as String? ?? '';
    if (id.isEmpty) return;
    final Query<CustomCategoryEntity> q = _categoryBox.query(CustomCategoryEntity_.categoryId.equals(id)).build();
    try {
      CustomCategoryEntity? existing = q.findFirst();
      if (existing == null) {
        existing = CustomCategoryEntity(
          categoryId: id,
          name: m['name'] as String? ?? '',
          iconEmoji: m['iconEmoji'] as String? ?? '📁',
          createdAt: _parseDate(m['createdAt']),
        );
      } else {
        existing.name = m['name'] as String? ?? existing.name;
        existing.iconEmoji = m['iconEmoji'] as String? ?? existing.iconEmoji;
      }
      _categoryBox.put(existing);
    } finally {
      q.close();
    }
  }

  void _upsertCard(Map<String, dynamic> m) {
    final String id = m['cardId'] as String? ?? '';
    if (id.isEmpty) return;
    final Query<TopicCardEntity> q = _cardBox.query(TopicCardEntity_.cardId.equals(id)).build();
    try {
      TopicCardEntity? existing = q.findFirst();
      if (existing == null) {
        existing = TopicCardEntity(
          cardId: id,
          title: m['title'] as String? ?? '',
          category: m['category'] as String? ?? '',
          difficultyRaw: m['difficultyRaw'] as String? ?? 'beginner',
          guideJson: m['guideJson'] as String? ?? '[]',
          vocabJson: m['vocabJson'] as String? ?? '[]',
          isCustom: true,
          isFavorite: m['isFavorite'] as bool? ?? false,
          createdAt: _parseDate(m['createdAt']),
        );
        // Relink to its category
        final String? catId = m['customCategoryId'] as String?;
        if (catId != null) {
          final Query<CustomCategoryEntity> cq = _categoryBox.query(CustomCategoryEntity_.categoryId.equals(catId)).build();
          try {
            final CustomCategoryEntity? cat = cq.findFirst();
            if (cat != null) existing.customCategory.target = cat;
          } finally {
            cq.close();
          }
        }
      } else {
        existing.guideJson = m['guideJson'] as String? ?? existing.guideJson;
        existing.vocabJson = m['vocabJson'] as String? ?? existing.vocabJson;
        existing.isFavorite = m['isFavorite'] as bool? ?? existing.isFavorite;
      }
      _cardBox.put(existing);
    } finally {
      q.close();
    }
  }

  void _upsertSession(Map<String, dynamic> m) {
    final String id = m['sessionId'] as String? ?? '';
    if (id.isEmpty) return;
    final Query<PracticeSessionEntity> q = _sessionBox.query(PracticeSessionEntity_.sessionId.equals(id)).build();
    try {
      if (q.findFirst() != null) return; // skip duplicates
      _sessionBox.put(
        PracticeSessionEntity(
          sessionId: id,
          cardId: m['cardId'] as String? ?? '',
          cardTitle: m['cardTitle'] as String? ?? '',
          category: m['category'] as String? ?? '',
          durationSeconds: m['durationSeconds'] as int? ?? 0,
          wasCompleted: m['wasCompleted'] as bool? ?? true,
          completedAt: _parseDate(m['completedAt']),
          recordingPath: m['recordingPath'] as String?,
        ),
      );
    } finally {
      q.close();
    }
  }

  // ── Delete All ────────────────────────────────────────────────────────────

  /// Wipes ALL ObjectBox data and resets Hive settings to defaults.
  /// The onboarding flag is preserved so the user doesn't see onboarding again.
  Future<Either<Failure, void>> deleteAll() async {
    try {
      _cardBox.removeAll();
      _categoryBox.removeAll();
      _sessionBox.removeAll();

      // Reset settings — keep onboarding flag
      final bool seenOnboarding = _settingsBox.get(AppConstants.hiveUserSettingsKey)?.hasSeenOnboarding ?? true;
      final UserSettingsHive fresh = UserSettingsHive(
        hasSeenOnboarding: seenOnboarding,
        cardsSeedVersion: 0, // force re-seed of built-in deck on next launch
        cardsSeeded: false,
      );
      await _settingsBox.put(AppConstants.hiveUserSettingsKey, fresh);

      return const Right<Failure, void>(null);
    } catch (e, _) {
      return Left<Failure, void>(CacheFailure('Delete failed: $e'));
    }
  }

  // ── Serialization helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _cardToMap(TopicCardEntity e) => <String, dynamic>{
    'cardId': e.cardId,
    'title': e.title,
    'category': e.category,
    'difficultyRaw': e.difficultyRaw,
    'guideJson': e.guideJson,
    'vocabJson': e.vocabJson,
    'isFavorite': e.isFavorite,
    'isCustom': e.isCustom,
    'createdAt': e.createdAt.toIso8601String(),
    'customCategoryId': e.customCategory.target?.categoryId,
  };

  Map<String, dynamic> _categoryToMap(CustomCategoryEntity e) => <String, dynamic>{
    'categoryId': e.categoryId,
    'name': e.name,
    'iconEmoji': e.iconEmoji,
    'createdAt': e.createdAt.toIso8601String(),
  };

  Map<String, dynamic> _sessionToMap(PracticeSessionEntity e) => <String, dynamic>{
    'sessionId': e.sessionId,
    'cardId': e.cardId,
    'cardTitle': e.cardTitle,
    'category': e.category,
    'durationSeconds': e.durationSeconds,
    'wasCompleted': e.wasCompleted,
    'completedAt': e.completedAt.toIso8601String(),
    'recordingPath': e.recordingPath,
  };

  DateTime _parseDate(dynamic val) {
    if (val is String) {
      return DateTime.tryParse(val)?.toUtc() ?? DateTime.now().toUtc();
    }
    return DateTime.now().toUtc();
  }
}
