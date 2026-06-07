import '../../domain/feed_repository.dart';

class ToggleFeedSaveUseCase {
  ToggleFeedSaveUseCase(this._repository);

  final FeedRepository _repository;

  Future<bool> call(String feedItemId) => _repository.toggleSave(feedItemId);
}
