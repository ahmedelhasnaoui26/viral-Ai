String formatCompactCount(int value) {
  if (value >= 1000000) {
    final m = value / 1000000;
    return '${m >= 10 ? m.toStringAsFixed(0) : m.toStringAsFixed(1)}M';
  }
  if (value >= 1000) {
    final k = value / 1000;
    return '${k >= 10 ? k.toStringAsFixed(0) : k.toStringAsFixed(1)}K';
  }
  return '$value';
}
