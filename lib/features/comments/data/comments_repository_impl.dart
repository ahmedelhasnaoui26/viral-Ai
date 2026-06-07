import '../domain/comment.dart';
import '../domain/comments_repository.dart';
import 'supabase_comments_datasource.dart';

class CommentsRepositoryImpl implements CommentsRepository {
  CommentsRepositoryImpl(this._dataSource);

  final SupabaseCommentsDataSource _dataSource;

  @override
  Future<List<Comment>> fetchComments(String feedItemId) async {
    final rows = await _dataSource.fetchRows(feedItemId);
    final userId = _dataSource.currentUserId;
    return rows
        .map((r) => Comment.fromMap(r, currentUserId: userId))
        .toList();
  }

  @override
  Future<Comment> postComment({
    required String feedItemId,
    required String text,
    required String videoOwnerId,
  }) async {
    final userId = _dataSource.currentUserId;
    if (userId == null) {
      throw StateError('Sign in to comment');
    }

    final row = await _dataSource.insertComment(
      userId: userId,
      feedItemId: feedItemId,
      text: text.trim(),
    );

    if (videoOwnerId.isNotEmpty && videoOwnerId != userId) {
      final profile = await _dataSource.profileRow(userId);
      final actorName = _displayName(profile, userId);
      await _dataSource.insertNotification({
        'user_id': videoOwnerId,
        'actor_id': userId,
        'type': 'comment',
        'feed_item_id': feedItemId,
        'title': actorName,
        'body': ' commented on your video',
      });
    }

    final profile = await _dataSource.profileRow(userId);
    return Comment.fromMap(
      {...row, if (profile != null) 'profiles': profile},
      currentUserId: userId,
    );
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await _dataSource.deleteRow(commentId);
  }

  String _displayName(Map<String, dynamic>? profile, String userId) {
    final display = profile?['display_name'] as String?;
    if (display != null && display.trim().isNotEmpty) return display.trim();
    final handle = profile?['handle'] as String?;
    if (handle != null && handle.trim().isNotEmpty) return handle.trim();
    return '@${userId.substring(0, 8)}';
  }
}
