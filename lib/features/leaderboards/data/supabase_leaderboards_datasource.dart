import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseLeaderboardsDataSource {
  SupabaseLeaderboardsDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Map<String, dynamic>>> topVideos({int limit = 20}) async {
    final rows = await _supabase
        .from('feed_items')
        .select('id, creator_handle, caption, thumbnail_url, views_count, likes_count, shares_count')
        .order('views_count', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> topTemplates({int limit = 20}) async {
    final rows = await _supabase
        .from('templates')
        .select('id, title, thumbnail_url, uses_count, likes_count')
        .order('uses_count', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> feedForCreators({int limit = 200}) async {
    final rows = await _supabase
        .from('feed_items')
        .select('creator_id, creator_handle, views_count, likes_count, shares_count')
        .not('creator_id', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> profilesByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    final rows = await _supabase
        .from('profiles')
        .select('id, handle, display_name, avatar_url')
        .inFilter('id', ids);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }
}
