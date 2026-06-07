import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/analytics/analytics_event.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/app_env.dart';
import '../../../core/di/providers.dart';
import '../data/remote_generation_repository.dart';
import '../data/services/cloudflare_r2_service.dart';
import '../data/services/replicate_service.dart';
import '../data/services/supabase_video_repository.dart';
import '../data/services/video_storage_service.dart';
import '../domain/generation_repository.dart';
import 'generation_controller.dart';

final cloudflareR2ServiceProvider = Provider<CloudflareR2Service>((ref) {
  return CloudflareR2Service(
    ref.watch(supabaseClientProvider),
    ref.watch(dioProvider),
  );
});

final replicateServiceProvider = Provider<ReplicateService>((ref) {
  return ReplicateService(ref.watch(supabaseClientProvider));
});

final supabaseVideoRepositoryProvider = Provider<SupabaseVideoRepository>((ref) {
  return SupabaseVideoRepository(
    ref.watch(supabaseClientProvider),
    publicAssetBase: AppEnv.publicAssetBaseUrl,
  );
});

final videoStorageServiceProvider = Provider<VideoStorageService>((ref) {
  return VideoStorageService(
    r2Service: ref.watch(cloudflareR2ServiceProvider),
    replicateService: ref.watch(replicateServiceProvider),
    videoRepository: ref.watch(supabaseVideoRepositoryProvider),
  );
});

final generationRepositoryProvider = Provider<GenerationRepository>((ref) {
  return RemoteGenerationRepository(
    ref.watch(supabaseClientProvider),
    ref.watch(retryExecutorProvider),
    ref.watch(dioProvider),
  );
});

final analyticsResolvedProvider = Provider<AnalyticsService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider).asData?.value;
  return analytics ?? const _NoopAnalyticsService();
});

final generationControllerProvider =
    NotifierProvider<GenerationController, GenerationState>(
  GenerationController.new,
);

class _NoopAnalyticsService implements AnalyticsService {
  const _NoopAnalyticsService();

  @override
  Future<void> identify(String userId) async {}

  @override
  Future<void> track(AnalyticsEvent event) async {}
}
