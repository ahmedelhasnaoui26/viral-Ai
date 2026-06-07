import 'dart:io';

import 'generation_job.dart';

abstract class GenerationRepository {
  Future<({String objectKey, Uri uploadUrl})> createUploadUrl({
    required String fileName,
    required String contentType,
  });

  Future<void> uploadImageFile({
    required File file,
    required Uri uploadUrl,
    required void Function(double progress) onProgress,
  });

  Future<GenerationJob> createJob({
    required String objectKey,
    required String prompt,
    required String style,
    required int durationSeconds,
    String? templateId,
  });

  Future<GenerationJob> getJob(String jobId);
  Future<String> getSignedDownloadUrl(String objectKey);

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
  });
}
