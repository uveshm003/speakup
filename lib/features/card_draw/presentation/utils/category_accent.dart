import 'package:flutter/material.dart';

import 'package:speakup/features/home/domain/built_in_categories.dart';

/// Emoji for a built-in category name; custom categories get a neutral glyph.
String emojiForCategory(String categoryName) {
  for (final BuiltInCategoryDef d in kBuiltInBrowseCategories) {
    if (d.name == categoryName) {
      return d.emoji;
    }
  }
  return '🎯';
}

/// Accent color for a topic [category] name (built-in or custom).
Color accentColorForCategory(String categoryName) {
  for (final BuiltInCategoryDef d in kBuiltInBrowseCategories) {
    if (d.name == categoryName) {
      return d.accentColor;
    }
  }
  final int h = categoryName.hashCode.abs() % 360;
  return HSLColor.fromAHSL(1, h.toDouble(), 0.45, 0.48).toColor();
}
