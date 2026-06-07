import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../data/leaderboards_repository_impl.dart';
import '../data/supabase_leaderboards_datasource.dart';
import '../domain/leaderboard_entry.dart';
import '../domain/leaderboards_repository.dart';
import 'usecases/fetch_top_creators_usecase.dart';
import 'usecases/fetch_top_templates_usecase.dart';
import 'usecases/fetch_top_videos_usecase.dart';

final leaderboardsDataSourceProvider = Provider<SupabaseLeaderboardsDataSource>((ref) {
  return SupabaseLeaderboardsDataSource(ref.watch(supabaseClientProvider));
});

final leaderboardsRepositoryProvider = Provider<LeaderboardsRepository>((ref) {
  return LeaderboardsRepositoryImpl(ref.watch(leaderboardsDataSourceProvider));
});

final fetchTopCreatorsUseCaseProvider = Provider<FetchTopCreatorsUseCase>((ref) {
  return FetchTopCreatorsUseCase(ref.watch(leaderboardsRepositoryProvider));
});

final fetchTopVideosUseCaseProvider = Provider<FetchTopVideosUseCase>((ref) {
  return FetchTopVideosUseCase(ref.watch(leaderboardsRepositoryProvider));
});

final fetchTopTemplatesUseCaseProvider = Provider<FetchTopTemplatesUseCase>((ref) {
  return FetchTopTemplatesUseCase(ref.watch(leaderboardsRepositoryProvider));
});

final topCreatorsLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(fetchTopCreatorsUseCaseProvider).call();
});

final topVideosLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(fetchTopVideosUseCaseProvider).call();
});

final topTemplatesLeaderboardProvider = FutureProvider<List<LeaderboardEntry>>((ref) {
  return ref.watch(fetchTopTemplatesUseCaseProvider).call();
});
