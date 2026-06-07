import '../../../core/utils/creator_display.dart';

class FeedItem {
  const FeedItem({
    required this.id,
    required this.userId,
    required this.generationJobId,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.templateId,
    required this.creatorHandle,
    required this.creatorDisplayName,
    required this.caption,
    required this.viewsCount,
    required this.likesCount,
    required this.sharesCount,
    required this.commentsCount,
    required this.createdAt,
    this.liked = false,
    this.saved = false,
    this.followingCreator = false,
  });

  final String id;
  final String userId;
  final String? generationJobId;
  final String videoUrl;
  final String? thumbnailUrl;
  final String? templateId;
  final String creatorHandle;
  final String creatorDisplayName;
  final String caption;
  final int viewsCount;
  final int likesCount;
  final int sharesCount;
  final int commentsCount;
  final DateTime createdAt;
  final bool liked;
  final bool saved;
  final bool followingCreator;

  FeedItem copyWith({
    bool? liked,
    bool? saved,
    bool? followingCreator,
    int? likesCount,
    int? sharesCount,
    String? creatorDisplayName,
  }) {
    return FeedItem(
      id: id,
      userId: userId,
      generationJobId: generationJobId,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      templateId: templateId,
      creatorHandle: creatorHandle,
      creatorDisplayName: creatorDisplayName ?? this.creatorDisplayName,
      caption: caption,
      viewsCount: viewsCount,
      likesCount: likesCount ?? this.likesCount,
      sharesCount: sharesCount ?? this.sharesCount,
      commentsCount: commentsCount,
      createdAt: createdAt,
      liked: liked ?? this.liked,
      saved: saved ?? this.saved,
      followingCreator: followingCreator ?? this.followingCreator,
    );
  }

  static FeedItem fromMap(
    Map<String, dynamic> row, {
    bool liked = false,
    bool saved = false,
    bool followingCreator = false,
  }) {
    return FeedItem(
      id: row['id'] as String,
      userId: row['creator_id'] as String? ?? '',
      generationJobId: row['generation_job_id'] as String?,
      videoUrl: row['video_url'] as String,
      thumbnailUrl: row['thumbnail_url'] as String?,
      templateId: row['template_id'] as String?,
      creatorHandle: row['creator_handle'] as String,
      creatorDisplayName: CreatorDisplay.label(
        handle: row['creator_handle'] as String?,
        userId: row['creator_id'] as String?,
      ),
      caption: row['caption'] as String,
      viewsCount: (row['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      sharesCount: (row['shares_count'] as num?)?.toInt() ?? 0,
      commentsCount: (row['comments_count'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(row['created_at'] as String),
      liked: liked,
      saved: saved,
      followingCreator: followingCreator,
    );
  }

  int get trendingScore => viewsCount + (likesCount * 3) + (sharesCount * 5);
}
