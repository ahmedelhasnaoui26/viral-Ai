import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCreditsDataSource {
  SupabaseCreditsDataSource(this._supabase);

  final SupabaseClient _supabase;

  Future<Map<String, dynamic>?> fetchRow(String userId) async {
    return _supabase
        .from('user_credits')
        .select('balance, plan, watermark_enabled')
        .eq('user_id', userId)
        .maybeSingle();
  }
}
