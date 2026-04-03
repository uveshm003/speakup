import 'package:flutter/material.dart';

/// A hard-coded challenge definition (catalogue item shown in the browse grid).
class ChallengeDef {
  const ChallengeDef({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.durationDays,
    required this.tasksPerDay,
    required this.accentColor,
    this.category,
  });

  /// Unique identifier — must be stable across app versions.
  final String id;

  /// Display title.
  final String title;

  /// One-line description.
  final String subtitle;

  /// Emoji used as the hero icon.
  final String emoji;

  /// Total days in the challenge.
  final int durationDays;

  /// Minimum practice sessions required each day.
  final int tasksPerDay;

  /// Accent gradient / badge color.
  final Color accentColor;

  /// The built-in category to draw cards from.
  /// `null` means random (any category).
  final String? category;
}
