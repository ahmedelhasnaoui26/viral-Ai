class TemplateItem {
  const TemplateItem({
    required this.id,
    required this.title,
    required this.description,
    required this.thumbnailUrl,
    required this.prompt,
    required this.style,
    required this.duration,
    required this.aspectRatio,
    required this.category,
    required this.usesCount,
    required this.likesCount,
    required this.sharesCount,
    required this.creatorId,
    required this.isTrending,
    required this.isPremium,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String description;
  final String thumbnailUrl;
  final String prompt;
  final String style;
  final int duration;
  final String aspectRatio;
  final String category;
  final int usesCount;
  final int likesCount;
  final int sharesCount;
  final String? creatorId;
  final bool isTrending;
  final bool isPremium;
  final DateTime createdAt;

  factory TemplateItem.fromMap(Map<String, dynamic> row) {
    return TemplateItem(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String,
      thumbnailUrl: row['thumbnail_url'] as String,
      prompt: row['prompt'] as String,
      style: row['style'] as String,
      duration: (row['duration'] as num?)?.toInt() ?? 5,
      aspectRatio: (row['aspect_ratio'] as String?) ?? '9:16',
      category: row['category'] as String,
      usesCount: (row['uses_count'] as num?)?.toInt() ?? 0,
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      sharesCount: (row['shares_count'] as num?)?.toInt() ?? 0,
      creatorId: row['creator_id'] as String?,
      isTrending: row['is_trending'] as bool? ?? false,
      isPremium: row['is_premium'] as bool? ?? false,
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}
