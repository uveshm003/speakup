enum Difficulty { beginner, intermediate, advanced }

extension DifficultySerialization on Difficulty {
  String get raw => switch (this) {
    Difficulty.beginner => 'beginner',
    Difficulty.intermediate => 'intermediate',
    Difficulty.advanced => 'advanced',
  };
}

Difficulty difficultyFromRaw(String raw) {
  switch (raw.toLowerCase()) {
    case 'beginner':
      return Difficulty.beginner;
    case 'intermediate':
      return Difficulty.intermediate;
    case 'advanced':
      return Difficulty.advanced;
    default:
      return Difficulty.beginner;
  }
}
