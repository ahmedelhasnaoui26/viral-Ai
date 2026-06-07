import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../generation/application/generation_providers.dart';
import '../data/feed_repository_impl.dart';
import '../data/supabase_feed_datasource.dart';
import '../domain/feed_item.dart';
import '../domain/feed_repository.dart';
import 'usecases/fetch_feed_usecase.dart';
import 'usecases/increment_feed_share_usecase.dart';
import 'usecases/toggle_feed_like_usecase.dart';
import 'usecases/toggle_feed_save_usecase.dart';
import 'usecases/toggle_follow_usecase.dart';

final feedDataSourceProvider = Provider<SupabaseFeedDataSource>((ref) {
  return SupabaseFeedDataSource(ref.watch(supabaseClientProvider));
});

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepositoryImpl(ref.watch(feedDataSourceProvider));
});

final fetchFeedUseCaseProvider = Provider<FetchFeedUseCase>((ref) {
  return FetchFeedUseCase(ref.watch(feedRepositoryProvider));
});

final toggleFeedLikeUseCaseProvider = Provider<ToggleFeedLikeUseCase>((ref) {
  return ToggleFeedLikeUseCase(ref.watch(feedRepositoryProvider));
});

final toggleFeedSaveUseCaseProvider = Provider<ToggleFeedSaveUseCase>((ref) {
  return ToggleFeedSaveUseCase(ref.watch(feedRepositoryProvider));
});

final toggleFollowUseCaseProvider = Provider<ToggleFollowUseCase>((ref) {
  return ToggleFollowUseCase(ref.watch(feedRepositoryProvider));
});

final incrementFeedShareUseCaseProvider = Provider<IncrementFeedShareUseCase>((ref) {
  return IncrementFeedShareUseCase(ref.watch(feedRepositoryProvider));
});

final feedControllerProvider =
    AsyncNotifierProvider<FeedController, List<FeedItem>>(FeedController.new);

class FeedController extends AsyncNotifier<List<FeedItem>> {
  @override
  Future<List<FeedItem>> build() async {
    return ref.read(fetchFeedUseCaseProvider)();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(fetchFeedUseCaseProvider)());
  }

  Future<void> toggleLike(String itemId) async {
    final current = state.asData?.value;
    if (current == null) return;

    final index = current.indexWhere((e) => e.id == itemId);
    if (index < 0) return;

    final item = current[index];
    final optimisticLiked = !item.liked;
    final optimisticCount = item.likesCount + (optimisticLiked ? 1 : -1);

    final optimistic = [...current];
    optimistic[index] = item.copyWith(
      liked: optimisticLiked,
      likesCount: optimisticCount.clamp(0, 1 << 30),
    );
    state = AsyncValue.data(optimistic);

    try {
      await ref.read(toggleFeedLikeUseCaseProvider)(itemId);
      await refresh();
    } catch (error, stack) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> toggleSave(String itemId) async {
    final current = state.asData?.value;
    if (current == null) return;

    final index = current.indexWhere((e) => e.id == itemId);
    if (index < 0) return;
    final item = current[index];
    final optimistic = [...current];
    optimistic[index] = item.copyWith(saved: !item.saved);
    state = AsyncValue.data(optimistic);

    try {
      await ref.read(toggleFeedSaveUseCaseProvider)(itemId);
      await refresh();
    } catch (error, stack) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> toggleFollow(String creatorId) async {
    final current = state.asData?.value;
    if (current == null) return;

    final optimistic = current
        .map(
          (item) => item.userId == creatorId
              ? item.copyWith(followingCreator: !item.followingCreator)
              : item,
        )
        .toList();
    state = AsyncValue.data(optimistic);

    try {
      await ref.read(toggleFollowUseCaseProvider)(creatorId);
      await refresh();
    } catch (error, stack) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(error, stack);
    }
  }

  Future<void> prefetch(int index) async {
    final items = state.asData?.value;
    if (items == null || index < 0 || index >= items.length) return;
    try {
      var url = items[index].videoUrl.trim();
      if (!url.startsWith('http')) {
        url = await ref.read(generationRepositoryProvider).getSignedDownloadUrl(url);
      }
      await ref.read(videoCacheServiceProvider).get(url);
    } catch (_) {}
  }

  Future<void> recordView(String feedItemId) async {
    await ref.read(feedRepositoryProvider).incrementView(feedItemId);
  }

  Future<void> recordShare(String itemId) async {
    final current = state.asData?.value;
    if (current == null) return;

    final index = current.indexWhere((e) => e.id == itemId);
    if (index < 0) return;

    final item = current[index];
    final optimistic = [...current];
    optimistic[index] = item.copyWith(sharesCount: item.sharesCount + 1);
    state = AsyncValue.data(optimistic);

    try {
      await ref.read(incrementFeedShareUseCaseProvider)(itemId);
    } catch (error, stack) {
      state = AsyncValue.data(current);
      Error.throwWithStackTrace(error, stack);
    }
  }
}
