import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/generation/application/generation_providers.dart';

/// Resolves a feed video URL or R2 object key to a playable HTTPS URL.
Future<String> resolveVideoPlayUrl(WidgetRef ref, String videoUrl) async {
  final value = videoUrl.trim();
  if (value.isEmpty) {
    throw StateError('Video URL is missing');
  }
  if (value.startsWith('http')) return value;
  return ref.read(generationRepositoryProvider).getSignedDownloadUrl(value);
}
