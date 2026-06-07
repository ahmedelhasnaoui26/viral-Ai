import 'feed_item.dart';

abstract class FeedRepository {
  Future<List<FeedItem>> fetchFeed({int limit = 40});
  Future<bool> toggleLike(String feedItemId);
  Future<bool> toggleSave(String feedItemId);
  Future<bool> toggleFollow(String creatorId);
  Future<void> recordTemplateUse({
    required String templateId,
    required String creatorId,
  });
  Future<void> incrementView(String feedItemId);
  Future<void> incrementShare(String feedItemId);
}
