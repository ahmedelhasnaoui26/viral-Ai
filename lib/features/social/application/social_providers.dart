import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/social_repository_impl.dart';
import '../data/supabase_social_datasource.dart';
import '../domain/follow_user.dart';
import '../domain/social_repository.dart';
import 'usecases/fetch_followers_usecase.dart';
import 'usecases/fetch_following_usecase.dart';

final socialDataSourceProvider = Provider<SupabaseSocialDataSource>((ref) {
  return SupabaseSocialDataSource(ref.watch(supabaseClientProvider));
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  return SocialRepositoryImpl(ref.watch(socialDataSourceProvider));
});

final fetchFollowersUseCaseProvider = Provider<FetchFollowersUseCase>((ref) {
  return FetchFollowersUseCase(ref.watch(socialRepositoryProvider));
});

final fetchFollowingUseCaseProvider = Provider<FetchFollowingUseCase>((ref) {
  return FetchFollowingUseCase(ref.watch(socialRepositoryProvider));
});

final followersListProvider = FutureProvider.family<List<FollowUser>, String>((ref, userId) {
  return ref.watch(fetchFollowersUseCaseProvider).call(userId);
});

final followingListProvider = FutureProvider.family<List<FollowUser>, String>((ref, userId) {
  return ref.watch(fetchFollowingUseCaseProvider).call(userId);
});
