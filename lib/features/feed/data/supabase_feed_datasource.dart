import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseFeedDataSource {
  SupabaseFeedDataSource(this._supabase);

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchFeedRows({int limit = 40}) async {
    final rows = await _supabase
        .from('feed_items')
        .select(
          'id, creator_id, generation_job_id, video_url, thumbnail_url, '
          'template_id, creator_handle, caption, views_count, likes_count, '
          'shares_count, comments_count, created_at',
        )
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Set<String>> likedFeedIds(String userId, List<String> feedIds) async {
    if (feedIds.isEmpty) return {};
    final rows = await _supabase
        .from('likes')
        .select('feed_item_id')
        .eq('user_id', userId)
        .inFilter('feed_item_id', feedIds);
    return (rows as List<dynamic>)
        .map((r) => r['feed_item_id'] as String)
        .toSet();
  }

  Future<Set<String>> savedFeedIds(String userId, List<String> feedIds) async {
    if (feedIds.isEmpty) return {};
    final rows = await _supabase
        .from('saved_posts')
        .select('feed_item_id')
        .eq('user_id', userId)
        .inFilter('feed_item_id', feedIds);
    return (rows as List<dynamic>)
        .map((r) => r['feed_item_id'] as String)
        .toSet();
  }

  Future<Set<String>> followingIds(String userId, Set<String> creatorIds) async {
    if (creatorIds.isEmpty) return {};
    final rows = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId)
        .inFilter('following_id', creatorIds.toList());
    return (rows as List<dynamic>)
        .map((r) => r['following_id'] as String)
        .toSet();
  }

  Future<Map<String, dynamic>?> findLike(String userId, String feedItemId) async {
    return _supabase
        .from('likes')
        .select('id')
        .eq('user_id', userId)
        .eq('feed_item_id', feedItemId)
        .maybeSingle();
  }

  Future<void> deleteLike(String likeId) async {
    await _supabase.from('likes').delete().eq('id', likeId);
  }

  Future<void> insertLike(String userId, String feedItemId) async {
    await _supabase.from('likes').insert({
      'user_id': userId,
      'feed_item_id': feedItemId,
    });
  }

  Future<Map<String, dynamic>?> feedCreatorRow(String feedItemId) async {
    return _supabase
        .from('feed_items')
        .select('creator_id')
        .eq('id', feedItemId)
        .maybeSingle();
  }

  Future<Map<String, dynamic>?> profileRow(String userId) async {
    return _supabase
        .from('profiles')
        .select('handle, display_name')
        .eq('id', userId)
        .maybeSingle();
  }

  Future<void> insertNotification(Map<String, dynamic> payload) async {
    await _supabase.from('notifications').insert(payload);
  }

  Future<Map<String, dynamic>?> findSave(String userId, String feedItemId) async {
    return _supabase
        .from('saved_posts')
        .select('id')
        .eq('user_id', userId)
        .eq('feed_item_id', feedItemId)
        .maybeSingle();
  }

  Future<void> deleteSave(String saveId) async {
    await _supabase.from('saved_posts').delete().eq('id', saveId);
  }

  Future<void> insertSave(String userId, String feedItemId) async {
    await _supabase.from('saved_posts').insert({
      'user_id': userId,
      'feed_item_id': feedItemId,
    });
  }

  Future<Map<String, dynamic>?> findFollow(String userId, String creatorId) async {
    return _supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', userId)
        .eq('following_id', creatorId)
        .maybeSingle();
  }

  Future<void> deleteFollow(String userId, String creatorId) async {
    await _supabase
        .from('follows')
        .delete()
        .eq('follower_id', userId)
        .eq('following_id', creatorId);
  }

  Future<void> insertFollow(String userId, String creatorId) async {
    await _supabase.from('follows').insert({
      'follower_id': userId,
      'following_id': creatorId,
    });
  }

  Future<void> incrementViewRpc(String feedItemId) async {
    await _supabase.rpc('increment_feed_view', params: {'p_feed_item_id': feedItemId});
  }

  Future<void> incrementShareRpc(String feedItemId) async {
    await _supabase.rpc('increment_feed_share', params: {'p_feed_item_id': feedItemId});
  }

  Future<List<Map<String, dynamic>>> profilesByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    final rows = await _supabase
        .from('profiles')
        .select('id, handle, display_name')
        .inFilter('id', userIds);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
