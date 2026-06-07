import '../../../core/utils/creator_display.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import 'supabase_feed_datasource.dart';

class FeedRepositoryImpl implements FeedRepository {
  FeedRepositoryImpl(this._dataSource);

  final SupabaseFeedDataSource _dataSource;

  @override
  Future<List<FeedItem>> fetchFeed({int limit = 40}) async {
    final rows = await _dataSource.fetchFeedRows(limit: limit);
    var items = rows.map(FeedItem.fromMap).toList();
    items.sort((a, b) => b.trendingScore.compareTo(a.trendingScore));
    items = await _enrichWithProfiles(items);

    final userId = _dataSource.currentUserId;
    if (userId == null || items.isEmpty) return items;

    final ids = items.map((e) => e.id).toList();
    final likedIds = await _dataSource.likedFeedIds(userId, ids);
    final savedIds = await _dataSource.savedFeedIds(userId, ids);
    final creatorIds = items.map((e) => e.userId).where((id) => id.isNotEmpty).toSet();
    final followingIds = await _dataSource.followingIds(userId, creatorIds);

    return items
        .map(
          (item) => item.copyWith(
            liked: likedIds.contains(item.id),
            saved: savedIds.contains(item.id),
            followingCreator: followingIds.contains(item.userId),
          ),
        )
        .toList();
  }

  Future<List<FeedItem>> _enrichWithProfiles(List<FeedItem> items) async {
    if (items.isEmpty) return items;

    final creatorIds = items.map((e) => e.userId).where((id) => id.isNotEmpty).toSet().toList();
    final profiles = await _dataSource.profilesByIds(creatorIds);
    final profileById = {for (final p in profiles) p['id'] as String: p};

    return items.map((item) {
      final profile = profileById[item.userId];
      if (profile == null) return item;
      return item.copyWith(
        creatorDisplayName: CreatorDisplay.label(
          displayName: profile['display_name'] as String?,
          handle: profile['handle'] as String? ?? item.creatorHandle,
          userId: item.userId,
        ),
      );
    }).toList();
  }

  @override
  Future<bool> toggleLike(String feedItemId) async {
    final userId = _dataSource.currentUserId;
    if (userId == null) return false;

    final existing = await _dataSource.findLike(userId, feedItemId);
    if (existing != null) {
      await _dataSource.deleteLike(existing['id'] as String);
      return false;
    }

    await _dataSource.insertLike(userId, feedItemId);

    final feedRow = await _dataSource.feedCreatorRow(feedItemId);
    final creatorId = feedRow?['creator_id'] as String?;
    if (creatorId != null && creatorId != userId) {
      final profile = await _dataSource.profileRow(userId);
      await _dataSource.insertNotification({
        'user_id': creatorId,
        'actor_id': userId,
        'type': 'like',
        'feed_item_id': feedItemId,
        'title': _displayName(profile, userId),
        'body': ' liked your video',
      });
    }

    return true;
  }

  @override
  Future<bool> toggleSave(String feedItemId) async {
    final userId = _dataSource.currentUserId;
    if (userId == null) return false;

    final existing = await _dataSource.findSave(userId, feedItemId);
    if (existing != null) {
      await _dataSource.deleteSave(existing['id'] as String);
      return false;
    }

    await _dataSource.insertSave(userId, feedItemId);
    return true;
  }

  @override
  Future<bool> toggleFollow(String creatorId) async {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId == creatorId) return false;

    final existing = await _dataSource.findFollow(userId, creatorId);
    if (existing != null) {
      await _dataSource.deleteFollow(userId, creatorId);
      return false;
    }

    await _dataSource.insertFollow(userId, creatorId);

    final profile = await _dataSource.profileRow(userId);
    await _dataSource.insertNotification({
      'user_id': creatorId,
      'actor_id': userId,
      'type': 'follow',
      'title': _displayName(profile, userId),
      'body': ' started following you',
    });

    return true;
  }

  @override
  Future<void> recordTemplateUse({
    required String templateId,
    required String creatorId,
  }) async {
    final userId = _dataSource.currentUserId;
    if (userId == null || userId == creatorId) return;

    final profile = await _dataSource.profileRow(userId);
    await _dataSource.insertNotification({
      'user_id': creatorId,
      'actor_id': userId,
      'type': 'template_used',
      'template_id': templateId,
      'title': _displayName(profile, userId),
      'body': ' used your template',
    });
  }

  @override
  Future<void> incrementView(String feedItemId) async {
    await _dataSource.incrementViewRpc(feedItemId);
  }

  @override
  Future<void> incrementShare(String feedItemId) async {
    await _dataSource.incrementShareRpc(feedItemId);
  }

  String _displayName(Map<String, dynamic>? profile, String userId) {
    final display = profile?['display_name'] as String?;
    if (display != null && display.trim().isNotEmpty) return display.trim();
    final handle = profile?['handle'] as String?;
    if (handle != null && handle.trim().isNotEmpty) return handle.trim();
    return '@${userId.substring(0, 8)}';
  }
}
