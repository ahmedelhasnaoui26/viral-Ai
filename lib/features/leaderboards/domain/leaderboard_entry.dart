class LeaderboardEntry {
  const LeaderboardEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.score,
    this.thumbnailUrl,
  });

  final String id;
  final String title;
  final String subtitle;
  final int score;
  final String? thumbnailUrl;
}
