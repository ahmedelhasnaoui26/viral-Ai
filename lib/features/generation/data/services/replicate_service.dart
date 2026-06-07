import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/generation_job.dart';

/// Thin client for Replicate orchestration — actual inference runs on Supabase Edge Functions.
///
/// The server calls Replicate, downloads the temporary output, uploads to R2, and saves metadata.
class ReplicateService {
  ReplicateService(this._supabase);

  final SupabaseClient _supabase;

  /// Step 2 — Create a generation job (starts Replicate prediction on the server).
  Future<GenerationJob> createPrediction({
    required String inputObjectKey,
    required String prompt,
    required String style,
    required int durationSeconds,
    String? templateId,
  }) async {
    final response = await _supabase.functions.invoke(
      'create-generation-job',
      body: {
        'objectKey': inputObjectKey,
        'prompt': prompt,
        'style': style,
        'durationSeconds': durationSeconds,
        if (templateId != null) 'templateId': templateId,
      },
    );
    return _jobFromMap(_map(response.data));
  }

  /// Step 3 — Poll job status; server archives Replicate output to R2 when ready.
  Future<GenerationJob> pollPredictionUntilCompleted(String jobId) async {
    return getJob(jobId);
  }

  Future<GenerationJob> getJob(String jobId) async {
    final response = await _supabase.functions.invoke(
      'get-generation-job',
      body: {'jobId': jobId},
    );
    return _jobFromMap(_map(response.data));
  }

  GenerationJob _jobFromMap(Map<String, dynamic> data) {
    final status = _statusFrom(data['status'] as String);
    final apiObjectKey = data['objectKey'] as String? ?? '';
    final isCreateResponse = status == GenerationStatus.processing &&
        data['outputUrl'] == null &&
        data['outputObjectKey'] == null;

    return GenerationJob(
      id: data['jobId'] as String,
      status: status,
      inputObjectKey: data['inputObjectKey'] as String? ??
          (isCreateResponse ? apiObjectKey : ''),
      outputObjectKey: data['outputObjectKey'] as String? ??
          data['outputUrl'] as String? ??
          (isCreateResponse ? null : apiObjectKey),
      r2VideoUrl: data['r2VideoUrl'] as String?,
      replicatePredictionId: data['replicatePredictionId'] as String?,
      errorMessage: data['errorMessage'] as String?,
      isExtended: data['isExtended'] as bool? ?? false,
      clipCount: (data['clipCount'] as num?)?.toInt() ?? 1,
      completedClips: (data['completedClips'] as num?)?.toInt() ?? 0,
      progressPercent: (data['progressPercent'] as num?)?.toInt() ?? 0,
      extendPhase: data['extendPhase'] as String?,
      targetDurationSeconds: (data['targetDurationSeconds'] as num?)?.toInt() ?? 5,
    );
  }

  GenerationStatus _statusFrom(String raw) {
    switch (raw) {
      case 'queued':
        return GenerationStatus.queued;
      case 'processing':
        return GenerationStatus.processing;
      case 'archiving':
        return GenerationStatus.archiving;
      case 'completed':
        return GenerationStatus.completed;
      default:
        return GenerationStatus.failed;
    }
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is! Map<String, dynamic>) {
      throw StateError('Unexpected response from generation service');
    }
    return data;
  }
}
