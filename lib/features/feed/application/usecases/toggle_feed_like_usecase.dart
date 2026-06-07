import '../../domain/feed_repository.dart';

class ToggleFeedLikeUseCase {
  ToggleFeedLikeUseCase(this._repository);

  final FeedRepository _repository;

  Future<bool> call(String feedItemId) => _repository.toggleLike(feedItemId);
}
