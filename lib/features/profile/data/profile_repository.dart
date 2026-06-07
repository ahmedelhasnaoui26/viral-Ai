import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/creator_display.dart';
import '../../templates/domain/template_item.dart';
import '../domain/profile_models.dart';

class ProfileRepository {
  ProfileRepository(this._supabase);

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<void> ensureProfile(String userId) async {
    final existing = await _supabase
        .from('profiles')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (existing != null) return;

    await _supabase.from('profiles').insert({
      'id': userId,
      'handle': '@${userId.substring(0, 8)}',
      'display_name': 'Creator',
    });
  }

  Future<UserProfile?> fetchProfile(String userId) async {
    final row = await _supabase
        .from('profiles')
        .select('id, handle, display_name, bio, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return UserProfile.fromMap(row);
  }

  Future<ProfileStats> fetchStats(String userId) async {
    final feedRows = await _supabase
        .from('feed_items')
        .select('views_count, likes_count')
        .eq('creator_id', userId);

    var videoCount = 0;
    var totalViews = 0;
    var totalLikes = 0;
    for (final row in feedRows as List<dynamic>) {
      videoCount++;
      totalViews += (row['views_count'] as num?)?.toInt() ?? 0;
      totalLikes += (row['likes_count'] as num?)?.toInt() ?? 0;
    }

    final followers = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    final following = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);

    return ProfileStats(
      videoCount: videoCount,
      totalViews: totalViews,
      totalLikes: totalLikes,
      followersCount: (followers as List).length,
      followingCount: (following as List).length,
    );
  }

  Future<List<ProfileVideoItem>> fetchPublishedVideos(String userId) async {
    final rows = await _supabase
        .from('feed_items')
        .select(
          'id, video_url, thumbnail_url, views_count, likes_count, template_id, created_at, generation_job_id',
        )
        .eq('creator_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) => ProfileVideoItem.fromFeedMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<List<ProfileVideoItem>> fetchSavedVideos(String userId) async {
    final rows = await _supabase
        .from('saved_posts')
        .select(
          'feed_item_id, feed_items(id, video_url, thumbnail_url, views_count, likes_count, template_id, created_at, generation_job_id)',
        )
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (rows as List<dynamic>)
        .map((r) {
          final feed = r['feed_items'] as Map<String, dynamic>?;
          if (feed == null) return null;
          return ProfileVideoItem.fromFeedMap(feed);
        })
        .whereType<ProfileVideoItem>()
        .toList();
  }

  Future<List<TemplateItem>> fetchUserTemplates(String userId) async {
    final rows = await _supabase
        .from('templates')
        .select()
        .eq('creator_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>)
        .map((r) => TemplateItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<CreatorDashboardStats> fetchCreatorDashboard(String userId) async {
    final videos = await fetchPublishedVideos(userId);
    final templates = await fetchUserTemplates(userId);

    var totalViews = 0;
    var totalLikes = 0;
    var totalShares = 0;
    for (final v in videos) {
      totalViews += v.viewsCount;
      totalLikes += v.likesCount;
    }

    final shareRows = await _supabase
        .from('feed_items')
        .select('shares_count')
        .eq('creator_id', userId);
    for (final row in shareRows as List<dynamic>) {
      totalShares += (row['shares_count'] as num?)?.toInt() ?? 0;
    }

    var templateUses = 0;
    for (final t in templates) {
      templateUses += t.usesCount;
    }

    final topVideos = [...videos]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));

    return CreatorDashboardStats(
      totalViews: totalViews,
      totalLikes: totalLikes,
      totalShares: totalShares,
      totalRemixes: templateUses,
      videoCount: videos.length,
      templateUses: templateUses,
      topVideos: topVideos.take(5).toList(),
    );
  }

  Future<List<FeaturedCreator>> fetchFeaturedCreators({int limit = 5}) async {
    final viewerId = currentUserId;

    final feedRows = await _supabase
        .from('feed_items')
        .select('creator_id, creator_handle')
        .not('creator_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(100);

    final counts = <String, int>{};
    final handles = <String, String>{};
    for (final row in feedRows as List<dynamic>) {
      final id = row['creator_id'] as String?;
      if (id == null) continue;
      counts[id] = (counts[id] ?? 0) + 1;
      final rawHandle = row['creator_handle'] as String? ?? '';
      if (!CreatorDisplay.isPlaceholderHandle(rawHandle)) {
        handles[id] = rawHandle;
      }
    }

    final sortedIds = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    Set<String> followingIds = {};
    if (viewerId != null && sortedIds.isNotEmpty) {
      final followRows = await _supabase
          .from('follows')
          .select('following_id')
          .eq('follower_id', viewerId)
          .inFilter('following_id', sortedIds.take(limit).toList());
      followingIds = (followRows as List<dynamic>)
          .map((r) => r['following_id'] as String)
          .toSet();
    }

    final result = <FeaturedCreator>[];
    for (final id in sortedIds.take(limit)) {
      final profile = await fetchProfile(id);
      final stats = await fetchStats(id);
      final handle = profile?.handle ?? handles[id] ?? '';
      result.add(
        FeaturedCreator(
          id: id,
          handle: handle,
          displayName: CreatorDisplay.label(
            displayName: profile?.displayName,
            handle: handle,
            userId: id,
          ),
          followersCount: stats.followersCount,
          isFollowing: followingIds.contains(id),
          isSelf: viewerId == id,
        ),
      );
    }
    return result;
  }

  Future<UserProfile> updateProfile({
    required String userId,
    required String handle,
    required String displayName,
    required String bio,
    String? avatarUrl,
  }) async {
    await ensureProfile(userId);

    final normalizedHandle = _normalizeHandle(handle);

    final row = await _supabase
        .from('profiles')
        .update({
          'handle': normalizedHandle,
          'display_name': displayName,
          'bio': bio,
          'avatar_url': avatarUrl,
        })
        .eq('id', userId)
        .select('id, handle, display_name, bio, avatar_url')
        .maybeSingle();

    if (row == null) {
      throw StateError('Profile update failed. No row was updated.');
    }

    return UserProfile.fromMap(row);
  }

  String _normalizeHandle(String handle) {
    var value = handle.trim();
    if (value.isEmpty) return '@creator';
    if (!value.startsWith('@')) value = '@$value';
    return value;
  }

  Future<bool> isFollowing(String followerId, String followingId) async {
    final row = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('follower_id', followerId)
        .eq('following_id', followingId)
        .maybeSingle();
    return row != null;
  }
}
