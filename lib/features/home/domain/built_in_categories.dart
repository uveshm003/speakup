import 'package:flutter/material.dart';

/// Built-in deck categories (names must match [assets/data/cards.json]).
class BuiltInCategoryDef {
  const BuiltInCategoryDef({required this.name, required this.emoji, required this.accentColor});

  final String name;
  final String emoji;
  final Color accentColor;
}

/// Ordered list for browse grid and category selection.
const List<BuiltInCategoryDef> kBuiltInBrowseCategories = <BuiltInCategoryDef>[
  BuiltInCategoryDef(name: 'Opinion & Debate', emoji: '💬', accentColor: Color(0xFF6366F1)),
  BuiltInCategoryDef(name: 'Current Affairs', emoji: '📰', accentColor: Color(0xFF2563EB)),
  BuiltInCategoryDef(name: 'Personal Growth', emoji: '🌱', accentColor: Color(0xFF16A34A)),
  BuiltInCategoryDef(name: 'Technology', emoji: '💻', accentColor: Color(0xFF0891B2)),
  BuiltInCategoryDef(name: 'Culture & Society', emoji: '🌍', accentColor: Color(0xFFEA580C)),
  BuiltInCategoryDef(name: 'Business & Work', emoji: '💼', accentColor: Color(0xFF475569)),
  BuiltInCategoryDef(name: 'Storytelling & Personal', emoji: '📖', accentColor: Color(0xFFDB2777)),
];

/// Sentinel for the home grid "My Categories" tile (not a JSON category name).
const String kMyCategoriesGridId = '__my_categories__';
