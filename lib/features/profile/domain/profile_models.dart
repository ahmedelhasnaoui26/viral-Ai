class UserProfile {
  const UserProfile({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.bio,
    required this.avatarUrl,
  });

  final String id;
  final String handle;
  final String displayName;
  final String bio;
  final String? avatarUrl;

  String get displayLabel =>
      displayName.isNotEmpty ? displayName : (handle.isNotEmpty ? handle : 'Creator');

  static UserProfile fromMap(Map<String, dynamic> row) {
    return UserProfile(
      id: row['id'] as String,
      handle: row['handle'] as String? ?? '',
      displayName: row['display_name'] as String? ?? '',
      bio: row['bio'] as String? ?? '',
      avatarUrl: row['avatar_url'] as String?,
    );
  }
}

class ProfileStats {
  const ProfileStats({
    required this.videoCount,
    required this.totalViews,
    required this.totalLikes,
    required this.followersCount,
    required this.followingCount,
  });

  final int videoCount;
  final int totalViews;
  final int totalLikes;
  final int followersCount;
  final int followingCount;

  static const empty = ProfileStats(
    videoCount: 0,
    totalViews: 0,
    totalLikes: 0,
    followersCount: 0,
    followingCount: 0,
  );
}

class ProfileVideoItem {
  const ProfileVideoItem({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.viewsCount,
    required this.likesCount,
    required this.templateId,
    required this.createdAt,
    this.generationJobId,
  });

  final String id;
  final String videoUrl;
  final String? thumbnailUrl;
  final int viewsCount;
  final int likesCount;
  final String? templateId;
  final DateTime createdAt;
  final String? generationJobId;

  static ProfileVideoItem fromFeedMap(Map<String, dynamic> row) {
    return ProfileVideoItem(
      id: row['id'] as String,
      videoUrl: row['video_url'] as String,
      thumbnailUrl: row['thumbnail_url'] as String?,
      viewsCount: (row['views_count'] as num?)?.toInt() ?? 0,
      likesCount: (row['likes_count'] as num?)?.toInt() ?? 0,
      templateId: row['template_id'] as String?,
      createdAt: DateTime.parse(row['created_at'] as String),
      generationJobId: row['generation_job_id'] as String?,
    );
  }
}

class CreatorDashboardStats {
  const CreatorDashboardStats({
    required this.totalViews,
    required this.totalLikes,
    required this.totalShares,
    required this.totalRemixes,
    required this.videoCount,
    required this.templateUses,
    required this.topVideos,
  });

  final int totalViews;
  final int totalLikes;
  final int totalShares;
  final int totalRemixes;
  final int videoCount;
  final int templateUses;
  final List<ProfileVideoItem> topVideos;
}

class FeaturedCreator {
  const FeaturedCreator({
    required this.id,
    required this.handle,
    required this.displayName,
    required this.followersCount,
    this.isFollowing = false,
    this.isSelf = false,
  });

  final String id;
  final String handle;
  final String displayName;
  final int followersCount;
  final bool isFollowing;
  final bool isSelf;

  FeaturedCreator copyWith({bool? isFollowing}) {
    return FeaturedCreator(
      id: id,
      handle: handle,
      displayName: displayName,
      followersCount: followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isSelf: isSelf,
    );
  }
}
