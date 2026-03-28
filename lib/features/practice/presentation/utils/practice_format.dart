/// Formats seconds as `m:ss` (e.g. 2:00, 0:45).
String formatPracticeMmSs(int totalSeconds) {
  final int m = totalSeconds ~/ 60;
  final int s = totalSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

/// Human-readable duration for summaries (e.g. "2 min", "45s", "3 min 20s").
String formatPracticeDurationLabel(int seconds) {
  if (seconds <= 0) {
    return '0s';
  }
  if (seconds < 60) {
    return '${seconds}s';
  }
  final int m = seconds ~/ 60;
  final int s = seconds % 60;
  if (s == 0) {
    return '$m min';
  }
  return '$m min ${s}s';
}
