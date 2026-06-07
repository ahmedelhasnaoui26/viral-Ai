import '../../domain/feed_repository.dart';

class IncrementFeedShareUseCase {
  IncrementFeedShareUseCase(this._repository);

  final FeedRepository _repository;

  Future<void> call(String feedItemId) => _repository.incrementShare(feedItemId);
}
