import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/generation_job.dart';
import '../../domain/video_metadata.dart';
import 'cloudflare_r2_service.dart';
import 'replicate_service.dart';
import 'supabase_video_repository.dart';

/// Orchestrates the full client-side generation flow.
///
/// Architecture (server handles steps 4–7):
/// 1. User uploads image → R2 input key
/// 2. createPrediction() → Replicate inference starts
/// 3. pollPredictionUntilCompleted() → server downloads Replicate output,
///    uploads to R2, saves Supabase metadata
/// 4. UI receives permanent [GenerationJob.r2VideoUrl] / [GenerationJob.outputObjectKey]
class VideoStorageService {
  VideoStorageService({
    required CloudflareR2Service r2Service,
    required ReplicateService replicateService,
    required SupabaseVideoRepository videoRepository,
  })  : _r2 = r2Service,
        _replicate = replicateService,
        _videos = videoRepository;

  final CloudflareR2Service _r2;
  final ReplicateService _replicate;
  final SupabaseVideoRepository _videos;

  /// Upload input image, run inference, poll until permanent R2 URL is ready.
  Future<GenerationJob> generateVideo({
    required File imageFile,
    required String prompt,
    required String style,
    required int durationSeconds,
    String? templateId,
    void Function(double uploadProgress)? onUploadProgress,
    void Function(String statusMessage)? onStatusMessage,
    void Function(int progressPercent)? onProgress,
  }) async {
    // Step 1 — Upload source image to R2 (permanent input storage).
    onStatusMessage?.call('Getting upload URL…');
    final upload = await _r2.createInputUploadUrl(
      fileName: imageFile.uri.pathSegments.last,
      contentType: 'image/jpeg',
    );

    onStatusMessage?.call('Uploading image…');
    await _r2.uploadFile(
      file: imageFile,
      uploadUrl: upload.uploadUrl,
      contentType: 'image/jpeg',
      onProgress: onUploadProgress ?? (_) {},
    );

    // Step 2 — Start Replicate prediction (server-side).
    onStatusMessage?.call('Starting AI generation…');
    final job = await _replicate.createPrediction(
      inputObjectKey: upload.objectKey,
      prompt: prompt,
      style: style,
      durationSeconds: durationSeconds,
      templateId: templateId,
    );

    // Step 3 — Poll until server archives output to R2.
    return pollPredictionUntilCompleted(
      job.id,
      durationSeconds: durationSeconds,
      onStatusMessage: onStatusMessage,
      onProgress: onProgress,
    );
  }

  /// Extended jobs need ~5–8 min per clip plus merge; scale client wait time.
  static int maxPollAttemptsForDuration(int durationSeconds) {
    final clips = durationSeconds <= 5 ? 1 : durationSeconds ~/ 5;
    // ~6 min per clip at 3s interval, minimum 10 min for single clip.
    return (clips * 120).clamp(200, 1800);
  }

  /// Poll the job until completed/failed. Server performs download → R2 → Supabase save.
  Future<GenerationJob> pollPredictionUntilCompleted(
    String jobId, {
    int durationSeconds = 5,
    void Function(String statusMessage)? onStatusMessage,
    void Function(int progressPercent)? onProgress,
    int? maxAttempts,
    Duration interval = const Duration(seconds: 3),
  }) async {
    final attempts = maxAttempts ?? maxPollAttemptsForDuration(durationSeconds);

    for (var attempt = 0; attempt < attempts; attempt++) {
      final job = await _replicate.getJob(jobId);

      if (job.status == GenerationStatus.failed) {
        throw StateError(job.errorMessage ?? 'Video generation failed');
      }

      if (job.status == GenerationStatus.completed) {
        if (!job.hasPermanentStorage) {
          throw StateError(
            'Generation finished but permanent R2 URL is missing. Retry or check backend logs.',
          );
        }
        debugPrint('[VideoStorageService] Permanent URL ready: ${job.r2VideoUrl}');
        return job;
      }

      final elapsed = (attempt + 1) * interval.inSeconds;
      final message = switch (job.status) {
        GenerationStatus.queued => 'Queued… ($elapsed s)',
        GenerationStatus.processing => job.isExtended
            ? 'Generating clip ${job.completedClips + 1}/${job.clipCount}… ($elapsed s)'
            : 'Generating video… ($elapsed s)',
        GenerationStatus.archiving => job.extendPhase == 'merging'
            ? 'Merging clips with ffmpeg… ($elapsed s)'
            : 'Saving to permanent storage… ($elapsed s)',
        _ => 'Working… ($elapsed s)',
      };
      onStatusMessage?.call(message);
      onProgress?.call(job.progressPercent);

      await Future<void>.delayed(interval);
    }

    final last = await _replicate.getJob(jobId);
    if (last.status == GenerationStatus.completed && last.hasPermanentStorage) {
      return last;
    }
    if (last.status == GenerationStatus.failed) {
      throw StateError(last.errorMessage ?? 'Video generation failed');
    }

    final maxMinutes = (attempts * interval.inSeconds) ~/ 60;
    if (last.isExtended) {
      throw StateError(
        'Still processing (${last.completedClips}/${last.clipCount} clips, '
        '${last.progressPercent}% after ~$maxMinutes min). '
        'Check Profile in a few minutes — generation may still finish on the server.',
      );
    }

    throw StateError(
      'Video generation timed out after ~$maxMinutes min. '
      'Check Profile — the server may still be saving to R2.',
    );
  }

  /// Resolve a playable URL — prefer permanent public R2 URL, else sign the object key.
  Future<String> resolvePlayableUrl(GenerationJob job) async {
    if (job.r2VideoUrl != null && job.r2VideoUrl!.startsWith('http')) {
      return job.r2VideoUrl!;
    }
    final key = job.outputObjectKey;
    if (key != null && key.isNotEmpty && !key.startsWith('http')) {
      return _r2.getSignedDownloadUrl(key);
    }
    throw StateError('No permanent video URL available for job ${job.id}');
  }

  Future<VideoMetadata?> fetchMetadata(String jobId) => _videos.fetchByJobId(jobId);
}
