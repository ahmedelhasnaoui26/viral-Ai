import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/comments_repository_impl.dart';
import '../data/supabase_comments_datasource.dart';
import '../domain/comment.dart';
import '../domain/comments_repository.dart';
import 'usecases/delete_comment_usecase.dart';
import 'usecases/fetch_comments_usecase.dart';
import 'usecases/post_comment_usecase.dart';

final commentsDataSourceProvider = Provider<SupabaseCommentsDataSource>((ref) {
  return SupabaseCommentsDataSource(ref.watch(supabaseClientProvider));
});

final commentsRepositoryProvider = Provider<CommentsRepository>((ref) {
  return CommentsRepositoryImpl(ref.watch(commentsDataSourceProvider));
});

final fetchCommentsUseCaseProvider = Provider<FetchCommentsUseCase>((ref) {
  return FetchCommentsUseCase(ref.watch(commentsRepositoryProvider));
});

final postCommentUseCaseProvider = Provider<PostCommentUseCase>((ref) {
  return PostCommentUseCase(ref.watch(commentsRepositoryProvider));
});

final deleteCommentUseCaseProvider = Provider<DeleteCommentUseCase>((ref) {
  return DeleteCommentUseCase(ref.watch(commentsRepositoryProvider));
});

final commentsForFeedProvider = FutureProvider.family<List<Comment>, String>((ref, feedItemId) {
  return ref.watch(fetchCommentsUseCaseProvider).call(feedItemId);
});
