import 'dart:io';

import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/network/retry_executor.dart';
import '../domain/generation_job.dart';
import '../domain/generation_repository.dart';
import 'services/cloudflare_r2_service.dart';
import 'services/replicate_service.dart';

/// Facade over R2 + Replicate edge functions (kept for backward compatibility).
class RemoteGenerationRepository implements GenerationRepository {
  RemoteGenerationRepository(this._supabase, this._retryExecutor, Dio dio)
      : _r2 = CloudflareR2Service(_supabase, dio),
        _replicate = ReplicateService(_supabase);

  final SupabaseClient _supabase;
  final RetryExecutor _retryExecutor;
  final CloudflareR2Service _r2;
  final ReplicateService _replicate;

  @override
  Future<({String objectKey, Uri uploadUrl})> createUploadUrl({
    required String fileName,
    required String contentType,
  }) {
    return _r2.createInputUploadUrl(fileName: fileName, contentType: contentType);
  }

  @override
  Future<void> uploadImageFile({
    required File file,
    required Uri uploadUrl,
    required void Function(double progress) onProgress,
  }) {
    return _r2.uploadFile(
      file: file,
      uploadUrl: uploadUrl,
      contentType: 'image/jpeg',
      onProgress: onProgress,
    );
  }

  @override
  Future<GenerationJob> createJob({
    required String objectKey,
    required String prompt,
    required String style,
    required int durationSeconds,
    String? templateId,
  }) {
    return _retryExecutor.run(
      () => _replicate.createPrediction(
        inputObjectKey: objectKey,
        prompt: prompt,
        style: style,
        durationSeconds: durationSeconds,
        templateId: templateId,
      ),
    );
  }

  @override
  Future<GenerationJob> getJob(String jobId) {
    return _retryExecutor.run(() => _replicate.getJob(jobId));
  }

  @override
  Future<String> getSignedDownloadUrl(String objectKey) {
    return _r2.getSignedDownloadUrl(objectKey);
  }

  @override
  Future<void> publishGeneration({
    required String generationJobId,
    required bool postToCommunity,
    required String caption,
    required String thumbnailUrl,
    bool publishTemplate = false,
    String? templateTitle,
    String? templateDescription,
    String? templateCategory,
    bool templateIsPremium = false,
  }) async {
    await _supabase.functions.invoke(
      'publish-generation',
      body: {
        'generationJobId': generationJobId,
        'postToCommunity': postToCommunity,
        'caption': caption,
        'thumbnailUrl': thumbnailUrl,
        'publishTemplate': publishTemplate,
        if (templateTitle != null) 'templateTitle': templateTitle,
        if (templateDescription != null) 'templateDescription': templateDescription,
        if (templateCategory != null) 'templateCategory': templateCategory,
        'templateIsPremium': templateIsPremium,
      },
    );
  }
}
