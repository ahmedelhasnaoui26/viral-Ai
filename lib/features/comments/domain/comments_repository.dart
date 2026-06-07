import 'comment.dart';

abstract class CommentsRepository {
  Future<List<Comment>> fetchComments(String feedItemId);
  Future<Comment> postComment({
    required String feedItemId,
    required String text,
    required String videoOwnerId,
  });
  Future<void> deleteComment(String commentId);
}
