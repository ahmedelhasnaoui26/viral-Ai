import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseSocialDataSource {
  SupabaseSocialDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<List<String>> followerIds(String userId) async {
    final rows = await _supabase
        .from('follows')
        .select('follower_id')
        .eq('following_id', userId);
    return (rows as List<dynamic>).map((r) => r['follower_id'] as String).toList();
  }

  Future<List<String>> followingIds(String userId) async {
    final rows = await _supabase
        .from('follows')
        .select('following_id')
        .eq('follower_id', userId);
    return (rows as List<dynamic>).map((r) => r['following_id'] as String).toList();
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
