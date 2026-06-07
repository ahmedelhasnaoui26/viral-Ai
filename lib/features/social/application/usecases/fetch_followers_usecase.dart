import '../../domain/follow_user.dart';
import '../../domain/social_repository.dart';

class FetchFollowersUseCase {
  FetchFollowersUseCase(this._repository);

  final SocialRepository _repository;

  Future<List<FollowUser>> call(String userId) => _repository.fetchFollowers(userId);
}
