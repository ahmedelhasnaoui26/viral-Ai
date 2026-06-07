class FollowUser {
  const FollowUser({
    required this.id,
    required this.handle,
    required this.displayName,
    this.avatarUrl,
  });

  final String id;
  final String handle;
  final String displayName;
  final String? avatarUrl;

  factory FollowUser.fromProfileMap(Map<String, dynamic> map) {
    final display = map['display_name'] as String?;
    final handle = map['handle'] as String?;
    final id = map['id'] as String;
    return FollowUser(
      id: id,
      handle: handle ?? '',
      displayName: (display?.trim().isNotEmpty == true)
          ? display!.trim()
          : (handle?.trim().isNotEmpty == true ? handle!.trim() : 'Creator'),
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
