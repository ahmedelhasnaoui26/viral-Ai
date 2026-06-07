import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseReportsDataSource {
  SupabaseReportsDataSource(this._supabase);

  final SupabaseClient _supabase;

  String? get currentUserId => _supabase.auth.currentUser?.id;

  Future<Map<String, dynamic>> insertReport(Map<String, dynamic> payload) async {
    return _supabase.from('reports').insert(payload).select().single();
  }

  Future<void> insertModerationQueue(Map<String, dynamic> payload) async {
    await _supabase.from('moderation_queue').insert(payload);
  }
}
