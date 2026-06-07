class DraftGeneration {
  const DraftGeneration({
    required this.id,
    required this.imageUrl,
    required this.prompt,
    required this.style,
    required this.duration,
    this.templateId,
    required this.createdAt,
  });

  final String id;
  final String? imageUrl;
  final String prompt;
  final String style;
  final int duration;
  final String? templateId;
  final DateTime createdAt;

  factory DraftGeneration.fromMap(Map<String, dynamic> map) {
    return DraftGeneration(
      id: map['id'] as String,
      imageUrl: map['image_url'] as String?,
      prompt: map['prompt'] as String? ?? '',
      style: map['style'] as String? ?? 'cinematic',
      duration: (map['duration'] as num?)?.toInt() ?? 5,
      templateId: map['template_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
