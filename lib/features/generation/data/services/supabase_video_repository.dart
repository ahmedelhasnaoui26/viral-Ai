import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/video_metadata.dart';

/// Reads/writes permanent video metadata from Supabase `generation_jobs`.
class SupabaseVideoRepository {
  SupabaseVideoRepository(this._supabase, {required this.publicAssetBase});

  final SupabaseClient _supabase;
  final String publicAssetBase;

  /// Fetch saved metadata for a completed job.
  Future<VideoMetadata?> fetchByJobId(String jobId) async {
    final row = await _supabase
        .from('generation_jobs')
        .select(
          'id, user_id, input_object_key, prompt, style, duration_seconds, '
          'provider_job_id, r2_video_url, output_object_key, created_at, status',
        )
        .eq('id', jobId)
        .maybeSingle();

    if (row == null) return null;
    if (row['status'] != 'completed') return null;
    return VideoMetadata.fromMap(row, publicAssetBase: publicAssetBase);
  }

  /// List completed videos for the signed-in user (profile / library).
  Future<List<VideoMetadata>> fetchForCurrentUser({int limit = 50}) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    final rows = await _supabase
        .from('generation_jobs')
        .select(
          'id, user_id, input_object_key, prompt, style, duration_seconds, '
          'provider_job_id, r2_video_url, output_object_key, created_at, status',
        )
        .eq('user_id', userId)
        .eq('status', 'completed')
        .not('r2_video_url', 'is', null)
        .order('created_at', ascending: false)
        .limit(limit);

    return (rows as List<dynamic>)
        .map((r) => VideoMetadata.fromMap(
              r as Map<String, dynamic>,
              publicAssetBase: publicAssetBase,
            ))
        .toList();
  }
}
