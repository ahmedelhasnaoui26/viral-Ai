import '../../domain/comment.dart';
import '../../domain/comments_repository.dart';

class PostCommentUseCase {
  PostCommentUseCase(this._repository);

  final CommentsRepository _repository;

  Future<Comment> call({
    required String feedItemId,
    required String text,
    required String videoOwnerId,
  }) =>
      _repository.postComment(
        feedItemId: feedItemId,
        text: text,
        videoOwnerId: videoOwnerId,
      );
}
