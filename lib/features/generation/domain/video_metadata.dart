/// Metadata persisted in Supabase after a video is archived to R2.
class VideoMetadata {
  const VideoMetadata({
    required this.id,
    required this.userId,
    required this.originalImageUrl,
    required this.replicatePredictionId,
    required this.prompt,
    required this.style,
    required this.duration,
    required this.r2VideoUrl,
    required this.outputObjectKey,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String originalImageUrl;
  final String? replicatePredictionId;
  final String prompt;
  final String style;
  final int duration;
  final String r2VideoUrl;
  final String outputObjectKey;
  final DateTime createdAt;

  factory VideoMetadata.fromMap(Map<String, dynamic> row, {required String publicAssetBase}) {
    final inputKey = row['input_object_key'] as String? ?? '';
    final base = publicAssetBase.replaceAll(RegExp(r'/$'), '');
    return VideoMetadata(
      id: row['id'] as String,
      userId: row['user_id'] as String,
      originalImageUrl: inputKey.startsWith('http') ? inputKey : '$base/$inputKey',
      replicatePredictionId: row['provider_job_id'] as String?,
      prompt: row['prompt'] as String? ?? '',
      style: row['style'] as String? ?? '',
      duration: (row['duration_seconds'] as num?)?.toInt() ?? 5,
      r2VideoUrl: row['r2_video_url'] as String? ?? '',
      outputObjectKey: row['output_object_key'] as String? ?? '',
      createdAt: DateTime.parse(row['created_at'] as String),
    );
  }
}
