import 'package:flutter/material.dart';

import 'entities/challenge_def.dart';

/// The master catalogue of built-in challenges.
/// Keep IDs stable — they are used as Hive storage keys.
const List<ChallengeDef> kBuiltInChallenges = <ChallengeDef>[
  ChallengeDef(
    id: 'debate_7',
    title: '7-Day Debate Boot Camp',
    subtitle: 'Sharpen your argument and counter-argument skills every day.',
    emoji: '💬',
    durationDays: 7,
    tasksPerDay: 1,
    accentColor: Color(0xFF6366F1),
    category: 'Opinion & Debate',
  ),
  ChallengeDef(
    id: 'news_7',
    title: '7-Day Current Affairs',
    subtitle: 'Discuss a fresh news topic each day and expand your world view.',
    emoji: '📰',
    durationDays: 7,
    tasksPerDay: 1,
    accentColor: Color(0xFF2563EB),
    category: 'Current Affairs',
  ),
  ChallengeDef(
    id: 'growth_15',
    title: '15-Day Growth Sprint',
    subtitle: 'Two sessions a day focused on self-improvement topics.',
    emoji: '🌱',
    durationDays: 15,
    tasksPerDay: 2,
    accentColor: Color(0xFF16A34A),
    category: 'Personal Growth',
  ),
  ChallengeDef(
    id: 'story_15',
    title: '15-Day Storytelling',
    subtitle: 'Craft compelling personal narratives one story at a time.',
    emoji: '📖',
    durationDays: 15,
    tasksPerDay: 1,
    accentColor: Color(0xFFDB2777),
    category: 'Storytelling & Personal',
  ),
  ChallengeDef(
    id: 'fluency_30',
    title: '30-Day Fluency Challenge',
    subtitle: 'The ultimate test — two daily sessions across all topics for a month.',
    emoji: '🏆',
    durationDays: 30,
    tasksPerDay: 2,
    accentColor: Color(0xFFF59E0B),
    category: null, // random — all categories
  ),
];
