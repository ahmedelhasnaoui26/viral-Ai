class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.createdAt,
    required this.feedItemId,
  });

  final String id;
  final String type;
  final String title;
  final String body;
  final DateTime createdAt;
  final String? feedItemId;

  static NotificationItem fromMap(Map<String, dynamic> row) {
    return NotificationItem(
      id: row['id'] as String,
      type: row['type'] as String,
      title: row['title'] as String,
      body: row['body'] as String,
      createdAt: DateTime.parse(row['created_at'] as String),
      feedItemId: row['feed_item_id'] as String?,
    );
  }
}
