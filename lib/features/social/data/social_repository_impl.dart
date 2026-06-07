import '../domain/follow_user.dart';
import '../domain/social_repository.dart';
import 'supabase_social_datasource.dart';

class SocialRepositoryImpl implements SocialRepository {
  SocialRepositoryImpl(this._dataSource);

  final SupabaseSocialDataSource _dataSource;

  @override
  Future<List<FollowUser>> fetchFollowers(String userId) async {
    final ids = await _dataSource.followerIds(userId);
    final profiles = await _dataSource.profilesByIds(ids);
    final byId = {for (final p in profiles) p['id'] as String: p};
    return ids
        .map((id) => FollowUser.fromProfileMap(byId[id] ?? {'id': id}))
        .toList();
  }

  @override
  Future<List<FollowUser>> fetchFollowing(String userId) async {
    final ids = await _dataSource.followingIds(userId);
    final profiles = await _dataSource.profilesByIds(ids);
    final byId = {for (final p in profiles) p['id'] as String: p};
    return ids
        .map((id) => FollowUser.fromProfileMap(byId[id] ?? {'id': id}))
        .toList();
  }
}
