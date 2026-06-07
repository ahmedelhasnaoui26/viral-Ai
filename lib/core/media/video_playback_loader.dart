import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/generation/application/generation_providers.dart';
import '../di/providers.dart';
import '../utils/video_url_resolver.dart';

/// Downloads a feed/profile video to a local file, resolving R2 keys when needed.
Future<File> loadVideoFile(
  WidgetRef ref,
  String videoUrl, {
  String? jobId,
}) async {
  final trimmed = videoUrl.trim();
  if (trimmed.isEmpty) {
    throw StateError('Video URL is missing');
  }

  try {
    return await _downloadResolved(ref, trimmed);
  } catch (error) {
    if (jobId == null || jobId.isEmpty) rethrow;

    final job = await ref.read(generationRepositoryProvider).getJob(jobId);
    final fresh = job.outputUrl?.trim() ?? '';
    if (fresh.isEmpty || fresh == trimmed) rethrow;

    return _downloadResolved(ref, fresh);
  }
}

Future<File> _downloadResolved(WidgetRef ref, String source) async {
  final playUrl = await resolveVideoPlayUrl(ref, source);
  return ref.read(videoCacheServiceProvider).get(playUrl);
}
