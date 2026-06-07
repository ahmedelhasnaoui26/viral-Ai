import '../../domain/follow_user.dart';
import '../../domain/social_repository.dart';

class FetchFollowingUseCase {
  FetchFollowingUseCase(this._repository);

  final SocialRepository _repository;

  Future<List<FollowUser>> call(String userId) => _repository.fetchFollowing(userId);
}
