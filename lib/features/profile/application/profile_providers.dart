import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/providers.dart';
import '../../templates/domain/template_item.dart';
import '../data/profile_repository.dart';
import '../domain/profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return null;
  final repo = ref.watch(profileRepositoryProvider);
  await repo.ensureProfile(userId);
  return repo.fetchProfile(userId);
});

final currentUserStatsProvider = FutureProvider<ProfileStats>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return ProfileStats.empty;
  return ref.watch(profileRepositoryProvider).fetchStats(userId);
});

final currentUserVideosProvider = FutureProvider<List<ProfileVideoItem>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(profileRepositoryProvider).fetchPublishedVideos(userId);
});

final currentUserSavedVideosProvider = FutureProvider<List<ProfileVideoItem>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(profileRepositoryProvider).fetchSavedVideos(userId);
});

final currentUserTemplatesProvider = FutureProvider<List<TemplateItem>>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) return [];
  return ref.watch(profileRepositoryProvider).fetchUserTemplates(userId);
});

final creatorDashboardProvider = FutureProvider<CreatorDashboardStats>((ref) async {
  final userId = ref.watch(supabaseClientProvider).auth.currentUser?.id;
  if (userId == null) {
    return const CreatorDashboardStats(
      totalViews: 0,
      totalLikes: 0,
      totalShares: 0,
      totalRemixes: 0,
      videoCount: 0,
      templateUses: 0,
      topVideos: [],
    );
  }
  return ref.watch(profileRepositoryProvider).fetchCreatorDashboard(userId);
});

final featuredCreatorsProvider = FutureProvider<List<FeaturedCreator>>((ref) {
  return ref.watch(profileRepositoryProvider).fetchFeaturedCreators();
});

final creatorProfileProvider = FutureProvider.family<UserProfile?, String>((ref, userId) {
  return ref.watch(profileRepositoryProvider).fetchProfile(userId);
});
