import 'follow_user.dart';

abstract class SocialRepository {
  Future<List<FollowUser>> fetchFollowers(String userId);
  Future<List<FollowUser>> fetchFollowing(String userId);
}
