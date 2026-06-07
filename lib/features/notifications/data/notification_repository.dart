import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/notification_item.dart';

class NotificationRepository {
  NotificationRepository(this._supabase);

  final SupabaseClient _supabase;

  Future<List<NotificationItem>> fetchNotifications({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _supabase
        .from('notifications')
        .select('id, type, title, body, feed_item_id, created_at')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((r) => NotificationItem.fromMap(r as Map<String, dynamic>))
        .toList();
  }
}
