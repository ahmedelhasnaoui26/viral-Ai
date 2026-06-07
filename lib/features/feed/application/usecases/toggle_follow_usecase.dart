import '../../domain/feed_repository.dart';

class ToggleFollowUseCase {
  ToggleFollowUseCase(this._repository);

  final FeedRepository _repository;

  Future<bool> call(String creatorId) => _repository.toggleFollow(creatorId);
}
