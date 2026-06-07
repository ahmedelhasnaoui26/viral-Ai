import '../../domain/comment.dart';
import '../../domain/comments_repository.dart';

class FetchCommentsUseCase {
  FetchCommentsUseCase(this._repository);

  final CommentsRepository _repository;

  Future<List<Comment>> call(String feedItemId) => _repository.fetchComments(feedItemId);
}
