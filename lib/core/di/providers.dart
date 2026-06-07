import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../analytics/analytics_service.dart';
import '../analytics/composite_analytics_service.dart';
import '../analytics/mixpanel_analytics_service.dart';
import '../analytics/posthog_analytics_service.dart';
import '../monetization/revenuecat_service.dart';
import '../media/video_cache_service.dart';
import '../network/retry_executor.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final retryExecutorProvider = Provider<RetryExecutor>((ref) {
  return const RetryExecutor();
});

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 120),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
});

final revenueCatServiceProvider = Provider<RevenueCatService>((ref) {
  return RevenueCatService.instance;
});

final revenueCatOfferingsProvider = FutureProvider<Offerings?>((ref) async {
  final service = ref.watch(revenueCatServiceProvider);
  await service.initialize();
  if (!service.isConfigured) return null;
  return service.getOfferings();
});

final analyticsServiceProvider = FutureProvider<AnalyticsService>((ref) async {
  final mixpanel = await MixpanelAnalyticsService.create();
  final posthog = await PosthogAnalyticsService.create();
  return CompositeAnalyticsService([mixpanel, posthog]);
});

final videoCacheServiceProvider = Provider<VideoCacheService>((ref) {
  return VideoCacheService();
});
