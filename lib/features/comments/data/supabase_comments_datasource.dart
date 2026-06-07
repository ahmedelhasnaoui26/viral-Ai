import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCommentsDataSource {
  SupabaseCommentsDataSource(this._supabase);

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchRows(String feedItemId) async {
    final rows = await _supabase
        .from('comments')
        .select('id, user_id, feed_item_id, text, created_at')
        .eq('feed_item_id', feedItemId)
        .order('created_at', ascending: true);
    final list = (rows as List<dynamic>).cast<Map<String, dynamic>>();
    if (list.isEmpty) return list;

    final userIds = list.map((r) => r['user_id'] as String).toSet().toList();
    final profiles = await _supabase
        .from('profiles')
        .select('id, handle, display_name')
        .inFilter('id', userIds);
    final profileById = <String, Map<String, dynamic>>{};
    for (final p in profiles as List<dynamic>) {
      final m = p as Map<String, dynamic>;
      profileById[m['id'] as String] = m;
    }

    return list.map((r) {
      final uid = r['user_id'] as String;
      return {...r, 'profiles': profileById[uid]};
    }).toList();
  }

  Future<Map<String, dynamic>> insertComment({
    required String userId,
    required String feedItemId,
    required String text,
  }) async {
    final row = await _supabase
        .from('comments')
        .insert({
          'user_id': userId,
          'feed_item_id': feedItemId,
          'text': text,
        })
        .select('id, user_id, feed_item_id, text, created_at')
        .single();
    return row;
  }

  Future<void> deleteRow(String commentId) async {
    await _supabase.from('comments').delete().eq('id', commentId);
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
}
