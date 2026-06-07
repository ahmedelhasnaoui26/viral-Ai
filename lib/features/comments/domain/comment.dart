class Comment {
  const Comment({
    required this.id,
    required this.userId,
    required this.feedItemId,
    required this.text,
    required this.createdAt,
    required this.authorLabel,
    this.isOwn = false,
  });

  final String id;
  final String userId;
  final String feedItemId;
  final String text;
  final DateTime createdAt;
  final String authorLabel;
  final bool isOwn;

  factory Comment.fromMap(
    Map<String, dynamic> map, {
    required String? currentUserId,
  }) {
    final profile = map['profiles'] as Map<String, dynamic>?;
    final display = profile?['display_name'] as String?;
    final handle = profile?['handle'] as String?;
    final userId = map['user_id'] as String;
    var label = display?.trim() ?? '';
    if (label.isEmpty) label = handle?.trim() ?? '';
    if (label.isEmpty) label = '@${userId.substring(0, 8)}';

    return Comment(
      id: map['id'] as String,
      userId: userId,
      feedItemId: map['feed_item_id'] as String,
      text: map['text'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      authorLabel: label,
      isOwn: currentUserId != null && userId == currentUserId,
    );
  }
}
