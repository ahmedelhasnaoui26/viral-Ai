import '../../domain/feed_item.dart';
import '../../domain/feed_repository.dart';

class FetchFeedUseCase {
  FetchFeedUseCase(this._repository);

  final FeedRepository _repository;

  Future<List<FeedItem>> call({int limit = 40}) => _repository.fetchFeed(limit: limit);
}
