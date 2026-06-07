import '../../domain/comments_repository.dart';

class DeleteCommentUseCase {
  DeleteCommentUseCase(this._repository);

  final CommentsRepository _repository;

  Future<void> call(String commentId) => _repository.deleteComment(commentId);
}
