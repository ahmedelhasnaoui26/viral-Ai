import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseDraftsDataSource {
  SupabaseDraftsDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<List<Map<String, dynamic>>> fetchRows(String userId) async {
    final rows = await _supabase
        .from('draft_generations')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    return (rows as List<dynamic>).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> insertDraft(Map<String, dynamic> payload) async {
    return _supabase.from('draft_generations').insert(payload).select().single();
  }

  Future<void> deleteRow(String draftId) async {
    await _supabase.from('draft_generations').delete().eq('id', draftId);
  }
}
